# Sum of Products Constraint
An optional element that can be added to the database is the sum of products constraint. It is a set of products that has a limit in their sum. The available limit is for the sell quantity of the products. It is designed to represent products that are not the same, but share a limited market.
 
The user can define a sum of products constraint using the `OptBio.add_sum_of_products_constraint!` function. The function receives the database object, the label of the products set, the limit for the sell quantity, and the list of products that are part of the set. 

```julia
OptBio.add_sum_of_products_constraint!(
    database;
    label = "Sugar",
    product_id = ["Crystal Sugar", "Refined Sugar"],
    sell_limit = 15000000.0,
)
```
