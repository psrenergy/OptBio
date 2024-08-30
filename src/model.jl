function variableref(args...)
    return Array{JuMP.VariableRef, length(args)}(undef, args...)
end

function constraintref(args...)
    return Array{JuMP.ConstraintRef, length(args)}(undef, args...)
end

function expressionref(args...)
    return Array{JuMP.AffExpr, length(args)}(undef, args...)
end

abstract type Model end

@kwdef mutable struct OptBioModel <: Model
    jump::JuMP.Model
end

function OptBioModel(inputs::OptBioInputs)
    jump_model = LightBenders.SubproblemModel(direct_model(HiGHS.Optimizer()))
    set_silent(jump_model)
    return OptBioModel(
        jump = jump_model,
    )
end

function annuity_function(
    capacity_base::Float64,
    capex_base::Float64,
    interest_rate::Float64,
    lifespan::Float64,
    scaling_factor::Float64,
)
    if scaling_factor == 1.0
        return function (capacity)
            cap = capex_base * capacity / capacity_base
            annuity = cap * interest_rate / (1 - (1 + interest_rate)^(-lifespan))
            return annuity
        end
    else
        return function (capacity)
            cap = capex_base * (capacity / capacity_base)^scaling_factor
            annuity = cap * interest_rate / (1 - (1 + interest_rate)^(-lifespan))
            return annuity
        end
    end
end

function exponential_section_points_normalized(ratio::Float64, n_sections::Int)
    first_value = (ratio - 1) / (ratio^n_sections - 1)
    sections_points = first_value * [(ratio^i - 1) / (ratio - 1) for i in 1:n_sections]
    sections_points = [0.0, sections_points...]
    return sections_points
end

function capacity_section_points(
    maximum_capacity::Float64,
    maximum_capacity_for_scale::Float64,
    n_sections::Int,
    ratio::Float64,
)
    if isnan(maximum_capacity_for_scale)
        maximum_capacity_for_scale = Inf
    end
    if maximum_capacity_for_scale > maximum_capacity
        sections_points = exponential_section_points_normalized(ratio, n_sections) * maximum_capacity
    else
        sections_points = exponential_section_points_normalized(ratio, n_sections) * maximum_capacity_for_scale
    end
    return sections_points
end

function solve_model(inputs::OptBioInputs)
    if is_deterministic_equivalent(inputs.config)
        return deterministic_equivalent(inputs)
    elseif is_benders(inputs.config)
        return benders(inputs)
    end
end

function check_future_cost_lower_bound_correctness(future_cost_value::Vector{Float64}, inputs::OptBioInputs)
    for s in 1:inputs.config.scenarios
        correct_lower_bound =
            -sum(
                maximum_availability(inputs.product, i) * inputs.product.sell_price[i, s] for
                i in 1:size(inputs.product)
            )
        if future_cost_value[s] < correct_lower_bound
            @warn "The lower bound calculation for the problem might be incorrect."
        end
    end
    return nothing
end

function post_process_investment_and_annuity(
    inputs::OptBioInputs,
    problem_results,
)
    initial_capacity = inputs.plant.initial_capacity
    maximum_capacity_for_scale = inputs.plant.maximum_capacity_for_scale
    reference_capex = inputs.plant.reference_capex
    reference_capacity = inputs.plant.reference_capacity
    scaling_factor = inputs.plant.scaling_factor
    lifespan = inputs.plant.lifespan
    interest_rate = inputs.plant.interest_rate

    investment = problem_results.dim1["investment"]
    annuity = zeros(size(inputs.plant))

    for k in 1:size(inputs.plant)
        if !isnan(maximum_capacity_for_scale[k])
            if initial_capacity[k] < maximum_capacity_for_scale[k]
                investment_for_initial_capacity =
                    reference_capex[k] * (initial_capacity[k] / reference_capacity[k])^scaling_factor[k]
                investment[k] = investment[k] - investment_for_initial_capacity
            else
                investment_for_maximum_scale_capacity =
                    reference_capex[k] * (maximum_capacity_for_scale[k] / reference_capacity[k])^scaling_factor[k]
                investment_for_initial_capacity =
                    investment_for_maximum_scale_capacity * initial_capacity[k] / maximum_capacity_for_scale[k]
                investment[k] = investment[k] - investment_for_initial_capacity
            end
        else
            investment_for_initial_capacity =
                reference_capex[k] * (initial_capacity[k] / reference_capacity[k])^scaling_factor[k]
            investment[k] = investment[k] - investment_for_initial_capacity
        end

        annuity[k] = investment[k] * interest_rate[k] / (1 - (1 + interest_rate[k])^(-lifespan[k]))
    end

    post_processed_investment_and_annuity = Dict(
        "investment" => investment,
        "annuity" => annuity,
    )
    return post_processed_investment_and_annuity
end

function get_variable_value(model::OptBioModel, name::Symbol)
    variable = model.jump[name]

    value = fill(NaN, size(variable))
    for i in eachindex(variable)
        if isassigned(variable, i)
            value[i] = JuMP.value(variable[i])
            value[i] = round(value[i], digits = 4)
        end
    end
    return value
end
