using Test

include("../src/BasicSorts.jl")
using .BasicSorts
using Random, StatsBase

@testset "Node KDTree Initial Tests" begin
    rng = Xoshiro(3)
    D = 3
    N = 100
    basedata = rand(rng, D, N)
    root = NodeKDTree(basedata)
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

    #randomly delete 20% of a tree and check
    points = rand(rng, D, N)
    ratio  = 0.3
    to_delete = sample(rng, collect(1:N), floor(Int64, N * ratio); replace = false)
    tree = NodeKDTree(points)
    for index in to_delete
        _, node = nn_search(tree, points[:, index])
        remove_node!(node)
    end
    #check if we can still insert some `20% nodes....
    
    to_add = rand(rng, D, floor(Int64, N * ratio))
    for column in eachcol(to_add)
        add_point!(tree, copy(column))
    end

    bool_flag = true
    for column in eachcol(to_add)
        dist, node = nn_search(tree, copy(column))
        bool_flag = bool_flag & isapprox(dist, 0)
    end
    @test bool_flag == true
end

@testset "KDTreeMatrix Initial Tests" begin
    rng = Xoshiro(3)
    D = 3
    N = 100
    basedata = rand(rng, D, N)

    tree = KDTreeMatrix(basedata)
    tree = double_tree(tree)
    index = rand(rng, 1:N)
    point = basedata[:, index]
    dist, index = nn_search(tree, point)
    @test tree.storage[:,index] == point
    @test isapprox(dist, 0.0)

    secindex = mod(index + rand(rng, 1:N), N) + 1
    secpoint = basedata[:, secindex]
    lazydelete!(tree, index)

    secdist, secindex = nn_search(tree, secpoint)
    @test tree.storage[:, secindex] == secpoint
    @test isapprox(secdist, 0.0)

    new_point = rand(rng, D)
    add_point!(tree, new_point)
    dist, index = nn_search(tree, new_point)
    @test tree.storage[:, index] == new_point
    @test isapprox(dist, 0.0)
    
    ratio = 0.3
    to_delete = sample(rng, findall(tree.sentinel), floor(Int64, N * ratio); replace = false)
    for index in to_delete
        lazydelete!(tree, index)
    end
    to_add = rand(rng, D, floor(Int64, N * ratio))
    for column in eachcol(to_add)
        add_point!(tree, copy(column))
    end

    all_found = all(column -> isapprox(nn_search(tree, copy(column))[1], 0.0), eachcol(to_add))
    @test all_found
end