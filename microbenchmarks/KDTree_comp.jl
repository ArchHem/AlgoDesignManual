include("../src/BasicSorts.jl")
using .BasicSorts
using Random, Plots, BenchmarkTools

function construction_benchmark_bt(N::Int, D::Int = 3, rng::AbstractRNG = Xoshiro(3))
    data = rand(rng, D, N)
    data1 = copy(data)

    b1 = @benchmark KDTreeMatrix($data)
    b2 = @benchmark NodeKDTree($data1)

    return (b1, b2)
end

function search_benchmark_bt(N::Int, D::Int = 3, rng::AbstractRNG = Xoshiro(3))
    data = rand(rng, D, N)
    data1 = copy(data)
    tree_1 = KDTreeMatrix(data)
    tree_2 = NodeKDTree(data1)
    point = rand(rng, D)
    b1 = @benchmark nn_search($tree_1, $point)
    b2 = @benchmark nn_search($tree_2, $point)
    return (b1, b2)
end

function grand_benchmark_bt(ns::Vector{Int}, D::Int = 2)
    construction_benchmark_bt(10, D)
    search_benchmark_bt(10, D)

    build_matrix_times = Float64[]
    build_node_times = Float64[]
    search_matrix_times = Float64[]
    search_node_times = Float64[]
    for n in ns
        println("Benchmarking N = $n...")
        b_cons_matrix, b_cons_node = construction_benchmark_bt(n, D)
        push!(build_matrix_times, mean(b_cons_matrix).time / 1e9)
        push!(build_node_times, mean(b_cons_node).time / 1e9)

        b_search_matrix, b_search_node = search_benchmark_bt(n, D)
        push!(search_matrix_times, mean(b_search_matrix).time / 1e9)
        push!(search_node_times, mean(b_search_node).time / 1e9)
    end

    p1 = plot(ns, build_matrix_times; label = "KDTreeMatrix", title = "Construction Time",
              xlabel = "N", ylabel = "Time (s)", lw = 2, marker = :circle, legend = :topleft)
    plot!(p1, ns, build_node_times; label = "NodeKDTree", lw = 2, marker = :diamond)

    p2 = plot(ns, search_matrix_times; label = "KDTreeMatrix", title = "Search Time",
              xlabel = "N", ylabel = "Time (s)", lw = 2, marker = :circle, legend = :topleft)
    plot!(p2, ns, search_node_times; label = "NodeKDTree", lw = 2, marker = :diamond)

    return plot(p1, p2; layout = (1, 2), size = (1200, 500))
end

ns = [2^i + 1 for i in 1:12]
grand_benchmark_bt(ns)