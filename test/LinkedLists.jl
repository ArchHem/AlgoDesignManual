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

@testset "MListNode Tests" begin

    @testset "Constructors" begin
        l0 = MListEnd{Int}()
        @test l0 isa MListEnd{Int}
        @test length(l0) == 0

        l1 = MListNode(10)
        @test l1 isa MListNode{Int}
        @test value(l1) == 10
        @test next(l1) isa MListEnd{Int}
        @test length(l1) == 1

        l2 = MListNode(20, l1)
        @test value(l2) == 20
        @test value(next(l2)) == 10
        @test length(l2) == 2

        l3 = MListNode(1, 2, 3)
        @test l3 isa MListNode{Int}
        @test collect(l3) == [1, 2, 3]
        @test length(l3) == 3

        l4_float = MListNode(1.0, 2.0, 3.0)
        @test l4_float isa MListNode{Float64}
        @test collect(l4_float) == [1.0, 2.0, 3.0]

        l5_mixed = MListNode(1, 2.0, 3)
        @test l5_mixed isa MListNode{Float64}
        @test collect(l5_mixed) == [1.0, 2.0, 3.0]

        l_end_typed = MListEnd(5)
        @test l_end_typed isa MListEnd{Int}
    end

    @testset "Basic Properties" begin
        l_empty = MListEnd{Float32}()
        l_single = MListNode(100)
        l_multi = MListNode("a", "b", "c")

        @test eltype(l_empty) == Float32
        @test eltype(l_single) == Int
        @test eltype(l_multi) == String

        @test length(l_empty) == 0
        @test length(l_single) == 1
        @test length(l_multi) == 3

        @test ndims(l_empty) == 1
        @test ndims(l_single) == 1
        @test ndims(l_multi) == 1

        @test size(l_empty) == (0,)
        @test size(l_single) == (1,)
        @test size(l_multi) == (3,)

        @test firstindex(l_empty) == 0
        @test firstindex(l_single) == 1
        @test firstindex(l_multi) == 1

        @test lastindex(l_empty) == 0
        @test lastindex(l_single) == 1
        @test lastindex(l_multi) == 3

        @test value(l_empty) === nothing
        @test value(l_single) == 100
        @test value(l_multi) == "a"

        @test next(l_empty) === nothing
        @test next(l_single) isa MListEnd{Int}
        @test value(next(l_multi)) == "b"
    end

    @testset "Iteration & Collection" begin
        l_empty = MListEnd{Int}()
        @test collect(l_empty) == []

        l_nums = MListNode(10, 20, 30)
        @test collect(l_nums) == [10, 20, 30]

        iter_sum = 0
        for x in l_nums
            iter_sum += x
        end
        @test iter_sum == 60

        @test Vector(l_nums) == [10, 20, 30]
    end

    @testset "Core Operations" begin
        l_orig = MListNode(1, 2, 3)
        l_copy = copy(l_orig)
        @test l_copy isa MListNode{Int}
        @test collect(l_copy) == [1, 2, 3]
        @test !(l_copy === l_orig)
        @test !(next(l_copy) === next(l_orig))
        l_orig.value = 100
        @test value(l_copy) == 1

        l_end = MListEnd{Int}()
        @test copy(l_end) == l_end

        @test MListNode(1,2,3) == MListNode(1,2,3)
        @test MListNode(1,2,3) != MListNode(1,2,4)
        @test MListNode(1,2,3) != MListNode(1,2)
        @test MListNode(1,2) != MListNode(1,2,3)
        @test MListEnd{Int}() == MListEnd{Int}()
        @test MListEnd{Int}() == MListEnd{Float64}()
        @test MListNode(1) != MListEnd{Int}()
        @test MListEnd{Int}() != MListNode(1)
        @test MListNode(1.0, 2.0) == MListNode(1, 2)

        l = MListNode(:a, :b, :c)
        @test l[1] == :a
        @test l[2] == :b
        @test l[3] == :c

        l_mutable = MListNode(10, 20, 30)
        l_mutable[2] = 200
        @test l_mutable[2] == 200
        @test collect(l_mutable) == [10, 200, 30]
        l_mutable[1] = 100
        @test collect(l_mutable) == [100, 200, 30]
        l_mutable[3] = 300
        @test collect(l_mutable) == [100, 200, 300]
    end

    @testset "List Manipulation" begin
        l = MListNode(1,2,3)
        lr = reverse(l)
        @test collect(lr) == [3,2,1]
        @test collect(l) == [1,2,3]
        @test lr isa MListNode{Int}
        @test reverse(MListEnd{Int}()) isa MListEnd{Int}

        l_mut = MListNode(10,20,30)
        l_mut_rev = reverse!(l_mut)
        @test l_mut_rev isa MListNode{Int}
        @test collect(l_mut_rev) == [30,20,10]
        @test value(l_mut) == 10
        @test next(l_mut) isa MListEnd
        @test reverse!(MListEnd{Int}()) isa MListEnd{Int}

        l_map_in = MListNode(1,2,3)
        l_map_out = map(x -> x*x, l_map_in)
        @test collect(l_map_out) == [1,4,9]
        @test collect(l_map_in) == [1,2,3]
        @test l_map_out isa MListNode{Int}
        @test map(x->x, MListEnd{Float64}()) isa MListEnd{Float64}

        l_map_in2 = MListNode(4,5,6)
        l_map_out_multi = map(+, l_map_in, l_map_in2)
        @test collect(l_map_out_multi) == [1+4, 2+5, 3+6]
        @test l_map_out_multi isa MListNode{Int}

        l_filter_in = MListNode(1,2,3,4,5)
        l_filter_out = filter(isodd, l_filter_in)
        @test collect(l_filter_out) == [1,3,5]
        @test collect(l_filter_in) == [1,2,3,4,5]
        @test l_filter_out isa MListNode{Int}

        l_pop = MListNode(1,2,3,4)
        val_popped = popnext!(l_pop)
        @test val_popped == 2
        @test collect(l_pop) == [1,3,4]
        val_popped2 = popnext!(next(l_pop))
        @test val_popped2 == 4
        @test collect(l_pop) == [1,3]

        l_ins = MListNode(10, 30)
        node_to_insert = MListNode(20)
        insertnext!(l_ins, node_to_insert)
        @test collect(l_ins) == [10, 20, 30]
        l_ins_end = MListNode(100)
        node_to_insert2 = MListNode(200)
        insertnext!(l_ins_end, node_to_insert2)
        @test collect(l_ins_end) == [100, 200]

        l_insf = MListNode(1, 4)
        list_to_insert = MListNode(2, 3)
        insertfull!(l_insf, list_to_insert)
        @test collect(l_insf) == [1, 2, 3, 4]
        @test value(next(list_to_insert)) == 3
        @test value(next(next(list_to_insert))) == 4

        l_insf_single_target = MListNode(10)
        list_to_insert2 = MListNode(20,30)
        insertfull!(l_insf_single_target, list_to_insert2)
        @test collect(l_insf_single_target) == [10,20,30]

        l_cat1 = MListNode(1,2)
        l_cat2 = MListNode(3,4)
        cat!(l_cat1, l_cat2)
        @test collect(l_cat1) == [1,2,3,4]
        @test collect(l_cat2) == [3,4]
    end

    @testset "Broadcasting" begin
        y = MListNode(1, 2, 3)
        y_plus_1 = y .+ 1
        @test y_plus_1 isa MListNode{Int}
        @test collect(y_plus_1) == [2, 3, 4]
        @test collect(y) == [1, 2, 3]

        y_times_2 = y .* 2
        @test y_times_2 isa MListNode{Int}
        @test collect(y_times_2) == [2, 4, 6]

        y_float = MListNode(1.0, 2.0)
        y_plus_int = y_float .+ 1
        @test y_plus_int isa MListNode{Float64}
        @test collect(y_plus_int) == [2.0, 3.0]

        z = MListNode(10, 20, 30)
        z_orig_id = objectid(z)
        z .= z .+ 5
        @test objectid(z) == z_orig_id
        @test z isa MListNode{Int}
        @test collect(z) == [15, 25, 35]

        w = MListNode(1.0, 2.0, 3.0)
        w .+= 0.5
        @test w isa MListNode{Float64}
        @test collect(w) == [1.5, 2.5, 3.5]
    end

    @testset "Promotion Rules" begin
        @test promote_type(MListNode{Int}, MListNode{Float64}) == MListNode{Float64}
        @test promote_type(MListNode{Int}, MListNode{Int}) == MListNode{Int}

        @test promote_type(MListEnd{Int}, MListEnd{Float64}) == MListEnd{Float64}

        @test promote_type(MListNode{Int}, StaticListNode{Float32}) == MListNode{promote_type(Int,Float32)}
        @test promote_type(MListEnd{Int}, StaticListEnd{Float32}) == MListEnd{promote_type(Int,Float32)}

        ml = MListNode(1,2,3)
        sl = StaticListNode(4,5,6)
        v_f64 = [1.0, 2.0]
        v_i32 = Int32[7,8]

        @test promote_type(typeof(ml), typeof(v_f64)) == Vector{Float64}
        @test promote_type(typeof(sl), typeof(v_i32)) == Vector{Int}

        p_ml_vf64 = promote(ml, v_f64)
        @test p_ml_vf64[1] isa Vector{Float64}
        @test p_ml_vf64[2] isa Vector{Float64}
        @test p_ml_vf64[1] == [1.0, 2.0, 3.0]
        @test p_ml_vf64[2] == [1.0, 2.0]

        p_sl_vi32 = promote(sl, v_i32)
        @test p_sl_vi32[1] isa Vector{Int}
        @test p_sl_vi32[2] isa Vector{Int}
        @test p_sl_vi32[1] == [4,5,6]
        @test p_sl_vi32[2] == [7,8]
    end

    @testset "Error Handling" begin
        l_empty = MListEnd{Int}()
        l_single = MListNode(1)
        l_double = MListNode(1,2)

        @test_throws BoundsError l_empty[1]
        @test_throws BoundsError l_single[0]
        @test_throws BoundsError l_single[2]
        @test_throws BoundsError l_double[-1]
        @test_throws BoundsError l_double[3]

        @test_throws BoundsError l_empty[1] = 10
        @test_throws BoundsError l_single[0] = 10
        @test_throws BoundsError l_single[2] = 10
        l_s_mut = MListNode(1)
        l_s_mut[1]=5
        @test l_s_mut[1] == 5

        @test_throws BoundsError popnext!(l_single)
        @test_throws MethodError popnext!(l_empty)
        
        l_dest_map! = MListNode(1,2,3)
        l_src_map!  = MListNode(10,20,30)
        @test_throws UndefVarError map!(+, l_dest_map!, l_src_map!)

        dest_list_int = MListNode(1,2,3)
        @test_throws TypeError (dest_list_int .= dest_list_int .+ 0.5)
    end

    @testset "MListNode from StaticListNode" begin
        sl1 = StaticListNode(10, StaticListNode(20, StaticListEnd{Int}()))
        ml1 = MListNode(sl1)
        @test ml1 isa MListNode{Int}
        @test collect(ml1) == [10, 20]

        sl_single = StaticListNode(100)
        ml_single = MListNode(sl_single)
        @test ml_single isa MListNode{Int}
        @test collect(ml_single) == [100]

        sl_float = StaticListNode(1.0f0, StaticListNode(2.0f0, StaticListEnd{Float32}()))
        ml_float = MListNode(sl_float)
        @test ml_float isa MListNode{Float32}
        @test collect(ml_float) == [1.0f0, 2.0f0]
    end
end
