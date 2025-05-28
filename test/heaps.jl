using Test
include("../src/BasicSorts.jl")
using .BasicSorts, Random

@testset "BasicHeap API Tests" begin

    @testset "Constructor and build_max_heap!" begin
        heap = BasicHeap(Int[])
        @test isempty(heap)
        @test length(heap) == 0

        arr_sorted = [1, 2, 3, 4, 5]
        heap_sorted = BasicHeap(arr_sorted)
        @test length(heap_sorted) == 5
        @test heap_sorted.storage[1] == 5

        arr_shuffled = [3, 1, 4, 1, 5, 9, 2, 6]
        heap_shuffled = BasicHeap(arr_shuffled)
        @test length(heap_shuffled) == 8
        @test heap_shuffled.storage[1] == 9
        @test heap_shuffled.storage[1] >= heap_shuffled.storage[2]
        @test heap_shuffled.storage[1] >= heap_shuffled.storage[3]
        @test heap_shuffled.storage[2] >= heap_shuffled.storage[4]
        @test heap_shuffled.storage[2] >= heap_shuffled.storage[5]
    end

    @testset "push!" begin
        heap = BasicHeap(Int[])
        push!(heap, 10)
        @test length(heap) == 1
        @test heap.storage[1] == 10

        push!(heap, 5)
        @test length(heap) == 2
        @test heap.storage[1] == 10

        push!(heap, 15)
        @test length(heap) == 3
        @test heap.storage[1] == 15
        @test heap.storage == [15, 5, 10] || heap.storage == [15, 10, 5]

        heap_multi_push = BasicHeap(Int[])
        for i in [1, 5, 2, 8, 3, 7, 4, 6]
            push!(heap_multi_push, i)
        end
        @test length(heap_multi_push) == 8
        @test heap_multi_push.storage[1] == 8
        @test heap_multi_push.storage[1] >= heap_multi_push.storage[2]
        @test heap_multi_push.storage[1] >= heap_multi_push.storage[3]
        @test heap_multi_push.storage[2] >= heap_multi_push.storage[4]
        @test heap_multi_push.storage[2] >= heap_multi_push.storage[5]
    end

    @testset "pop!" begin
        heap_empty_pop = BasicHeap(Int[])
        @test_throws BoundsError pop!(heap_empty_pop)

        heap_single = BasicHeap([42])
        @test pop!(heap_single) == 42
        @test isempty(heap_single)
        @test length(heap_single) == 0

        arr = [3, 1, 4, 1, 5, 9, 2, 6]
        heap = BasicHeap(arr)
        
        @test pop!(heap) == 9
        @test length(heap) == 7
        @test heap.storage[1] == 6

        @test pop!(heap) == 6
        @test length(heap) == 6
        @test heap.storage[1] == 5

        popped_elements = Int[]
        while !isempty(heap)
            push!(popped_elements, pop!(heap))
        end
        @test popped_elements == [5, 4, 3, 2, 1, 1]
        @test isempty(heap)
    end

    @testset "heapsort and heapsort!" begin
        arr1 = [3, 1, 4, 1, 5, 9, 2, 6]
        heapsort!(arr1)
        @test arr1 == [1, 1, 2, 3, 4, 5, 6, 9]

        arr2 = [5, 4, 3, 2, 1]
        heapsort!(arr2)
        @test arr2 == [1, 2, 3, 4, 5]

        arr3 = [1, 2, 3, 4, 5]
        heapsort!(arr3)
        @test arr3 == [1, 2, 3, 4, 5]

        arr_empty = Int[]
        heapsort!(arr_empty)
        @test arr_empty == Int[]

        arr_single = [7]
        heapsort!(arr_single)
        @test arr_single == [7]

        original_arr = [3, 1, 4, 1, 5, 9, 2, 6]
        sorted_arr = heapsort(original_arr)
        @test sorted_arr == [1, 1, 2, 3, 4, 5, 6, 9]
        @test original_arr == [3, 1, 4, 1, 5, 9, 2, 6]

        original_arr_empty = Int[]
        sorted_arr_empty = heapsort(original_arr_empty)
        @test sorted_arr_empty == Int[]
        @test original_arr_empty == Int[]

        original_arr_single = [100]
        sorted_arr_single = heapsort(original_arr_single)
        @test sorted_arr_single == [100]
        @test original_arr_single == [100]
    end

    @testset "Edge Cases and Type Flexibility" begin
        neg_arr = [-5, -1, -8, -3]
        heap_neg = BasicHeap(neg_arr)
        @test heap_neg.storage[1] == -1
        @test pop!(heap_neg) == -1
        @test pop!(heap_neg) == -3

        float_arr = [3.14, 1.618, 2.718, 0.5]
        heap_float = BasicHeap(float_arr)
        @test heap_float.storage[1] == 3.14
        @test pop!(heap_float) == 3.14
        push!(heap_float, 4.0)
        @test pop!(heap_float) == 4.0

        struct MyStruct
            val::Int
        end
        Base.:>(a::MyStruct, b::MyStruct) = a.val > b.val

        custom_arr = [MyStruct(5), MyStruct(2), MyStruct(8), MyStruct(1)]
        heap_custom = BasicHeap(custom_arr)
        @test heap_custom.storage[1].val == 8
        @test pop!(heap_custom).val == 8
        @test pop!(heap_custom).val == 5
    end
end