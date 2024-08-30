# Process
A process is an operation that transforms a set of input products into a different set of output products, in specific proportions, and it's realized in a plant.  

## Process Definition
The user can define a process in the database using the `OptBio.add_process!` function. All the parameters available are essential for the process definition. The user must pass the database object as the first argument.

```julia	
OptBio.add_process!(
    database;
    label = "Integrated ethanol production",
    opex = 0.6,
    product_input = ["Sugarcane", "Straw"],
    factor_input = [1.0, 0.9],
    product_output = ["Ethanol 1G", "Ethanol 2G"],
    factor_output = [7.5, 6.0],
)
```

The `opex` parameter defines the operational expenditure of the process. It is based on the amount of the first input product that is being processed. In the example above, the operational expenditure is multiplied by the amount of tons of sugarcane processed, and added to the total cost of the operation.

The `product_input` and `product_output` parameters define the input and output products of the process, respectively. The `factor_input` and `factor_output` parameters define the proportion of each input and output product in the process. In the example above, the process "Integrated ethanol production" receives 1 ton of sugarcane and 0.9 tons of straw, and produces 7.5 kL of first-generation ethanol and 6.0 kL of second-generation ethanol.

## Linking Process to Plant

After defining the process, it is necessary to link it to a plant. The `OptBio.set_process_plant!` function is used for this purpose. The function receives the database object, the label of the process, and the label of the plant.

```julia
OptBio.set_process_plant!(database, "Integrated ethanol production", "Ethanol Plant")
```
