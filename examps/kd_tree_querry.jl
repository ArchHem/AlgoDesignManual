using BenchmarkTools, Plots, Random
include("../src/AbstractModule.jl")
using .Basics

function bf_nn(data::Matrix{T}, point::AbstractVector{T}) where T
    bestindex, bestdist = -1, typemax(T)
    @inbounds for i in axes(data, 2)
        candidate = @view data[:, i]
        dist = sum(@. (candidate - point)^2)
        if dist < bestdist
            bestdist = dist
            bestindex = i
        end
    end
    return bestindex, @views data[:, bestindex]
end

u = rand(4,10000)

tree = KDTreeMatrix(u)
point = rand(Xoshiro(1),4)
index, closest = nn_search(tree,point)
indexb, closestb = bf_nn(u,point)