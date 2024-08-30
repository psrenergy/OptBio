Base.@kwdef struct ProblemResults
    dim0::Dict{String, Float64} = Dict{String, Float64}()
    dim1::Dict{String, Vector{Float64}} =
        Dict{String, Vector{Float64}}()
    dim2::Dict{String, Matrix{Float64}} =
        Dict{String, Matrix{Float64}}()
    dim3::Dict{String, Array{Float64, 3}} =
        Dict{String, Array{Float64, 3}}()
    dim4::Dict{String, Array{Float64, 4}} =
        Dict{String, Array{Float64, 4}}()
    dim5::Dict{String, Array{Float64, 5}} =
        Dict{String, Array{Float64, 5}}()
end
function Base.setindex!(
    problem_results::ProblemResults,
    val::Float64,
    key::String,
)
    return problem_results.dim0[key] = val
end
function Base.setindex!(
    problem_results::ProblemResults,
    val::Vector{Float64},
    key::String,
)
    return problem_results.dim1[key] = val
end
function Base.setindex!(
    problem_results::ProblemResults,
    val::Matrix{Float64},
    key::String,
)
    return problem_results.dim2[key] = val
end
function Base.setindex!(
    problem_results::ProblemResults,
    val::Array{Float64, 3},
    key::String,
)
    return problem_results.dim3[key] = val
end
function Base.setindex!(
    problem_results::ProblemResults,
    val::Array{Float64, 4},
    key::String,
)
    return problem_results.dim4[key] = val
end
function Base.setindex!(
    problem_results::ProblemResults,
    val::Array{Float64, 5},
    key::String,
)
    return problem_results.dim5[key] = val
end

function check_source_exists(link_dict::Dict, number::Int)
    sources = link_dict["source"]
    values = link_dict["value"]
    for i in 1:length(sources)
        if sources[i] == number && values[i] != 0
            # println(" for " * string(i) * "  there is a link leaving")
            return true
        end
    end
    return false
end

function generate_flowchart_with_results(
    case_path::String,
    process::Process,
    product_label::Vector{String},
    problem_results::ProblemResults,
    compiled::Bool,
)
    used_processes = zeros(Bool, size(process))
    process_usage_quantifier = problem_results.dim2["level"]
    for j in 1:size(process)
        if any(process_usage_quantifier[j, :] .> 0)
            used_processes[j] = true
        end
    end
    generate_flowchart(process, product_label, case_path, compiled; used_processes = used_processes)
    return nothing
end

function generate_dashboard(case_path::String, compiled::Bool)
    package_path = dirname(@__DIR__)
    scripts_path = compiled ? joinpath(Sys.BINDIR, "psrio-scripts") : joinpath(package_path, "psrio-scripts")

    results_path = joinpath(case_path, "results")
    psrio = PSRIO.create()
    PSRIO.run(psrio, results_path;
        model = "none",
        recipes = [joinpath(scripts_path, "optbio_dashboard.lua")],
        verbose = 0,
    )
    return nothing
end

function generate_results_menu(case_path::String, compiled::Bool)
    package_path = dirname(@__DIR__)
    scripts_path = compiled ? joinpath(Sys.BINDIR, "psrio-scripts") : joinpath(package_path, "psrio-scripts")

    results_path = joinpath(case_path, "results")
    psrio = PSRIO.create()
    PSRIO.run(psrio, results_path;
        model = "none",
        recipes = [joinpath(scripts_path, "optbio_results_menu.lua")],
        verbose = 0,
    )
    return nothing
end

function write_graf_file(file_path::String, data::Array{Float64, 4}, agents::Vector{String}, unit::String)
    return PSRI.array_to_file(
        GrafCSV.Writer,
        file_path,
        data,
        agents = agents,
        unit = unit,
        initial_stage = 1,
        initial_year = 2024,
    )
end

function calculate_production_consumption_revenue(
    inputs::OptBioInputs,
    f_value::Array{Float64, 3},
    g_value::Array{Float64, 3},
    sell_value::Array{Float64, 2},
)
    I = size(inputs.product)
    S = inputs.config.scenarios

    produced = zeros(I, 1, S, 1)
    consumed = zeros(I, 1, S, 1)
    revenue = zeros(I, 1, S, 1)
    for i in 1:I, s in 1:S
        consumers_i = consumers(inputs.product, i)
        producers_i = producers(inputs.product, i)
        if !isempty(consumers_i)
            consumed[i, 1, s, 1] = sum(f_value[j, i, s] for j in consumers_i)
        end
        if !isempty(producers_i)
            produced[i, 1, s, 1] = sum(g_value[j, i, s] for j in producers_i)
        end
        revenue[i, 1, s, 1] = sell_value[i, s] * inputs.product.sell_price[i, s]
    end
    return produced, consumed, revenue
end

