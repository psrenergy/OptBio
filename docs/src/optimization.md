# Model

OptBio runs a model that aims to maximize the expected profit of the defined production chain, considering the uncertainty associated with the availability of the basis product and the selling prices of the bioproducts. According to the input parameters, the model will define the capacity and the associated investment in each industrial plant, as well as the amount of each bioproduct to be produced and sold. The model can be decomposed into two stages: the investment stage and the operation stage. In the deterministic equivalent solution method, one model is created, including all variables and constraints of both stages. In the Benders solution method, the stages are defined and solved separately, and the communication between them is made through Benders cuts. The master variable is the capacity of each industrial plant. The details of each stage of the model are presented below.

# Investment model

The Investment model is the stage in charge of defining the capacity and the investment associated with each industrial plant. The model aims to minimize the annuities of the investments in the plants and, in the Benders solution method, the expected value of the future costs.  

## Sets

- ``K``: set of plants
- ``S``: set of scenarios

## Constants

- ``B^{ref}_k``: capex of a reference plant
- ``C^{ref}_k``: capacity of a reference plant
- ``C^0_k``: plant initial capacity
- ``\sigma_k``: plant scaling factor
- ``r_k``: plant annual interest rate
- ``n_k``: plant number of years of lifespan
- ``\overline{C}_k``: plant maximum capacity, defined by the user
- ``\overline{\overline{C}}_k``: plant maximum reachable capacity, calculated according to input products availability
- ``\overline{C}^\sigma_k``: plant capacity threshold for scale economy
- ``\hat{Q}_s``: evaluated future cost
- ``\hat{C}_{k, s}``: evaluated capacity
- ``\hat{\lambda}_{k, s}``: evaluated marginal cost of capacity constraints
- ``m``: number of pieces for piecewise linearization
- ``q``: ratio at which each piece increases

## Decision Variables

- ``C_k``: plant capacity
- ``B_k``: plant investment
- ``A_k``: plant annuity
- ``Q_s``: future cost

## Others

- ``\dot{C}_{k,p}``: plant capacity values for piecewise linearization
- ``\dot{B}_{k,p}``: plant investment values for piecewise linearization

The original relation between the variables of investment ``B_k`` and capacity ``C_k`` is exponential, as shown below:

```math
 B_k = B^{ref}_k \cdot \left( \frac{C_k}{C^{ref}_k} \right) ^{\sigma_k}  
```

It expresses the scale economy of the plants. A intuitive way to understand it is to think that if the capacity of a plant is doubled, the investment associated is less than double, and if the capacity is halved, the investment is more than halved.

When there is a pre-existing capacity ``C^0_k``, the investment associated with ``C_k^0`` is subtracted from the investment associated with the total capacity ``C_k``:
```math
 B_k = B^{ref}_k \cdot \left( \frac{C_k}{C^{ref}_k} \right) ^{\sigma_k} - B^{ref}_k \cdot \left( \frac{C_k^0}{C^{ref}_k} \right) ^{\sigma_k} 
```


The function is both nonlinear as nonconvex. In order to linearize it, the capacity domain is divided into ``m`` pieces, defined by ``m + 1`` points.
The investment is evaluated at each point, and a linear function connects each pair of points.
To reduce approximation errors, the points are defined by a geometric progression, with a ratio ``1 + q``.
This way, the points are more concentrated in the lower capacity values, where the investment values are more sensitive to changes in capacity.

```math
 \dot{C}_{k,0} = C^0_k, \ \ \ \forall k \in K 
```

```math
 \dot{C}_{k,p} = C^0_k + ( \text{min}\{\overline{\overline{C}}_k, \overline{C}^\sigma_k \}- C^0_k) \cdot \frac{(1 + q)^p - 1}{(1+q)^m - 1}  \ \ \ \forall \ p = 0,\dots,m, \ k \in K 
```

```math
 \dot{B}_{k,p} = B^{ref}_k \cdot \left( \frac{\dot{C}_{k,p}}{C^{ref}_k} \right) ^{\sigma_k} - B^{ref}_k \cdot \left( \frac{C^0_{k,p}}{C^{ref}_k} \right) ^{\sigma_k} \ \ \ \forall \ p = 0,\dots,m, \ k \in K 
```

