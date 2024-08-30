@kwdef mutable struct Product
    label::Vector{String} = String[]
    id::Vector{Int} = Int[]
    unit::Vector{String} = String[]
    initial_availability::Matrix{Float64} = Matrix{Float64}(undef, (0, 0))
    sell_limit::Vector{Float64} = Float64[]
    sell_price::Matrix{Float64} = Matrix{Float64}(undef, (0, 0))
    minimum_sell_quantity::Vector{Float64} = Float64[]
    minimum_sell_violation_penalty::Vector{Float64} = Float64[]
    # caches
    _consumers::Vector{Vector{Int}} = Vector{Int}[]
    _producers::Vector{Vector{Int}} = Vector{Int}[]
    _maximum_availability::Vector{Float64} = Float64[]
end

function load!(product::Product, db::DatabaseSQLite)
    collection = "Product"

    I = PSRI.max_elements(db, collection)
    product.label = PSRI.get_parms(db, collection, "label")
    product.id = PSRI.get_parms(db, collection, "id")
    product.initial_availability = zeros(I, 1)
    product.initial_availability .= PSRI.get_parms(db, collection, "initial_availability")
    product.sell_limit = PSRI.get_parms(db, collection, "sell_limit")
    product.sell_price = zeros(I, 1)
    product.sell_price .= PSRI.get_parms(db, collection, "sell_price")
    product.unit = PSRI.get_parms(db, collection, "unit")
    product.minimum_sell_quantity = PSRI.get_parms(db, collection, "minimum_sell_quantity")
    product.minimum_sell_violation_penalty = PSRI.get_parms(db, collection, "minimum_sell_violation_penalty")

    validate(product)

    return product
end

function read_scenarios!(product::Product, path::String, S::Int)
    price_scenarios = CSV.read(joinpath(path, "price_scenarios.csv"), DataFrame)
    initial_availability_scenarios = CSV.read(joinpath(path, "initial_availability_scenarios.csv"), DataFrame)
    product.sell_price = Matrix{Float64}(undef, size(product), S)
    product.initial_availability = Matrix{Float64}(undef, size(product), S)
    for s in 1:S, i in 1:size(product)
        product.sell_price[i, s] = parse(Float64, price_scenarios[s+1, i+1])
        product.initial_availability[i, s] = parse(Float64, initial_availability_scenarios[s+1, i+1])
    end

    return product
end

