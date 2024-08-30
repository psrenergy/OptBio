# Plant
A plant is a facility that can realize a set of processes. The model will choose its capacity and the investment associated to it.

The user can define a plant in the database using the `OptBio.add_plant!` function. The essential parameters for the plant definition are the label, the reference capacity, and the reference capital expenditure. It is also necessary to pass the database object as the first argument.

```julia
OptBio.add_plant!(
    database;
    label = "Sugar Mill",
    reference_capacity = 100.0,
    reference_capex = 100000.0,
)
```

The capacity of the plant is defined by the amount of the first input product that can be processed by the plant within a year. In the example above, if a process that has sugarcane as the first input product is linked to the plant "Sugar Mill", the reference capacity of the plant will be 100.0 tons of sugarcane per year.

## Scaling Factor
The relation between the chosen capacity and investment will be based on the reference capacity and reference capital expenditure of the plant. The relation is not linear, it considers the economies of scale. The scaling factor is defined by the user and it is used to calculate the investment associated with the chosen capacity. The scaling factor must be greater than zero, and it's default value is 0.7.

```julia
OptBio.add_plant!(
    database;
    label = "Sugar Mill",
    reference_capacity = 100.0,
    reference_capex = 100000.0,
    scaling_factor = 0.8,
)
```
If the relation between the chosen capacity and investment is linear, the scaling factor must be set to 1.0. More details about the scaling factor can be found in the [model definition](optimization.md).

## Interest Rate and Lifespan
The user can define the interest rate and the lifespan of the plant using the `interest_rate` and `lifespan` parameters. The interest rate is the annual interest rate of the investment, and the lifespan is the number of years that the plant will be operational, which also define the number of years that the investment will be paid. The default values are 0.1 and 20, respectively.

```julia
OptBio.add_plant!(
    database;
    label = "Sugar Mill",
    reference_capacity = 100.0,
    reference_capex = 100000.0,
    interest_rate = 0.08,
    lifespan = 25,
)
```

## Maximum Capacity
The user can limit the capacity that the model can choose for the plant using the `maximum_capacity` parameter. If no limit is defined, the model whatever capacity it finds optimal.  
    
```julia
OptBio.add_plant!(
    database;
    label = "Sugar Mill",
    reference_capacity = 100.0,
    reference_capex = 100000.0,
    maximum_capacity = 150.0,
)
```

## Maximum Capacity for Scale
When the capacity chosen by the model is too far from the reference capacity, the scale economy considered by the model can be unrealistic high. The user can define a maximum capacity for scale using the `maximum_capacity_for_scale` parameter. The model will still be able to choose a capacity greater than the maximum capacity for scale, but after that, the scale economy will be considered linear. More details about the maximum capacity for scale can be found in the [model definition](optimization.md). When no limit is defined, the model will consider the scale economy for any capacity.

```julia
OptBio.add_plant!(
    database;
    label = "Sugar Mill",
    reference_capacity = 100.0,
    reference_capex = 100000.0,
    maximum_capacity_for_scale = 700.0,
)
```
