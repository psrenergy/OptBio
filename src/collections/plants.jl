@kwdef mutable struct Plant
    label::Vector{String} = String[]
    id::Vector{Int} = Int[]
    initial_capacity::Vector{Float64} = Float64[]
    reference_capex::Vector{Float64} = Float64[]
    reference_capacity::Vector{Float64} = Float64[]
    scaling_factor::Vector{Float64} = Float64[]
    interest_rate::Vector{Float64} = Float64[]
    lifespan::Vector{Int} = Int[]
    maximum_capacity::Vector{Float64} = Float64[]
    maximum_capacity_for_scale::Vector{Float64} = Float64[]
    # caches
    _maximum_possible_capacity::Vector{Float64} = Float64[]
end

function load!(plant::Plant, db::DatabaseSQLite)
    collection = "Plant"

    plant.label = PSRI.get_parms(db, collection, "label")
    plant.id = PSRI.get_parms(db, collection, "id")
    plant.initial_capacity = PSRI.get_parms(db, collection, "initial_capacity")
    plant.reference_capex = PSRI.get_parms(db, collection, "reference_capex")
    plant.reference_capacity = PSRI.get_parms(db, collection, "reference_capacity")
    plant.scaling_factor = PSRI.get_parms(db, collection, "scaling_factor")
    plant.interest_rate = PSRI.get_parms(db, collection, "interest_rate")
    plant.lifespan = PSRI.get_parms(db, collection, "lifespan")
    plant.maximum_capacity = PSRI.get_parms(db, collection, "maximum_capacity")
    plant.maximum_capacity_for_scale = PSRI.get_parms(db, collection, "maximum_capacity_for_scale")

    validate(plant)

    return plant
end

function maximum_possible_capacity(plant::Plant, k::Int)
    return plant._maximum_possible_capacity[k]
end

function validate(plant::Plant)
    collection = "Plant"
    n_plants = length(plant.label)
    if n_plants == 0
        validation_error(;
            collection = collection,
            message = "There are no items in the '$collection' collection. Please create at least one plant.",
        )
    end
    for k in 1:n_plants
        plant_label = plant.label[k]
        if plant.reference_capex[k] < 0
            attribute = "Capex"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = plant_label,
                message = "The '$attribute' attribute for '$plant_label' in the '$collection' collection has a negative value. Please provide a value greater than or equal to zero.",
            )
        end
        if plant.reference_capacity[k] < 0
            attribute = "Reference Capacity"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = plant_label,
                message = "The '$attribute' attribute for '$plant_label' in the '$collection' collection has a value less than or equal to zero. Please enter a value greater than zero.",
            )
        end
        if plant.scaling_factor[k] <= 0
            attribute = "Scalling Factor"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = plant_label,
                message = "The '$attribute' attribute for '$plant_label' in the '$collection' collection has a value less than or equal to zero. Please enter a value greater than zero.",
            )
        end
        if plant.lifespan[k] < 1
            attribute = "Lifespan"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = plant_label,
                message = "The '$attribute' attribute for '$plant_label' in the '$collection' collection has a value less than one. Please enter a value greater than or equal to one.",
            )
        end
        if plant.initial_capacity[k] < 0
            attribute = "Initial Capacity"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = plant_label,
                message = "The '$attribute' attribute for '$plant_label' in the '$collection' collection has a negative value. Please provide a value greater than or equal to zero.",
            )
        end
        if plant.maximum_capacity[k] < 0
            attribute = "Maximum Capacity"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = plant_label,
                message = "The '$attribute' attribute for '$plant_label' in the '$collection' collection has a negative value. Please provide a value greater than or equal to zero.",
            )
        elseif plant.maximum_capacity[k] < plant.initial_capacity[k]
            attribute = "Maximum Capacity"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = plant_label,
                message = "The '$attribute' attribute for '$plant_label' in the '$collection' collection is less than the initial capacity. Please provide a value greater than or equal to the initial capacity.",
            )
        end
        if plant.maximum_capacity_for_scale[k] < 0
            attribute = "Maximum Capacity for Scale"
            validation_error(;
                collection = collection,
                attribute = attribute,
                identifier = plant_label,
                message = "The '$attribute' attribute for '$plant_label' in the '$collection' collection has a negative value. Please provide a value greater than or equal to zero.",
            )
        end
    end
end

"""
    OptBio.add_plant!(db::DatabaseSQLite; kwargs...)

Add a plant to the database.

# Arguments

  - `db::DatabaseSQLite`: Database.
  - `kwargs...`: Keyword arguments with the plant attributes.

The following attributes are available:

  - `label::String`: Plant label.
  - `initial_capacity::Float64`: Initial capacity of the plant for a year. Default is `0.0`.
  - `reference_capex::Float64`: Capex of a reference plant.
  - `reference_capacity::Float64`: Capacity of the reference plant.
  - `scaling_factor::Float64`: Factor to scale the relation between capacity and capex according to the reference plant. Default is `0.7`.
  - `interest_rate::Float64`: Annual interest rate for the Capex. Default is `0.1`.
  - `lifespan::Int`: Years of lifespan for the plant. Defines the amount of installment payments for the Capex. Default is `20`.
  - `maximum_capacity::Float64`: Maximum capacity of the plant for a year. Can be left empty.
  - `maximum_capacity_for_scale::Float64`: Maximum capacity of the plant at which the scaling factor is applied. After this capacity, the Capex is linearly scaled with the capacity. Can be left empty.

# Example

```julia
OptBio.add_plant!(
    db;
    label = "Sugar Mill",
    reference_capacity = 100.0,
    reference_capex = 52000.0,
)
```
"""
function add_plant!(
    db::DatabaseSQLite;
    kwargs...,
)
    return PSRI.create_element!(
        db,
        "Plant";
        kwargs...,
    )
end

function Base.size(plant::Plant)
    return length(plant.label)
end
