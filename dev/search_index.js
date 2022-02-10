var documenterSearchIndex = {"docs":
[{"location":"domain/#ConstraintDomains.jl","page":"ConstraintDomains.jl","title":"ConstraintDomains.jl","text":"","category":"section"},{"location":"domain/","page":"ConstraintDomains.jl","title":"ConstraintDomains.jl","text":"Currently only discrete domains are supported using the following function. ","category":"page"},{"location":"domain/","page":"ConstraintDomains.jl","title":"ConstraintDomains.jl","text":"ConstraintDomains.domain","category":"page"},{"location":"domain/#ConstraintDomains.domain","page":"ConstraintDomains.jl","title":"ConstraintDomains.domain","text":"domain()\n\nConstruct an EmptyDomain.\n\n\n\n\n\ndomain(a::Tuple{T, Bool}, b::Tuple{T, Bool}) where {T <: Real}\ndomain(intervals::Vector{Tuple{Tuple{T, Bool},Tuple{T, Bool}}}) where {T <: Real}\n\nConstruct a domain of continuous interval(s). ```julia d1 = domain((0., true), (1., false)) # d1 = [0, 1) d2 = domain([ # d2 = 0, 1) ∪ (3.5, 42, (1., false),     (3.5, false), (42., true), ])\n\n\n\n\n\ndomain(values)\ndomain(range::R) where {T <: Real, R <: AbstractRange{T}}\n\nConstruct either a SetDomain or a RangeDomain.\n\nd1 = domain(1:5)\nd2 = domain([53.69, 89.2, 0.12])\nd3 = domain([2//3, 89//123])\nd4 = domain(4.3)\n\n\n\n\n\n","category":"function"},{"location":"learning/#Learning-through-ICNs","page":"Learning (ICN)","title":"Learning through ICNs","text":"","category":"section"},{"location":"learning/","page":"Learning (ICN)","title":"Learning (ICN)","text":"This feature is very basic so far, and should follow the procedure below","category":"page"},{"location":"learning/","page":"Learning (ICN)","title":"Learning (ICN)","text":"Make the package a dev version ] dev Constraints\n(Recommended) In user_home/.julia/dev/Constraints, git checkout -b newcomposition\nDefine a new constraint _c and add it to usual_constraint in Constraints.jl\nAdd it to the list of constraints to be learned in learn.jl (check the function below)\nEnter a new julia session, and run\nusing Constraints\nConstraints.learn_from_icn()\nRun tests: ] test Constraints\nCommit, push, and make a draft PR to the dev branch","category":"page"},{"location":"learning/","page":"Learning (ICN)","title":"Learning (ICN)","text":"function learn_from_icn()\n    targets = Dict(\n        :all_different => Dict(\n            :domains => [domain([1,2,3,4]) for i in 1:4],\n        ),\n        :dist_different => Dict(\n            :domains => [domain(Vector(1:4)) for i in 1:4],\n        ),\n        :ordered => Dict(\n            :domains => [domain([1,2,3,4]) for i in 1:4],\n        ),\n        :all_equal => Dict(\n            :domains => [domain([1,2,3,4]) for i in 1:4],\n        ),\n        :eq => Dict(\n            :domains => [domain(Vector(1:10)) for i in 1:2],\n        ),\n        :all_equal_param => Dict(\n            :domains => [domain(Vector(8:12)) for i in 1:4],\n            :param => 10,\n        ),\n    )\n\n    config = Dict(\n        :local_iter => 100,\n        :global_iter => 10,\n        :search => :complete,\n        :metric => hamming,\n        :population => 400,\n    )\n\n    path = joinpath(dirname(pathof(Constraints)),\"compositions\")\n\n    for t in targets\n        @info \"Starting learning for $(t.first)\"\n        name = \"_icn_$(t.first)\"\n        compose_to_file!(\n            concept(usual_constraints[t.first]),\n            name,\n            joinpath(path, \"$name.jl\");\n            domains=t.second[:domains],\n            param=get(t.second, :param, nothing),\n            local_iter=config[:local_iter],\n            global_iter=config[:global_iter],\n            search=config[:search],\n            metric=config[:metric],\n            popSize=config[:population],\n            language=:Julia,\n        )\n    end\n\nend","category":"page"},{"location":"icn/#CompositionalNetworks.jl","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.jl","text":"","category":"section"},{"location":"icn/","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.jl","text":"Pages = [\"public.md\"]\nDepth = 5","category":"page"},{"location":"icn/","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.jl","text":"CompositionalNetworks.jl, a Julia package for Interpretable Compositional Networks (ICN), a variant of neural networks, allowing the user to get interpretable results, unlike regular artificial neural networks.","category":"page"},{"location":"icn/","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.jl","text":"The current state of our ICN focuses on the composition of error functions for LocalSearchSolvers.jl, but produces results independently of it and export it to either/both Julia functions or/and human readable output.","category":"page"},{"location":"icn/#How-does-it-work?","page":"CompositionalNetworks.jl","title":"How does it work?","text":"","category":"section"},{"location":"icn/","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.jl","text":"The package comes with a basic ICN for learning global constraints. The ICN is composed of 4 layers: transformation, arithmetic, aggregation, and comparison. Each contains several operations that can be composed in various ways. Given a concept (a predicate over the variables' domains), a metric (hamming by default), and the variables' domains, we learn the binary weights of the ICN. ","category":"page"},{"location":"icn/#Installation","page":"CompositionalNetworks.jl","title":"Installation","text":"","category":"section"},{"location":"icn/","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.jl","text":"] add CompositionalNetworks","category":"page"},{"location":"icn/","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.jl","text":"As the package is in a beta version, some changes in the syntax and features are likely to occur. However, those changes should be minimal between minor versions. Please update with caution.","category":"page"},{"location":"icn/#Quickstart","page":"CompositionalNetworks.jl","title":"Quickstart","text":"","category":"section"},{"location":"icn/","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.jl","text":"# 4 variables in 1:4\ndoms = [domain([1,2,3,4]) for i in 1:4]\n\n# allunique concept (that is used to define the :all_different constraint)\nerr = explore_learn_compose(allunique, domains=doms)\n# > interpretation: identity ∘ count_positive ∘ sum ∘ count_eq_left\n\n# test our new error function\n@assert err([1,2,3,3], dom_size = 4) > 0.0\n\n# export an all_different function to file \"current/path/test_dummy.jl\" \ncompose_to_file!(icn, \"all_different\", \"test_dummy.jl\")","category":"page"},{"location":"icn/","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.jl","text":"The output file should produces a function that can be used as follows (assuming the maximum domain size is 7)","category":"page"},{"location":"icn/","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.jl","text":"import CompositionalNetworks\n\nall_different([1,2,3,4,5,6,7]; dom_size = 7)\n# > 0.0 (which means true, no errors)","category":"page"},{"location":"icn/","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.jl","text":"Please see JuliaConstraints/Constraints.jl/learn.jl for an extensive example of ICN learning and compositions.","category":"page"},{"location":"icn/#Public-interface","page":"CompositionalNetworks.jl","title":"Public interface","text":"","category":"section"},{"location":"icn/","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.jl","text":"Modules = [CompositionalNetworks]\nPrivate = false","category":"page"},{"location":"icn/#CompositionalNetworks.ICN","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.ICN","text":"ICN(; nvars, dom_size, param, transformation, arithmetic, aggregation, comparison)\n\nConstruct an Interpretable Compositional Network, with the following arguments:\n\nnvars: number of variable in the constraint\ndom_size: maximum domain size of any variable in the constraint\nparam: optional parameter (default to nothing)\ntransformation: a transformation layer (optional)\narithmetic: a arithmetic layer (optional)\naggregation: a aggregation layer (optional)\ncomparison: a comparison layer (optional)\n\n\n\n\n\n","category":"type"},{"location":"icn/#CompositionalNetworks.aggregation_layer-Tuple{}","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.aggregation_layer","text":"aggregation_layer()\n\nGenerate the layer of aggregations of the ICN. The operations are mutually exclusive, that is only one will be selected.\n\n\n\n\n\n","category":"method"},{"location":"icn/#CompositionalNetworks.arithmetic_layer-Tuple{}","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.arithmetic_layer","text":"arithmetic_layer()\n\nGenerate the layer of arithmetic operations of the ICN. The operations are mutually exclusive, that is only one will be selected.\n\n\n\n\n\n","category":"method"},{"location":"icn/#CompositionalNetworks.comparison_layer","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.comparison_layer","text":"comparison_layer(param = false)\n\nGenerate the layer of transformations functions of the ICN. Iff param value is set, also includes all the parametric comparison with that value. The operations are mutually exclusive, that is only one will be selected.\n\n\n\n\n\n","category":"function"},{"location":"icn/#CompositionalNetworks.compose","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.compose","text":"compose(icn, weights=nothing)\n\nReturn a function composed by some of the operations of a given ICN. Can be applied to any vector of variables. If weights are given, will assign to icn.\n\n\n\n\n\n","category":"function"},{"location":"icn/#CompositionalNetworks.compose_to_file!-Tuple{Any, Any, Any}","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.compose_to_file!","text":"compose_to_file!(concept, name, path; domains, param = nothing, language = :Julia, search = :complete, global_iter = 10, local_iter = 100, metric = hamming, popSize = 200)\n\nExplore, learn and compose a function and write it to a file.\n\nArguments:\n\nconcept: the concept to learn\nname: the name to give to the constraint\npath: path of the output file\n\nKeywords arguments:\n\ndomains: domains that defines the search space\nparam: an optional paramater of the constraint\nlanguage: the language to export to, default to :julia\nsearch: either :partial or :complete search\nglobal_iter: number of learning iteration\nlocal_iter: number of generation in the genetic algorithm\nmetric: the metric to measure the distance between a configuration and known solutions\npopSize: size of the population in the genetic algorithm\n\n\n\n\n\n","category":"method"},{"location":"icn/#CompositionalNetworks.explore","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.explore","text":"explore(domains, concept, param = nothing; search_limit = 1000, solutions_limit = 100)\n\nSearch (a part of) a search space and returns a pair of vector of configurations: (solutions, non_solutions). If the search space size is over search_limit, then both solutions and non_solutions are limited to solutions_limit.\n\nBeware that if the density of the solutions in the search space is low, solutions_limit needs to be reduced. This process will be automatic in the future (simple reinforcement learning).\n\nArguments:\n\ndomains: a collection of domains\nconcept: the concept of the targeted constraint\nparam: an optional parameter of the constraint\nsol_number: the required number of solutions (half of the number of configurations), default to 100\n\n\n\n\n\n","category":"function"},{"location":"icn/#CompositionalNetworks.explore_learn_compose","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.explore_learn_compose","text":"explore_learn_compose(concept; domains, param = nothing, search = :complete, global_iter = 10, local_iter = 100, metric = hamming, popSize = 200, action = :composition)\n\nExplore a search space, learn a composition from an ICN, and compose an error function.\n\nArguments:\n\nconcept: the concept of the targeted constraint\ndomains: domains of the variables that define the training space\nparam: an optional parameter of the constraint\nsearch: either flexible,:partial or :complete search. Flexible search will use search_limit and solutions_limit to determine if the search space needs to be partially or completely explored\nglobal_iter: number of learning iteration\nlocal_iter: number of generation in the genetic algorithm\nmetric: the metric to measure the distance between a configuration and known solutions\npopSize: size of the population in the genetic algorithm\naction: either :symbols to have a description of the composition or :composition to have the composed function itself\n\n\n\n\n\n","category":"function"},{"location":"icn/#CompositionalNetworks.hamming-Tuple{Any, Any}","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.hamming","text":"hamming(x, X)\n\nCompute the hamming distance of x over a collection of solutions X, i.e. the minimal number of variables to switch in xto reach a solution.\n\n\n\n\n\n","category":"method"},{"location":"icn/#CompositionalNetworks.lazy-Tuple{Vararg{Function}}","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.lazy","text":"lazy(funcs::Function...)\n\nGenerate methods extended to a vector instead of one of its components. A function f should have the following signature: f(i::Int, x::V).\n\n\n\n\n\n","category":"method"},{"location":"icn/#CompositionalNetworks.lazy_param-Tuple{Vararg{Function}}","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.lazy_param","text":"lazy_param(funcs::Function...)\n\nGenerate methods extended to a vector instead of one of its components. A function f should have the following signature: f(i::Int, x::V; param).\n\n\n\n\n\n","category":"method"},{"location":"icn/#CompositionalNetworks.learn_compose","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.learn_compose","text":"learn_compose(;\n    nvars, dom_size, param=nothing, icn=ICN(nvars, dom_size, param),\n    X, X_sols, global_iter=100, local_iter=100, metric=hamming, popSize=200\n)\n\nCreate an ICN, optimize it, and return its composition.\n\n\n\n\n\n","category":"function"},{"location":"icn/#CompositionalNetworks.manhattan-Tuple{Any, Any}","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.manhattan","text":"manhattan(x, X)\n\n\n\n\n\n","category":"method"},{"location":"icn/#CompositionalNetworks.minkowski-Tuple{Any, Any, Any}","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.minkowski","text":"minkowski(x, X, p)\n\n\n\n\n\n","category":"method"},{"location":"icn/#CompositionalNetworks.optimize!-NTuple{9, Any}","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.optimize!","text":"optimize!(icn, X, X_sols, global_iter, local_iter; metric=hamming, popSize=100)\n\nOptimize and set the weigths of an ICN with a given set of configuration X and solutions X_sols. The best weigths among global_iter will be set.\n\n\n\n\n\n","category":"method"},{"location":"icn/#CompositionalNetworks.regularization-Tuple{Any}","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.regularization","text":"regularization(icn)\n\nReturn the regularization value of an ICN weights, which is proportional to the normalized number of operations selected in the icn layers.\n\n\n\n\n\n","category":"method"},{"location":"icn/#CompositionalNetworks.show_layers-Tuple{Any}","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.show_layers","text":"show_layers(icn)\n\nReturn a formated string with each layers in the icn.\n\n\n\n\n\n","category":"method"},{"location":"icn/#CompositionalNetworks.transformation_layer","page":"CompositionalNetworks.jl","title":"CompositionalNetworks.transformation_layer","text":"transformation_layer(param = false)\n\nGenerate the layer of transformations functions of the ICN. Iff param value is true, also includes all the parametric transformations.\n\n\n\n\n\n","category":"function"},{"location":"public/#Public","page":"Public","title":"Public","text":"","category":"section"},{"location":"public/","page":"Public","title":"Public","text":"Pages = [\"public.md\"]\nDepth = 5","category":"page"},{"location":"public/","page":"Public","title":"Public","text":"Modules = [Constraints]\nPrivate = false","category":"page"},{"location":"public/#Constraints.usual_constraints","page":"Public","title":"Constraints.usual_constraints","text":"usual_constraints::Dict\n\nDictionary that contains all the usual constraints defined in Constraint.jl. It is based on XCSP3-core specifications available at https://arxiv.org/abs/2009.00514\n\nAdding a new constraint is as simple as\n\n@usual name p a sym₁ sym₂\n\nwhere\n\nname: constraint name\np: the length of the parameters (0 means no parameters)\na: the length of the arguments/variables (0 means any length is possible).\nsymᵢ: a sequence of symmetries (can be left empty)\n\nBoth a alone, or p and a together are optional.\n\nNote that concept_name needs to be defined. Unless both error_name and icn_error_name are defined, a default error function will be computed. Please (re-)define error_name for a hand_made error function.\n\n\n\n\n\n","category":"constant"},{"location":"public/#Constraints.usual_symmetries","page":"Public","title":"Constraints.usual_symmetries","text":"symmetries\n\nA Dictionary that contains the function to apply for each symmetry to avoid searching a whole space.\n\n\n\n\n\n","category":"constant"},{"location":"public/#Constraints.Constraint","page":"Public","title":"Constraints.Constraint","text":"Constraint\n\nParametric stucture with the following fields.\n\nconcept: a Boolean function that, given an assignment x, outputs true if x satisfies the constraint, and false otherwise.\nerror: a positive function that works as preferences over invalid assignements. Return 0.0 if the constraint is satisfied, and a strictly positive real otherwise.\n\n\n\n\n\n","category":"type"},{"location":"public/#Constraints.args-Tuple{Constraint}","page":"Public","title":"Constraints.args","text":"args(c::Constraint)\n\nReturn the expected length restriction of the arguments in a constraint c. The value nothing indicates that any strictly positive number of value is accepted.\n\n\n\n\n\n","category":"method"},{"location":"public/#Constraints.concept-Tuple{Constraint}","page":"Public","title":"Constraints.concept","text":"concept(c::Constraint)\n\nReturn the concept (function) of constraint c.     concept(c::Constraint, x...; param = nothing) Apply the concept of c to values x and optionally param.\n\n\n\n\n\n","category":"method"},{"location":"public/#Constraints.error_f-Tuple{Constraint}","page":"Public","title":"Constraints.error_f","text":"error_f(c::Constraint)\n\nReturn the error function of constraint c.     error_f(c::Constraint, x; param = nothing) Apply the error function of c to values x and optionally param.\n\n\n\n\n\n","category":"method"},{"location":"public/#Constraints.params_length-Tuple{Constraint}","page":"Public","title":"Constraints.params_length","text":"params_length(c::Constraint)\n\nReturn the expected length restriction of the arguments in a constraint c. The value nothing indicates that any strictly positive number of parameters is accepted.\n\n\n\n\n\n","category":"method"},{"location":"public/#Constraints.symmetries-Tuple{Constraint}","page":"Public","title":"Constraints.symmetries","text":"symmetries(c::Constraint)\n\nReturn the list of symmetries of c.\n\n\n\n\n\n","category":"method"},{"location":"internal/#Internal","page":"Internal","title":"Internal","text":"","category":"section"},{"location":"internal/","page":"Internal","title":"Internal","text":"Pages = [\"internal.md\"]\nDepth = 5","category":"page"},{"location":"internal/","page":"Internal","title":"Internal","text":"Modules = [Constraints]\nPublic = false","category":"page"},{"location":"internal/#Constraints.less_than_param","page":"Internal","title":"Constraints.less_than_param","text":"less_than_param\n\nConstraint ensuring that the value of x is less than a given parameter param.\n\n\n\n\n\n","category":"constant"},{"location":"internal/#Constraints.minus_equal_param","page":"Internal","title":"Constraints.minus_equal_param","text":"minus_equal_param\n\nConstraint ensuring that the difference between x[1] and x[2] is equal to a given parameter param.\n\n\n\n\n\n","category":"constant"},{"location":"internal/#Constraints.ordered","page":"Internal","title":"Constraints.ordered","text":"ordered(x)\n\nGlobal constraint ensuring that all the values of x are ordered.\n\n\n\n\n\n","category":"constant"},{"location":"internal/#Constraints.sequential_tasks","page":"Internal","title":"Constraints.sequential_tasks","text":"sum_equal_param\n\nConstraint ensuring that the start and completion times of two tasks are not intersecting: x[1] ≤ x[2] || x[3] ≤ x[4].\n\n\n\n\n\n","category":"constant"},{"location":"internal/#Constraints.sum_equal_param","page":"Internal","title":"Constraints.sum_equal_param","text":"sum_equal_param\n\nGlobal constraint ensuring that the sum of the values of x is equal to a given parameter param.\n\n\n\n\n\n","category":"constant"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = Constraints","category":"page"},{"location":"#Constraints.jl","page":"Home","title":"Constraints.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"A  back-end pacage for JuliaConstraints front packages, such as LocalSearchSolvers.jl.","category":"page"},{"location":"","page":"Home","title":"Home","text":"It provides the following features:","category":"page"},{"location":"","page":"Home","title":"Home","text":"A dictionary to store usual constraint: usual_contraint, which contains the following entries\n:all_different\n:dist_different\n:eq, :all_equal, :all_equal_param\n:ordered\n:always_true (mainly for testing default Constraint() constructor)\nFor each constraint c, the following properties\narguments length\nconcept (predicate the variables compliance with c)\nerror (a function that evaluate how much c is violated)\nparameters length\nknown symmetries of c\nA learning function using CompositionalNetworks.jl. If no error function is given when instanciating c, it will check the existence of a composition related to c and set the error to it.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Follow the list of the constraints currently stored in usual_constraint. Note that if the constraint is named _my_constraint, it can be accessed as usual_contraint[:my_constraint].","category":"page"},{"location":"","page":"Home","title":"Home","text":"Constraints._all_different\nConstraints._all_equal\nConstraints._all_equal_param\nConstraints._dist_different\nConstraints._eq\nConstraints._ordered","category":"page"},{"location":"#Contributing","page":"Home","title":"Contributing","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Contributions to this package are more than welcome and can be arbitrarily, and not exhaustively, split as follows:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Adding new constraints and symmetries\nAdding new ICNs to learn error of existing constraints\nCreating other compositional networks which target other kind of constraints\nJust making stuff better, faster, user-friendlier, etc.","category":"page"},{"location":"#Contact","page":"Home","title":"Contact","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Do not hesitate to contact me (@azzaare) or other members of JuliaConstraints on GitHub (file an issue), the julialang discourse forum, the julialang slack channel, the julialang zulip server, or the Human of Julia (HoJ) discord server.","category":"page"}]
}
