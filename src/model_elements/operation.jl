function operation!(
    model::JuMP.Model,
    inputs::OptBioInputs,
)
    # load inputs
    I = size(inputs.product)
    J = size(inputs.process)
    K = size(inputs.plant)
    opex = inputs.process.opex
    sell_limit = inputs.product.sell_limit

    # random variables
    sell_price = zeros(I) # we initialize the sell price as zero
    # and change to the correct value in the second stage modifier
    @variable(model, initial_availability[1:I])
    ## load state variables
    capacity = model[:capacity]
    investment = model[:investment]
    annuity = model[:annuity]

    inputs_vector = inputs.process.inputs
    outputs_vector = inputs.process.outputs
    input_factors = inputs.process.inputs_factor
    output_factors = inputs.process.outputs_factor
    maximum_capacity = inputs.plant.maximum_capacity
    initial_capacity = inputs.plant.initial_capacity
    minimum_sell_quantity = inputs.product.minimum_sell_quantity
    minimum_sell_violation_penalty = inputs.product.minimum_sell_violation_penalty

    # variables
    ## definitions
    @variable(model, final_availability[1:I] >= 0)
    @variable(model, inflow[1:J, 1:I] >= 0) # fluxo do bioproduto i entrando no processo j
    @variable(model, outflow[1:J, 1:I] >= 0) # fluxo do bioproduto i saindo do processo j
    @variable(model, sell[1:I] >= 0) # quantidade vendida do bioproduto i
    @variable(model, level[1:J] >= 0) # level do processo j
    @variable(model, minimum_sell_violation[1:I] >= 0) # violacao da venda minima do bioproduto i

    # expressions and constraints
    @expression(model, cost,
        sum(inflow[j, inputs_vector[j][1]] * opex[j] for j in 1:J) -
        sum(sell[i] * sell_price[i] for i in 1:I)
    )
    @constraint(
        model,
        product_availability[i = 1:I],
        final_availability[i] ==
        initial_availability[i] - sum(inflow[j, i] for j in consumers(inputs.product, i)) +
        sum(outflow[j, i] for j in producers(inputs.product, i)) - sell[i]
    )
    @constraint(
        model,
        proportions_in[j = 1:J, i = 1:length(inputs_vector[j]); input_factors[j][i] != 0],
        level[j] == (1 / input_factors[j][i]) * inflow[j, inputs_vector[j][i]]
    )
    @constraint(
        model,
        proportions_out[j = 1:J, i = 1:length(outputs_vector[j]); output_factors[j][i] != 0],
        level[j] == (1 / output_factors[j][i]) * outflow[j, outputs_vector[j][i]]
    )
    @constraint(model, capacity_limit[k = 1:K],
        sum(inflow[j, inputs_vector[j][1]] for j in 1:J if inputs.process.plant_index[j] == k) <= capacity[k]
    )
    @constraint(
        model,
        sell_unavailability[i = 1:I; inputs.product.sell_price[i] == 0],
        sell[i] == 0,
    )
    @constraint(
        model,
        sell_lower_bound[i = 1:I; !isnan(minimum_sell_quantity[i]) && minimum_sell_quantity[i] > 0],
        sell[i] >= minimum_sell_quantity[i] - minimum_sell_violation[i],
    )
    @constraint(
        model,
        sell_upper_bound[i = 1:I; !isnan(sell_limit[i])],
        sell[i] <= sell_limit[i],
    )
    for i in 1:I
        if !isnan(minimum_sell_quantity[i]) && minimum_sell_quantity[i] > 0
            cost += minimum_sell_violation[i] * minimum_sell_violation_penalty[i]
        end
    end
    if size(inputs.sum_of_products_constraint) > 0
        @constraint(
            model,
            sum_of_products_sell_limit[g = 1:size(inputs.sum_of_products_constraint)],
            sum(sell[i] for i in inputs.sum_of_products_constraint.product_id[g]) <=
            inputs.sum_of_products_constraint.sell_limit[g]
        )
    end
    @objective(model, Min, cost)
    return nothing
end

function scenarios(num_scenario::Int)
    if num_scenario == 1
        return nothing
    else
        return num_scenario
    end
end
