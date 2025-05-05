#TSP Heuretics

#naive TSP heuretics

#Greedy method (implented without k-d lookup so scales N^2), see bellow for KD-method
using Random, LinearAlgebra
using BenchmarkTools, Plots
include("../../src/AbstractModule.jl")
using .Basics

function TSP_greed_naive_views(x::AbstractMatrix{T}, i = rand(1:size(x,2))) where T
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

function greedy_TSP_kd(x::AbstractMatrix{T}, i = rand(1:size(x,2)), rebuild_ratio = 0.7)
    tree = KDTreeMatrix(copy(x))
    numelems = size(x,2)
    currelems = numelems
    totdist = zero(T)
    while currelems > 0
        currpoint = @views tree.storage[:,i]
        #revise
        if currelems/numelems < rebuild_ratio
            numelems = sum(tree.sentinel)
            tree = rebuild(tree)
            #recalculate position in new tree
            i, point = nn_search(tree,currpoint)
            #delete the old (current) point
            lazydelete!(tree, i)
            currelems -= 1
            i, point = nn_search(tree,currpoint)
            displ = point - currpoint
            totdist += sqrt(dot(displ,displ))
            currelems -= 1
        else
            lazydelete!(tree,i)
            i, point = nn_search(tree,currpoint)
            displ = point - currpoint
            totdist += sqrt(dot(displ,displ))
            currelems -= 1
        end
        currpoint = point
    end

    return totdist
end

sizes = [1000, 2500, 5000, 10000, 15000, 20000]
dimensions = 4

function TSP_greedy_comp(sizes = sizes)

end

res1 = plot_greedy_views_benchmark(sizes, 4)


plot(res1, res2, layout = (1,2))