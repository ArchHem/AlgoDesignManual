include("../src/SearchTrees.jl")
using .SearchTrees
using Test
using Random


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
#AVL tests
@testset "AVLHead Public API Tests" begin

    @testset "Empty Tree Constructor and isempty" begin
        tree = AVLHead{Int, Int}()
        @test isempty(tree)
        @test length(tree) == 0
        @test keytype(tree) == Int
        @test valtype(tree) == Int
        @test height(tree) == 0
        @test_throws KeyError tree[1]
        @test !haskey(tree, 1)
        @test collect(keys(tree)) == []
        @test collect(values(tree)) == []
    end

    @testset "Insertion, Get, HasKey, Length" begin
        tree = AVLHead{Int, Int}()

        @test (tree[10] = 100) == 100
        @test !isempty(tree)
        @test length(tree) == 1
        @test tree.ref isa AVLNode{Int, Int}
        @test key(tree.ref) == 10
        @test value(tree.ref) == 100
        @test haskey(tree, 10)
        @test !haskey(tree, 5)
        @test tree[10] == 100
        @test height(tree) == 1

        @test (tree[5] = 50) == 50
        @test length(tree) == 2
        @test key(tree.ref) == 10
        @test key(tree.ref.left) == 5
        @test haskey(tree, 5)
        @test tree[5] == 50
        @test height(tree) == 2

        @test (tree[15] = 150) == 150
        @test length(tree) == 3
        @test key(tree.ref) == 10
        @test key(tree.ref.left) == 5
        @test key(tree.ref.right) == 15
        @test haskey(tree, 15)
        @test tree[15] == 150
        @test height(tree) == 2

        @test (tree[10] = 101) == 101
        @test length(tree) == 3
        @test tree[10] == 101
        @test height(tree) == 2
    end

    @testset "Iteration (keys, values, pairs)" begin
        tree = AVLHead{Int, Int}()
        elements = [10 => 100, 5 => 50, 15 => 150, 2 => 20, 7 => 70, 12 => 120, 17 => 170]
        for (k, v) in elements
            tree[k] = v
        end
        @test length(tree) == length(elements)

        expected_keys = [2, 5, 7, 10, 12, 15, 17]
        expected_values = [20, 50, 70, 100, 120, 150, 170]
        expected_pairs = [2 => 20, 5 => 50, 7 => 70, 10 => 100, 12 => 120, 15 => 150, 17 => 170]

        @test collect(keys(tree)) == expected_keys
        @test collect(values(tree)) == expected_values
        @test collect(tree) == expected_pairs
    end

    @testset "AVL Balancing via setindex!" begin
        tree = AVLHead{Int, Int}()

        tree[10] = 100
        tree[20] = 200
        tree[30] = 300
        @test key(tree.ref) == 20
        @test key(tree.ref.left) == 10
        @test key(tree.ref.right) == 30
        @test height(tree) == 2
        @test loadbalance(tree.ref) == 0
        @test length(tree) == 3

        tree = AVLHead{Int, Int}()
        tree[30] = 300
        tree[20] = 200
        tree[10] = 100
        @test key(tree.ref) == 20
        @test key(tree.ref.left) == 10
        @test key(tree.ref.right) == 30
        @test height(tree) == 2
        @test loadbalance(tree.ref) == 0
        @test length(tree) == 3

        tree = AVLHead{Int, Int}()
        tree[10] = 100
        tree[30] = 300
        tree[20] = 200
        @test key(tree.ref) == 20
        @test key(tree.ref.left) == 10
        @test key(tree.ref.right) == 30
        @test height(tree) == 2
        @test loadbalance(tree.ref) == 0
        @test length(tree) == 3

        tree = AVLHead{Int, Int}()
        tree[30] = 300
        tree[10] = 100
        tree[20] = 200
        @test key(tree.ref) == 20
        @test key(tree.ref.left) == 10
        @test key(tree.ref.right) == 30
        @test height(tree) == 2
        @test loadbalance(tree.ref) == 0
        @test length(tree) == 3
    end

    @testset "minkey and maxkey" begin
        tree = AVLHead{Int, Int}()
        elements = [10, 5, 15, 2, 7, 12, 17]
        for k in elements
            tree[k] = k * 10
        end

        @test minkey(tree.ref) == 2
        @test maxkey(tree.ref) == 17

        @test minkey(tree.ref.right) == 12
        @test maxkey(tree.ref.left) == 7
    end

    @testset "Deletion" begin
        tree = AVLHead{Int, Int}()
        elements = [10 => 100, 5 => 50, 15 => 150, 2 => 20, 7 => 70, 12 => 120, 17 => 170, 1 => 10, 8 => 80]
        for (k, v) in elements
            tree[k] = v
        end
        initial_len = length(elements)
        @test length(tree) == initial_len

        @test delete!(tree, 1) === tree
        @test !haskey(tree, 1)
        @test length(tree) == initial_len - 1
        @test collect(keys(tree)) == [2, 5, 7, 8, 10, 12, 15, 17]

        @test delete!(tree, 2) === tree
        @test !haskey(tree, 2)
        @test length(tree) == initial_len - 2
        @test collect(keys(tree)) == [5, 7, 8, 10, 12, 15, 17]

        @test delete!(tree, 10) === tree
        @test !haskey(tree, 10)
        @test length(tree) == initial_len - 3
        @test collect(keys(tree)) == [5, 7, 8, 12, 15, 17]
        @test key(tree.ref) == 12

        @test_throws KeyError delete!(tree, 99)
        @test length(tree) == initial_len - 3

        for k in [5, 7, 8, 12, 15, 17]
            delete!(tree, k)
        end
        @test isempty(tree)
        @test length(tree) == 0
        @test collect(keys(tree)) == []
    end

    @testset "empty!" begin
        tree = AVLHead{Int, Int}()
        tree[1] = 10
        tree[2] = 20
        @test !isempty(tree)
        @test length(tree) == 2

        empty!(tree)
        @test isempty(tree)
        @test length(tree) == 0
        @test isleaf(tree.ref)
        @test_throws KeyError tree[1]
    end

    @testset "Constructors with initial elements" begin
        pairs_to_insert = [4 => 40, 2 => 20, 6 => 60, 1 => 10, 3 => 30, 5 => 50, 7 => 70]

        tree_from_pairs = AVLHead{Int, Int}(pairs_to_insert)
        @test length(tree_from_pairs) == 7
        @test collect(keys(tree_from_pairs)) == [1, 2, 3, 4, 5, 6, 7]

        tree_copy = AVLHead{Int, Int}(tree_from_pairs)
        @test length(tree_copy) == 7
        @test collect(keys(tree_copy)) == [1, 2, 3, 4, 5, 6, 7]
        @test tree_copy[4] == 40

        tree_untyped = AVLHead(pairs_to_insert)
        @test keytype(tree_untyped) == Int
        @test valtype(tree_untyped) == Int
        @test length(tree_untyped) == 7
        @test collect(keys(tree_untyped)) == [1, 2, 3, 4, 5, 6, 7]
    end

    @testset "Random Inserts and Deletes" begin
        tree = AVLHead{Int, String}()
        num_operations = 1000
        keys_to_insert = collect(1:num_operations)
        shuffled_keys = shuffle(keys_to_insert)

        for i in 1:num_operations
            k = shuffled_keys[i]
            v = "Value_$k"
            tree[k] = v
            @test is_tree_balanced(tree.ref)
            @test length(tree) == i
        end

        shuffled_keys_to_delete = shuffle(keys_to_insert)
        for i in 1:num_operations
            k = shuffled_keys_to_delete[i]
            if haskey(tree, k)
                delete!(tree, k)
                @test is_tree_balanced(tree.ref)
                @test length(tree) == num_operations - i
            end
        end
        @test isempty(tree)
        @test is_tree_balanced(tree.ref)
    end

    @testset "Sequential Inserts and Deletes" begin
        tree = AVLHead{Int, String}()
        num_elements = 500

        for i in 1:num_elements
            tree[i] = "Value_$i"
            @test is_tree_balanced(tree.ref)
            @test length(tree) == i
        end

        for i in 1:num_elements
            delete!(tree, i)
            @test is_tree_balanced(tree.ref)
            @test length(tree) == num_elements - i
        end
        @test isempty(tree)
        @test is_tree_balanced(tree.ref)

        tree = AVLHead{Int, String}()
        for i in 1:num_elements
            tree[i] = "Value_$i"
            @test is_tree_balanced(tree.ref)
        end

        for i in num_elements:-1:1
            delete!(tree, i)
            @test is_tree_balanced(tree.ref)
            @test length(tree) == i - 1
        end
        @test isempty(tree)
        @test is_tree_balanced(tree.ref)
    end

    @testset "Mixed Inserts and Deletes" begin
        tree = AVLHead{Int, String}()
        initial_inserts = 200
        for i in 1:initial_inserts
            tree[i] = "Value_$i"
        end
        @test is_tree_balanced(tree.ref)
        @test length(tree) == initial_inserts

        num_mixed_ops = 500
        for _ in 1:num_mixed_ops
            op_type = rand(Bool)
            if op_type && length(tree) < 500
                key_to_op = rand(1:1000)
                tree[key_to_op] = "Value_$key_to_op"
            else
                if !isempty(tree)
                    k_to_delete = first(rand(keys(tree)))
                    delete!(tree, k_to_delete)
                end
            end
            @test is_tree_balanced(tree.ref)
        end
    end


end