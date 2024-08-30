function benders(
    inputs::OptBioInputs,
)
    I = size(inputs.product)
    num_scenarios = inputs.config.scenarios
    num_openings = num_scenarios # two-stage problem has one opening per scenario
    max_iteration = inputs.config.maximum_iterations

    policy_training_options = LightBenders.PolicyTrainingOptions(;
        num_scenarios = num_scenarios,
        lower_bound = -1.05 *
                      1 / num_scenarios * sum(
            maximum_availability(inputs.product, i) * inputs.product.sell_price[i, s] for i in 1:I,
            s in 1:num_scenarios
        ),
        implementation_strategy = LightBenders.BendersSerialTraining(),
        stopping_rule = LightBenders.GapWithMinimumNumberOfIterations(;
            abstol = 1,
            min_iterations = inputs.config.minimum_iterations,
        ),
        debugging_options = LightBenders.DebuggingOptions(;
            logs_dir = joinpath(inputs.path, "training_logs"),
            write_lp = inputs.config.write_lp,
        ),
    )

    policy = LightBenders.train(;
        state_variables_builder = state_variables_builder,
        first_stage_builder = first_stage_builder,
        second_stage_builder = second_stage_builder,
        second_stage_modifier = second_stage_modifier,
        inputs = inputs,
        policy_training_options = policy_training_options,
    )

    simulation_options = LightBenders.SimulationOptions(;
        num_scenarios = num_scenarios,
        state_handling = LightBenders.SimulationStateHandling.StatesFixedInPolicyResult,
        implementation_strategy = LightBenders.BendersSerialSimulation(),
        debugging_options = LightBenders.DebuggingOptions(;
            logs_dir = joinpath(inputs.path, "simulation_logs"),
            write_lp = inputs.config.write_lp,
        ),
    )

    results = LightBenders.simulate(;
        state_variables_builder = state_variables_builder,
        first_stage_builder = first_stage_builder,
        second_stage_builder = second_stage_builder,
        second_stage_modifier = second_stage_modifier,
        inputs = inputs,
        policy = policy,
        simulation_options = simulation_options,
    )
    return gather_light_benders_results(results, num_scenarios)
end