function save_multi_units_product_output(
    file_path::String,
    data::Array{Float64, 4},
    data_name::String,
    product_label::Vector{String},
    product_unit::Vector{String},
)
    I = size(data, 1)
    S = size(data, 3)

    output = Matrix{Union{String, Float64}}(undef, (S + 2, I + 1))
    output[1, :] .= ["Product", product_label...]
    output[2, :] .= ["Unit", product_unit...]
    output[3:end, 1] .= ["$data_name - Scenario $i" for i in 1:S]
    output[3:end, 2:end] = reshape(data, (I, S))'

    CSV.write(file_path * ".csv", Tables.table(output), header = false)

    return nothing
end

function calculate_and_save_financial_results(
    inputs::OptBioInputs,
    results_path::String,
    f_value::Array{Float64, 3},
    penalty_value::Matrix{Float64},
    violation_value::Matrix{Float64},
    annuity_value::Vector{Float64},
    revenue::Array{Float64, 4},
)
    S = inputs.config.scenarios
    I = size(inputs.product)
    J = size(inputs.process)
    K = size(inputs.plant)

    opex = zeros(J, 1, S, 1)
    for j in 1:J, s in 1:S
        i = inputs.process.inputs[j][1]
        opex[j, 1, s, 1] = f_value[j, i, s] * inputs.process.opex[j][1]
    end

    penalty_value = [isnan(penalty_value[i, s]) ? 0.0 : penalty_value[i, s] for i in 1:I, s in 1:S]
    penalty = reshape(penalty_value, (I, 1, S, 1))
    violation = reshape(violation_value, (I, 1, S, 1))
    annuity = reshape(annuity_value, (K, 1, 1, 1))

    write_graf_file(joinpath(results_path, "plants_annuity"), annuity, inputs.plant.label, "\$")
    write_graf_file(joinpath(results_path, "processes_opex"), opex, inputs.process.label, "\$")
    write_graf_file(joinpath(results_path, "products_penalty"), penalty, inputs.product.label, "\$")
    write_graf_file(joinpath(results_path, "products_revenue"), revenue, inputs.product.label, "\$")

    financial_summary_agents = ["Resulting profit", "Sales revenue", "Opex", "Annual Capex", "Violation penalty"]
    financial_summary = zeros(5, 1, S, 1)

    for s in 1:S
        total_revenue = sum(revenue[i, 1, s, 1] for i in 1:I)
        total_opex = sum(opex[j, 1, s, 1] for j in 1:J)
        total_anuities = sum(annuity[k, 1, 1, 1] for k in 1:K)
        total_penalty = sum(penalty[i, 1, s, 1] for i in 1:I)
        resulting_profit = total_revenue - total_opex - total_anuities - total_penalty
        financial_summary[:, 1, s, 1] = [resulting_profit, total_revenue, total_opex, total_anuities, total_penalty]
    end

    write_graf_file(joinpath(results_path, "financial_summary"), financial_summary, financial_summary_agents, "\$")

    return nothing
end

function calculate_and_save_plant_capacity_data(
    inputs::OptBioInputs,
    results_path::String,
    capacity_value::Vector{Float64},
    f_value::Array{Float64, 3},
)
    S = inputs.config.scenarios
    I = size(inputs.product)
    J = size(inputs.process)
    K = size(inputs.plant)

    capacity = reshape(capacity_value, (K, 1, 1, 1))
    used_capacity = zeros(K, 1, S, 1)
    used_capacity_pu = zeros(K, 1, S, 1)
    for k in 1:K, s in 1:S
        if capacity_value[k] > 0
            J_k = [j for j in 1:J if inputs.process.plant_index[j] == k]
            for j in J_k
                first_input = inputs.process.inputs[j][1]
                used_process = f_value[j, first_input, s]
                used_capacity[k, 1, s, 1] += used_process
            end
            used_capacity_pu[k, 1, s, 1] = used_capacity[k, 1, s, 1] / capacity_value[k]
        end
    end

    write_graf_file(joinpath(results_path, "plant_used_capacity_pu"), used_capacity_pu, inputs.plant.label, "pu")

    plants_per_unit = Dict{String, Vector{Int}}()

    for k in 1:K
        j_k = findfirst(inputs.process.plant_index .== k)
        first_input = inputs.process.inputs[j_k][1]
        unit = inputs.product.unit[first_input]
        if !haskey(plants_per_unit, unit)
            plants_per_unit[unit] = Vector{Int}()
        end
        if !(k in plants_per_unit[unit])
            push!(plants_per_unit[unit], k)
        end
    end

    for (unit, indices) in plants_per_unit
        capacity_per_unit = capacity[indices, :, :, :]
        used_capacity_per_unit = used_capacity[indices, :, :, :]

        write_graf_file(
            joinpath(results_path, "plants_capacity_$unit"),
            capacity_per_unit,
            inputs.plant.label[indices],
            unit,
        )
        write_graf_file(
            joinpath(results_path, "plants_used_capacity_$unit"),
            used_capacity_per_unit,
            inputs.process.label[indices],
            unit,
        )

        initial_capacity_per_unit = reshape(inputs.plant.initial_capacity[indices], (length(indices), 1, 1, 1))
        constructed_capacity_per_unit = capacity_per_unit - initial_capacity_per_unit
        write_graf_file(
            joinpath(results_path, "plants_initial_capacity_$unit"),
            initial_capacity_per_unit,
            inputs.process.label[indices],
            unit,
        )
        write_graf_file(
            joinpath(results_path, "plants_constructed_capacity_$unit"),
            constructed_capacity_per_unit,
            inputs.process.label[indices],
            unit,
        )
    end
    return nothing
