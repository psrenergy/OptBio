<img src="assets/logo-with-name.png" alt="OptBio logo"/>

## Introduction

OptBio is a Julia package designed for modeling and optimizing the value of bioproducts. It employs stochastic optimization to account for uncertainties in product selling prices and variations in crop yields. The package determines the optimal investment, production capacity, and operation of industrial plants to maximize profit. Built on the JuMP modeling language, OptBio uses the HiGHS solver to address these optimization problems.

Developed by [PSR](https://www.psr-inc.com/en/), a global provider of consulting services, computational modeling, and energy innovation, this package is part of a research and development initiative funded by [Tevisa](https://tevisa.com.br/), a thermoelectric generation company in Brazil, and is aligned with the Brazilian government's [R&D program](https://www.gov.br/aneel/pt-br/assuntos/programa-de-pesquisa-desenvolvimento-e-inovacao) (PD-16269-0123/2023). The project also involved collaboration with the Brazilian federal university [UNIFEI](https://unifei.edu.br/). Considering the potential of bioproducts for decarbonization, OptBio was specifically utilized to model the sugarcane production chain with a focus on biofuels. More informations about the project can be found in the [video](https://www.youtube.com/watch?v=Obb-jGBMuLg) (in portuguese).

## Installation

To install the package, you can follow these steps:

1. Clone the repository:
    ```bash
    git clone https://github.com/psrenergy/OptBio.git
    ```
2. Navigate to the package directory and activate the project environment:
    ```bash
    cd OptBio
    julia --project
    ```
3. Once in the Julia REPL, instantiate the environment to set up the necessary dependencies:
    ```julia
    julia> import Pkg

    julia> Pkg.instantiate()
    ```
This will configure everything you need to start using the package.

## Contributing

Users are encouraged to contributing by opening issues and opening pull requests. If you wish to implement a feature please follow 
the [JuMP Style Guide](https://jump.dev/JuMP.jl/v0.21.10/developers/style/#Style-guide-and-design-principles).
