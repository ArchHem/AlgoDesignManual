#array based heap

#maxheap
struct BasicHeap{T}
    storage::Vector{T}
end

function BasicHeap(x::Vector{T}) where T
    y = copy(x)
    storage = build_max_heap!(y)
    return BasicHeap{T}(storage)
end

function build_max_heap!(y)
    L = length(y)

    #find first non-leaf node
    non_leaf_length = div(L, 2)
    for i in non_leaf_length:-1:1
        _shift_down!(y, L, i)
    end
    return y
end

#build the API

#We want; 
#push!
#pop!
#internal ops?

Base.length(x::BasicHeap) = length(x.storage)
Base.isempty(x::BasicHeap) = isempty(x.storage)

#bubble-down: restore local heap property "downward"
#Maybe there is way to get TCO out of way?
#restore local propety, and repair affected subtree.
function _shift_down!(x::Vector{T}, L, i) where T
    left_index = 2 * i
    right_index = 2 * i + 1
    maxindex = i
    if left_index <= L && x[left_index] > x[maxindex]
        maxindex = left_index
    end

    if right_index <= L && x[right_index] > x[maxindex]
        maxindex = right_index
    end
    if maxindex != i
        x[i], x[maxindex] = x[maxindex], x[i]
        _shift_down!(x, L, maxindex)
    end
    return nothing
end

function _shift_up!(x::Vector{T}, i) where T
    while i > 1 # Move up towards the root
        parent_index = div(i, 2)
        if x[i] > x[parent_index]
            x[i], x[parent_index] = x[parent_index], x[i]
            i = parent_index
        else
            break
        end
    end
    return nothing
end

#now we can add pop and push easily....
#We let base.push! heuretics handle this. Normally we would just use the dynamic array heuretics instead.
function Base.push!(heap::BasicHeap{T}, item::T) where T
    push!(heap.storage, item)
    _shift_up!(heap.storage, length(heap.storage))
    return heap
end

function Base.pop!(heap::BasicHeap{T})::T where T
    
    max_val = heap.storage[1]
    if length(heap) == 1
        empty!(heap.storage)
    else
        #swap with lowest element, and propegate it wodn.
        heap.storage[1] = pop!(heap.storage)
        _shift_down!(heap.storage, length(heap.storage), 1)
    end
    return max_val
end

function heapsort!(x::Vector{T}) where T
    build_max_heap!(x)
    N = length(x)

    result = Vector{T}(undef, N)
    heap = BasicHeap(x)

    for i in reverse(1:N)
        x[i] = pop!(heap)
    end
    return result
end

function heapsort(x::Vector{T}) where T
    
    y = deepcopy(x)
    heapsort!(y)
    return y
end