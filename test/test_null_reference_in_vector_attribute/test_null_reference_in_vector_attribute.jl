module TestNullReferenceInVectorAttribute

using OptBio
using Test
import PSRClassesInterface as PSRI

function build_case()
    filename = joinpath(@__DIR__, "test16.optbio")

    rm(filename, force = true)

    db = OptBio.create_case(
        filename;
        force = true,
        path_migrations_directory = OptBio.optbio_migrations_dir(),
    )

    OptBio.add_product!(
        db;
        label = "Product 1",
        unit = "unit",
        initial_availability = 1.0,
    )

    OptBio.add_product!(
        db;
        label = "Product 2",
        unit = "unit",
    )

    OptBio.add_product!(
        db;
        label = "Product 3",
        unit = "unit",
    )

    OptBio.add_plant!(
        db;
        label = "Plant 1",
        reference_capacity = 1.0,
        reference_capex = 1.0,
    )

    OptBio.add_process!(
        db;
        label = "Process 1",
        opex = 1.0,
        product_input = ["Product 1"],
        factor_input = [1.0],
        product_output = ["Product 2", "Product 3"],
        factor_output = [1.0, 1.0],
    )

    OptBio.set_process_plant!(
        db,
        "Process 1",
        "Plant 1",
    )

    @test begin
        try
            OptBio.main([filename])
            true
        catch
            false
        end
    end

    PSRI.delete_element!(db, "Product", "Product 3")

    PSRI.PSRDatabaseSQLite.close!(db)
    return nothing
end

function test_null_reference_in_vector_attribute_benders()
    build_case()
    filename = joinpath(@__DIR__, "test16.optbio")

    @test_throws OptBio.SimpleValidations.ValidationException OptBio.main([filename])

    GC.gc()
    GC.gc()

    rm(filename, force = true)
    results_folder = joinpath(dirname(filename), "results")
    rm(results_folder, recursive = true, force = true)

    return nothing
end

function test_null_reference_in_vector_attribute_deterministic()
    build_case()
    filename = joinpath(@__DIR__, "test16.optbio")
    db = PSRI.load_study(PSRI.PSRDatabaseSQLiteInterface(), filename)
    OptBio.update_configuration!(
        db;
        solution_method = Int(OptBio.DETERMINISTIC),
    )

    @test_throws OptBio.SimpleValidations.ValidationException OptBio.main([filename])

    GC.gc()
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

TestNullReferenceInVectorAttribute.runtests()

end
