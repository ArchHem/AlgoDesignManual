"""
    KDTreeMatrix{T}

A semi-static, heap-array-like KD-tree storing D-dimensional points in a flat `Matrix{T}` structure.

# Fields
- `storage::Matrix{T}`: The D×M matrix storing points in a binary heap layout.
- `sentinel::BitVector`: Boolean mask marking which heap slots are used (true = occupied).
- 'unused::BitVector': Is the node no longer reachable?
"""
struct KDTreeMatrix{T}
    storage::Matrix{T}
    sentinel::BitVector
    unused::BitVector
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
    if left > right
        return 
    elseif left == right
        heap_storage[:, index] .= @views x[:, left]
        sentinel[index] = true
        return
    end
    currdim = mod(depth, D) + 1

    median_index = div(left + right,2)
    quickselect!(x, median_index, [currdim,:], left, right)
    sentinel[index] = true
    heap_storage[:, index] .= @views x[:, median_index]

    KDTree!_(x, heap_storage, sentinel,  depth + 1, 2*index, left, median_index-1)
    KDTree!_(x, heap_storage, sentinel,  depth + 1, 2*index+1, median_index+1, right)
    

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
    return KDTreeMatrix{T}(storage,sentinel,.!sentinel)

end

"""
    nn_search(tree::KDTreeMatrix{T}, query::AbstractVector{T}) -> (best_index, best_distance)

Performs a nearest-neighbor search in the KDTree for the query point.

Returns the index and the point closest to the query point.

This is a recursive search that respects the heap layout (2i and 2i+1 children).
"""
function nn_search(tree::KDTreeMatrix{T}, query::Vector{T}) where T

    function recursor(query, index, depth, best_dist = typemax(T), best_index = -1)
        if  index > length(tree.sentinel) || tree.unused[index]
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
Lzaily deletes an elemement from a KDTreeMatrix
- 'x': Tree to lazily delete element from
- 'index': Index of the element in the underlying heap-like storage to delete
"""
function lazydelete!(x::KDTreeMatrix, index::Int)
    x.sentinel[index] = false
    L = length(x.sentinel)
    #propegate soft deletion upward
    while index > 0
        if !x.sentinel[index]
            left = 2 * index
            right = 2 * index + 1
            left_unused = left > L || x.unused[left]
            right_unused = right > L || x.unused[right]

            if left_unused && right_unused
                x.unused[index] = true
            else
                break
            end
        else
            break
        end
        index = div(index, 2)
    end
    return 
end

"""
    rebuild(x::KDTreeMatrix)
    Rebuild a KDTree, discarding all invalideted nodes
-'x': Current tree instance to rebuild from
"""

function rebuild(x::KDTreeMatrix)
    #maybe use views here?
    valid_storage = x.storage[:, x.sentinel]
    newtree = KDTreeMatrix(valid_storage)
    return newtree
end

mutable struct NodeKDTRee{T}
    point::Vector{T}
    dimension::Int64
    parent::Union{NodeKDTRee{T},Nothing}
    left::Union{NodeKDTRee{T},Nothing}
    right::Union{NodeKDTRee{T},Nothing}
end

function NodeKDTRee(x::Matrix{T},level = 0, parent = nothing, left = 1, right = size(x,2)) where T
    if left > right
        return nothing
    end
    
    dim = mod(level, size(x,1)) + 1
    median_index = div(left + right,2)
    quickselect!(x, median_index, [dim,:], left, right)
    node = NodeKDTRee{T}(x[:, median_index], dim, parent, nothing, nothing)
    node.left = NodeKDTRee(x, level + 1, node, left, median_index - 1)
    node.right = NodeKDTRee(x, level + 1, node, median_index + 1, right)
    return node
end

Base.show(io::IO, x::NodeKDTRee) = begin
    println(io, "NodeKDTree:")
    println(io, "  Parent: ", x.parent === nothing ? "Nothing" : x.parent.point)
    println(io, "  Dimension: ", x.dimension)
    println(io, "  Point: ", x.point)
    println(io, "  Left: ", x.left === nothing ? "Nothing" : x.left.point)
    println(io, "  Right: ", x.right === nothing ? "Nothing" : x.right.point)
end

function nn_search(tree, query::Vector{T}, 
        depth = 0, best_dist = typemax(T), best_node = nothing) where T
    
    if isnothing(tree)
        return best_dist, best_node
    end

    actdist = sum(@. (tree.point - query)^2)
    dim = mod(depth, length(tree.point)) + 1
    diff = query[dim] - tree.point[dim]

    if actdist < best_dist
        best_dist = actdist
        best_node = tree
    end

    split = diff < zero(T)
    nearnode = split ? tree.left : tree.right
    farnode = split ? tree.right : tree.left
    best_dist, best_node = nn_search(nearnode, query, 
        depth + 1, best_dist, best_node)
    if diff^2 < best_dist
        best_dist, best_node = nn_search(farnode, query, 
            depth + 1, best_dist, best_node)
    end

    return best_dist, best_node

end

#find the minimum valued node along a given subtree
function find_min(tree::NodeKDTRee{T}, dim::Int = tree.dimension) where T
    if isnothing(tree)
        return nothing
    end

    if tree.dimension == dim
        #if leaf has no left children it must be minimum in that subtree...
        return isnothing(tree.left) ? tree : find_min(tree.left, dim)
    else
        left_min = find_min(tree.left, dim)
        right_min = find_min(tree.right, dim)
        min_node = tree
        for candidate in (left_min, right_min)
            if candidate !== nothing && candidate.point[dim] < min_node.point[dim]
                min_node = candidate
            end
        end
        return min_node
    end
end

function deleteat!(node::NodeKDTRee{T}) where T
    if isnothing(node)
        return nothing
    end

    if !isnothing(node.right)
        min_node = find_min(node.right, node.dimension)
        node.point = min_node.point
        deleteat!(min_node)

    elseif !isnothing(node.left)
        min_node = find_min(node.left, node.dimension)
        node.point = min_node.point

        deleteat!(min_node)
        node.right = node.left
        node.left = nothing
    else
        if node.parent !== nothing

            if node.parent.left === node
                node.parent.left = nothing
            elseif node.parent.right === node
                node.parent.right = nothing
            end
        end
        
    end
    return nothing
end