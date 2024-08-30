@kwdef mutable struct SumOfProductsConstraint
    label::Vector{String} = String[]
    id::Vector{Int} = Int[]
    product_id::Vector{Vector{Int}} = Vector{Int}[]
    product_reference::Vector{Vector{String}} = Vector{String}[]
    sell_limit::Vector{Float64} = Float64[]
end

function load!(sum_of_products_constraint::SumOfProductsConstraint, db::DatabaseSQLite)
    collection = "SumOfProductsConstraint"

    sum_of_products_constraint.label = PSRI.get_parms(db, collection, "label")
    sum_of_products_constraint.id = PSRI.get_parms(db, collection, "id")
    sum_of_products_constraint.product_id = PSRI.get_vector_map(db, collection, "Product", "id")
    sum_of_products_constraint.product_reference = PSRI.get_vector_references(db, collection, "Product", "id")
    sum_of_products_constraint.sell_limit = PSRI.get_parms(db, collection, "sell_limit")

    validate(sum_of_products_constraint)

    return sum_of_products_constraint
end

function validate(sum_of_products_constraint::SumOfProductsConstraint)
    collection = "SumOfProductsConstraint"
    n_sum_of_products_constraints = size(sum_of_products_constraint)
    for g in 1:n_sum_of_products_constraints
        sum_of_products_constraint_label = sum_of_products_constraint.label[g]
        if sum_of_products_constraint.sell_limit[g] < 0
            attribute = "Sell Limit"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = sum_of_products_constraint_label,
                message = "The '$attribute' attribute for '$sum_of_products_constraint_label' in the '$collection' collection has a negative value. Please provide a value greater than or equal to zero.",
            )
        end
        if isempty(sum_of_products_constraint.product_reference[g])
            attribute = "Product"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = sum_of_products_constraint_label,
                message = "The '$attribute' vector for the sum of products constraint '$sum_of_products_constraint_label' is empty. Please create at least one $attribute association to link this sum of products constraint to a product.",
            )
        end
        empty_rows = 0
        for i in 1:length(sum_of_products_constraint.product_reference[g])
            if isempty(sum_of_products_constraint.product_reference[g][i])
                empty_rows += 1
            end
        end
        if empty_rows > 0
            attribute = "Product"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = sum_of_products_constraint_label,
                message = "The '$attribute' vector for the sum of products constraint '$sum_of_products_constraint_label' has $(empty_rows) empty element(s). Please provide valid product references or delete the rows.",
            )
        end
    end
end

"""
    add_sum_of_products_constraint!(db::DatabaseSQLite; kwargs...)

Add a sum of products constraint to the database.

# Arguments

  - `db::DatabaseSQLite`: Database
  - `kwargs...`: Keyword arguments with the sum of products constraint attributes.

The following attributes are available:

  - `label::String`: Sum of products constraint label.
  - `product_id::Vector{String}`: Vector with labels of products to be included in the sum of products constraint.
  - `sell_limit::Float64`: Sell limit for the sum of products in the vector.

# Example

```julia
OptBio.add_sum_of_products_constraint!(
    db;
    label = "Ethanol",
    product_id = ["Ethanol 1G", "Ethanol 2G"],
    sell_limit = 2000.0,
)
```
"""
function add_sum_of_products_constraint!(
    db::DatabaseSQLite;
    kwargs...,
)
    return PSRI.create_element!(
        db,
        "SumOfProductsConstraint";
        kwargs...,
    )
end

function Base.size(sum_of_products_constraint::SumOfProductsConstraint)
    return length(sum_of_products_constraint.label)
end
