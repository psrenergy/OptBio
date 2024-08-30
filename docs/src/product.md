# Product
A product is an element that can be sold, or used to produce other products. The user can define a product in the database using the `OptBio.add_product!` function. The essential parameters for the product definition are the label and the unit. It is also necessary to pass the database object as the first argument. 
    
```julia
OptBio.add_product!(
    database;
    label = "Sugar",
    unit = "t",
)
```
The optional attributes for the product are all listed in this section.

## Initial Availability
The user can define the initial availability of the product using the `initial_availability` parameter. The default value is 0.0.

```julia
OptBio.add_product!(
    database;
    label = "Sugarcane",
    unit = "t",
    initial_availability = 100.0,
)
```
At least one product must have an initial availability greater than zero. 

## Sell Price
The sell price of the product is defined using the `sell_price` parameter. The default value is 0.0. There must be at least one product with a sell price greater than zero.

```julia
OptBio.add_product!(
    database;
    label = "Sugar",
    unit = "t",
    sell_price = 5000.0,
)
```

## Sell Limit
The user can define the maximum amount of the product that can be sold using the `sell_limit` parameter. If no limit is defined, no limit is considered.

```julia
OptBio.add_product!(
    database;
    label = "Sugar",
    unit = "t",
    sell_price = 5000.0,
    sell_limit = 100.0,
)
```

## Minimum Sell Quantity
The user can define the minimum amount of the product that must be sold using the `minimum_sell_quantity` parameter. The default value is 0.0, meaning that there is no minimum quantity to be sold. 

If the user defines a minimum sell quantity, they must also define a penalty for not selling the minimum quantity. The penalty is defined using the `minimum_sell_violation_penalty` parameter. 

```julia
OptBio.add_product!(
    database;
    label = "Sugar",
    unit = "t",
    sell_price = 5000.0,
    minimum_sell_quantity = 50.0,
    minimum_sell_violation_penalty = 1000.0,
)
```
