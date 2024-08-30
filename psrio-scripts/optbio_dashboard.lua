local generic<const> = Generic();

local function create_tab(label, icon)
    local tab<const> = Tab(label);
    tab:push("# " .. label);
    tab:set_icon(icon);
    return tab;
end

capacity_files = generic:get_files("^plants_capacity_.*\\.(csv|hdr)$");
availability_files = generic:get_files("^initial_availability_.*\\.(csv|hdr)$");

local function tab_investments()
    local tab<const> = create_tab("Costs and Revenues", "receipt");

    local plants_annuity = generic:load("plants_annuity")
        :aggregate_blocks(BY_SUM())
        :aggregate_scenarios(BY_AVERAGE())
        :aggregate_stages(BY_SUM());

    local processes_opex = generic:load("processes_opex")
        :aggregate_blocks(BY_SUM())
        :aggregate_scenarios(BY_AVERAGE())
        :aggregate_stages(BY_SUM());
    
    local plants_has_values = plants_annuity:gt(0);
    local process_has_values = processes_opex:gt(0);

    local chart = Chart("Plants Annuity");
    chart:add_column_categories(plants_annuity:select_agents(plants_has_values), "Capex");
    tab:push(chart);

    local chart = Chart("Processes Opex");
    chart:add_column_categories(processes_opex:select_agents(process_has_values), "Opex");
    tab:push(chart);

    local products_revenue = generic:load("products_revenue")
        :aggregate_blocks(BY_SUM())
        :aggregate_scenarios(BY_AVERAGE())
        :aggregate_stages(BY_SUM());

    local product_has_values = products_revenue:gt(0);

    local chart = Chart("Annual Revenues");
    chart:add_column_categories(products_revenue:select_agents(product_has_values), "Sales Revenue", { color = "#66A61E" });
    tab:push(chart);

    local product_penalty = generic:load("products_penalty")
        :aggregate_blocks(BY_SUM())
        :aggregate_scenarios(BY_AVERAGE())
        :aggregate_stages(BY_SUM());

    local penalty_has_values = product_penalty:gt(0);
    if product_penalty:select_agents(penalty_has_values):loaded() then
        local chart = Chart("Minimal Sell Violation Penalty");
        chart:add_column_categories(product_penalty:select_agents(penalty_has_values), "Penalty");
        tab:push(chart);
    end

    total_annual_cost = plants_annuity:aggregate_agents(BY_SUM(), "total") + processes_opex:aggregate_agents(BY_SUM(), "total") + product_penalty:aggregate_agents(BY_SUM(), "total")

    local chart = Chart("Costs and Revenues");
    chart:add_column_categories(total_annual_cost:aggregate_agents(BY_SUM(), "Total"), "Costs");
    chart:add_column_categories(products_revenue:aggregate_agents(BY_SUM(), "Total"), "Revenues", { color = "#66A61E" });
    tab:push(chart);

    return tab
end

local function tab_operation()
    local tab<const> = create_tab("Production Overview", "factory");

    for i = 1, #capacity_files do
        plant_capacity_file = capacity_files[i];
        suffix = plant_capacity_file:sub(17);
        local plant_capacity = generic:load(plant_capacity_file)
            :aggregate_blocks(BY_SUM())
            :aggregate_scenarios(BY_AVERAGE())
            :aggregate_stages(BY_SUM());

        local initial_capacity = generic:load("plants_initial_capacity_" .. suffix)
            :aggregate_blocks(BY_SUM())
            :aggregate_scenarios(BY_AVERAGE())
            :aggregate_stages(BY_SUM());
        
        local constructed_capacity = generic:load("plants_constructed_capacity_" .. suffix)
            :aggregate_blocks(BY_SUM())
            :aggregate_scenarios(BY_AVERAGE())
            :aggregate_stages(BY_SUM());

        local capacity_has_values = plant_capacity:gt(0);
        local initial_capacity_has_values = initial_capacity:gt(0);

        if plant_capacity:select_agents(capacity_has_values):loaded() then
            local chart = Chart("Plant capacities");
            chart:add_column_stacking_categories(initial_capacity:select_agents(capacity_has_values), "Existing Capacity");
            chart:add_column_stacking_categories(constructed_capacity:select_agents(capacity_has_values), "Added Capacity");
            tab:push(chart);
        end
        
    end

    for i = 1, #availability_files do
        suffix = availability_files[i]:sub(22);
        local initial_availability = generic:load("initial_availability_" .. suffix)
            :aggregate_blocks(BY_SUM())
            :aggregate_scenarios(BY_AVERAGE())
            :aggregate_stages(BY_SUM());
        
        local final_availability = generic:load("final_availability_" .. suffix)
            :aggregate_blocks(BY_SUM())
            :aggregate_scenarios(BY_AVERAGE())
            :aggregate_stages(BY_SUM());

        local produced = generic:load("produced_" .. suffix)
            :aggregate_blocks(BY_SUM())
            :aggregate_scenarios(BY_AVERAGE())
            :aggregate_stages(BY_SUM());

        local consumed = generic:load("consumed_" .. suffix)
            :aggregate_blocks(BY_SUM())
            :aggregate_scenarios(BY_AVERAGE())
            :aggregate_stages(BY_SUM());

        local sold = generic:load("sold_" .. suffix)
            :aggregate_blocks(BY_SUM())
            :aggregate_scenarios(BY_AVERAGE())
            :aggregate_stages(BY_SUM());

        local violation = generic:load("violation_" .. suffix)
            :aggregate_blocks(BY_SUM())
            :aggregate_scenarios(BY_AVERAGE())
            :aggregate_stages(BY_SUM());

        local product_has_values = produced:gt(0) | consumed:gt(0) | sold:gt(0) | final_availability:gt(0);
        local initial_availability_has_values = initial_availability:gt(0)
        local violation_has_values = violation:gt(0);

        if initial_availability:select_agents(initial_availability_has_values):loaded() then
            local chart = Chart("Products initial availability");
            chart:add_column_categories(initial_availability:select_agents(product_has_values):convert(suffix), "Initial availability");
            tab:push(chart);
        end
        if produced:select_agents(product_has_values):loaded() then
            local chart = Chart("Products overview");
            chart:add_column_categories(produced:select_agents(product_has_values):convert(suffix), "Amount produced");
            chart:add_column_categories(consumed:select_agents(product_has_values):convert(suffix), "Amount consumed");
            chart:add_column_categories(sold:select_agents(product_has_values):convert(suffix), "Amount sold");
            chart:add_column_categories(final_availability:select_agents(product_has_values):convert(suffix), "Final availability");
            tab:push(chart);
        end
        if violation:select_agents(violation_has_values):loaded() then
            local chart = Chart("Minimal sell violation");
            chart:add_column_categories(violation:select_agents(violation_has_values):convert(suffix), "Violation");
            tab:push(chart);
        end
    end
    return tab
end

local dashboard<const> = Dashboard();
dashboard:set_title("OptBio");
dashboard:push(tab_operation());
dashboard:push(tab_investments());
dashboard:save("optbio_dashboard");
