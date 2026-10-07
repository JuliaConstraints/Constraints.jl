module Constraints

# Imports
using CompositionalNetworks
import ConstraintCommons
using ConstraintDomains
using DataFrames
using Dictionaries
using PrettyTables
using TestItems

import ConstraintCommons: Automaton, MDD, USUAL_CONSTRAINT_PARAMETERS, accept, incsert!,
                          symcon

# Exports
export Constraint
export ConstraintSpec
export ConceptError
export ConceptPenalty
export PenaltyProfile

export USUAL_CONSTRAINTS
export USUAL_SYMMETRIES
export CONSTRAINT_SPECS
export PENALTY_PROFILES
export FASTEST_ICN_PENALTIES
export PENALTY_FORMULAS

export args
export concept
export concept_error
export constraint_spec
export constraints_parameters
export constraints_descriptions
export describe
export error_f
export extract_parameters
export register_constraint_spec!
export semantic_id
# export learn_from_icn
export params_length
export penalty_f
export penalty_formula
export penalty_profile
export penalty_profiles
export fastest_icn_penalty_f
export fastest_icn_penalty_profile
export register_penalty_profile!
export symmetries

export AbstractInvariant
export BoundError
export InvariantChange
export bind_error
export candidate_value
export commit_changes!
export initialize_invariant
export invariant_value
export rebuild_invariant!
export rollback_changes!
export supports_incremental
export synchronize_invariant!

# Includes internals
include("constraint.jl")
include("invariant.jl")

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

# SECTION - Solver-independent reference and candidate penalties
include("penalties.jl")
include("xcsp3_core.jl")

# Incremental methods are defined by the files above, so capability metadata is finalized here.
_refresh_constraint_spec_capabilities!()

end
