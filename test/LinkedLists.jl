using Test
using Random
include("../src/LinkedList.jl")

@testset "SimpleLinkedList Tests" begin
    empty_list = SimpleLinkedList()
    @test length(empty_list) == 0
    @test eltype(empty_list) === Nothing
    @test collect(empty_list) == []
    list = SimpleLinkedList(1, 2, 3)
    @test length(list) == 3
    @test eltype(list) === Int
    @test collect(list) == [1, 2, 3]

    iter_empty = iterate(empty_list)
    @test iter_empty=== nothing
    iter1 = iterate(list)
    @test iter1[1] == 1
    iter2 = iterate(list, iter1[2])
    @test iter2[1] == 2
    iter3 = iterate(list, iter2[2])
    @test iter3[1] == 3
    iter4 = iterate(list, iter3[2])
    @test iter4 === nothing

    rev_empty = reverse(empty_list)
    @test length(rev_empty) == 0
    @test collect(rev_empty) == []
    rev_list = reverse(list)
    @test length(rev_list) == 3
    @test collect(rev_list) == [3, 2, 1]
    single_node = SimpleLinkedList(10)

    boolval = true
    rng = Xoshiro(1)
    vals = rand(rng, 20)
    first_node = SimpleLinkedList()
    for (i, elem) in enumerate(first_node)
        boolval = boolval && (elem == vals[i])
    end
    @test boolval

end