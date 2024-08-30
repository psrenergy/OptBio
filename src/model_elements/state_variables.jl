function state_variables!(
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
    @variable(model, capacity[k = 1:K] >= initial_capacity[k]) # capacity of plant k
    @variable(model, investment[1:K])
    @variable(model, annuity[1:K] >= 0)
    LightBenders.set_state(
        model,
        :capacity,
        capacity[:],
    )
    LightBenders.set_state(
        model,
        :investment,
        investment[:],
    )
    LightBenders.set_state(
        model,
        :annuity,
        annuity[:],
    )
    return nothing
end
