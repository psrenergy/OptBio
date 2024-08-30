using Test
using OptBio

@testset verbose = true "OptBio Tests" begin

    # Includes all .jl files inside the "test" folder
    function recursive_include(path::String)
        for file in readdir(path)
            file_path = joinpath(path, file)
            if isdir(file_path)
                recursive_include(file_path)
                continue
            elseif !endswith(file, ".jl")
                continue
            elseif startswith(file, "test_")
                include(file_path)
            end
        end
    end

    recursive_include(@__DIR__)
end
