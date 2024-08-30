@kwdef mutable struct OptBioInputs
    db::DatabaseSQLite
    path::String
    config::Configuration = Configuration()
    product::Product = Product()
    process::Process = Process()
    plant::Plant = Plant()
    sum_of_products_constraint::SumOfProductsConstraint = SumOfProductsConstraint()
end

function OptBioInputs(database_path::String, compiled::Bool)
    path = dirname(database_path)

    db = PSRI.load_study(
        PSRI.PSRDatabaseSQLiteInterface(),
        database_path,
        optbio_migrations_dir(; is_compiled = compiled),
    )

    inputs = OptBioInputs(path = path, db = db)

    load!(inputs.config, db)
    load!(inputs.product, db)
    load!(inputs.process, db)
    load!(inputs.plant, db)
    load!(inputs.sum_of_products_constraint, db)

    if has_validation_errors()
        dump_validation_errors(joinpath(path, "validation_errors.json"))
        throw(ValidationException())
    end

    compute_producers_and_consumers!(inputs)
    validate_relations(inputs)

    if inputs.config.scenarios > 1
        if isfile(joinpath(path, "price_scenarios.csv")) && isfile(joinpath(path, "initial_availability_scenarios.csv"))
            read_scenarios!(inputs.product, path, inputs.config.scenarios)
            validate_scenarios(inputs)
        else
            write_scenarios(inputs.product, path, inputs.config.scenarios)
            println(
                "The scenario files have been generated and pre-filled with default values. To customize the scenarios, please edit the files \"initial_availability_scenarios.csv\" and \"price_scenarios.csv\" before rerunning the model.",
            )
            can_model_run = false
            return inputs, can_model_run
        end
    end

    if has_validation_errors()
        dump_validation_errors(joinpath(path, "validation_errors.json"))
        throw(ValidationException())
    end

    calculate_maximum_capacity_and_availability!(inputs)

    can_model_run = true
    return inputs, can_model_run
end

function generate_flowchart(
    process::Process,
    product_label::Vector{String},
    path::String,
    compiled::Bool;
    used_processes::Vector{Bool} = Bool[],
)
    template_path =
        compiled ? joinpath(Sys.BINDIR, "flowchart-template", "optbio_flowchart.html") :
        joinpath(dirname(@__DIR__), "flowchart-template", "optbio_flowchart.html")
    case_flowchart_path =
        isempty(used_processes) ? joinpath(path, "optbio_flowchart.html") :
        joinpath(path, "results", "optbio_flowchart.html")
    open(template_path, "r") do file
        return html_content = read(file, String)
    end
    data = register_relations(process, product_label, path, used_processes)
    html_content = replace(html_content, "data = []" => "data = $data")
    open(case_flowchart_path, "w") do file
        return write(file, html_content)
    end
    return nothing
end

function register_relations(process::Process, product_label::Vector{String}, path::String, used_processes::Vector{Bool})
    if isempty(used_processes)
        used_processes = fill(true, length(process.label))
    end
    data = Vector{Dict{String, Union{String, Int}}}()
    for (j, process_label) in enumerate(process.label)
        process_inputs = process.inputs[j]
        process_outputs = process.outputs[j]
        for i_in in process_inputs
            push!(
                data,
                Dict(
                    "Product" => product_label[i_in],
                    "relation type" => "input",
                    "Process" => process_label,
                    "is used" => Int(used_processes[j]),
                ),
            )
        end
        for i_out in process_outputs
            push!(
                data,
                Dict(
                    "Product" => product_label[i_out],
                    "relation type" => "output",
                    "Process" => process_label,
                    "is used" => Int(used_processes[j]),
                ),
            )
        end
    end
    json_data = JSON.json(data)
    return json_data
end

function optbio_migrations_dir(; is_compiled::Bool = false)
    if is_compiled
        return joinpath(Sys.BINDIR, "database", "migrations")
    else
        return joinpath(dirname(@__DIR__), "database", "migrations")
    end
end

