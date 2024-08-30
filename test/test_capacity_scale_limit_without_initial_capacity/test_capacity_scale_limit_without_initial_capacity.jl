module TestCapacityScaleLimitWithoutInitialCapacity

using OptBio
using Test
import PSRClassesInterface as PSRI

function build_case()
    filename = joinpath(@__DIR__, "test11.optbio")

    rm(filename, force = true)

    reference_capacity = 14400.0
    initial_availability = 3 * reference_capacity
    initial_capacity = 0.0
    maximum_scale_capacity = 2 * reference_capacity
    reference_capex = 100.0
    scaling_factor = 0.7

    db = OptBio.create_case(
        filename;
        force = true,
        path_migrations_directory = OptBio.optbio_migrations_dir(),
    )

    OptBio.add_product!(
        db;
        label = "Sugar",
        unit = "kg",
        initial_availability = initial_availability,
    )

    OptBio.add_product!(
        db;
        label = "Caramel",
        unit = "kg",
        sell_price = 25.0,
    )

    OptBio.add_plant!(
        db;
        label = "Pan",
        reference_capacity = reference_capacity,
        reference_capex = reference_capex,
        initial_capacity = initial_capacity,
        scaling_factor = scaling_factor,
        lifespan = 5,
        maximum_capacity_for_scale = maximum_scale_capacity,
    )

    OptBio.add_process!(
        db;
        label = "Melting",
        opex = 1.0,
        product_input = ["Sugar"],
        factor_input = [1.0],
        product_output = ["Caramel"],
        factor_output = [0.65],
    )

    OptBio.set_process_plant!(db, "Melting", "Pan")

    PSRI.PSRDatabaseSQLite.close!(db)
    return (
        reference_capacity,
        initial_availability,
        initial_capacity,
        maximum_scale_capacity,
        reference_capex,
        scaling_factor,
    )
end

function test_capacity_scale_limit_without_initial_capacity_benders()
    reference_capacity,
    initial_availability,
    initial_capacity,
    maximum_scale_capacity,
    reference_capex,
    scaling_factor = build_case()
    filename = joinpath(@__DIR__, "test11.optbio")

    inputs, solution = OptBio.main([filename])

    investment_at_maximum_scale_capacity =
        reference_capex * (maximum_scale_capacity / reference_capacity)^scaling_factor
    calculated_investment = investment_at_maximum_scale_capacity * initial_availability / maximum_scale_capacity
    calculated_sell = initial_availability * 0.65
    calculated_objective = -calculated_sell * 25.0 + calculated_investment + 1.0 * initial_availability

    @test isapprox(solution["objective_value"][1], calculated_objective, atol = abs(calculated_objective) / 100)
    @test isapprox(solution["investment"][1], calculated_investment, atol = 0.1)
    @test solution["capacity"] == [initial_availability]
    @test isapprox(solution["sell"], [0.0 calculated_sell]', atol = 1e-2)

    rm(filename, force = true)
    results_folder = joinpath(dirname(filename), "results")
    rm(results_folder, recursive = true, force = true)

    return nothing
end

function test_capacity_scale_limit_without_initial_capacity_deterministic()
    reference_capacity,
    initial_availability,
    initial_capacity,
    maximum_scale_capacity,
    reference_capex,
    scaling_factor = build_case()
    filename = joinpath(@__DIR__, "test11.optbio")
    db = PSRI.load_study(PSRI.PSRDatabaseSQLiteInterface(), filename)
    OptBio.update_configuration!(
        db;
        solution_method = Int(OptBio.DETERMINISTIC),
    )

    inputs, solution = OptBio.main([filename])

    investment_at_maximum_scale_capacity =
        reference_capex * (maximum_scale_capacity / reference_capacity)^scaling_factor
    calculated_investment = investment_at_maximum_scale_capacity * initial_availability / maximum_scale_capacity
    calculated_sell = initial_availability * 0.65
    calculated_objective = -calculated_sell * 25.0 + calculated_investment + 1.0 * initial_availability

    @test isapprox(solution["objective_value"][1], calculated_objective, atol = abs(calculated_objective) / 100)
    @test isapprox(solution["investment"][1], calculated_investment, atol = 0.1)
    @test solution["capacity"] == [initial_availability]
    @test isapprox(solution["sell"], [0.0 calculated_sell]', atol = 1e-2)

    GC.gc()
    rm(filename, force = true)
    results_folder = joinpath(dirname(filename), "results")
    rm(results_folder, recursive = true, force = true)

    return nothing
end

function runtests()
    Base.GC.gc()
    Base.GC.gc()
    for name in names(@__MODULE__; all = true)
        if startswith("$name", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
end

TestCapacityScaleLimitWithoutInitialCapacity.runtests()

end
