local function create_results_menu()

    tab_menu = Tab("Dashboard Menu");
    tab_menu:set_icon("square-menu");
    tab_menu:push("# Dashboard Menu");
    tab_menu:push("[Click here](optbio_dashboard.html) to access the dashboard with summarized results");
    tab_menu:push("[Click here](optbio_flowchart.html) to access the flowchart of the production chain and the path chosen");


    return tab_menu
end

local results_menu<const> = Dashboard();
results_menu:set_title("Results Menu");
results_menu:push(create_results_menu());
results_menu:save("optbio_results_menu");