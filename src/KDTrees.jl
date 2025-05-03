"""
    KDTreeMatrix{T}

A semi-static, heap-array-like KD-tree storing D-dimensional points in a flat `Matrix{T}` structure.

# Fields
- `storage::Matrix{T}`: The D×M matrix storing points in a binary heap layout.
- `numelems::Int64`: The number of points stored (equal to number of columns in input).
- `sentinel::BitVector`: Boolean mask marking which heap slots are used (true = occupied).
"""
struct KDTreeMatrix{T}
    storage::Matrix{T}
    numelems::Int64
    sentinel::BitVector
end

"""
    KDTree!_(x, heap_storage, sentinel, depth=0, index=1, left=1, right=size(x,2))

Recursive internal function to build a heap-like KDTree in-place.

- `x`: input matrix (D×N), where each column is a point.
- `heap_storage`: pre-allocated D×M matrix where the tree will be stored.
- `sentinel`: a BitVector marking which heap indices are populated.
- `depth`: current depth of the tree (affects split dimension).
- `index`: current index in the heap layout (starts at 1).
- `left`, `right`: current slice bounds for processing a sub-array of points.

This partitions the space and places medians in heap order.
"""
function KDTree!_(x::Matrix, heap_storage::Matrix, sentinel, depth = 0, index = 1, left = 1, right = size(x,2))

    D, N = size(x)
    if left == right
        heap_storage[:, index] .= @views x[:, left]
        sentinel[index] = true
        return
    end
    currdim = mod(depth, D) + 1

    median_index = div(left + right,2)
    quickselect!(x, median_index, [currdim,:], left, right)
    sentinel[index] = true
    heap_storage[:, index] .= @views x[:, median_index]

    KDTree!_(x, heap_storage, sentinel, depth + 1, 2*index, left, median_index)
    KDTree!_(x, heap_storage, sentinel, depth + 1, 2*index+1, median_index+1, right)
    

end

"""
    KDTreeMatrix(x::Matrix{T}) where T

Builds a heap-structured KDTree from a D×N matrix `x`, where each column is a D-dimensional point.

The resulting tree is stored in an array-based binary heap using `2i`/`2i+1` child layout. Internal allocation is rounded up to the nearest power-of-two size.

Returns a `KDTreeMatrix{T}`.
"""
function KDTreeMatrix(x::Matrix{T}) where T
    D, N = size(x)
    buffer = 1
    while buffer < N
        buffer *= 2
    end
    buffer *= 2
    storage = Matrix{T}(undef,D, buffer)
    sentinel = falses(buffer)
    KDTree!_(x,storage,sentinel)
    return KDTreeMatrix{T}(storage,N,sentinel)


end