#array based heap

#maxheap
struct BasicHeap{T}
    storage::Vector{T}
end

function BasicHeap(x::Vector{T})
    storage = build_max_heap(x)
    return BasicHeap{T}(storage)
end

#O(n) heapin func for max heas
function _heapify!(x, L, i)
    #L is true length of heap
    leftindex = 2*i
    rightindex = 2*i + 1

    #replace node with max-child
    maxindex = i
    if leftindex <= L && x[leftindex] > x[maxindex]
        maxindex = leftindex
    end

    if rightindex <= L && x[rightindex] > x[maxindex]
        maxindex = rightindex
    end

    if maxindex != i
        x[i], x[maxindex] = x[maxindex], x[i]
        #repair  subtree
        _heapify!(x, L, maxindex)
    end
    return nothing
end

function build_max_heap(x)
    y = copy(x)
    L = length(y)

    #find first non-leaf node
    non_leaf_length = div(L, 2)

    #get back to prevous level...
    non_leaf_length = currl - div(width, 2)
    for i in non_leaf_length:-1:1
        _heapify!(y, L, i)
    end
    return y
end