end

function calculate_and_save_product_balance_data(
    inputs::OptBioInputs,
    results_path::String,
    final_availability_value::Array{Float64, 2},
    sell_value::Array{Float64, 2},
    produced::Array{Float64, 4},
    consumed::Array{Float64, 4},
    violation::Matrix{Float64},
)
    S = inputs.config.scenarios
    I = size(inputs.product)

    products_per_unit = Dict{String, Vector{Int}}()

    for (i, unit) in enumerate(inputs.product.unit)
        if !haskey(products_per_unit, unit)
            products_per_unit[unit] = Vector{Int}()
        end
        push!(products_per_unit[unit], i)
    end

    for (unit, indices) in products_per_unit
        final_availability_per_unit = reshape(final_availability_value[indices, :], (length(indices), 1, S, 1))
        initial_availability_per_unit =
            reshape(inputs.product.initial_availability[indices], (length(indices), 1, 1, 1))
        sell_per_unit = reshape(sell_value[indices, :], (length(indices), 1, S, 1))

        produced_per_unit = produced[indices, :, :, :]
        consumed_per_unit = consumed[indices, :, :, :]
        violation_per_unit = violation[indices, :, :, :]

        write_graf_file(
            joinpath(results_path, "final_availability_$(unit)"),
            final_availability_per_unit,
            inputs.product.label[indices],
            unit,
        )
        write_graf_file(
            joinpath(results_path, "initial_availability_$(unit)"),
            initial_availability_per_unit,
            inputs.product.label[indices],
            unit,
        )
        write_graf_file(joinpath(results_path, "sold_$(unit)"), sell_per_unit, inputs.product.label[indices], unit)
        write_graf_file(
            joinpath(results_path, "produced_$(unit)"),
            produced_per_unit,
            inputs.product.label[indices],
            unit,
        )
        write_graf_file(
            joinpath(results_path, "consumed_$(unit)"),
            consumed_per_unit,
            inputs.product.label[indices],
            unit,
        )
        write_graf_file(
            joinpath(results_path, "violation_$(unit)"),
            violation_per_unit,
            inputs.product.label[indices],
            unit,
        )
    end

    return nothing
end

function save_outputs(
    inputs::OptBioInputs,
    problem_results::ProblemResults,
)
    results_path = joinpath(inputs.path, "results")
    if isdir(results_path)
        rm(results_path; recursive = true)
        mkdir(results_path)
    else
        mkdir(results_path)
    end

    post_processed_investment_and_annuity = post_process_investment_and_annuity(inputs, problem_results)
    capacity_value = problem_results.dim1["capacity"]
    final_availability_value = problem_results.dim2["final_availability"]
    sell_value = problem_results.dim2["sell"]
    f_value = problem_results.dim3["inflow"]
    g_value = problem_results.dim3["outflow"]
    violation_value = problem_results.dim2["minimum_sell_violation"]
    penalty_value = violation_value .* inputs.product.minimum_sell_violation_penalty
    annuity_value = post_processed_investment_and_annuity["annuity"]
    solution = Dict(
        "objective_value" => problem_results.dim0["objective_value"],
        "capacity" => capacity_value,
        "investment" => post_processed_investment_and_annuity["investment"],
        "sell" => sell_value,
    )

    produced, consumed, revenue = calculate_production_consumption_revenue(inputs, f_value, g_value, sell_value)
    sold = reshape(sell_value, (size(inputs.product), 1, inputs.config.scenarios, 1))

    save_multi_units_product_output(
        joinpath(results_path, "unified_produced"),
        produced,
        "Produced",
        inputs.product.label,
        inputs.product.unit,
    )
    save_multi_units_product_output(
        joinpath(results_path, "unified_consumed"),
        consumed,
        "Consumed",
        inputs.product.label,
        inputs.product.unit,
    )
    save_multi_units_product_output(
        joinpath(results_path, "unified_sold"),
        sold,
        "Sold",
        inputs.product.label,
        inputs.product.unit,
    )

    calculate_and_save_financial_results(
        inputs,
        results_path,
        f_value,
        penalty_value,
        violation_value,
        annuity_value,
        revenue,
    )

    calculate_and_save_plant_capacity_data(inputs, results_path, capacity_value, f_value)

    calculate_and_save_product_balance_data(
        inputs,
        results_path,
        final_availability_value,
        sell_value,
        produced,
        consumed,
        violation_value,
    )

    return solution
end
