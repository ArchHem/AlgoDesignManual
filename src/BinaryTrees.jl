module BinaryTrees

#There is surprisngly little info on the AbstractDict type. As such, we do not subtype this.
#Static BST, using a sorted list under the hood
struct StaticBST{T, Z}
    keys::Vector{T} #sorted array
    values::Vector{Z}
end

#Elements of x must have a valid less-then implemented
#x is a sorted array
function BinarySearch(x::AbstractVector{T}, key::T, left = firstindex(x), right = lastindex(x)) where T
    if IndexStyle(x) != IndexLinear()
        throw(ErrorException("Binary search search only supported on arrays with linear indeces"))
    end
    while left <= right
        midindex = left + div(right - left, 2)
        #this picks the "higher" midpoint
        mid = x[midindex]
        if mid == key
            return midindex
        elseif mid < key
            #move to second half
            left = midindex + 1
        else
            right = midindex - 1
        end
    end
    return nothing
end

function StaticBST(keys::AbstractArray{T}, values::AbstractArray{Z}) where {T,Z}
    if length(keys) != length(values)
        throw(DimensionMismatch("Keys and values must have the same length."))
    end
    if length(Set(keys)) != length(keys)
        throw(ArgumentError("Keys must not contain duplicates."))
    end
    p = sortperm(keys)
    #indexing implicitly copies.
    return StaticBST{T, Z}(keys[p], values[p])
end

Base.keys(x::StaticBST) = x.keys
Base.values(x::StaticBST) = x.values
function Base.haskey(x::StaticBST, key)
    index = BinarySearch(keys(x), key)
    if isnothing(index)
        return false
    end
    return true
end

function Base.getindex(x::StaticBST, key)
    index = BinarySearch(keys(x), key)
    if isnothing(index)
        throw(KeyError(key))
    end
    return values(x)[index] 
end

function Base.setindex!(x::StaticBST, a, key)
    index = BinarySearch(keys(x), key)
    if isnothing(index)
        throw(KeyError(key))
    end
    x.values[index] = a
    return x
end

Base.length(x::StaticBST) = length(values(x))
Base.isempty(x::StaticBST) = isempty(values(x))

#first gets called
function Base.iterate(x::StaticBST{T, Z}) where {T,Z}
    if isempty(x)
        return nothing
    end
    i = 1
    return (x.keys[i] => x.values[i], i + 1)
end


function Base.iterate(x::StaticBST{T,Z}, state) where {T,Z}
    if state > length(x)
        return nothing
    end
    
    return (x.keys[state] => x.values[state], state + 1)
end

end