function calculate_maximum_capacity_and_availability!(inputs::OptBioInputs)
    product = inputs.product
    process = inputs.process
    plant = inputs.plant
    I = size(product)
    J = size(process)
    K = size(plant)

    plant_maximum_possible_capacity = zeros(K)
    process_maximum_possible_capacity = zeros(J)
    maximum_availability = zeros(I)
    filled_maximum_capacity = Set{Int}()
    filled_maximum_availability = Set{Int}()

    if all(!isempty, [producers(product, k) for k in 1:K])
        println(
            "Warning: All products from this base are produced by some process. Calculation of maximum capacity of the processes may not work.",
        )
    end

    for i in 1:I
        maximum_availability[i] = maximum(product.initial_availability[i, :])
    end

    for iterator in 1:(I+J)
        for j in 1:J
            if !(j in filled_maximum_capacity)
                j_first_input = process.inputs[j][1]
                if j_first_input in filled_maximum_availability
                    process_maximum_possible_capacity[j] = maximum_availability[j_first_input]
                    push!(filled_maximum_capacity, j)
                    plant_maximum_possible_capacity[process.plant_index[j]] +=
                        process_maximum_possible_capacity[j]
                end
            end
        end
        for i in 1:I
            if !(i in filled_maximum_availability)
                producers_i = producers(product, i)
                if issubset(producers_i, filled_maximum_capacity)
                    for j in producers_i
                        i_index = findfirst(isequal(i), process.outputs[j])
                        maximum_availability[i] +=
                            process_maximum_possible_capacity[j] * process.outputs_factor[j][i_index] /
                            process.inputs_factor[j][1]
                    end
                    push!(filled_maximum_availability, i)
                end
            end
        end
        if length(filled_maximum_capacity) == J && length(filled_maximum_availability) == I
            break
        end
    end

    if length(filled_maximum_capacity) < J || length(filled_maximum_availability) < I
        validation_error(;
            collection = "Process and Product",
            attribute = "Maximum Capacity and Availability",
            message = "Something went wrong while calculating the maximum capacity and availability of the processes and products. Please contact PSR.",
        )
    end

    for k in 1:K
        if !isnan(plant.maximum_capacity[k])
            plant_maximum_possible_capacity[k] = max(plant_maximum_possible_capacity[k], plant.maximum_capacity[k])
        else
            plant_maximum_possible_capacity[k] = max(plant_maximum_possible_capacity[k], plant.initial_capacity[k])
        end
    end

    plant._maximum_possible_capacity = plant_maximum_possible_capacity
    product._maximum_availability = maximum_availability
    return nothing
end

function identify_cycles(product::Product, process::Process)
    # DFS is a famous algorithm that can be used to identify cycles in a graph. It uses recursion through the function depth_first_search_visit.
    # In a directed graph, we use a stack to keep track of the nodes that are antecessors of the current node.
    # Our objective is to tell the user the first product that is part of a cycle and the processes that form this cycle.
    # cycles_head_and_processes below is a list of cycles, and each cycle is a tuple with one product and a list of processes.
    cycles_head_and_processes = depth_first_search(product, process)
    return cycles_head_and_processes
end

function depth_first_search(product::Product, process::Process)
    I = size(product)
    visited_products = zeros(Bool, I)
    product_in_stack = zeros(Bool, I)
    parent_product = zeros(Int, I)
    parent_process = zeros(Int, I)
    cycles_head_and_processes = Tuple{Int, Vector{Int}}[]
    for i in 1:I
        if !visited_products[i]
            depth_first_search_visit!(
                product,
                process,
                i,
                visited_products,
                product_in_stack,
                parent_product,
                parent_process,
                cycles_head_and_processes,
            )
        end
    end
    return cycles_head_and_processes
end

function depth_first_search_visit!(
    product::Product,
    process::Process,
    i::Int,
    visited_products::Vector{Bool},
    product_in_stack::Vector{Bool},
    parent_product::Vector{Int},
    parent_process::Vector{Int},
    cycles::Vector{Tuple{Int, Vector{Int}}},
)
    visited_products[i] = true
    product_in_stack[i] = true
    for j in consumers(product, i)
        for neighbor_of_i in process.outputs[j]
            if !visited_products[neighbor_of_i]
                parent_product[neighbor_of_i] = i
                parent_process[neighbor_of_i] = j
                depth_first_search_visit!(
                    product,
                    process,
                    neighbor_of_i,
                    visited_products,
                    product_in_stack,
                    parent_product,
                    parent_process,
                    cycles,
                )
            else
                if product_in_stack[neighbor_of_i]
                    cycle_head = neighbor_of_i
                    cycle_tail = i
                    processes_in_cycle =
                        compute_processes_in_cycle(parent_process, parent_product, cycle_head, cycle_tail, j)
                    push!(cycles, (cycle_head, processes_in_cycle))
                end
            end
        end
    end
    product_in_stack[i] = false
    return nothing
