function preprocess(prob::Problem, k; graph = build_graph(prob), maxpaths=1000)
    comm = prob.K[k]
    bfpaths = enumerate_bilevel_feasible(graph, comm.orig, comm.dest, prob, maxpaths + 1)
    if length(bfpaths) == 1
        return EmptyProblem(prob, k)
    elseif length(bfpaths) > maxpaths
        return preprocess_spgm(prob, k, graph=graph)
    else
        return preprocess_path(prob, k, bfpaths)
    end
end

preprocess(prob::Problem; graph = build_graph(prob), kwargs...) = [preprocess(prob, k; graph=graph, kwargs...) for k in 1:length(prob.K)]