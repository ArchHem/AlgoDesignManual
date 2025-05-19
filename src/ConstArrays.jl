#No need to re-create the whole of StaticArrays...
struct ConstVector{T,N} <: AbstractVector{T}
    data::NTuple{N,T}
end

ConstVector(x::NTuple{N,T}) where {N,T} = ConstVector{T,N}(x)
Base.length(x::ConstVector{T,N}) where {T,N} = N
Base.eltype(x::ConstVector{T,N}) where {T,N} = T
Base.ndims(x::ConstVector{T,N}) where {T,N} = 1
Base.size(x::ConstVector{T,N}) where {T,N} = (length(x),)

#technically immutable...
Base.copy(x::ConstVector{T,N}) where {T,N} = ConstVector{T,N}(x.data)
Base.collect(x::ConstVector{T,N}) where {T,N} = collect(x.data)
Base.Vector(x::ConstVector{T,N}) where {T, N} = collect(x)

#we dont want large ConstVectors....
promote_rule(::Type{<:ConstVector{T,N}},::Type{<:Vector{S}}) where {T, N, S} = Vector{promote_type(T,S)}

function Base.reverse(x::ConstVector{T,N}) where {T,N}
    return ConstVector{T,N}(reverse(x.data))
end

Base.show(io::IO, x::ConstVector{T,N}) where {T,N}= print(io::IO, x.data)
Base.:(==)(x::ConstVector{T,N}, y::ConstVector{T,N}) where {T,N} = x.data == y.data
Base.iterate(x::ConstVector{T,N}) where {T,N} = iterate(x.data)
#recycle iteration thru tuples...
Base.iterate(x::ConstVector{T,N}, state) where {T,N} = iterate(x.data, state)
Base.getindex(x::ConstVector{T,N}, i::Int) where {T,N} = getindex(x.data, i)
Base.getindex(x::ConstVector{T,N}, i) where {T,N} = ConstVector(getindex(x.data, i))
Base.:(+)(x::ConstVector{S,N}, y::ConstVector{T,N}) where {S,T,N} = ConstVector(x.data .+ y.data)
Base.:(-)(x::ConstVector{S,N}, y::ConstVector{T,N}) where {S,T,N} = ConstVector(x.data .- y.data)

#broadcasting, via the manual at: https://docs.julialang.org/en/v1/manual/interfaces/
#and at https://discourse.julialang.org/t/custom-broadcasting-for-static-immutable-type/69426
Broadcast.broadcastable(x::ConstVector) = x

struct CVStyle{N} <: Broadcast.BroadcastStyle end

Broadcast.BroadcastStyle(::Type{ConstVector{T,N}}) where {T,N} = CVStyle{N}()
#Promote broadcast to our style...
Broadcast.BroadcastStyle(::CVStyle{N}, ::Broadcast.DefaultArrayStyle{0}) where N = CVStyle{N}()

function Broadcast.materialize(B::Broadcast.Broadcasted{CVStyle{N}}) where N
    flat = Broadcast.flatten(B)
    args = flat.args
    f = flat.f
    datas = map(a -> a isa ConstVector ? a.data : Ref(a), args)
    println(datas)
    ConstVector(f.(datas...))
end
