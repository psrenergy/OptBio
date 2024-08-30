module TestSellLimit

using OptBio
using Test
import PSRClassesInterface as PSRI

function build_case()
    filename = joinpath(@__DIR__, "test3.optbio")

    rm(filename, force = true)

    db = OptBio.create_case(
        filename;
        force = true,
        path_migrations_directory = OptBio.optbio_migrations_dir(),
    )

    OptBio.add_product!(
        db;
        label = "Sugar",
        sell_price = 10000.0,
        unit = "ton",
        sell_limit = 60.0,
    )

    OptBio.add_product!(
        db;
        label = "Sugarcane",
        unit = "ton",
        initial_availability = 100.0,
    )

    OptBio.add_plant!(
        db;
        label = "Sugar Mill",
        reference_capacity = 100.0,
        reference_capex = 52000.0,
    )

    OptBio.add_process!(
        db;
        label = "Sugar Mill",
        opex = 0.0,
        product_input = ["Sugarcane"],
        factor_input = [1.0],
        product_output = ["Sugar"],
        factor_output = [0.75],
    )

    OptBio.set_process_plant!(db, "Sugar Mill", "Sugar Mill")

    OptBio.add_product!(
        db;
        label = "Straw",
        unit = "ton",
        initial_availability = 100.0,
    )

    OptBio.add_product!(
        db;
        label = "Ethanol 1G",
        unit = "kL",
        sell_price = 25.0,
    )

    OptBio.add_product!(
        db;
        label = "Ethanol 2G",
        unit = "kL",
        sell_price = 35.0,
    )

    OptBio.add_plant!(
        db;
        label = "Ethanol Plant",
        reference_capacity = 100.0,
        reference_capex = 60000.0,
    )

    OptBio.add_process!(
        db;
        label = "Integrated ethanol production",
        opex = 0.0,
        product_input = ["Sugarcane", "Straw"],
        factor_input = [1.0, 0.9],
        product_output = ["Ethanol 1G", "Ethanol 2G"],
        factor_output = [75.0, 60.0],
    )

    OptBio.set_process_plant!(db, "Integrated ethanol production", "Ethanol Plant")

    PSRI.PSRDatabaseSQLite.close!(db)
    return nothing
end

function test_sell_limit_benders()
    build_case()
    filename = joinpath(@__DIR__, "test3.optbio")

    inputs, solution = OptBio.main([filename])

    @test isapprox(solution["objective_value"], -6.71992e5, atol = 10)
    @test isapprox(solution["investment"], [44477.3395, 19446.7], rtol = 0.2)
    @test isapprox(solution["capacity"], [80.0, 20.0], rtol = 0.1)
    @test solution["sell"] == [60.0 0.0 0.0 1500.0 1200.0]'

    rm(filename, force = true)
    results_folder = joinpath(dirname(filename), "results")
    rm(results_folder, recursive = true, force = true)

    return nothing
end

function test_sell_limit_deterministic()
    build_case()
    filename = joinpath(@__DIR__, "test3.optbio")
    db = PSRI.load_study(PSRI.PSRDatabaseSQLiteInterface(), filename)
    OptBio.update_configuration!(
        db;
        solution_method = Int(OptBio.DETERMINISTIC),
    )

    inputs, solution = OptBio.main([filename])

    @test isapprox(solution["objective_value"], -6.71992e5, atol = 10)
    @test isapprox(solution["investment"], [44477.3395, 19446.7], rtol = 0.2)
    @test isapprox(solution["capacity"], [80.0, 20.0], rtol = 0.1)
    @test solution["sell"] == [60.0 0.0 0.0 1500.0 1200.0]'

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

TestSellLimit.runtests()

end
