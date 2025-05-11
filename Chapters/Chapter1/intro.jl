#TSP Heuretics

#naive TSP heuretics

#Greedy method (implented without k-d lookup so scales N^2), see bellow for KD-method
using Random, LinearAlgebra
using BenchmarkTools, Plots
include("../../src/BasicSorts.jl")
using .BasicSorts

function TSP_greed_naive_views(x::AbstractMatrix{T}, start = zeros(T,size(x,1))) where T
    #precompute distance matrix 
    #could do with an abstraction
    #each column of data is a single entry, i.e. we have dimension (D) number of rows

    #use squared eucleadin distance
    totdist = zero(T)
    D, N = size(x)
    currelem = start
    toq = x
    i = 0
    while size(toq)[2] > 1
        currmin = typemax(T)
        @inbounds for j in axes(toq,2)
            pot = @views currelem - toq[:,j]
            cdist = dot(pot, pot)
            if cdist < currmin
                currmin = cdist
                i = j
            end
        end
        totdist += sqrt(currmin)
        currelem = @view toq[:,i]
        toq = @views toq[:,1:end .!= i]
    end


    return totdist
end

#I am pretty sure its the choice of i causing stalls...
function greedy_TSP_kd(x::AbstractMatrix{T}, start = zeros(T,size(x,1)), rebuild_ratio = 0.7, stop_size = 10) where T
    tree = KDTreeMatrix(copy(x))
    numelems = size(x,2)
    currelems = numelems
    totdist = zero(T)
    currpoint = start
    while currelems > 1
        #if we hit critical ratio, rebuild
        
        if currelems/numelems < rebuild_ratio && numelems > stop_size
            tree = rebuild(tree)
            numelems = sum(tree.sentinel)
        end
        
        bestdist, i = nn_search(tree,currpoint)
        point = tree.storage[:, i]
        lazydelete!(tree,i)
        totdist += sqrt(bestdist)
        currelems -= 1
        currpoint = point
    end

    return totdist
end

dimensions = 4

function TSP_greedy_comp(sizes = [100, 200, 400, 800, 1600], dimensions = 4)
    naive_times = Float64[]
    kd_times = Float64[]
    naive_dists = Float64[]

    # Warm-up and correctness check
    x = rand(Float64, dimensions, 1000)
    dist1 = TSP_greed_naive_views(x)
    dist2 = greedy_TSP_kd(x)
    println("Initial comparison (N = 1000): dist1 == dist2? ", isapprox(dist1, dist2; rtol=1e-6))

    for N in sizes
        println("Running for N = $N")
        x = rand(Float64, dimensions, N)

        # Benchmark both methods
        naive_time = @elapsed dist1 = TSP_greed_naive_views(x)
        kd_time = @elapsed greedy_TSP_kd(x)

        # Record times and distances
        push!(naive_times, naive_time)
        push!(kd_times, kd_time)
        push!(naive_dists, dist1)
    end

    p1 = plot(
        sizes,
        naive_times,
        label = "Naive Linear Search",
        lw = 2,
        marker = :circle,
        yscale = :log10,
        xlabel = "Number of Points (N)",
        ylabel = "Runtime (seconds, log scale)",
        title = "Greedy TSP: Runtime Comparison"
    )
    plot!(p1, sizes, kd_times, label = "KD-Tree", lw = 2, marker = :diamond)

    p2 = plot(
        sizes,
        naive_dists,
        label = "Naive Distance",
        lw = 2,
        marker = :circle,
        xlabel = "Number of Points (N)",
        ylabel = "Total Path Length",
        title = "Greedy TSP: Distances"
    )

    final_plot = plot(p1, p2, layout = (2, 1), size = (800, 600))
    return final_plot
end

sizes = [2^i for i in 4:15]
res = TSP_greedy_comp(sizes)