module TestScalingFactorApproximation

using OptBio
using Test
import PSRClassesInterface as PSRI

function build_case()
    filename = joinpath(@__DIR__, "test2.optbio")

    rm(filename, force = true)

    capacity = 14400.0
    capex = 100.0

    db = OptBio.create_case(
        filename;
        force = true,
        path_migrations_directory = OptBio.optbio_migrations_dir(),
    )

    OptBio.add_product!(
        db;
        label = "Sugar",
        unit = "kg",
        initial_availability = capacity / 50,
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
        reference_capacity = capacity,
        reference_capex = capex,
        scaling_factor = 0.7,
        lifespan = 5,
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
    return capacity, capex
end

function test_scaling_factor_approximation_benders()
    capacity, capex = build_case()
    filename = joinpath(@__DIR__, "test2.optbio")

    inputs, solution = OptBio.main([filename])

    @test isapprox(solution["objective_value"], -4390.293950449029, atol = 0.1)
    @test isapprox(solution["investment"][1], capex * (1 / 50)^0.7, atol = 0.1)
    @test solution["capacity"] == [capacity / 50]
    @test solution["sell"] == [0.0 187.2]'

    rm(filename, force = true)
    results_folder = joinpath(dirname(filename), "results")
    rm(results_folder, recursive = true, force = true)

    return nothing
end

function test_scaling_factor_approximation_deterministic()
    capacity, capex = build_case()
    filename = joinpath(@__DIR__, "test2.optbio")
    db = PSRI.load_study(PSRI.PSRDatabaseSQLiteInterface(), filename)
    OptBio.update_configuration!(
        db;
        solution_method = Int(OptBio.DETERMINISTIC),
    )

    inputs, solution = OptBio.main([filename])

    @test isapprox(solution["objective_value"], -4390.293950449029, atol = 0.1)
    @test isapprox(solution["investment"][1], capex * (1 / 50)^0.7, atol = 0.1)
    @test solution["capacity"] == [capacity / 50]
    @test solution["sell"] == [0.0 187.2]'

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

TestScalingFactorApproximation.runtests()

end
