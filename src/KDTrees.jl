struct KDTree{T}
    storage::Matrix{T}
    split_dims::Vector{Int}
    left_child::Vector{Int}
    right_child::Vector{Int}
end

size(x::KDTree{T}) where T = size(x.storage)

function KDTree_(x::Matrix{T}, level::Int64, dim_split, left_children, right_children) where T
    Num_elements, dimensions = size(x)
    if N == 1
        return 1
    end
    currdim = mod(level, dimensions)
    currview = @views x[:, currdim]
    currmed = lower_median(currview)


    

    #split into those that are 



end


function KDTree(x::Matrix{T}) where T
    #constructor
    Num_elements, dimensions = size(x)
    storage_length = 2^(ceil(Int64,log2(Num_elements)))
    data = fill(NaN, storage_length, dimensions)


    
end
