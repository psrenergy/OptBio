@kwdef mutable struct Process
    label::Vector{String} = String[]
    id::Vector{Int} = Int[]
    opex::Vector{Float64} = Float64[]
    inputs_references::Vector{Vector{String}} = String[]
    outputs_references::Vector{Vector{String}} = String[]
    inputs::Vector{Vector{Int}} = Int[]
    outputs::Vector{Vector{Int}} = Int[]
    inputs_factor::Vector{Vector{Float64}} = Float64[]
    outputs_factor::Vector{Vector{Float64}} = Float64[]
    plant_index::Vector{Int} = Int[]
end

function load!(process::Process, db::DatabaseSQLite)
    collection = "Process"
    J = PSRI.max_elements(db, collection)

    process.label = PSRI.get_parms(db, collection, "label")
    process.id = PSRI.get_parms(db, collection, "id")
    process.opex = PSRI.get_parms(db, collection, "opex")
    process.inputs = PSRI.get_vector_map(db, "Process", "Product", "input")
    process.outputs = PSRI.get_vector_map(db, "Process", "Product", "output")
    process.inputs_references = PSRI.get_vector_references(db, "Process", "Product", "input")
    process.outputs_references = PSRI.get_vector_references(db, "Process", "Product", "output")
    process.inputs_factor = PSRI.get_vectors(db, "Process", "factor_input")
    process.outputs_factor = PSRI.get_vectors(db, "Process", "factor_output")
    process.plant_index = PSRI.get_map(db, collection, "Plant", "id")

    validate(process)

    return process
end

function validate(process::Process)
    collection = "Process"
    n_process = length(process.label)
    if n_process == 0
        validation_error(;
            collection = collection,
            message = "There are no items in the '$collection' collection. Please create at least one process.",
        )
    end
    for j in 1:n_process
        process_label = process.label[j]
        if process.opex[j] < 0
            attribute = "Opex"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = process_label,
                message = "The '$attribute' attribute for '$process_label' in the '$collection' collection has a negative value. Please provide a value greater than or equal to zero.",
            )
        end
        if isempty(process.inputs_references[j])
            attribute = "Input"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = process_label,
                message = "The '$attribute' vector for the process '$process_label' is empty. Please create at least one $attribute association to link this process to a product.",
            )
        else
            for (i, product_string) in enumerate(process.inputs_references[j])
                if isempty(product_string)
                    attribute = "Input"
                    validation_error(;
                        collection = collection,
                        attribute = attribute,
                        identifier = process_label,
                        message = "The '$attribute' vector for the process '$process_label' has an empty 'Product' field at index $i. Please provide a product reference.",
                    )
                end
            end
        end
        if isempty(process.outputs_references[j])
            attribute = "Output"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = process_label,
                message = "The '$attribute' vector for the process '$process_label' is empty. Please create at least one $attribute association to link this process to a product.",
            )
        else
            for (i, product_string) in enumerate(process.outputs_references[j])
                if isempty(product_string)
                    attribute = "Output"
                    validation_error(;
                        collection = collection,
                        attribute = attribute,
                        identifier = process_label,
                        message = "The '$attribute' vector for the process '$process_label' has an empty 'Product' field at index $i. Please provide a product reference.",
                    )
                end
            end
        end
        if any(i -> i <= 0, process.inputs_factor[j])
            attribute = "Input Factor"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = process_label,
                message = "The '$attribute' vector for the process '$process_label' has values less than or equal to zero. Please ensure that only values greater than zero are provided.",
            )
        end
        if any(i -> i <= 0, process.outputs_factor[j])
            attribute = "Output Factor"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = process_label,
                message = "The '$attribute' vector for the process '$process_label' has values less than or equal to zero. Please ensure that only values greater than zero are provided.",
            )
        end
        if process.plant_index[j] == -1
            attribute = "Plant"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = process_label,
                message = "There are no plants associated with the process '$process_label'. Please provide a plant association for this process.",
            )
        end
    end
end

"""
    add_process!(db::DatabaseSQLite; kwargs...)

Add a process to the database.

# Arguments

  - `db::DatabaseSQLite`: Database.
  - `kwargs...`: Keyword arguments with the process attributes.

The following attributes are available:

  - `label::String`: Process label.
  - `opex::Float64`: Operating expense, based the amount of the first product in the input vector that is being processed.
  - `product_input::Vector{String}`: Input product labels.
  - `factor_input::Vector{Float64}`: Vector of factors at which the input products are consumed. Must be ordered according to `product_input`. Each factor is based on the unit of the corresponding product.
  - `product_output::Vector{String}`: Output product labels.
  - `factor_output::Vector{Float64}`: Vector of factors at which the output products are produced. Must be ordered according to `product_output`, and follow proportions to match `inputs_factor`. Each factor is based on the unit of the corresponding product.

# Example

```julia
OptBio.add_process!(
    db;
    label = "Sugar Mill",
    opex = 0.0,
    product_input = ["Sugarcane"],
    factor_input = [1.0],
    product_output = ["Sugar"],
    factor_output = [0.75],
)
```

After creating the process, it is necessary to associate it with a plant. This can be done with the `set_process_plant!` function.
"""
function add_process!(
    db::DatabaseSQLite;
    kwargs...,
)
    return PSRI.create_element!(
        db,
        "Process";
        kwargs...,
    )
end

"""
    OptBio.set_process_plant!(db::DatabaseSQLite, process_label::String, plant_label::String)

Set the plant associated with a process.

# Example

```julia
OptBio.set_process_plant!(db, "Sugar Mill", "Sugar Mill")
```
"""
function set_process_plant!(
    db::DatabaseSQLite,
    process_label::String,
    plant_label::String,
)
    PSRI.set_related!(
        db,
        "Process",
        "Plant",
        process_label,
        plant_label,
        "id",
    )
    return nothing
end

function Base.show(io::IO, process::Process)
    # Should we keep this?
    println(io, "")

    println(io, "label: " * string(process.label))
    println(io, "id: " * string(process.id))

    println(io, "opex: " * string(process.opex))

    println(io, "inputs: " * string(process.inputs))
    println(io, "outputs: " * string(process.outputs))

    println(io, "inputs_factor: " * string(process.inputs_factor))
    println(io, "outputs_factor: " * string(process.outputs_factor))

    return nothing
end

function Base.size(process::Process)
    return length(process.label)
end
