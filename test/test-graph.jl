@testset "Graph" begin
    prob = read_problem("../problems/paper/d30-01.json")
    graph = build_graph(prob)

    @testset "Minimal shortest path" begin
        for t in 1:1000
            o, d = randperm(prob.V)[1:2]
            cBuiltIn = NetPricingTollBranch.shortest_path_old(graph, o, d)[2]
            cMinimal = shortest_path(graph, o, d)[2]
            @test cBuiltIn ≈ cMinimal
        end
    end
end