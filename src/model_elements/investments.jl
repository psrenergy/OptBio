function investments!(
    model::JuMP.Model,
    inputs::OptBioInputs,
)
    # load inputs
    K = size(inputs.plant)
    S = inputs.config.scenarios
    reference_capex = inputs.plant.reference_capex
    reference_capacity = inputs.plant.reference_capacity
    scaling_factor = inputs.plant.scaling_factor
    interest_rate = inputs.plant.interest_rate
    lifespan = inputs.plant.lifespan
    maximum_capacity = inputs.plant.maximum_capacity
    initial_capacity = inputs.plant.initial_capacity
    maximum_capacity_for_scale = inputs.plant.maximum_capacity_for_scale

    # variables
    ## load state variables
    capacity = model[:capacity]
    investment = model[:investment]
    annuity = model[:annuity]

    # constraints
    for k in 1:K
        if scaling_factor[k] != 1.0
            investment_function(capacity_entry) =
                reference_capex[k] * (capacity_entry / reference_capacity[k])^scaling_factor[k]

            capacity_domain = capacity_section_points(
                maximum_possible_capacity(inputs.plant, k),
                maximum_capacity_for_scale[k],
                100,
                1.05,
            )

            investment_over_capacity = [investment_function(x) for x in capacity_domain]
            if !isnan(maximum_capacity_for_scale[k]) &&
               maximum_capacity_for_scale[k] < maximum_possible_capacity(inputs.plant, k)
                push!(capacity_domain, maximum_possible_capacity(inputs.plant, k))
                push!(
                    investment_over_capacity,
                    investment_function(capacity_domain[end-1]) * capacity_domain[end] / capacity_domain[end-1],
                )
            end

            @constraint(
                model,
                investment[k] == piecewiselinear(model, capacity[k], capacity_domain, investment_over_capacity),
            )
        end
    end
    @constraint(
        model,
        max_capacity[k = 1:K; !isnan(maximum_capacity[k])],
        capacity[k] <= maximum_capacity[k],
    )
    @constraint(
        model,
        linear_scale[k = 1:K; scaling_factor[k] == 1.0],
        investment[k] == reference_capex[k] * capacity[k] / reference_capacity[k],
    )
    @constraint(
        model,
        annuity_con[k = 1:K],
        annuity[k] == investment[k] * interest_rate[k] / (1 - (1 + interest_rate[k])^(-lifespan[k]))
    )
    @objective(model, Min, sum(annuity[k] for k in 1:K) + 0.0)
    return nothing
end
