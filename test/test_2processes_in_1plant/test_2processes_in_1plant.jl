module Test2ProcessesIn1Plant

using OptBio
using Test
import PSRClassesInterface as PSRI

function build_case()
    filename = joinpath(@__DIR__, "test6.optbio")

    rm(filename, force = true)

    reference_capacity = 14400.0
    reference_capex = 100.0

    db = OptBio.create_case(
        filename;
        force = true,
        path_migrations_directory = OptBio.optbio_migrations_dir(),
    )

    OptBio.add_product!(
        db;
        label = "Sugar",
        unit = "kg",
        initial_availability = 3 * reference_capacity,
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
        scaling_factor = 1.0,
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

    OptBio.add_product!(
        db;
        label = "Chocolate",
        unit = "kg",
        initial_availability = reference_capacity,
    )

    OptBio.add_product!(
        db;
        label = "Fondue",
        unit = "kg",
        sell_price = 40.0,
    )

    OptBio.add_process!(
        db;
        label = "Melting Carefully",
        opex = 2.0,
        product_input = ["Chocolate"],
        factor_input = [1.0],
        product_output = ["Fondue"],
        factor_output = [0.9],
    )

    OptBio.set_process_plant!(db, "Melting Carefully", "Pan")

    PSRI.PSRDatabaseSQLite.close!(db)

    return reference_capacity, reference_capex
end

function test_2processes_in_1plant_benders()
    reference_capacity, reference_capex = build_case()
    filename = joinpath(@__DIR__, "test6.optbio")

    inputs, solution = OptBio.main([filename])

    sell = [0.0 reference_capacity * 3 * 0.65 0.0 reference_capacity * 0.9]'
    objective =
        -sell[2] * 25.0 - sell[4] * 40.0 + 4 * reference_capex + 1.0 * reference_capacity * 3 + 2.0 * reference_capacity
    @test isapprox(solution["objective_value"], objective; atol = 1e-3 * abs(objective))
    @test solution["investment"] == [4 * reference_capex]
    @test solution["capacity"] == [4 * reference_capacity]
    @test solution["sell"] == sell

    rm(filename, force = true)
    results_folder = joinpath(dirname(filename), "results")
    rm(results_folder, recursive = true, force = true)

    return nothing
end

function test_2processes_in_1plant_deterministic()
    reference_capacity, reference_capex = build_case()
    filename = joinpath(@__DIR__, "test6.optbio")
    db = PSRI.load_study(PSRI.PSRDatabaseSQLiteInterface(), filename)
    OptBio.update_configuration!(
        db;
        solution_method = Int(OptBio.DETERMINISTIC),
    )

    inputs, solution = OptBio.main([filename])

    sell = [0.0 reference_capacity * 3 * 0.65 0.0 reference_capacity * 0.9]'
    objective =
        -sell[2] * 25.0 - sell[4] * 40.0 + 4 * reference_capex + 1.0 * reference_capacity * 3 + 2.0 * reference_capacity
    @test isapprox(solution["objective_value"], objective; atol = 1e-3 * abs(objective))
    @test solution["investment"] == [4 * reference_capex]
    @test solution["capacity"] == [4 * reference_capacity]
    @test solution["sell"] == sell

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

Test2ProcessesIn1Plant.runtests()

end