end

function compute_processes_in_cycle(
    parent_process::Vector{Int},
    parent_product::Vector{Int},
    cycle_head::Int,
    cycle_tail::Int,
    process_index::Int,
)
    process_in_cycle = [process_index]
    current_product = cycle_tail
    while current_product != cycle_head
        current_process = parent_process[current_product]
        push!(process_in_cycle, current_process)
        current_product = parent_product[current_product]
    end
    return process_in_cycle
end

function compute_producers_and_consumers!(inputs::OptBioInputs)
    product = inputs.product
    process = inputs.process
    I = size(product)
    J = size(process)
    product._consumers = Vector{Int}[[] for i in 1:I]
    product._producers = Vector{Int}[[] for i in 1:I]

    for j in 1:J
        for i in process.inputs[j]
            push!(product._consumers[i], j)
        end
        for i in process.outputs[j]
            push!(product._producers[i], j)
        end
    end
end

function validate_process_inputs_and_outputs(process::Process, product::Product)
    for j in eachindex(process.label)
        collection = "Process"
        process_label = process.label[j]
        both_input_and_output = intersect(process.inputs[j], process.outputs[j])
        for i in both_input_and_output
            product_label_i = product.label[i]
            validation_error(;
                collection = collection,
                attribute = "Input and Output",
                identifier = process_label,
                message = "The process '$process_label' is associated with the same product '$product_label_i' in both the 'Input' and 'Output' collections, which is not allowed. Please remove either the 'Input' or 'Output' association containing this link.",
            )
        end
    end
    return nothing
end

function validate_plant_has_processes(plant::Plant, process::Process)
    for k in eachindex(plant.label)
        collection = "Plant"
        plant_label = plant.label[k]
        plant_processes = findall(isequal(k), process.plant_index)

        if isempty(plant_processes)
            validation_error(;
                collection = collection,
                attribute = "Process",
                identifier = plant_label,
                message = "There are no processes associated with the plant '$plant_label'. Please provide a process association for this plant.",
            )
        end
    end
    return nothing
end

function validate_all_processes_in_plant_have_same_unit(plant::Plant, process::Process, product::Product)
    for k in eachindex(plant.label)
        collection = "Plant"
        plant_label = plant.label[k]
        plant_processes = findall(isequal(k), process.plant_index)

        if !isempty(plant_processes)
            process_index = plant_processes[1]
            process_1st_input = process.inputs[process_index][1]
            product_unit = product.unit[process_1st_input]
            plant_unit = product_unit
            for j in plant_processes[2:end]
                product_unit = product.unit[process.inputs[j][1]]
                if product_unit != plant_unit
                    validation_error(;
                        collection = collection,
                        attribute = "Unit",
                        identifier = plant_label,
                        message = "The plant '$plant_label' has processes associated with different units. Please provide processes with the same unit for this plant.
                        Note that the unit of the first input product of the process is used to determine the unit of the process.",
                    )
                end
            end
        end
    end
    return nothing
end

function validate_all_products_in_sum_of_products_constraint_have_same_unit(
    sum_of_products_constraint::SumOfProductsConstraint,
    product::Product,
)
    for g in eachindex(sum_of_products_constraint.label)
        collection = "SumOfProductsConstraint"
        sum_of_products_constraint_label = sum_of_products_constraint.label[g]
        first_product = sum_of_products_constraint.product_id[g][1]
        unit = product.unit[first_product]
        for i in 2:length(sum_of_products_constraint.product_id[g])
            if product.unit[sum_of_products_constraint.product_id[g][i]] != unit
                validation_error(;
                    collection = collection,
                    attribute = "Unit",
                    identifier = sum_of_products_constraint_label,
                    message = "The product set '$sum_of_products_constraint_label' contains products with different units. Please provide products with the same unit for this product set.",
                )
            end
        end
    end
    return nothing
end

