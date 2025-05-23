include("../src/SearchTrees.jl")
using .SearchTrees

using BenchmarkTools
using Plots

sizes = 2 .^ (3:15)

bst_times = Float64[]
linear_times = Float64[]
dict_times = Float64[]

for N in sizes
    keys_data = collect(1:N)
    values_data = collect(1001:(1000+N))
    bst_instance = StaticBST(keys_data, values_data)
    julia_dict = Dict{Int, Int}(zip(keys_data, values_data))
    println("Benchmarking size N = $N")
    bst_bench = @benchmark $bst_instance[key] setup=(key = $keys_data[rand(1:$N)])
    push!(bst_times, median(bst_bench).time)
    linear_bench = @benchmark findfirst(isequal(key), $keys_data) setup=(key = $keys_data[rand(1:$N)])
    push!(linear_times, median(linear_bench).time)
    dict_bench = @benchmark $julia_dict[key] setup=(key = $keys_data[rand(1:$N)])
    push!(dict_times, median(dict_bench).time)
end

plot(sizes, bst_times,
     label="StaticBST (Binary Search)",
     xlabel="Data Size (N)",
     ylabel="Median Time (ns)",
     title="Search Performance: StaticBST vs. findfirst vs. Dict",
     marker=:circle,
     linewidth=2,
     legend=:topleft,
     xscale=:log10,
     yscale=:log10,
     grid=true,
     size=(900, 600))

plot!(sizes, linear_times,
      label="findfirst (Linear Search)",
      marker=:square,
      linewidth=2,
      linestyle=:dash)

plot!(sizes, dict_times,
      label="Julia Dict (Hash Table)",
      marker=:utriangle,
      linewidth=2,
      linestyle=:dot,
      color=:purple)