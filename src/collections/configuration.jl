@enum Solver begin
    HIGHS
end

@enum SolutionMethod begin
    DETERMINISTIC
    BENDERS
end

@kwdef mutable struct Configuration
    scenarios::Int = 0
    minimum_iterations::Int = 0
    maximum_iterations::Int = 0
    write_lp::Bool = false
    optimization_solver::Solver = HIGHS
    solution_method::SolutionMethod = BENDERS
end

function load!(config::Configuration, db::DatabaseSQLite)
    collection = "Configuration"
    n_config = PSRI.max_elements(db, "Configuration")
    if n_config == 0
        validation_error(;
            collection = collection,
            message = "The '$collection' collection is currently empty. Please ensure that exactly one configuration is created.",
        )
    elseif n_config > 1
        validation_error(;
            collection = collection,
            message = "Multiple elements have been found in the '$collection' collection. Please ensure the creation of exactly one configuration.",
        )
    end

    config.scenarios = PSRI.get_parms(db, collection, "scenarios")[1]
    config.minimum_iterations = PSRI.get_parms(db, collection, "minimum_iterations")[1]
    config.maximum_iterations = PSRI.get_parms(db, collection, "maximum_iterations")[1]
    write_lp = PSRI.get_parms(db, collection, "write_lp")[1]
    config.write_lp = Bool(write_lp)
    optimization_solver = PSRI.get_parms(db, collection, "optimization_solver")[1]
    config.optimization_solver = Solver(optimization_solver)
    solution_method = PSRI.get_parms(db, collection, "solution_method")[1]
    config.solution_method = SolutionMethod(solution_method)

    validate(config)

    return config
end

function update_configuration!(
    db::PSRI.PSRDatabaseSQLite.DatabaseSQLite;
    kwargs...,
)
    id = PSRI.get_parms(db, "Configuration", "id")[1]
    for attribute in keys(kwargs)
        value = kwargs[attribute]
        if isa(value, Vector)
            PSRI.PSRDatabaseSQLite._update_vector_parameter!(
                db,
                "Configuration",
                string(attribute),
                id,
                value,
            )
        else
            PSRI.PSRDatabaseSQLite._update_scalar_parameter!(
                db,
                "Configuration",
                string(attribute),
                id,
                value,
            )
        end
    end
    return db
end

function validate(config::Configuration)
    collection = "Configuration"
    if config.scenarios < 1
        attribute = "Scenarios"
        validation_error(;
            collection = collection,
            attribute = attribute,
            message = "The '$attribute' attribute in the '$collection' collection has a value less than one. Please enter a value greater than or equal to one.",
        )
    end
    if config.minimum_iterations < 1
        attribute = "Minimum Iterations"
        validation_error(;
            collection = collection,
            attribute = attribute,
            message = "The '$attribute' attribute in the '$collection' collection has a value less than one. Please enter a value greater than or equal to one.",
        )
    end
    if config.maximum_iterations < config.minimum_iterations
        attribute = "Maximum Iterations"
        validation_error(;
            collection = collection,
            attribute = attribute,
            message = "In the '$collection' collection, the maximum number of iterations is set to a value less than the minimum number of iterations. Please ensure that the maximum iterations value is greater than or equal to the minimum iterations value.",
        )
    end
end

function is_benders(config::Configuration)
    return config.solution_method == BENDERS
end

function is_deterministic_equivalent(config::Configuration)
    return config.solution_method == DETERMINISTIC
end
