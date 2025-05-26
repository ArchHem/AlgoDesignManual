include("../src/SearchTrees.jl")
using .SearchTrees
using Test


@testset "StaticBST Functionality" begin

    @testset "Constructor and Properties" begin
        keys_a = ["apple", "banana", "cherry"]
        values_a = [10, 20, 30]
        bst_a = StaticBST(keys_a, values_a)

        @test length(bst_a) == 3
        @test !isempty(bst_a)
        @test keytype(bst_a) == String
        @test valtype(bst_a) == Int

        keys_b_unsorted = ["zebra", "apple", "fig", "grape"]
        values_b_unsorted = [300, 100, 200, 150]
        bst_b = StaticBST(keys_b_unsorted, values_b_unsorted)

        @test length(bst_b) == 4
        @test collect(keys(bst_b)) == ["apple", "fig", "grape", "zebra"]
        @test collect(values(bst_b)) == [100, 200, 150, 300]

        @test_throws ArgumentError StaticBST(["a", "b", "a"], [1, 2, 3])
        @test_throws ArgumentError StaticBST([1, 2, 1], ["x", "y", "z"])

        @test_throws DimensionMismatch StaticBST(["a", "b"], [1])
        @test_throws DimensionMismatch StaticBST([1], ["x", "y"])

        empty_bst = StaticBST(String[], Int[])
        @test length(empty_bst) == 0
        @test isempty(empty_bst)
        @test keytype(empty_bst) == String
        @test valtype(empty_bst) == Int
    end

    @testset "Key and Value Access" begin
        keys_c = ["cat", "dog", "elephant", "fish"]
        values_c = [1, 2, 3, 4]
        bst_c = StaticBST(keys_c, values_c)

        @test haskey(bst_c, "cat")
        @test haskey(bst_c, "dog")
        @test haskey(bst_c, "fish")
        @test !haskey(bst_c, "bird")
        @test !haskey(bst_c, "zebra")

        @test bst_c["cat"] == 1
        @test bst_c["elephant"] == 3
        @test bst_c["fish"] == 4
        @test_throws KeyError bst_c["bird"]
        @test_throws KeyError bst_c["mouse"]

        empty_bst = StaticBST(Int[], String[])
        @test !haskey(empty_bst, 5)
        @test_throws KeyError empty_bst[5]
    end

    @testset "Value Mutation (setindex!)" begin
        keys_d = ["alpha", "beta", "gamma"]
        values_d = [100, 200, 300]
        bst_d = StaticBST(keys_d, values_d)

        bst_d["beta"] = 250
        @test bst_d["beta"] == 250
        @test bst_d["alpha"] == 100

        bst_d["gamma"] = 350
        @test bst_d["gamma"] == 350

        @test_throws KeyError bst_d["delta"] = 400
        @test !haskey(bst_d, "delta")
    end

    @testset "Iteration" begin
        keys_e = ["one", "two", "three"]
        values_e = [1, 2, 3]
        bst_e = StaticBST(keys_e, values_e)

        @test minkey(bst_e) == "one"
        @test maxkey(bst_e) == "two"

        expected_pairs_e = ["one" => 1, "three" => 3, "two" => 2]
        expected_pairs_e_sorted = sort(expected_pairs_e, by=p->p.first)
        @test collect(bst_e) == expected_pairs_e_sorted

        collected_pairs = Pair{String, Int}[]
        for (k, v) in bst_e
            push!(collected_pairs, k => v)
        end
        @test collected_pairs == expected_pairs_e_sorted

        empty_bst = StaticBST(String[], Float64[])
        @test collect(empty_bst) == []
        @test_nowarn for (k,v) in empty_bst end
    end
end