function write_scenarios(product::Product, path::String, S::Int)
    initial_availability = vcat([product.initial_availability' for s in 1:S]...)
    sell_price = vcat([product.sell_price' for s in 1:S]...)
    write_scenarios(
        product.label,
        product.unit,
        path,
        S,
        initial_availability,
        sell_price,
    )
    return nothing
end

"""
    OptBio.write_scenarios(
        product_label::Vector{String},
        product_unit::Vector{String},
        path::String,
        S::Int,
        initial_availability::Matrix{Float64},
        sell_price::Matrix{Float64},
    )

    Write scenarios attributes values to CSV files.

# Arguments

  - `product_label::Vector{String}`: Product labels.
  - `product_unit::Vector{String}`: Product units.
  - `path::String`: The path of the directory where the CSV files will be written.
  - `S::Int`: Number of scenarios.
  - `initial_availability::Matrix{Float64}`: Initial availability of the products for each scenario.
  - `sell_price::Matrix{Float64}`: Sell price of the products for each scenario.

# Example

```julia
product_label = ["Sugar", "Sugarcane"]
product_unit = ["ton", "ton"]

price_scenarios = [
    5000.0 0.0
    4000.0 0.0
    3000.0 0.0
]

initial_availability_scenarios = [
    0.0 100.0
    0.0 150.0
    0.0 80.0
]

OptBio.write_scenarios(
    product_label,
    product_unit,
    "directory_of_the_case",
    3,
    initial_availability_scenarios,
    price_scenarios,
)
```
"""
function write_scenarios(
    product_label::Vector{String},
    product_unit::Vector{String},
    path::String,
    S::Int,
    initial_availability::Matrix{Float64},
    sell_price::Matrix{Float64},
)
    I = length(product_label)

    price_scenarios = Matrix{Union{String, Float64}}(undef, (S + 2, I + 1))
    price_scenarios[1, :] .= ["Product", product_label...]
    price_scenarios[2, :] .= ["Unit", "\$/" .* product_unit...]
    price_scenarios[3:end, 1] .= ["Price - Scenario $s" for s in 1:S]
    price_scenarios[3:end, 2:end] .= sell_price

    CSV.write(
        joinpath(path, "price_scenarios.csv"),
        Tables.table(price_scenarios),
        header = false,
    )

    initial_availability_scenarios = Matrix{Union{String, Float64}}(undef, (S + 2, I + 1))
    initial_availability_scenarios[1, :] .= ["Product", product_label...]
    initial_availability_scenarios[2, :] .= ["Unit", product_unit .* "/year"...]
    initial_availability_scenarios[3:end, 1] .= ["Initial Availability - Scenario $s" for s in 1:S]
    initial_availability_scenarios[3:end, 2:end] .= initial_availability

    CSV.write(
        joinpath(path, "initial_availability_scenarios.csv"),
        Tables.table(initial_availability_scenarios),
        header = false,
    )

    return nothing
end

function consumers(product::Product, i::Int)
    return product._consumers[i]
end

function producers(product::Product, i::Int)
    return product._producers[i]
end

function maximum_availability(product::Product, i::Int)
    return product._maximum_availability[i]
end

function validate(product::Product)
    collection = "Product"
    S = size(product.sell_price)[2]
    n_product = length(product.label)
    if n_product == 0
        validation_error(;
            collection = collection,
            message = "There are no items in the '$collection' collection. Please create at least one product.",
        )
    end
    if all(iszero(product.initial_availability))
        attribute = "Initial Availability"
        validation_error(;
            collection = collection,
            attribute = attribute,
            message = "All items in the '$collection' collection have the '$attribute' attribute set to zero. Please assign an initial value to at least one product.",
        )
    end
    for i in 1:n_product
        product_label = product.label[i]
        if S == 1
            if product.initial_availability[i, 1] < 0
                attribute = "Initial Availability"
                validation_error(;
                    collection = collection,
                    attribute = attribute,
                    identifier = product_label,
                    message = "The '$attribute' attribute for '$product_label' in the '$collection' collection has a negative value. Please provide a value greater than or equal to zero.",
                )
            end
            if product.sell_price[i, 1] < 0
                attribute = "Sell Price"
                validation_error(;
                    collection = collection,
                    attribute = attribute,
                    identifier = product_label,
                    message = "The '$attribute' attribute for '$product_label' in the '$collection' collection has a negative value. Please provide a value greater than or equal to zero.",
                )
            end
        end
        if !isnan(product.sell_limit[i])
            if product.sell_limit[i] < 0
                attribute = "Sell Limit"
                validation_error(;
                    collection = collection,
                    attribute = attribute,
                    identifier = product_label,
                    message = "The '$attribute' attribute for '$product_label' in the '$collection' collection has a negative value. Please provide a value greater than or equal to zero.",
                )
            end
        end
        if !isnan(product.minimum_sell_quantity[i])
            if product.minimum_sell_quantity[i] < 0
                attribute = "Minimum Sell Quantity"
                validation_error(;
                    collection = collection,
                    attribute = attribute,
                    identifier = product_label,
                    message = "The '$attribute' attribute for '$product_label' in the '$collection' collection has a negative value. Please provide a value greater than or equal to zero, or leave it empty.",
                )
            end
            if product.minimum_sell_violation_penalty[i] <= 0
                attribute = "Minimum Sell Violation Penalty"
                validation_error(;
                    collection = collection,
                    attribute = attribute,
                    identifier = product_label,
                    message = "The '$attribute' attribute for '$product_label' in the '$collection' collection has a non-positive value. Please provide a value greater than zero.",
                )
            end
        end
    end
end

"""
    OptBio.add_product!(db::DatabaseSQLite; kwargs...)

Add a product to the database.

# Arguments

  - `db::DatabaseSQLite`: Database.
  - `kwargs...`: Keyword arguments with the product attributes.

The following attributes are available:

  - `label::String`: Product label.
  - `unit::String`: Product unit.
  - `initial_availability::Float64`: Initial availability of the product for a year. Default is `0.0`.
  - `sell_limit::Float64`: Maximum amount of the product that can be sold within a year. Can be left empty.
  - `sell_price::Float64`: Price of the product, based on its unit. Default is `0.0`, meaning the product is not for sale.
  - `minimum_sell_quantity::Float64`: Minimum amount of the product that can be sold within a year. Default is `0.0`.
  - `minimum_sell_violation_penalty::Float64`: Penalty for violating the minimum sell quantity. Needs to be fulfilled if `minimum_sell_quantity` is greater than zero.

# Example

```julia
OptBio.add_product!(
    db;
    label = "Sugar",
    sell_price = 5000.0,
    unit = "ton",
)

OptBio.add_product!(
    db;
    label = "Sugarcane",
    unit = "ton",
    initial_availability = 100.0,
)
```
"""
function add_product!(
    db::DatabaseSQLite;
    kwargs...,
)
    PSRI.create_element!(
        db,
        "Product";
        kwargs...,
    )
    return nothing
end

function Base.show(io::IO, product::Product)
    # Should we keep this?
    println(io, "")

    println(io, "label: " * string(product.label))
    println(io, "id: " * string(product.id))

    println(io, "initial_availability: " * string(product.initial_availability))
    println(io, "sell_limit: " * string(product.sell_limit))
    println(io, "sell_price: " * string(product.sell_price))

    println(io, "unit: " * string(product.unit))

    return nothing
end

function Base.size(product::Product)
    return length(product.label)
end
