module TestMigrations

using OptBio
using Test

const PSRDatabaseSQLite = OptBio.PSRI.PSRDatabaseSQLite

function test_optbio_migrations()
    @test PSRDatabaseSQLite.test_migrations(OptBio.optbio_migrations_dir())
    return nothing
end

function runtests()
    for name in names(@__MODULE__; all = true)
        if startswith("$name", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
end

TestMigrations.runtests()

end
