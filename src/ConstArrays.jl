#No need to re-create the whole of StaticArrays...
module ConstArrays
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
#We could have AbstractVector here instead?
Base.promote_rule(::Type{<:ConstVector{T,N}},::Type{<:Vector{S}}) where {T, N, S} = Vector{promote_type(T,S)}

function Base.reverse(x::ConstVector{T,N}) where {T,N}
    return ConstVector{T,N}(reverse(x.data))
end

Base.show(io::IO, x::ConstVector{T,N}) where {T,N} = print(io,"ConstVector{$T,$N}(", x.data, ")")
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
Base.Broadcast.broadcastable(x::ConstVector) = x

struct CVStyle{N} <: Base.Broadcast.BroadcastStyle end

Base.Broadcast.BroadcastStyle(::Type{ConstVector{T,N}}) where {T,N} = CVStyle{N}()
#Promote broadcast to our style...
Base.Broadcast.BroadcastStyle(::CVStyle{N}, ::Base.Broadcast.DefaultArrayStyle{M}) where {N, M} = Broadcast.DefaultArrayStyle{M}()
Base.Broadcast.BroadcastStyle(::CVStyle{N}, ::Base.Broadcast.DefaultArrayStyle{0}) where N = CVStyle{N}()

#does not fully work....
#via https://discourse.julialang.org/t/broadcasting-power-with-integer-literal-issues/105449/2
Base.Broadcast.broadcasted(::typeof(Base.literal_pow), ^, x::ConstVector{T,N}, ::Val{p}) where {T,N,p} = Base.broadcasted(CVStyle{N}(), ^, x, p)

function Base.Broadcast.materialize(B::Base.Broadcast.Broadcasted{CVStyle{N}}) where N
    flat = Base.Broadcast.flatten(B)
    args = flat.args
    f = flat.f
    datas = map(a -> a isa ConstVector ? a.data : a, args)
    ConstVector(f.(datas...))
end
export ConstVector
end
