module Constraints

# Imports
using CompositionalNetworks
using ConstraintCommons
using ConstraintDomains
using DataFrames
using Dictionaries
using PrettyTables
using TestItemRunner
using TestItems

import ConstraintCommons: extract_parameters, USUAL_CONSTRAINT_PARAMETERS

# Exports
export Constraint

export USUAL_CONSTRAINTS
export USUAL_SYMMETRIES

export args
export concept
export constraints_parameters
export constraints_descriptions
export describe
export error_f
export extract_parameters
# export learn_from_icn
export params_length
export symmetries

# Includes internals
include("constraint.jl")

# Includes learned errors from ICN
# foreach(include, readdir(joinpath(dirname(pathof(Constraints)), "compositions"); join=true))

## SECTION - Usual constraints (based on and including XCSP3-core categories)
include("usual_constraints.jl")

# SECTION - Generic Constraints: intention, extension
include("constraints/intention.jl")
include("constraints/extension.jl")

# SECTION - Constraints defined from Languages
include("constraints/regular.jl")
include("constraints/mdd.jl")

# SECTION - Comparison-based Constraints
include("constraints/all_different.jl")
include("constraints/all_equal.jl")
include("constraints/ordered.jl")

# SECTION - Counting and Summing Constraints
include("constraints/sum.jl")
include("constraints/count.jl")
include("constraints/n_values.jl")
include("constraints/cardinality.jl")

# SECTION - Connection Constraints
include("constraints/maximum.jl")
include("constraints/minimum.jl")
include("constraints/element.jl")
include("constraints/channel.jl")

# SECTION - Packing and Scheduling Constraints
include("constraints/cumulative.jl")
include("constraints/no_overlap.jl")

# SECTION - Constraints on Graphs
include("constraints/circuit.jl")

# SECTION - Elementary Constraints
include("constraints/instantiation.jl")

end
