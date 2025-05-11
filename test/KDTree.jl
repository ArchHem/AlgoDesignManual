using Test

include("../src/BasicSorts.jl")
using .BasicSorts
using Random

@testset "Node KDTree Initial Tests" begin
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

    new_point = rand(rng, D)
    add_point!(root, new_point)
    dist, nearest = nn_search(root, new_point)
    @test nearest.point == new_point
    @test isapprox(dist, 0.0)
end