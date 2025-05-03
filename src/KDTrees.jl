struct KDTreeMatrix{T}
    storage::Matrix{T}
    numelems::Int64
    sentinel::BitVector
end

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