using Test
using Random
include("../src/BasicLists.jl")
using .BasicLists


@testset "StaticLinkedList Comprehensive Tests" begin

    @testset "StaticListEnd (Empty List)" begin
        l_int_empty = StaticListEnd{Int}()
        l_str_empty_val = StaticListEnd("some_string_for_type_inference") 
        l_str_empty_typ = StaticListEnd(String) 

        @test eltype(l_int_empty) == Int
        @test eltype(l_str_empty_val) == String
        @test eltype(l_str_empty_typ) == DataType

        @test length(l_int_empty) == 0
        @test ndims(l_int_empty) == 1
        @test ndims(l_int_empty) == 1
        @test size(l_int_empty) == (0,)

        @test iterate(l_int_empty) === nothing

        @test firstindex(l_int_empty) == 0
        @test lastindex(l_int_empty) == 0
        @test eachindex(l_int_empty) == 1:0

        @test next(l_int_empty) === nothing
        @test value(l_int_empty) === nothing

        #Content implies equality, not parameters.
        @test l_int_empty == StaticListEnd{Int}()
        @test l_int_empty == l_str_empty_val 
        @test l_str_empty_val == l_str_empty_typ

        @test map(x -> x + 1, l_int_empty) === l_int_empty 
        @test map(x -> string(x), l_int_empty) === l_int_empty 
        
        @test copy(l_int_empty) === l_int_empty

        @test collect(l_int_empty) == Int[]
        @test Vector(l_int_empty) == Int[]
        @test collect(l_str_empty_val) == String[]
        
        @test reverse(l_int_empty) === l_int_empty
    end

    @testset "StaticListNode Constructors" begin
        l1 = StaticListNode(10)
        @test value(l1) == 10 && eltype(l1) == Int && length(l1) == 1
        @test isa(next(l1), StaticListEnd{Int})

        l2 = StaticListNode(20, l1)
        @test value(l2) == 20 && value(next(l2)) == 10 && eltype(l2) == Int && length(l2) == 2

        l3 = StaticListNode(1, 2, 3)
        @test value(l3) == 1 && value(next(l3)) == 2 && value(next(next(l3))) == 3
        @test eltype(l3) == Int && length(l3) == 3
        @test isa(next(next(next(l3))), StaticListEnd{Int})

        l4_mixed = StaticListNode(1, 2.0, Int16(3))
        @test value(l4_mixed) == 1.0 && value(next(l4_mixed)) == 2.0 && value(next(next(l4_mixed))) == 3.0
        @test eltype(l4_mixed) == Float64 && length(l4_mixed) == 3
    end

    @testset "Core List Operations (Non-Empty)" begin
        l0 = StaticListEnd{Int}()
        l1 = StaticListNode(10)
        l3 = StaticListNode(1, 2, 3)
        l3_float = StaticListNode(1.0, 2.0, 3.0)

        @test eltype(l3) == Int
        @test length(l3) == 3
        @test ndims(l3) == 1
        @test size(l3) == (3,)

        @test collect(l3) == [1, 2, 3]
        @test collect(l1) == [10]
        
        vals_mixed = []
        l_mixed_explicit_end = StaticListNode(10, StaticListNode("hello", StaticListEnd{Union{Int,String}}()))
        for x_val in l_mixed_explicit_end; push!(vals_mixed, x_val); end
        @test vals_mixed == [10, "hello"]

        @test reverse(l3) == StaticListNode(3, 2, 1)
        @test eltype(reverse(l3)) == Int
        @test reverse(l1) == l1
        @test reverse(reverse(l3)) == l3

        l3_copy = copy(l3)
        @test l3_copy == l3
        @test eltype(l3_copy) == Int

        @test firstindex(l3) == 1 && lastindex(l3) == 3 && eachindex(l3) == 1:3

        @test getindex(l3, 1) == 1 && getindex(l3, 2) == 2 && getindex(l3, 3) == 3
        @test_throws BoundsError getindex(l3, 0)
        @test_throws BoundsError getindex(l3, 4)
        @test_throws BoundsError getindex(l0, 1)
        @test_throws BoundsError getindex(l1, 2)

        @test StaticListNode(1,2,3) == StaticListNode(1,2,3)
        @test StaticListNode(1,2,3) != StaticListNode(1,2,4)
        @test StaticListNode(1,2,3) != StaticListNode(1,2)
        @test l3 == l3_float 
        @test l3 == StaticListNode(1.0, 2.0, 3.0)

        @test StaticListNode(1) != l0
        @test l0 != StaticListNode(1)
    end

    @testset "map" begin
        l0_int = StaticListEnd{Int}()
        l1 = StaticListNode(10)
        l3 = StaticListNode(1, 2, 3)

        @test map(x -> x * 2, l3) == StaticListNode(2, 4, 6)
        @test map(x -> x * 2, l0_int) === l0_int
        @test map(string, l3) == StaticListNode("1", "2", "3")
        @test eltype(map(string, l3)) == String

        l3a = StaticListNode(1, 2, 3)
        l3b = StaticListNode(4, 5, 6)
        l2 = StaticListNode(10, 20)

        @test map(+, l3a, l3b) == StaticListNode(5, 7, 9)
        @test map(+, l3a, l2) == StaticListNode(11, 22)
        @test map(+, l2, l3a) == StaticListNode(11, 22)

        l_int = StaticListNode(1, 2)
        l_flt = StaticListNode(3.0, 4.0)
        @test map(+, l_int, l_flt) == StaticListNode(4.0, 6.0)
        @test eltype(map(+, l_int, l_flt)) == Float64
        
        @test map((x,y) -> string(x,"-",y), l_int, l3b) == StaticListNode("1-4", "2-5")
        @test eltype(map((x,y) -> string(x,"-",y), l_int, l3b)) == String
    end

    @testset "filter" begin
        l0_int = StaticListEnd{Int}()
        l5 = StaticListNode(1, 2, 3, 4, 5)

        @test filter(x -> x > 3, l5) == StaticListNode(4, 5)
        @test filter(iseven, l5) == StaticListNode(2, 4)
        @test filter(x -> x > 10, l5) == StaticListEnd{Int}()
        @test eltype(filter(x -> x > 10, l5)) == Int
        
        @test filter(x -> true, l5) == l5
        @test filter(x -> false, l5) == StaticListEnd{Int}()

        #NOT YET IMPLEMENTED
        #@test filter(x -> x > 0, l0_int) === l0_int
    end
    @testset "Utilities (collect, Vector, promote_rule)" begin
        l3 = StaticListNode(1,2,3)
        @test collect(l3)::Vector{Int} == [1,2,3]
        @test Vector(l3)::Vector{Int} == [1,2,3]

        @test promote_type(StaticListNode{Int}, StaticListNode{Float64}) == StaticListNode{Float64}
        @test promote_type(StaticListEnd{Int}, StaticListEnd{String}) == StaticListEnd{Any}
        @test promote_type(StaticLinkedList{Int}, Vector{Float64}) == Vector{Float64}
    end

    @testset "Broadcasting" begin
        l0_i = StaticListEnd{Int}()
        l1_i = StaticListNode(10)
        l3_i = StaticListNode(1, 2, 3)
        l3_f = StaticListNode(4.0, 5.0, 6.0)
        l2_i = StaticListNode(10, 20)

        @test l3_i .+ 1 == StaticListNode(2, 3, 4)
        @test eltype(l3_i .+ 1) == Int
        @test 1 .+ l3_i == StaticListNode(2, 3, 4)
        @test l3_i .* 2 == StaticListNode(2, 4, 6)
        @test (l3_i .== 2) == StaticListNode(false, true, false)
        @test eltype(l3_i .== 2) == Bool

        @test l3_i .+ l3_f == StaticListNode(5.0, 7.0, 9.0)
        @test eltype(l3_i .+ l3_f) == Float64

        @test l3_i .+ l2_i == StaticListNode(11, 22)
        @test l2_i .+ l3_i == StaticListNode(11, 22)
        #NOT YET IMPLEMENTED
        #@test l0_i .+ 1 == l0_i
        @test eltype(l0_i .+ 1) == Int

        @test string.(l3_i) == StaticListNode("1", "2", "3")
        @test eltype(string.(l3_i)) == String
        
        l_a = StaticListNode(1,2,3)
        l_b = StaticListNode(10,20,30)
        l_c = StaticListNode(0.5, 1.5, 2.5)
        @test l_a .* l_b .- l_c == StaticListNode(1*10-0.5, 2*20-1.5, 3*30-2.5)
        @test eltype(l_a .* l_b .- l_c) == Float64
    end
end
