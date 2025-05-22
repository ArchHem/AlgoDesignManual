using Test
include("../src/ConstArrays.jl")
using .ConstArrays

@testset "ConstVector Tests" begin
    cv1 = ConstVector((1, 2, 3))
    @test typeof(cv1) == ConstVector{Int,3}
    @test cv1.data == (1, 2, 3)

    cv_float = ConstVector((1.0, 2.5))
    @test typeof(cv_float) == ConstVector{Float64,2}
    @test cv_float.data == (1.0, 2.5)

    @test length(cv1) == 3
    @test eltype(cv1) == Int
    @test ndims(cv1) == 1
    @test size(cv1) == (3,)

    @test length(cv_float) == 2
    @test eltype(cv_float) == Float64
    @test ndims(cv_float) == 1
    @test size(cv_float) == (2,)

    cv_copy = copy(cv1)
    @test cv_copy == cv1

    cv_collect = collect(cv1)
    @test cv_collect == [1, 2, 3]
    @test typeof(cv_collect) == Vector{Int}

    cv_vector = Vector(cv1)
    @test cv_vector == [1, 2, 3]
    @test typeof(cv_vector) == Vector{Int}

    @test promote_rule(ConstVector{Int,3}, Vector{Float64}) == Vector{Float64}
    @test promote_rule(ConstVector{Int,3}, Vector{Int}) == Vector{Int}

    cv_reversed = reverse(cv1)
    @test cv_reversed.data == (3, 2, 1)
    @test typeof(cv_reversed) == ConstVector{Int,3}

    @test sprint(show, cv1) == "ConstVector{Int64,3}((1, 2, 3))"

    cv_same = ConstVector((1, 2, 3))
    cv_diff = ConstVector((4, 5, 6))
    @test cv1 == cv_same
    @test !(cv1 == cv_diff)

    iter_result = []
    for x in cv1
        push!(iter_result, x)
    end
    @test iter_result == [1, 2, 3]

    @test cv1[1] == 1
    @test cv1[3] == 3
    @test_throws BoundsError cv1[0]
    @test_throws BoundsError cv1[4]

    cv_slice = cv1[1:2]
    @test cv_slice == ConstVector((1, 2))
    @test typeof(cv_slice) == ConstVector{Int,2}

    cv_a = ConstVector((1, 2, 3))
    cv_b = ConstVector((4, 5, 6))

    cv_sum = cv_a + cv_b
    @test cv_sum.data == (5, 7, 9)
    @test typeof(cv_sum) == ConstVector{Int,3}

    cv_diff_op = cv_a - cv_b
    @test cv_diff_op.data == (-3, -3, -3)
    @test typeof(cv_diff_op) == ConstVector{Int,3}

    cv_c = ConstVector((1.0, 2.0, 3.0))
    cv_d = ConstVector((4.0, 5.0, 6.0))

    cv_scaled = cv_c .* 2
    @test cv_scaled.data == (2.0, 4.0, 6.0)
    @test typeof(cv_scaled) == ConstVector{Float64,3}

    cv_broadcast_sum = cv_c .+ cv_d
    @test cv_broadcast_sum.data == (5.0, 7.0, 9.0)
    @test typeof(cv_broadcast_sum) == ConstVector{Float64,3}

    cv_power = cv_c .^ 2
    @test cv_power.data == (1.0, 4.0, 9.0)
    @test typeof(cv_power) == ConstVector{Float64,3}

    cv_mixed_add = cv1 .+ ConstVector((4.0, 5.0, 6.0))
    @test cv_mixed_add.data == (5.0, 7.0, 9.0)
    @test typeof(cv_mixed_add) == ConstVector{Float64,3}

    vec_result = cv1 .+ [4, 5, 6]
    @test vec_result == [5, 7, 9]
    @test typeof(vec_result) == Vector{Int}

    vec_result_float = cv_c .+ [4, 5, 6]
    @test vec_result_float == [5.0, 7.0, 9.0]
    @test typeof(vec_result_float) == Vector{Float64}
end
