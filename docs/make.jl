import Pkg
Pkg.activate(dirname(@__DIR__))
Pkg.instantiate()
using OptBio

Pkg.activate(@__DIR__)
Pkg.instantiate()
using Documenter

makedocs(;
    modules = [OptBio],
    doctest = false,
    clean = true,
    format = Documenter.HTML(;
        mathengine = Documenter.MathJax2(),
        prettyurls = false,
        edit_link = nothing,
        footer = nothing,
        disable_git = true,
        repolink = nothing,
    ),
    sitename = "OptBio.jl",
    warnonly = true,
    pages = [
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "Manual" => [
            "Configuration" => "configuration.md",
            "Product" => "product.md",
            "Process" => "process.md",
            "Plant" => "plant.md",
            "Sum of products constraint" => "sum_of_products_constraint.md",
        ],
        "API Reference" => "api.md",
        "Mathematical Model" => "optimization.md",
    ],
)
