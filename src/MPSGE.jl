module MPSGE


import JuMP, MacroTools, PATHSolver, PrettyTables
import JuMP: value, set_value, Containers, set_lower_bound, set_upper_bound, @constraint

import JuMP.Containers: DenseAxisArray

export add!, Model, solve!, algebraic_version
export Sector, Commodity, Consumer, Aux, Production, DemandFunction, AuxConstraint, Endowment, Input, Output, Parameter, Demand, Tax, Nest
export value, set_value, get_value, set_fixed!, get_nested_commodity, set_lower_bound, set_upper_bound
export @parameter, @sector, @commodity, @consumer, @production, @demand

export MPSGEModel, input_tree, output_tree, new_Production, new_Demand

include("structs/references.jl")
include("structs/variables.jl")

include("model.jl")
include("macros.jl")
include("build/build_helpers.jl")
include("build/build_variables.jl")
include("build/build_implicitconstraints.jl")
include("build/build_zeroprofit.jl")
include("build/build_marketclearance.jl")
include("build/build_incomebalance.jl")
include("build/build_auxconstraints.jl")
include("build/build_startvalues_bounds.jl")
include("build/build.jl")
include("algebraic_wrapper.jl")
include("show.jl")



include("tree_structure/netput.jl")
include("tree_structure/model.jl")
include("tree_structure/build.jl")



end