```math
 \dot{C}_{k,m+1} = \overline{\overline{C}}_k, \ \ \ \forall k \in K, \ \text{if } \overline{C}^\sigma_k \leq \overline{\overline{C}}_k 
```

```math
 \dot{B}_{k,m+1} = B^{ref}_k \cdot \left( \frac{\dot{C}_{k,m}}{C^{ref}_k} \right) ^{\sigma_k} \cdot \frac{\dot{C}_{k,m+1}}{\dot{C}_{k,m}} - B^{ref}_k \cdot \left( \frac{C^0_k}{C^{ref}_k} \right) ^{\sigma_k}
    \text{if } \overline{C}^\sigma_k \leq \overline{\overline{C}}_k 
```

## Objective Function

### Deterministic equivalent solution method
```math
min{\sum_{k \in K} A_k}
```
### Benders solution method
The annuities are added to the objective function in both solution methods.
```math
min{\sum_{k \in K} A_k + \frac{1}{|S|} \sum_{s \in S} Q_s}
```

## Constraints

### Relation between investment and plant capacity

```math
(C_k, B_k) \in \text{piecewise}(\{ \dot{C}_{k,p}, \dot{B}_{k,p} \}_{p = 0}^m), \ \ \ \forall k \in K
```
This constraint guarantees that the pair ``(C_k, B_k)`` belongs to some linear segment defined by the points ``\{ \dot{C}_{k,p}, \dot{B}_{k,p} \}_{p = 0}^m``.


### [Plant](plant.md) existing capacity
```math
C_k \geq C^0_k, \ \ \ k \in K
```

### [Plant](plant.md) capacity limit
```math
C_k \leq \overline{C}_k, \ \ \ \forall k \in K
```
This constraint is only active if the user defines a maximum capacity for the plant.

### [Plant](plant.md) annuity calculation
```math
A_k = \frac{B_k \cdot r_k}{1 - (1 + r_k)^{-n_k}}, \ \ \ \forall k \in K
```

# Operation model

## Sets

- ``I``: set of [products](product.md)
- ``J``: set of [processes](process.md)
- ``K``: set of [plants](plant.md)
- ``G``: set of [sets of products with a sales limit in their sum](set_of_products_constraint.md)
- ``S``: set of scenarios
- ``I(g)``: set of products in set ``g``. ``g \in G``. ``I(g) \subseteq I``.
- ``I^{in}(j)``: set of products as an input of process ``j``
- ``I^{out}(j)``: set of products as an output of process ``j``
- ``J^c(i)``: set of processes consuming product ``i``
- ``J^p(i)``: set of processes producing product ``i``
- ``J(k)``: set of processes in plant
- ``u(j)``: function mapping process to its first input product

## Constants

- ``c_j``: process operational costs
- ``p_{i, s}``: product sell price
- ``\overline{v}_i``: product sell limit
- ``\underline{v}_i``: product minimum amount to be sold
- ``\omega_i``: penalty for product minimum amount to be sold violation
- ``\overline{w}_g``: sales limit for the sum of products in set ``g``
- ``D^0_{i,s}``: product initial availability
- ``C^0_k``: plant initial capacity
- ``\overline{C}_k``: plant maximum capacity
- ``\theta^{in}_{j, i}``: factor of product ``i`` being consumed by process ``j``
- ``\theta^{out}_{j, i}``: factor of product ``i`` being produced by process ``j``
- ``\hat{C}_k``: evaluated capacity

## Decision Variables

- ``D^f_{i, s}``: product final availability
- ``f^{in}_{j, i, s}``: amount of product ``i`` going into process ``j``
- ``f^{out}_{j, i, s}``: amount of product ``i`` going out of process ``j``
- ``l_{j, s}``: auxiliar variable for keeping proportions of process
- ``v_{i, s}``: product sell amount
- ``C_{k, s}``: plant capacity
- ``\lambda_{k, s}``: marginal cost of capacity constraints
- ``Q_s``: future cost
- ``\delta_{i,s}``: slack for product minimum amount to be sold

## Objective Function

### Deterministic equivalent solution method
In the deterministic equivalent solution method, is added to the objective function defined in the Investment model the expected value of the future costs.
```math
+ \frac{1}{|S|} \sum_{s \in S} Q_s
```
### Benders solution method
```math
min{\frac{1}{|S|} \sum_{s \in S} Q_s}
```

