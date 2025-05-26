#array based heap

#maxheap
struct BasicHeap{T}
    storage::Vector{T}
end

function BasicHeap(x::Vector{T})
    currlength = length(x)
    storage = deepcopy(x)

end

#O(n) heapin func for max heas
function heapify(x, L, i)
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
        heapify(x, L, maxindex)
    end
    return x
end