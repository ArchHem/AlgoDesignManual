using Test
include("../src/BasicSorts.jl")
using .BasicSorts, Random

@testset "quicksort 1D" begin
    rng = Xoshiro(3)
    x = rand(rng, 1000)

    z = rand(rng, 1:20, 50)

    u = sort(x)
    @test quicksort(x) == u
    quicksort!(x)
    @test x == u
    @test quicksort(z) == sort(z)
end

@testset "Higher dimensional quicksort" begin
    rng = Xoshiro(3)
    x0 = rand(rng, 10, 10, 10)
    x = copy(x0)

    indeces = sortperm(x[1,:, 1])
    quicksort!(x, [1, :, 1])
    @test x == x0[:, indeces, :]
end

@testset "quickselect" begin
    k = 5
    rng = Xoshiro(3)
    x = rand(rng, 1000)

    z = rand(rng, 1:20, 50)
    quickselect!(x,k)
    quickselect!(z,k)
    @test z[k] == sort(z)[k]
    @test x[k] == sort(x)[k]
end


