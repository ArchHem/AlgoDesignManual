using Test
using Random
include("../src/BasicLists.jl")
using .BasicLists

@testset "StaticLinkedList Tests" begin

    @testset "Construction and Basic Access" begin
        l = StaticListNode(1, 2, 3)
        @test isa(l, StaticListNode)
        @test value(l) == 1
        @test value(next(l)) == 2
        @test value(next(next(l))) == 3
        @test next(next(next(l))) isa StaticListEnd
    end

    @testset "Length and Indexing" begin
        l = StaticListNode(4, 5, 6)
        @test length(l) == 3
        @test l[1] == 4
        @test l[2] == 5
        @test l[3] == 6
        @test_throws BoundsError l[4]
    end

    @testset "Iteration" begin
        l = StaticListNode(7, 8, 9)
        values = [x for x in l]
        @test values == [7, 8, 9]
    end

    @testset "Reverse" begin
        l = StaticListNode("a", "b", "c")
        rev = reverse(l)
        @test collect(rev) == ["c", "b", "a"]
    end

    @testset "Copy" begin
        l = StaticListNode(10, 20, 30)
        cp = copy(l)
        @test cp == l
    end

    @testset "Equality" begin
        l1 = StaticListNode(1, 2, 3)
        l2 = StaticListNode(1, 2, 3)
        l3 = StaticListNode(1, 2)
        @test l1 == l2
        @test l1 != l3
        @test StaticListEnd(Int) == StaticListEnd(Int)
    end

    @testset "map" begin
        l = StaticListNode(1, 2, 3)
        squared = map(x -> x^2, l)
        @test collect(squared) == [1, 4, 9]
        e = StaticListEnd(Int)
        @test map(x -> x + 1, e) === e
    end

    @testset "filter" begin
        l = StaticListNode(1, 2, 3, 4)
        even = filter(x -> x % 2 == 0, l)
        @test collect(even) == [2, 4]

        none = filter(x -> false, l)
        @test collect(none) == Int[]
    end

    @testset "eachindex and collect" begin
        l = StaticListNode(5, 6, 7)
        @test eachindex(l) == 1:3
        @test collect(l) == [5, 6, 7]
    end

    @testset "Heterogeneous Type Promotion" begin
        l = StaticListNode(1, 2.5, 3)
        @test eltype(l) == Float64
        @test collect(l) == [1.0, 2.5, 3.0]
    end

end