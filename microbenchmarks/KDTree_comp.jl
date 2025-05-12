include("../src/BasicSorts.jl")
using .BasicSorts
using Random, Plots


function construction_benchmark(N, D = 3, rng = Xoshiro(3))
    data = rand(rng,D,N)
    data1 = copy(data)
    t1 = @elapsed KDTreeMatrix(data)
    t2 = @elapsed NodeKDTree(data1)

    return (t1, t2)
end

function search_benchmark(N, D = 3, rng = Xoshiro(3))
    data = rand(rng,D,N)
    data1 = copy(data)
    tree_1 =  KDTreeMatrix(data)
    tree_2 = NodeKDTree(data1)

    point = rand(rng, D)
    t1 = @elapsed nn_search(tree_1, point)
    t2 = @elapsed nn_search(tree_2, point)

    return (t1, t2)
end

function grand_benchmark(ns, D = 2)
    construction_benchmark(10, D)
    search_benchmark(10, D)
    build_matrix = Float64[]
    build_node = Float64[]
    search_matrix = Float64[]
    search_node = Float64[]
    for n in ns
        t1b, t2b = construction_benchmark(n)
        t1s, t2s = search_benchmark(n)
        push!(build_matrix, t1b)
        push!(build_node, t2b)
        push!(search_matrix, t1s)
        push!(search_node, t2s)
    end
    p1 = plot(ns, build_matrix; label = "KDTreeMatrix", title = "Construction Time",
              xlabel = "N", ylabel = "Time (s)", lw = 2, marker = :circle)
    plot!(p1, ns, build_node; label = "NodeKDTree", lw = 2, marker = :diamond)

    p2 = plot(ns, search_matrix; label = "KDTreeMatrix", title = "Search Time",
              xlabel = "N", ylabel = "Time (s)", lw = 2, marker = :circle)
    plot!(p2, ns, search_node; label = "NodeKDTree", lw = 2, marker = :diamond)

    return plot(p1, p2; layout = (1, 2))
end

ns = [2^i + 1 for i in 1:17]
grand_benchmark(ns)