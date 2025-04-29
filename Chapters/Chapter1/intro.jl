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
    
    while size(toq)[1] > 1
        currelem = @view toq[:,i]
        lmask = trues(size(toq)[2])
        lmask[i] = false
        toq = @views toq[:,lmask]
        currmin = typemax(T)
        @inbounds for j in axes(toq)[2]
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

function TSP_greed_naive_copies(x::AbstractMatrix{T}, i = rand(1:size(x)[1])) where T
    #precompute distance matrix 
    #could do with an abstraction
    #each row of data is a single entry, i.e. we have dimension (D) number of columns

    #use squared eucleadin distance
    totdist = zero(T)
    N, D = size(x)
    
    toq = x
    
    while size(toq)[1] > 1
        currelem = @view toq[i,:]
        lmask = trues(size(toq)[1])
        lmask[i] = false
        toq = toq[lmask,:]
        currmin = typemax(T)
        @inbounds for j in axes(toq)[1]
            pot = @views currelem - toq[j,:]
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

#comparassion of above methods

using BenchmarkTools, Plots

function compare_greedies(N, D, generator = randn, dtype = Float64)
    
    t_samples1 = zeros(length(N), length(D))
    t_samples2 = zeros(length(N), length(D))
    for (i, n) in enumerate(N)
        for (j, d) in enumerate(D)
            println(i," ",j)
            samples = generator(dtype, n, d)
            results_views = @benchmark TSP_greed_naive_views($samples,1)
            results_copies = @benchmark TSP_greed_naive_copies($samples,1)
            t_samples1[i,j] = mean(results_views.times)
            t_samples2[i,j] = mean(results_copies.times)
        end
    end
    return t_samples1, t_samples2
end

sizes = [10, 100, 1000, 10000]
dimensions = [3]

