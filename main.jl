import Pkg
Pkg.instantiate()

using OptBio

OptBio.main(ARGS, compiled = false);
