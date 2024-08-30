function _banner()
    # generated here https://patorjk.com/software/taag/#p=display&f=Big&t=OptBio%0A
    println("-------------------------------------------------------")
    println(raw"            ____        _   ____  _                 ")
    println(raw"           / __ \      | | |  _ \(_)                ")
    println(raw"          | |  | |_ __ | |_| |_) |_  ___            ")
    println(raw"          | |  | | '_ \| __|  _ <| |/ _ \           ")
    println(raw"          | |__| | |_) | |_| |_) | | (_) |          ")
    println(raw"           \____/| .__/ \__|____/|_|\___/           ")
    println(raw"                 | |                                ")
    println(raw"                 |_|                                ")

    println("OptBio v$PKG_VERSION ($GIT_DATE)            ")
    println("-------------------------------------------------------")
    return nothing
end

function parse_commandline(args)
    s = ArgParse.ArgParseSettings()
    #! format: off
    ArgParse.@add_arg_table! s begin
        "database_path"
        help = "path to the *.optbio file"
        arg_type = String
        default = pwd()
    end
    #! format: on
    return ArgParse.parse_args(args, s)
end

"""
    OptBio.main(args::Vector{String})

Main function to run the OptBio model.

# Arguments

  - `args::Vector{String}`: Vector with arguments to be parsed. The only argument is the path to the database file.

# Outputs

After running the model, a results folder will be created in the same directory as the database file. This folder will contain:

  - CSV files containing the solution of the optimization model.
  - A dashboard with the main results.
  - A flowchart with the whole production chain and the path chosen by the optimization model.

# Example

```julia
OptBio.main(["directory_of_the_case/my_case.optbio"])
```
"""
function main(args::Vector{String}; compiled::Bool = false)
    _banner()
    init_validations()

    parsed_args = parse_commandline(args)
    database_path = parsed_args["database_path"]
    path = dirname(database_path)

    @info("Case path: $(dirname(database_path))")

    if !isfile(database_path)
        error("The database $database_path does not exist.")
    end

    inputs, can_model_run = OptBioInputs(database_path, compiled)

    if can_model_run
        problem_results = solve_model(inputs)

        solution = save_outputs(inputs, problem_results)

        generate_dashboard(inputs.path, compiled)

        generate_flowchart_with_results(inputs.path, inputs.process, inputs.product.label, problem_results, compiled)

        generate_results_menu(inputs.path, compiled)

        finalize_optbio(inputs)

        return inputs, solution
    end

    return inputs
end

function finalize_optbio(inputs::OptBioInputs)
    println("OptBio v$PKG_VERSION ($GIT_DATE) finished successfully")
    finalize_inputs!(inputs)
    touch(joinpath(inputs.path, "OptBio.ok"))
    return nothing
end

function julia_main()::Cint
    main(ARGS, compiled = true)
    return 0
end
