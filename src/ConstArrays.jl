#No need to re-create the whole of StaticArrays...
struct ConstVector{T,N} where {T,N<:Integer} <:AbstractVector
    data::NTuple{N,T}
end

ConstVector(x::NTuple{N,T}) where {N,T} = ConstVector{T}(x)

Base.length(x::ConstVector{T,N}) where {T,N} = N
Base.eltype(x::ConstVector{T,N}) where {T,N} = T

#technically immutable...
Base.copy(x::ConstVector{T,N}) where {T,N} = ConstVector{T,N}(x.data)

function Base.reverse(x::ConstVector{T,N}) where {T,N}
    return ConstVector{T,N}(reverse(x.data))
end

Base.show(io::IO, x::ConstVector{T,N}) = println(io::IO, x.data)
Base.broadcastable(x::ConstVector{T,N}) where {T,N} = x
Base.:==(x::ConstVector{T,N}, y::ConstVector{T,N}) = x.data == y.data
Base.iterate(x::ConstVector{T,N}) = iterate(x.data)
#recycle iteration thru tuples...
Base.iterate(x::ConstVector{T,N}, state) where {T,N} = iterate(x.data, state)
Base.getindex(x::ConstVector{T,N}, i::Int) = x.data[i]


Base.:+(x::ConstVector{T,N}, y::ConstVector{T,N}) = x.data + y.data
Base.:-(x::ConstVector{T,N}, y::ConstVector{T,N}) = x.data - y.data

