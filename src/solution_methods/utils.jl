function state_variables_builder(inputs)
    model = OptBioModel(inputs)
    state_variables!(model.jump, inputs)
    return model.jump
end

function first_stage_builder(model, inputs)
    investments!(model, inputs)
    return model
end

function second_stage_builder(model, inputs)
    operation!(model, inputs)
    return model
end

function second_stage_modifier(model, inputs, s)
    sell = model[:sell]
    initial_availability = model[:initial_availability]
    for i in 1:size(inputs.product)
        JuMP.set_objective_coefficient(
            model,
            sell[i],
            -inputs.product.sell_price[i, s],
        ) # this is done so that the sell price is updated for each scenario
        # and the objective function is an affine function
        JuMP.fix(initial_availability[i], inputs.product.initial_availability[i, s]; force = true)
    end
    return nothing
end

function gather_light_benders_results(
    results::Dict{Tuple{String, Int}, Any},
    num_scenarios::Int,
)
    problem_results = ProblemResults()
    first_stage_var = ["capacity", "investment", "annuity"]
    two_dim_vars = ["final_availability", "sell", "level", "minimum_sell_violation"]
    three_dim_vars = ["inflow", "outflow"]
    setindex!(problem_results, results["objective", 0], "objective_value")
    for variable in first_stage_var
        value = results[variable, 1]
        setindex!(problem_results, round.(value, digits = 4), variable)
    end
    for variable in two_dim_vars
        value = zeros(size(results[variable, 1], 1), num_scenarios)
        for s in 1:num_scenarios
            value[:, s] = results[variable, s]
        end
        setindex!(problem_results, round.(value, digits = 4), variable)
    end
    for variable in three_dim_vars
        value = zeros(size(results[variable, 1], 1), size(results[variable, 1], 2), num_scenarios)
        for s in 1:num_scenarios
            value[:, :, s] = results[variable, s]
        end
        setindex!(problem_results, round.(value, digits = 4), variable)
    end
    return problem_results
end
