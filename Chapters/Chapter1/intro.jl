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

function TSP_greed_naive_copies(x::AbstractMatrix{T}, i = rand(1:size(x)[1]), reformat = 100) where T
    #precompute distance matrix 
    #could do with an abstraction
    #each column of data is a single entry, i.e. we have dimension (D) number of rows

    #use squared eucleadin distance
    totdist = zero(T)
    D, N = size(x)
    
    toq = x
    count = 1
    while size(toq)[2] > 1
        currelem = @view toq[:,i]
        
        toq = mod(count, reformat) == 0 ? toq[:,1:end .!= i] : @views toq[:,1:end .!= i]
        currmin = typemax(T)
        @inbounds for j in axes(toq,2)
            pot = @views currelem - toq[:,j]
            cdist = dot(pot, pot)
            if cdist < currmin
                currmin = cdist
                i = j
            end
        end
        count += 1
        totdist += sqrt(currmin)
    end


    return totdist
end

using BenchmarkTools, Plots


sizes = [1000, 2500, 5000, 10000, 15000, 20000]
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
        grid = true,
        titlesize = 6,
        guidefontsize = 5
    )
    return res
end

function plot_greedy_copies_benchmark(sizes::Vector{Int}, D::Int; generator=randn, dtype=Float64)
    times = zeros(length(sizes))
    
    for (i, n) in enumerate(sizes)
        println("Benchmarking N = $n")
        samples = generator(dtype, D, n) 
        result = @benchmark TSP_greed_naive_copies($samples, 1)
        times[i] = mean(result.times) / 1e6  
    end

    # Plotting
    res = plot(
        sizes,
        times,
        xlabel = "Number of Points (N)",
        ylabel = "Execution Time (ms)",
        title = "TSP Greedy Heuristic (Partial Copy Only)",
        marker = :circle,
        lw = 2,
        legend = false,
        grid = true,
        titlesize = 6,
        guidefontsize = 5
    )
    return res
end


res1 = plot_greedy_views_benchmark(sizes, 4)
res2 = plot_greedy_copies_benchmark(sizes, 4)

plot(res1, res2, layout = (1,2))