# Configuration
While creating a optbio database, using the `OptBio.create_case` function, the user can set parameters for the model execution.

## Number of scenarios
It is possible to define a number of uncertainty scenarios for the model, according to the number of scenarios defined, the user must provide different values for the products' sell price and initial availability. The user can define the number of scenarios using the `scenarios` parameter.

```julia
filename = "my_optbio_case_folder/my_chain.optbio"
OptBio.create_case(filename; scenarios = 3)
```

If the user does not define the number of scenarios, the default value is 1, and the user does not need to provide any scenario files.

## Solution Method

The user can define the solution method for the optimization problem using the `solution_method` parameter. The available methods are the Bender's Decomposition and the Deterministic Equivalent Formulation. The default method is the Bender's Decomposition.

```julia
filename = "my_optbio_case_folder/my_chain.optbio"
OptBio.create_case(filename; solution_method = OptBio.SolutionMethod.DETERMINISTIC)
```

## Bounds for number of iterations

The user can define the minimum and maximum number of iterations for the Bender's Decomposition method using the `minimum_iterations` and `maximum_iterations` parameters. The default values are 3 and 15, respectively.

```julia
filename = "my_optbio_case_folder/my_chain.optbio"
OptBio.create_case(filename; minimum_iterations = 5, maximum_iterations = 20)
```

## LP Writing

The user can choose to write the LP files for the model using the `write_lp` parameter. The default value is 0 (false).

```julia	
filename = "my_optbio_case_folder/my_chain.optbio"
OptBio.create_case(filename; write_lp = 1)
```
After the execution of the model, the LP files will be written in "my_optbio_case_folder/simulation_logs".
