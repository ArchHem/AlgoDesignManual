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

"""
    knn_search(tree::KDTreeMatrix{T}, query::AbstractVector{T}) -> (best_index, best_distance)

Performs a nearest-neighbor search in the KDTree for the query point.

Returns the index and the point closest to the query point.

This is a recursive search that respects the heap layout (2i and 2i+1 children).
"""
function nn_search(tree::KDTreeMatrix{T}, query::Vector{T}) where T

    function recursor(query,index, depth, best_dist = typemax(T), best_index = -1)
        if index > length(tree.sentinel)
            return best_dist, best_index
        end

        if tree.sentinel[index]
            point = @views tree.storage[:, index]
            actdist = sum(@. (point - query)^2)
            if actdist < best_dist
                best_dist = actdist
                best_index = index
            end
        else
            point = @views tree.storage[:, index]
        end

        dim = mod(depth, size(tree.storage, 1)) + 1
        
        diff = query[dim] - point[dim]
        near = diff < 0 ? 2 * index : 2 * index + 1
        far = diff < 0 ? 2 * index + 1 : 2 * index

        best_dist, best_index = recursor(query, near, depth + 1, best_dist, best_index)
        if diff^2 < best_dist
            best_dist, best_index = recursor(query, far, depth + 1, best_dist, best_index)
        end

        return best_dist, best_index

    end

    _, index = recursor(query,1,0,typemax(T),-1)

    return index, tree.storage[:, index]
end

"""
    lazydelete!(x::KDTreeMatrix,index)
- 'x': Tree to lazily delete element from
- 'index': Index of the element in the underlying heap-like storage to delete
"""
function lazydelete!(x::KDTreeMatrix, index::Int)
    tree.sentinel[index] = false
end

function rebuild(x::KDTreeMatrix)
end