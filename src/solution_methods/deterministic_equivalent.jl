function deterministic_equivalent(
    inputs::OptBioInputs,
)
    num_scenarios = inputs.config.scenarios
    options = LightBenders.DeterministicEquivalentOptions(
        num_scenarios = num_scenarios,
        debugging_options = LightBenders.DebuggingOptions(;
            logs_dir = joinpath(inputs.path, "det_eq_logs"),
            write_lp = inputs.config.write_lp,
        ),
    )
    results = LightBenders.deterministic_equivalent(
        state_variables_builder = state_variables_builder,
        first_stage_builder = first_stage_builder,
        second_stage_builder = second_stage_builder,
        second_stage_modifier = second_stage_modifier,
        inputs = inputs,
        options = options,
    )
    return gather_light_benders_results(results, num_scenarios)
end
