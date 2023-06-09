struct ConjugatePreprocessedModel <: AbstractConjugateSolver
    model::Model
    probs::Vector{AbstractCommodityProblem}
end

# Interface
problem(cmodel::ConjugatePreprocessedModel) = parent(first(cmodel.probs))
num_commodities(cmodel::ConjugatePreprocessedModel) = length(cmodel.probs)

# Init a conjugate model for the whole problem, weights = commodity demands, odpairs already set
function ConjugatePreprocessedModel(
    representation::Type{<:DualRepresentation},
    probs::Vector{<:AbstractCommodityProblem},
    weights=demand.(probs);
    silent=true, threads=nothing)

    model = Model(() -> Gurobi.Optimizer(current_env()))
    set_optimizer_attribute(model, MOI.Silent(), silent)
    set_optimizer_attribute(model, MOI.NumberOfThreads(), threads)

    parent_a1 = tolled_arcs(parent(first(probs)))
    @variable(model, t[a=parent_a1] ≥ 0)

    obj = AffExpr()

    for (prob, weight) in zip(probs, weights)
        (prob isa EmptyProblem) && continue
        repr = _make_representation(prob, representation)
        formulate_dual!(model, repr)
        obj += dualobj(repr) * weight
    end
    
    @objective(model, Max, obj)
    
    return ConjugatePreprocessedModel(model, probs)
end

ConjugatePreprocessedModel(probs::Vector{<:AbstractCommodityProblem}, weights=demand.(probs); kwargs...) =
    ConjugatePreprocessedModel(DualArc, probs, weights; kwargs...)

_make_representation(prob::AbstractCommodityProblem, ::Type{DualArc}) = DualArc(prob)
_make_representation(prob::AbstractCommodityProblem, ::Type{DualPath}) = DualArc(prob)
_make_representation(prob::PathPreprocessedProblem, ::Type{DualPath}) = DualPath(prob)

# Set demands (and maximize sum of tolls in priority list)
function set_demands(cmodel::ConjugatePreprocessedModel, demands, priority; discount=default_discount())
    model = cmodel.model
    for a in tolled_arcs(problem(cmodel))
        set_objective_coefficient(model, model[:t][a], -get(demands, a, 0.) * (a ∈ priority ? discount : 1.))
    end
    return nothing
end

# Optimize
JuMP.optimize!(cmodel::ConjugatePreprocessedModel) = optimize!(cmodel.model)
JuMP.objective_value(cmodel::ConjugatePreprocessedModel) = objective_value(cmodel.model)
tvals(cmodel::ConjugatePreprocessedModel) = value.(cmodel.model[:t]).data
