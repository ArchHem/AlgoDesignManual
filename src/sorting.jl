using Random

@inline function swap!(X,i::Int,j::Int, dim::Int)
    tmp = copy(selectdim(X,dim,j))
    selectdim(X,dim,j) .= selectdim(X,dim,i)
    selectdim(X,dim,i) .= tmp
    return nothing
end

function hoare_partition!(X,left,right,pivotIndex,dims)
    #dims should have 1x colon
    #works up to matrices: in higher dimensions there is no 1:1 mapping
    dim = findfirst(==(:),dims)
    subvec = @views X[dims...]
    pivot = subvec[pivotIndex]
    while true
        while subvec[left] < pivot
            left = left + 1
        end
        
        while subvec[right] > pivot
            right = right - 1
        end

        if left >= right
            return right
        end
        #dont swap equals?

        swap!(X,left,right,dim)

        left = left + 1
        right = right - 1
    end
end

#use randomized method
function quicksort!(X, dims, left = 1, right = nothing)
    if isnothing(right)
        dim = findfirst(==(:),dims)
        right = length(axes(X,dim))
    end
    if left >= right || left < 1
        return X
    end
    pivotIndex = rand(left:right)
    
    partitionIndex = hoare_partition!(X, left, right, pivotIndex, dims)
    
    quicksort!(X, dims, left, partitionIndex)   
    quicksort!(X, dims, partitionIndex + 1, right)  
end

function quicksort(X, dims, left = 1, right = nothing)
    if isnothing(right)
        dim = findfirst(==(:),dims)
        right = length(axes(X,dim))
    end
    Xc = copy(X)
    quicksort!(Xc, dims, left, right)
    return Xc
end

quicksort(X::AbstractVector) = quicksort(X,[:],firstindex(X),lastindex(X))
quicksort!(X::AbstractVector) = quicksort!(X,[:],firstindex(X),lastindex(X))

function quickselect!(X,k, dims, left = 1, right = nothing)
    if isnothing(right)
        dim = findfirst(==(:),dims)
        right = length(axes(X,dim))
    end
    subvec = @views X[dims...]
    while true
        if left == right
            return subvec[left]
        end
        pivotIndex = rand(left:right)
        pivotIndex = hoare_partition!(X,left,right,pivotIndex,dims)
        #shift to left
        #pivotindex is the index around which the data is now partitioned
        #i.e. beyond the new pivot there are only >= elements compares to the old one, and front, there are only ones that are <= compared 
       if k <= pivotIndex
            right = pivotIndex
        else
            left = pivotIndex + 1
        end
    end
end

quickselect!(x::AbstractVector, k) = quickselect!(x, k, [:], firstindex(x), lastindex(x))

function quickselect(X,k, dims, left = 1, right = nothing)
    if isnothing(right)
        dim = findfirst(==(:),dims)
        right = length(axes(X,dim))
    end
    Xc = copy(X)
    res = quickselect!(Xc,k,dims, left,right)
    return res
end

function lower_median(X::AbstractVector)
    index = div(length(X),2) + 1
    return quickselect(X,index,[:])
end