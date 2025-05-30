using Test
include("../src/BasicHash.jl")
using .BasicHash

@testset "HashNode Tests" begin
    node = HashNode{String, Int}()
    @test node.key === nothing
    @test node.value === nothing
    @test node.state == Int8(2)

    node_used = HashNode("key1", 100, Int8(1))
    @test node_used.key == "key1"
    @test node_used.value == 100
    @test node_used.state == Int8(1)

    node_deleted = HashNode{Symbol, Float64}(nothing, nothing, Int8(3))
    @test node_deleted.key === nothing
    @test node_deleted.value === nothing
    @test node_deleted.state == Int8(3)
end

@testset "HashMap Basic Functionality Tests" begin
    hm = HashMap{String, Int}(10)
    @test length(hm.storage) == 10
    @test hm.used_count == 0
    @test isempty(hm)

    hm["apple"] = 1
    @test hm.used_count == 1
    @test !isempty(hm)
    @test hm["apple"] == 1

    hm["banana"] = 2
    @test hm.used_count == 2
    @test hm["banana"] == 2

    hm["apple"] = 10
    @test hm.used_count == 2
    @test hm["apple"] == 10

    @test hm["banana"] == 2
    @test_throws KeyError hm["grape"]

    delete!(hm, "apple")
    @test hm.used_count == 1
    @test_throws KeyError hm["apple"]

    @test_throws KeyError delete!(hm, "orange")

    hm["grape"] = 3
    @test hm.used_count == 2
    @test hm["grape"] == 3
    @test hm["banana"] == 2
end

@testset "HashMap Rehashing Tests" begin
    hm = HashMap{String, Int}(4)
    @test length(hm.storage) == 4

    hm["a"] = 1
    @test hm.used_count == 1
    @test length(hm.storage) == 4

    hm["b"] = 2
    @test hm.used_count == 2
    @test length(hm.storage) == 4

    hm["c"] = 3
    @test hm.used_count == 3
    @test length(hm.storage) == 8

    @test hm["a"] == 1
    @test hm["b"] == 2
    @test hm["c"] == 3

    hm["d"] = 4
    @test hm.used_count == 4
    @test length(hm.storage) == 8

    delete!(hm, "a")
    @test hm.used_count == 3
    hm["e"] = 5
    @test hm.used_count == 4
    @test hm["e"] == 5
    @test hm["b"] == 2
    @test hm["c"] == 3
    @test hm["d"] == 4

    hm["f"] = 6
    @test hm.used_count == 5
    @test length(hm.storage) == 8

    hm["g"] = 7
    @test hm.used_count == 6
    @test length(hm.storage) == 16

    @test hm["b"] == 2
    @test hm["c"] == 3
    @test hm["d"] == 4
    @test hm["e"] == 5
    @test hm["f"] == 6
    @test hm["g"] == 7
end

@testset "HashMap Iteration and Collection Tests" begin
    hm = HashMap{String, Int}(10)
    hm["one"] = 1
    hm["two"] = 2
    hm["three"] = 3

    collected_pairs = collect(hm)
    @test length(collected_pairs) == 3
    @test Set(collected_pairs) == Set(["one" => 1, "two" => 2, "three" => 3])

    collected_keys = collect(keys(hm))
    @test length(collected_keys) == 3
    @test Set(collected_keys) == Set(["one", "two", "three"])

    collected_values = collect(values(hm))
    @test length(collected_values) == 3
    @test Set(collected_values) == Set([1, 2, 3])

    delete!(hm, "two")
    collected_pairs_after_delete = collect(hm)
    @test length(collected_pairs_after_delete) == 2
    @test Set(collected_pairs_after_delete) == Set(["one" => 1, "three" => 3])

    empty_hm = HashMap{Int, String}(5)
    @test collect(empty_hm) == []
    @test collect(keys(empty_hm)) == []
    @test collect(values(empty_hm)) == []
end

@testset "HashMap Varargs Constructor Test" begin
    hm = HashMap("a" => 1, "b" => 2, "c" => 3)
    @test hm.used_count == 3
    @test length(hm.storage) == 9
    @test hm["a"] == 1
    @test hm["b"] == 2
    @test hm["c"] == 3
end

@testset "HashMap Edge Cases and Type Stability" begin
    hm_float_bool = HashMap{Float64, Bool}(5)
    hm_float_bool[3.14] = true
    @test hm_float_bool[3.14] == true
    @test_throws KeyError hm_float_bool[2.71]

    struct MyKey
        id::Int
        name::String
    end
    Base.hash(mk::MyKey, h::UInt) = hash(mk.id, hash(mk.name, h))
    Base.:(==)(mk1::MyKey, mk2::MyKey) = mk1.id == mk2.id && mk1.name == mk2.name

    hm_custom_key = HashMap{MyKey, String}(5)
    key1 = MyKey(1, "Alpha")
    key2 = MyKey(2, "Beta")

    hm_custom_key[key1] = "Value A"
    hm_custom_key[key2] = "Value B"

    @test hm_custom_key[key1] == "Value A"
    @test hm_custom_key[MyKey(2, "Beta")] == "Value B"
    @test_throws KeyError hm_custom_key[MyKey(3, "Gamma")]

    empty_map = HashMap{Int, String}(1)
    @test isempty(empty_map)
    @test length(empty_map) == 0
    @test_throws KeyError empty_map[1]
    @test_throws KeyError delete!(empty_map, 1)
end