module BasicHash
#We will be using Base.hash since it is robust.

#we could use a 3-state enum but it stores it as 8 bytes (1 is enough)

struct HashNode{T,Z}
    #slow, but robust way of handling sentinels.
    key::Union{T, Nothing}
    value::Union{Z, Nothing}
    state::Int8
end

HashNode{T,Z}() where {T,Z}= HashNode{T,Z}(nothing, nothing, 2)

mutable struct HashMap{T,Z}
    #Techincally, we could use a three-state enum, but that would be 4 bytes
    storage::Vector{HashNode{T,Z}}
    used_count::Int64
end

HashMap{T,Z}(N::Int64) where {T,Z} = HashMap{T,Z}([HashNode{T,Z}() for i in 1:N], 0)

#state: 1 = used
#state: 2 = unused
#state 3: deleted

#use linear probing

Base.keytype(x::HashNode{T,Z}) where {T, Z} = T
Base.valtype(x::HashNode{T,Z}) where {T, Z} = Z
Base.keytype(x::HashMap{T,Z}) where {T, Z} = T
Base.valtype(x::HashMap{T,Z}) where {T, Z} = Z

Base.length(x::HashMap) = x.used_count

function find_bucket(x::HashMap{T,Z}, k::T) where {T,Z}
    #find the first unoccopied or key-matched bucket
    baseloc = hash(k)
    j = 0
    N = length(x.storage)
    first_deleted_slot = -1

    while j < N
        currindex = mod(baseloc + j, 1:N)
        currelem = x.storage[currindex]

        if currelem.state == Int8(1) && currelem.key == k #used and key is found
            return currindex
        elseif currelem.state == Int8(2) #unused slot - if we passed a former, deleted node, it must be the correct insertion point.
            if first_deleted_slot != -1 #we already found a deleted node before this slot  - insert there.
                return first_deleted_slot
            else
                return currindex
            end
        else #deleted
            if currelem.state == Int8(3) && first_deleted_slot == -1 
                first_deleted_slot = currindex #get first deleted slot.
            end
        end
        j += 1
    end
    throw(KeyError(k))
end

function Base.setindex!(x::HashMap{T,Z}, v::Z, k::T) where {T,Z}
    #ensure that insertion would not raise the hashmap load factor aboe critical factor.
    #If it atcually does, rehahsh into a double-sized array.
    index_to_insert = find_bucket(x,k)
    #2 options: either same key, or unoccopied

    if x.storage[index_to_insert].state != 1 #was not already in use
        x.used_count += 1
    end
    x.storage[index_to_insert] = HashNode{T,Z}(k, v, 1)

    load_ratio = x.used_count / length(x.storage)
    if load_ratio > 0.7
        rehash!(x, 2*length(x.storage))
    end
    return nothing
end

function Base.getindex(x::HashMap{T,Z}, k::T) where {T,Z}
    index = find_bucket(x,k)
    found_node = x.storage[index]
    #if node is used, and matches our key.
    if found_node.state == Int8(1) && found_node.key == k
        return found_node.value
    else
        throw(KeyError(k))
    end
end

function Base.delete!(x::HashMap{T,Z}, k::T) where {T,Z}
    index = find_bucket(x,k)
    found_node = x.storage[index]

    if found_node.state == Int8(1) && found_node.key == k
        x.storage[index] = HashNode{T,Z}(nothing, nothing, 3)
        x.used_count -= 1
    else
        throw(KeyError(k))
    end

    return nothing
end

function rehash!(x::HashMap{T,Z}, N::Int64) where {T,Z}
    #extract all key/value pairs.
    kvp = collect(x)
    #create new empty hashmap.
    newarr = [HashNode{T,Z}() for i in 1:N]
    
    x.storage = newarr
    x.used_count = 0
    for p in kvp
        #invoke setindex
        x[first(p)] = last(p)
    end
    return nothing
end

function Base.iterate(x::HashMap{T,Z}) where {T,Z}
    for i in 1:length(x.storage)
        node = x.storage[i]
        if node.state == Int8(1)
            return (node.key => node.value, i + 1)
        end
    end
    return nothing
end

function Base.iterate(x::HashMap{T,Z}, state::Int) where {T,Z}
    for i in state:length(x.storage)
        node = x.storage[i]
        if node.state == Int8(1)
            return (node.key => node.value, i + 1)
        end
    end
    return nothing
end

function Base.keys(x::HashMap{T,Z}) where {T,Z}
    return (node.key for node in x.storage if node.state == Int8(1))
end

function Base.values(x::HashMap{T,Z}) where {T,Z}
    return (node.value for node in x.storage if node.state == Int8(1))
end

function HashMap(x::Pair{T,Z}...) where {T,Z}
    N = length(x)
    res = HashMap{T,Z}(3*N)

    for u in x
        res[first(u)] = last(u)
    end
    return res
end

Base.isempty(x::HashMap) = x.used_count == 0

export HashNode, HashMap
end