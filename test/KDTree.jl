using Test

include("../src/AbstractModule.jl")
using .Basics
using Random

@testset "Node KDTree Tests" begin
    rng = Xoshiro(3)
    D = 3
    N = 100
    basedata = rand(rng, D, N)
    root = NodeKDTRee(basedata)
    #choose an elemement at random
    index = rand(rng, 1:N)
    #test that nn works
    point = basedata[:, index]

    dist, nearest = nn_search(root, point)
    @test nearest.point == point
    @test isapprox(dist, 0.0)

    secindex = mod(index + rand(rng, 1:N), N) + 1
    secpoint = basedata[:, secindex]

    #delete old point
    remove_node!(nearest)

    secdist, secnearest = nn_search(root, secpoint)
    @test secnearest.point == secpoint
    @test isapprox(secdist, 0.0)

end