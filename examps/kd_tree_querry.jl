using BenchmarkTools, Plots, Statistics
include("../src/AbstractModule.jl")
using .Basics

function nearest_kdtree(tree::KDTreeMatrix{T}, query::AbstractVector{T}) where T
    best_index, point = nn_search(tree, query)
    return best_index, point
end

function nearest_brute(data::Matrix{T}, query::AbstractVector{T}) where T
    best_dist = typemax(T)
    best_index = -1
    @inbounds for i in 1:size(data, 2)
        pt = @views data[:, i]
        dist = sum(@. (pt - query)^2)
        if dist < best_dist
            best_index = i
        end
    end
    return best_index, @views data[:, best_index]
end

function benchmark_knn_search(maxN::Int=10_000; step=500, D=4)
    ns = step:step:maxN
    kdtimes = Float64[]
    brutetimes = Float64[]

    for N in ns
        println("Benchmarking n = $N points")
        points = rand(D, N)
        tree = KDTreeMatrix(points)
        query = rand(D)

        
        kd_bench = @benchmark nn_search($tree, $query)
        push!(kdtimes, mean(kd_bench).time / 1e9)

        
        brute_bench = @benchmark nearest_brute($points, $query)
        push!(brutetimes, mean(brute_bench).time / 1e9)
    end

    u = plot(ns, kdtimes, label="KDTree Search", lw=2, xlabel="Number of Points (N)", ylabel="Time (s)", legend=:topleft)
    plot!(u, ns, brutetimes, label="Brute-Force Search", lw=2, linestyle=:dash)
    return u
end

examp = benchmark_knn_search()
show(examp)
