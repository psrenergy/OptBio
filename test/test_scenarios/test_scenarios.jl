module TestScenarios

using OptBio
using Test
import PSRClassesInterface as PSRI

function build_case()
    filename = joinpath(@__DIR__, "test15.optbio")

    rm(filename, force = true)

    db = OptBio.create_case(
        filename;
        force = true,
        path_migrations_directory = OptBio.optbio_migrations_dir(),
        scenarios = 3,
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
        initial_availability = 100.0,
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

    price_scenarios = [
        5000.0 0.0 0.0 0.5 0.7
        5000.0 0.0 0.0 500.0 700.0
        5000.0 0.0 0.0 0.5 0.7
    ]

    initial_availability_scenarios = [
        0.0 100.0 100.0 0.0 0.0
        0.0 150.0 150.0 0.0 0.0
        0.0 150.0 100.0 0.0 0.0
    ]

    product_label = ["Sugar", "Sugarcane", "Straw", "Ethanol 1G", "Ethanol 2G"]
    product_unit = ["ton", "ton", "ton", "kL", "kL"]

    OptBio.write_scenarios(product_label, product_unit, @__DIR__, 3, initial_availability_scenarios, price_scenarios)

    PSRI.PSRDatabaseSQLite.close!(db)
    return price_scenarios
end

function test_scenarios_benders()
    price_scenarios = build_case()
    filename = joinpath(@__DIR__, "test15.optbio")

    inputs, solution = OptBio.main([filename])

    capacity = [150.0, 150.0]
    investment = [52000 * (150 / 100)^0.7, 100000 * (150 / 100)^0.7]
    annuity = sum(investment) * 0.1 / (1 - 1.1^-20)
    sell = [
        100*0.75 0 0 0 0
        0 0 0 150*7.5 150*6
        150*0.75 0 0 0 0
    ]
    revenue = sum(sell .* price_scenarios) / 3
    objective = annuity - revenue

    @test isapprox(solution["objective_value"], objective, atol = 1)
    @test isapprox(solution["investment"], investment, atol = 1)
    @test isapprox(solution["capacity"], capacity, atol = 1)
    @test isapprox(solution["sell"], sell', atol = 1)

    rm(filename, force = true)
    rm(joinpath(@__DIR__, "price_scenarios.csv"), force = true)
    rm(joinpath(@__DIR__, "initial_availability_scenarios.csv"), force = true)
    results_folder = joinpath(dirname(filename), "results")
    rm(results_folder, recursive = true, force = true)

    return nothing
end

function test_scenarios_deterministic()
    price_scenarios = build_case()
    filename = joinpath(@__DIR__, "test15.optbio")
    db = PSRI.load_study(PSRI.PSRDatabaseSQLiteInterface(), filename)
    OptBio.update_configuration!(
        db;
        solution_method = Int(OptBio.DETERMINISTIC),
    )

    inputs, solution = OptBio.main([filename])

    capacity = [150.0, 150.0]
    investment = [52000 * (150 / 100)^0.7, 100000 * (150 / 100)^0.7]
    annuity = sum(investment) * 0.1 / (1 - 1.1^-20)
    sell = [
        100*0.75 0 0 0 0
        0 0 0 150*7.5 150*6
        150*0.75 0 0 0 0
    ]
    revenue = sum(sell .* price_scenarios) / 3
    objective = annuity - revenue

    @test isapprox(solution["objective_value"], objective, atol = 1)
    @test isapprox(solution["investment"], investment, atol = 1)
    @test isapprox(solution["capacity"], capacity, atol = 1)
    @test isapprox(solution["sell"], sell', atol = 1)

    GC.gc()
    rm(filename, force = true)
    rm(joinpath(@__DIR__, "price_scenarios.csv"), force = true)
    rm(joinpath(@__DIR__, "initial_availability_scenarios.csv"), force = true)
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

TestScenarios.runtests()

end