## Constraints

### Costs calculation
```math
Q_s = \sum_{j \in J} c_j \cdot f^{in}_{j,u(j)} - \sum_{i \in I} p_{i, s} \cdot v_{i, s} + \sum_{i \in I} \omega_i \cdot \delta_{i,s}, \ \ \ \forall s \in S
```

### [Product](product.md) availability
```math
D^f_{i, s} = D^0_{i,s} + \sum_{j \in J^p(i)} f^{out}_{j, i, s} - \sum_{j \in J^c(i)} f^{in}_{j,i,s} - v_{i,s}, \ \ \ \forall i \in I, s \in S
```

### [Process](process.md) proportions
```math
l_{j,s} = \frac{1}{\theta^{in}_{j,i}} \cdot f^{in}_{j,i,s}, \ \ \ \forall s \in S, j \in J, i \in I^{in}(j)
```

```math
l_{j,s} = \frac{1}{\theta^{out}_{j,i}} \cdot f^{out}_{j,i,s}, \ \ \ \forall s \in S, j \in J, i \in I^{out}(j)
```

### Plant capacity limit, based on the first product associated with the process
```math
\sum_{j \in J(k)} f^{in}_{j,{u(j)},s} \leq C_{k,s},  \ \ \ \forall s \in S, k \in K
```

### Capacity fishing constraint:
```math
C_{k,s} = \hat{C}_k \ \  :\lambda_{k,s} , \ \ \ \forall s \in S, k \in K
```
This constraint guarantees that the plant capacity in the operational model is equal to the plant capacity in the investment model, and it catches the marginal cost of capacity constraints, which is used in the Benders cuts.


### [Plant](plant.md) existing capacity
```math
C_{k,s} \geq C^0_k, \ \ \ \forall s \in S, k \in K
```

### [Product](product.md) sell limit
```math
v_{i,s} \leq \overline{v}_i, \ \ \ \forall i \in I, s \in S
```
This constraint is only active if the product has a sell limit.

### [Product](product.md) sell lower bound

```math
v_{i,s} \geq \underline{v}_i - \delta_{i,s}, \ \ \ \forall i \in I, s \in S
```
This constraint is only active if the product has a minimum amount to be sold.

### [Product](product.md) sell unavailability 

```math
v_{i,s} = 0, \ \ \ \forall i \in I, s \in S
```
This constraint is only active if the product sell price is zero.

### Sales limit for the [sum of products in each set](sum_of_products_constraint.md)

```math
\sum_{i \in I^{\overline{v}}_g} v_{i,s} \leq \overline{v}_g, \ \ \ \forall g \in I^{\overline{v}}, s \in S
```

### Positive amount constraints
```math
D^f_{i, s} \geq 0, \ \ \ \forall i \in I, s \in S
```

```math
f^{in}_{j,i,s} \geq 0, \ \ \ \forall j \in J, i \in I, s \in S
```

```math
f^{out}_{j,i,s} \geq 0, \ \ \ \forall \in J, i \in I, s \in S
```

```math
v_{i, s} \geq 0, \ \ \ \forall i \in I, s \in S
```

```math
C_{k, s} \geq 0, \ \ \ \forall k \in K, s \in S
```

```math
\delta_{i,s} \geq 0, \ \ \ \forall i \in I, s \in S
```

# Communication between stages

In the Benders solution method, the Investment model and the Operation model are solved iteratively, and the communication between them is made through Benders cuts. The Benders cuts are added to the Investment model, and they are based on the evaluated capacity ``\hat{C}_{k, s}``, operational cost ``\hat{Q}_s`` and marginal cost of capacity constraints ``\hat{\lambda}_{k, s}``. Also, the evaluated capacity of the Investment Model is updated in the fishing constraint of the Operation model.

### Benders cuts
```math
Q_s \geq \hat{Q}_s + \sum_{k \in K} \hat{\lambda}_{k, s} \cdot (C_k - \hat{C}_{k, s}), \ \ \ \forall s \in S
```
### Fishing constraint update
```math
C_{k,s} = \hat{C}_k \ \  :\lambda_{k,s} , \ \ \ \forall s \in S, k \in K
```