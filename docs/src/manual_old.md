# Manual
The OptBio module provides interfaces for defining production chains based on bioproducts and optimizing them, defining the best investment and operation strategies. For running the optimization, the user must define a database with the execution parameters and the elements of the production chain, and also, when using more than one scenario, the user must define the scenarios files. The user can then run the optimization using the `OptBio.main` function.

## Create study and set configurations
```@docs
OptBio.create_case
```

## Define the elements of the production chain
The fundamental elements of the production chain are products, plants, and processes. In addition, the user can define a set of products that may have a constraint over their sum. 

### Products
In OptBio, the `Product` collection encompasses both products that are made by some process, such as sugar and ethanol, and products that are used as inputs for other processes, such as sugarcane and bagasse. The user can define the products using the `OptBio.add_product!` function.
```@docs
OptBio.add_product!
```

### Plants
In OptBio, the `Plant` collection represents the industrial plants where the processes are executed. Multiple processes can be associated with the same plant. The user can define the plants using the `OptBio.add_plant!` function.
```@docs
OptBio.add_plant!
```
### Processes
A `Process` transforms a set of products into another set in specific proportions. Each `Process` must be linked to a `Plant`. Users can define processes using the `OptBio.add_process!` function and link them to a plant using the `OptBio.set_process_plant!` function.
```@docs
OptBio.add_process!
OptBio.set_process_plant!
```

### Sum of Products Constraint
A `SumOfProductsConstraint` is a collection composed by a set of products and a sell limit over their sum. The user can define the sum of products constraint using the `OptBio.add_sum_of_products_constraint!` function.
```@docs
OptBio.add_sum_of_products_constraint!
```

## Scenarios files
In cases where the OptBio case configuration sets a number of scenarios greater than one, the values for attributes that vary between scenarios are defined in CSV files. The attributes that can vary between scenarios are `sell_price` and `initial_availability`, both from `Product` collection. The user can provide the scenario files in two ways, listed below.

### Define scenarios by fulfilling the pre-generated CSV files
Once the case is created and all the elements of the production chain are defined, the user can run the OptBio main function, and it will generate the CSV files for the scenarios, with default values. The user can then fulfill the files with the desired values and run the OptBio main function again.

### Define scenarios by building the CSV files from scratch

First, the user must define matrices for price and initial availability scenarios. The matrices number of rows must be equal to the number of scenarios defined in the case. The number of columns must be equal to the number of products in the case. The user can then use the `OptBio.write_scenarios` function to write the CSV files.

```@docs
OptBio.write_scenarios
```

## Run the optimization
```@docs
OptBio.main
```