function validate_products_and_processes_graph_has_no_cycles(product::Product, process::Process)
    # This validation informs a product in a cycle and the list of processes that form the cycle.
    # It is informed that way because it's easier for the user to check the input and output products if we know the processes.
    cycles_head_and_processes = identify_cycles(product, process)
    for (cycle_head, processes_in_cycle) in cycles_head_and_processes
        cycle_head_label = product.label[cycle_head]
        processes_in_cycle_labels = [process.label[j] for j in processes_in_cycle]
        validation_error(;
            collection = "Product",
            attribute = "Cycle",
            identifier = cycle_head_label,
            message = "The product '$cycle_head_label' is part of a cycle that includes the following processes: $(join(processes_in_cycle_labels, ", ")). Please check if the cycle is correct, and if it is, please contact PSR.",
        )
    end
    return nothing
end

function validate_relations(inputs::OptBioInputs)
    validate_process_inputs_and_outputs(inputs.process, inputs.product)
    validate_plant_has_processes(inputs.plant, inputs.process)
    validate_all_processes_in_plant_have_same_unit(inputs.plant, inputs.process, inputs.product)
    validate_all_products_in_sum_of_products_constraint_have_same_unit(
        inputs.sum_of_products_constraint,
        inputs.product,
    )
    validate_products_and_processes_graph_has_no_cycles(inputs.product, inputs.process)
    return nothing
end

function validate_scenarios(inputs::OptBioInputs)
    product = inputs.product

    for i in eachindex(product.label)
        product_label = product.label[i]
        for s in 1:inputs.config.scenarios
            if product.initial_availability[i, s] < 0
                attribute = "Initial Availability"
                validation_error(;
                    collection = collection,
                    attribute = attribute,
                    identifier = product_label,
                    message = "The '$attribute' attribute for '$product_label' in the '$collection' collection for scenario $s has a negative value. Please provide a value greater than or equal to zero.",
                )
            end
            if product.sell_price[i, s] < 0
                attribute = "Sell Price"
                validation_error(;
                    collection = collection,
                    attribute = attribute,
                    identifier = product_label,
                    message = "The '$attribute' attribute for '$product_label' in the '$collection' collection for scenario $s has a negative value. Please provide a value greater than or equal to zero.",
                )
            end
        end
    end
end

function finalize_inputs!(inputs::OptBioInputs)
    PSRI.PSRDatabaseSQLite.close!(inputs.db)
    return nothing
end

"""
    OptBio.create_case(path_db::String; kwargs...)

Create a case for the OptBio model.

# Arguments

  - `path_db::String`: Path to the database.

  - `kwargs...`: Keyword arguments for the database creation and study configurations.

    For the database creation, the following keyword arguments are available:

      + `force::Bool`: If `true`, the database is created even if it already exists. Default is `false`.
      + `path_migrations_directory::String`: Path to the migrations directory. Suggestions: use `OptBio.optbio_migrations_dir()` to get the migrations directory.

    For the study configurations, the following keyword arguments are available:

      + `scenarios::Int`: Number of uncertainty scenarios. Default is `1`.
      + `solution_method::Int`: Solution method. Fulfill with 0 for deterministic equivalent, 1 for Benders decomposition. Default is `1`.
      + `minimum_iterations::Int`: Minimum number of iterations for the Benders decomposition. Default is `3`.
      + `maximum_iterations::Int`: Maximum number of iterations for the Benders decomposition. Default is `15`.
      + `write_lp`: If `1`, the LP files are written. Default is `0`.

# Returns

  - `db::DatabaseSQLite`: Database for the OptBio model.

# Example

```julia
db = OptBio.create_case(
    "directory_of_the_case/my_case.optbio";
    force = true,
    path_migrations_directory = OptBio.optbio_migrations_dir(),
    scenarios = 3,
)
```
"""
function create_case(
    path_db::String;
    path_migrations_directory::String = optbio_migrations_dir(),
    kwargs...,
)
    db = PSRI.create_study(
        PSRI.PSRDatabaseSQLiteInterface(),
        path_db;
        path_migrations_directory = path_migrations_directory,
        kwargs...,
    )
    return db
end

"""
    OptBio.close_database!(db::DatabaseSQLite)

Close the database for the OptBio model.
"""
function close_database!(db::DatabaseSQLite)
    PSRI.PSRDatabaseSQLite.close!(db)
    return nothing
end
