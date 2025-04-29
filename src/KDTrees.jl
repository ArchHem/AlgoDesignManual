struct KDTree{T}
    storage::Matrix{T}
    split_dims::Vector{Int}
    left_child::Vector{Int}
    right_child::Vector{Int}
end

size(x::KDTree{T}) where T = size(x.storage)

function KDTree!_(x::Matrix{T}, level::Int64 = 0, dim_split, left_children, right_children) where T
    N, D = size(x)

    if N <= 1 #recursion stop
        return 
    end

    curdim = mod(level, D) + 1 #account for 1 based indexing

    #execute quickselection

    midindex = div(N, 2) + 1 
    quickselect!(x, midindex, [:, curdim]) #continious along comparassion elements
    dim_split[midindex] = curdim

    







end


function KDTree(x::Matrix{T}) where T
    #constructor
    Num_elements, dimensions = size(x)
    storage_length = 2^(ceil(Int64,log2(Num_elements)))
    data = fill(NaN, storage_length, dimensions)


    
end
