module TestMoreComplexProductionChain

using OptBio
using Test
import PSRClassesInterface as PSRI

function build_case()
    filename = joinpath(@__DIR__, "test7.optbio")

    rm(filename, force = true)

    db = OptBio.create_case(
        filename;
        force = true,
        path_migrations_directory = OptBio.optbio_migrations_dir(),
    )

    OptBio.add_product!(
        db;
        label = "Product 1",
        initial_availability = 100.0,
        unit = "L",
    )

    OptBio.add_product!(
        db;
        label = "Product 2",
        unit = "L",
    )

    OptBio.add_product!(
        db;
        label = "Product 3",
        unit = "L",
    )

    OptBio.add_product!(
        db;
        label = "Product 4",
        unit = "L",
        sell_price = 100.0,
        minimum_sell_quantity = 30.0,
        minimum_sell_violation_penalty = 240.0,
    )

    OptBio.add_plant!(
        db;
        label = "Plant 1",
        reference_capacity = 200.0,
        reference_capex = 1000.0,
    )

    OptBio.add_plant!(
        db;
        label = "Plant 2",
        reference_capacity = 180.0,
        reference_capex = 1000.0,
    )

    OptBio.add_plant!(
        db;
        label = "Plant 3",
        reference_capacity = 120.0,
        reference_capex = 1000.0,
    )

    OptBio.add_process!(
        db;
        label = "Process 1",
        product_input = ["Product 1"],
        factor_input = [1.0],
        product_output = ["Product 2"],
        factor_output = [0.9],
        opex = 0.0,
    )

    OptBio.add_process!(
        db;
        label = "Process 2",
        product_input = ["Product 2"],
        factor_input = [0.9],
        product_output = ["Product 3"],
        factor_output = [0.6],
        opex = 0.0,
    )

    OptBio.add_process!(
        db;
        label = "Process 3",
        product_input = ["Product 3"],
        factor_input = [0.6],
        product_output = ["Product 4"],
        factor_output = [0.3],
        opex = 0.0,
    )

    OptBio.set_process_plant!(db, "Process 1", "Plant 1")
    OptBio.set_process_plant!(db, "Process 2", "Plant 2")
    OptBio.set_process_plant!(db, "Process 3", "Plant 3")

    PSRI.PSRDatabaseSQLite.close!(db)
    return nothing
end

function test_more_complex_production_chain_benders()
    build_case()
    filename = joinpath(@__DIR__, "test7.optbio")

    inputs, solution = OptBio.main([filename])

    capacity = [100.0, 90.0, 60.0]
    sell = [0.0 0.0 0.0 30.0]
    investment = [1000.0 * (1 / 2)^0.7, 1000.0 * (1 / 2)^0.7, 1000.0 * (1 / 2)^0.7]
    annuity = [investment[i] * 0.1 / (1 - (1.1)^-20) for i in 1:3]
    objective = sum(annuity) - 100 * 30
    @test isapprox(solution["objective_value"], objective; atol = 1e-3)
    @test isapprox(solution["investment"], investment; atol = 1e-3)
    @test solution["capacity"] == capacity
    @test solution["sell"] == sell'

    rm(filename, force = true)
    results_folder = joinpath(dirname(filename), "results")
    rm(results_folder, recursive = true, force = true)

    return nothing
end

function test_more_complex_production_chain_deterministic()
    build_case()
    filename = joinpath(@__DIR__, "test7.optbio")

    inputs, solution = OptBio.main([filename])

    capacity = [100.0, 90.0, 60.0]
    sell = [0.0 0.0 0.0 30.0]
    investment = [1000.0 * (1 / 2)^0.7, 1000.0 * (1 / 2)^0.7, 1000.0 * (1 / 2)^0.7]
    annuity = [investment[i] * 0.1 / (1 - (1.1)^-20) for i in 1:3]
    objective = sum(annuity) - 100 * 30
    @test isapprox(solution["objective_value"], objective; atol = 1e-3)
    @test isapprox(solution["investment"], investment; atol = 1e-3)
    @test solution["capacity"] == capacity
    @test solution["sell"] == sell'

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

TestMoreComplexProductionChain.runtests()

end
