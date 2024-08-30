module TestMinimumSellQuantity

using OptBio
using Test
import PSRClassesInterface as PSRI

function build_case()
    filename = joinpath(@__DIR__, "test5.optbio")

    rm(filename, force = true)

    db = OptBio.create_case(
        filename;
        force = true,
        path_migrations_directory = OptBio.optbio_migrations_dir(),
    )

    OptBio.add_product!(
        db;
        label = "Sugar",
        sell_price = 5000.0,
        unit = "ton",
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
        initial_availability = 80.0,
    )

    OptBio.add_product!(
        db;
        label = "Ethanol 1G",
        unit = "kL",
        sell_price = 0.5,
    )

    OptBio.add_product!(
        db;
        label = "Ethanol 2G",
        unit = "kL",
        sell_price = 0.7,
        minimum_sell_quantity = 600.0,
        minimum_sell_violation_penalty = 1000.0,
    )

    OptBio.add_plant!(
        db;
        label = "Ethanol Plant",
        reference_capacity = 100.0,
        reference_capex = 100000.0,
    )

    OptBio.add_process!(
        db;
        label = "Integrated ethanol production",
        opex = 0.0,
        product_input = ["Sugarcane", "Straw"],
        factor_input = [1.0, 0.9],
        product_output = ["Ethanol 1G", "Ethanol 2G"],
        factor_output = [7.5, 6.0],
    )

    OptBio.set_process_plant!(db, "Integrated ethanol production", "Ethanol Plant")

    PSRI.PSRDatabaseSQLite.close!(db)
    return nothing
end

function test_minimum_sell_quantity_benders()
    build_case()
    filename = joinpath(@__DIR__, "test5.optbio")

    inputs, solution = OptBio.main([filename])

    ethanol2g_sell = 80.0 / 0.9 * 6.0
    ethanol1g_sell = 80.0 / 0.9 * 7.5
    sugar_sell = (100.0 - 80.0 / 0.9) * 0.75

    capacity = [100.0 - 80.0 / 0.9, 80.0 / 0.9]
    investment = [52000.0 * (capacity[1] / 100.0)^0.7, 100000.0 * (capacity[2] / 100.0)^0.7]
    annuity = [investment[1] * 0.1 / (1 - (1.1)^-20), investment[2] * 0.1 / (1 - (1.1)^-20)]
    objective_value =
        sum(annuity) - sugar_sell * 5000.0 - ethanol1g_sell * 0.5 - ethanol2g_sell * 0.7 +
        (600.0 - ethanol2g_sell) * 1000.0

    @test isapprox(solution["objective_value"], objective_value, atol = 1)
    @test isapprox(solution["investment"], investment, atol = 10)
    @test isapprox(solution["capacity"], capacity, atol = 1e-2)
    @test isapprox(solution["sell"], [sugar_sell 0.0 0.0 ethanol1g_sell ethanol2g_sell]', atol = 1e-2)

    rm(filename, force = true)
    results_folder = joinpath(dirname(filename), "results")
    rm(results_folder, recursive = true, force = true)

    return nothing
end

function test_minimum_sell_quantity_deterministic()
    build_case()
    filename = joinpath(@__DIR__, "test5.optbio")
    db = PSRI.load_study(PSRI.PSRDatabaseSQLiteInterface(), filename)
    OptBio.update_configuration!(
        db;
        solution_method = Int(OptBio.DETERMINISTIC),
    )

    inputs, solution = OptBio.main([filename])

    ethanol2g_sell = 80.0 / 0.9 * 6.0
    ethanol1g_sell = 80.0 / 0.9 * 7.5
    sugar_sell = (100.0 - 80.0 / 0.9) * 0.75

    capacity = [100.0 - 80.0 / 0.9, 80.0 / 0.9]
    investment = [52000.0 * (capacity[1] / 100.0)^0.7, 100000.0 * (capacity[2] / 100.0)^0.7]
    annuity = [investment[1] * 0.1 / (1 - (1.1)^-20), investment[2] * 0.1 / (1 - (1.1)^-20)]
    objective_value =
        sum(annuity) - sugar_sell * 5000.0 - ethanol1g_sell * 0.5 - ethanol2g_sell * 0.7 +
        (600.0 - ethanol2g_sell) * 1000.0

    @test isapprox(solution["objective_value"], objective_value, atol = 1)
    @test isapprox(solution["investment"], investment, atol = 10)
    @test isapprox(solution["capacity"], capacity, atol = 1e-2)
    @test isapprox(solution["sell"], [sugar_sell 0.0 0.0 ethanol1g_sell ethanol2g_sell]', atol = 1e-2)

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

TestMinimumSellQuantity.runtests()

end
