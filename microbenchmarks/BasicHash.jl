
using BenchmarkTools
using Plots
using Random
include("../src/BasicHash.jl")
using .BasicHash

rng = Xoshiro(1)

#something fukny going on w this benchmark
#We can see approx O(1) indexing but its midly climbing towards the end.
function bmark_hashmap()
    Ns = [2^i for i in 3:14]
    tmes = zeros(length(Ns))
    data1 = randn(rng, 4)
    data2 = randn(rng, 4)
    pairs = Pair.(data1, data2)
    hmap = HashMap(pairs...)
    k = data1[1]
    getindex(hmap, k)

    for i in eachindex(Ns)
        data1 = randn(rng, Ns[i])
        data2 = randn(rng, Ns[i])
        pairs = Pair.(data1, data2)
        hmap = HashMap(pairs...)
        u = @benchmark getindex($hmap, rand($rng, $data1))
        t = median(u).time
        tmes[i] = t
    end
    return scatter(Ns, tmes, xlabel = "Hash Map initial element count", ylabel = "Key retriaval time (ns)", color = "green", xscale = :log2)
end

p1 = bmark_hashmap()