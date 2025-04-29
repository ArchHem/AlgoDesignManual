#TSP Heuretics

#naive TSP heuretics

#Greedy method (implented without k-d lookup so scales N^2), see bellow for KD-method
using Random, LinearAlgebra

function TSP_greed_naive_views(x::AbstractMatrix{T}, i = rand(1:size(x)[1])) where T
    #precompute distance matrix 
    #could do with an abstraction
    #each column of data is a single entry, i.e. we have dimension (D) number of rows

    #use squared eucleadin distance
    totdist = zero(T)
    D, N = size(x)
    
    toq = x
    
    while size(toq)[2] > 1
        currelem = @view toq[:,i]
        
        toq = @views toq[:,1:end .!= i]
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
    end


    return totdist
end

using BenchmarkTools, Plots


sizes = [10, 50, 100, 200, 400, 800, 5000, 10000, 20000]
dimensions = 4

function plot_greedy_views_benchmark(sizes::Vector{Int}, D::Int; generator=randn, dtype=Float64)
    times = zeros(length(sizes))
    
    for (i, n) in enumerate(sizes)
        println("Benchmarking N = $n")
        samples = generator(dtype, D, n) 
        result = @benchmark TSP_greed_naive_views($samples, 1)
        times[i] = mean(result.times) / 1e6  
    end

    # Plotting
    res = plot(
        sizes,
        times,
        xlabel = "Number of Points (N)",
        ylabel = "Execution Time (ms)",
        title = "TSP Greedy Heuristic (Views Only)",
        marker = :circle,
        lw = 2,
        legend = false,
        grid = true
    )
    return res
end


res1 = plot_greedy_views_benchmark(sizes, 4)
