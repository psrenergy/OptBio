module TestChainWithCycle

using OptBio
using Test
import PSRClassesInterface as PSRI

function build_case()
    filename = joinpath(@__DIR__, "test13.optbio")

    rm(filename, force = true)

    db = OptBio.create_case(
        filename;
        force = true,
        path_migrations_directory = OptBio.optbio_migrations_dir(),
    )

    OptBio.add_product!(
        db;
        label = "Wood Pulp",
        unit = "kg",
        initial_availability = 1000.0,
    )

    OptBio.add_product!(
        db;
        label = "Paper",
        unit = "kg",
        sell_price = 50.0,
    )

    OptBio.add_product!(
        db;
        label = "Cardboard",
        unit = "kg",
        sell_price = 100.0,
    )

    OptBio.add_plant!(
        db;
        label = "Paper Mill",
        reference_capacity = 100.0,
        reference_capex = 1000.0,
        interest_rate = 0.0,
    )

    OptBio.add_process!(
        db;
        label = "Paper Production",
        opex = 0.0,
        product_input = ["Wood Pulp"],
        factor_input = [1.0],
        product_output = ["Paper"],
        factor_output = [0.5],
    )

    OptBio.add_plant!(
        db;
        label = "Recycling Plant",
        reference_capacity = 100.0,
        reference_capex = 1000.0,
        interest_rate = 0.0,
    )

    OptBio.add_process!(
        db;
        label = "Paper Recycling",
        opex = 0.0,
        product_input = ["Paper"],
        factor_input = [1.0],
        product_output = ["Cardboard"],
        factor_output = [0.9],
    )

    OptBio.add_process!(
        db;
        label = "Cardboard Recycling",
        opex = 0.0,
        product_input = ["Cardboard"],
        factor_input = [1.0],
        product_output = ["Paper"],
        factor_output = [0.9],
    )

    OptBio.set_process_plant!(db, "Paper Production", "Paper Mill")
    OptBio.set_process_plant!(db, "Paper Recycling", "Recycling Plant")
    OptBio.set_process_plant!(db, "Cardboard Recycling", "Recycling Plant")

    PSRI.PSRDatabaseSQLite.close!(db)
    return nothing
end

function test_chain_with_cycle_benders()
    build_case()
    filename = joinpath(@__DIR__, "test13.optbio")

    @test_throws OptBio.SimpleValidations.ValidationException OptBio.main([filename])

    GC.gc()
    GC.gc()

    rm(filename, force = true)
    rm(joinpath(@__DIR__, "validation_errors.json"), force = true)

    return nothing
end

function test_chain_with_cycle_deterministic()
    build_case()
    filename = joinpath(@__DIR__, "test13.optbio")
    db = PSRI.load_study(PSRI.PSRDatabaseSQLiteInterface(), filename)
    OptBio.update_configuration!(
        db;
        solution_method = Int(OptBio.DETERMINISTIC),
    )

    @test_throws OptBio.SimpleValidations.ValidationException OptBio.main([filename])

    GC.gc()
    GC.gc()

    rm(filename, force = true)
    rm(joinpath(@__DIR__, "validation_errors.json"), force = true)

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

TestChainWithCycle.runtests()

end
