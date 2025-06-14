#comparing Base matrix mult and various optimizations
using Base.Threads
using LinearAlgebra
using Plots
using BenchmarkTools
using Random
using Base.Iterators
#write a*b into c.

println("Are the number of Julia and BLAS threads counts equal?")
println(BLAS.get_num_threads() == nthreads())

function naive_matrix_mult!(c::Matrix{T}, a::Matrix{T}, b::Matrix{T}) where T
    #color major moment
    @assert size(c, 1) == size(a, 1)
    @assert size(c, 2) == size(b, 2)
    #generally we would use axes.
    #C_ij = A_ik B_kj
    #U.e. c has result of N_rows a x N_cols b
    for j in 1:size(b, 2)
        for i in 1:size(a, 1)
            localsum = zero(T)
            for k in 1:size(a, 2)
                localsum = muladd(a[i, k], b[k, j], localsum)
            end
            c[i,j] = localsum
        end
    end
    return nothing
end

function naive_no_bounds_matrix_mult!(c::Matrix{T}, a::Matrix{T}, b::Matrix{T}) where T
    #color major moment
    @assert size(c, 1) == size(a, 1)
    @assert size(c, 2) == size(b, 2)
    #generally we would use axes.
    #C_ij = A_ik B_kj
    #U.e. c has result of N_rows a x N_cols b
    for j in 1:size(b, 2)
        for i in 1:size(a, 1)
            localsum = zero(T)
            for k in 1:size(a, 2)
                @inbounds localsum = muladd(a[i, k], b[k, j], localsum)
            end
            @inbounds c[i,j] = localsum
        end
    end
    return nothing
end

function simd_matrix_mult!(c::Matrix{T}, a::Matrix{T}, b::Matrix{T}) where T
    @assert size(c, 1) == size(a, 1)
    @assert size(c, 2) == size(b, 2)
    #Where is it best to use simd instructions? We generally want to apply them in places where 
    #the operatioss are parallizable and at least one memory source is contious. 
    #FMA might not be supported w simd registers 
    for j in 1:size(b, 2)
        @simd for i in 1:size(a, 1) #this is a continious memory for one of the matrices. 
            localsum = zero(T)
            for k in 1:size(a, 2) #this is cummultatuve op. This can not be simd'd
                @inbounds localsum = muladd(a[i, k], b[k, j], localsum)
            end
            @inbounds c[i,j] = localsum
        end
    end
    return nothing
end

function thread_simd_matrix_mult!(c::Matrix{T}, a::Matrix{T}, b::Matrix{T}) where T
    @assert size(c, 1) == size(a, 1)
    @assert size(c, 2) == size(b, 2)
    #Where is it best to use simd instructions? We generally want to apply them in places where 
    #the operatioss are parallizable and at least one memory source is contious. 
    #FMA might not be supported w simd registers 
    @threads for j in 1:size(b, 2)
        @simd for i in 1:size(a, 1) #this is a continious memory for one of the matrices. 
            localsum = zero(T)
            for k in 1:size(a, 2) #this is cummultatuve op. This can not be simd'd
                @inbounds localsum = muladd(a[i, k], b[k, j], localsum)
            end
            @inbounds c[i,j] = localsum
        end
    end
    return nothing
end








#Benchmark land

function relative_naive_benchmarks(T = Float32, M = 128, stepsize = 8)
    #do nN x N
    
    rng = Xoshiro(3)
    sizes = 1:stepsize:M+1
    maxpower = length(sizes)
    native_res = zeros(T,maxpower)
    naive_res = zeros(T, maxpower)
    naive_no_bounds = zeros(T, maxpower)
    naive_simd = zeros(T, maxpower)
    naive_threads = zeros(T, maxpower)

    for i in eachindex(sizes)
        N = sizes[i]
        println("Benchmarking N = $(N) wide matrices")
        u1 = randn(rng, T, N, N)
        u2 = randn(rng, T, N, N)
        u3 = randn(rng, T, N, N)

        nativet = @belapsed mul!($u1, $u2, $u3)
        naivet = @belapsed naive_matrix_mult!($u1, $u2, $u3)
        simdt = @belapsed simd_matrix_mult!($u1, $u2, $u3)
        noboundst = @belapsed naive_no_bounds_matrix_mult!($u1, $u2, $u3)
        threadst = @belapsed thread_simd_matrix_mult!($u1, $u2, $u3)

        native_res[i] = nativet
        naive_res[i] = naivet
        naive_no_bounds[i] = noboundst
        naive_simd[i] = simdt
        naive_threads[i] = threadst

    end

    p = plot(sizes, native_res, label = "Native (BLAS) matrix mult")
    plot!(p, sizes, naive_res, label = "Naive MatMul")
    plot!(p, sizes, naive_no_bounds, label = "Naive, no bounds checks")
    plot!(p, sizes, naive_simd, label = "Naive, SIMD")
    plot!(p, sizes, naive_threads, label = "Naively Multithreaded")
    return p
end

#naive_plot = relative_naive_benchmarks()

#basic tling

function tile_aware!(c::Matrix{T}, a::Matrix{T}, b::Matrix{T}, tilesize = 16) where T
    #=
    actual_tile_size = floor(Int64, cache_bytesize * load_factor / 3)
    elemsize = sizeof(T)
    #we each matrix tike to have total tile size of actual_tile_size

    tiledim = floor(Int64,sqrt(actual_tile_size / elemsize))
    =#
    @assert size(c, 1) == size(a, 1)
    @assert size(c, 2) == size(b, 2)
    @assert size(a, 2) == size(b, 1)
    fill!(c, zero(T))
    jindeces = collect(partition(axes(b, 2), tilesize))
    @threads for j in jindeces
        for i in partition(axes(a, 1), tilesize)
            for k in partition(axes(a, 2), tilesize)
                @inbounds c_view = @views c[i, j]
                @inbounds a_view = @views a[i, k]
                @inbounds b_view = @views b[k, j]
                for lj in axes(b_view, 2)
                    @simd for li in axes(a_view, 1)
                        for lk in axes(a_view, 2)
                            @inbounds c_view[li, lj] = muladd(a_view[li, lk], b_view[lk, lj], c_view[li,lj])
                        end
                    end
                end
            end
        end
    end
end

function tile_aware_swap!(c::Matrix{T}, a::Matrix{T}, b::Matrix{T}, tilesize = 16) where T
    #=
    actual_tile_size = floor(Int64, cache_bytesize * load_factor / 3)
    elemsize = sizeof(T)
    #we each matrix tike to have total tile size of actual_tile_size

    tiledim = floor(Int64,sqrt(actual_tile_size / elemsize))
    =#
    @assert size(c, 1) == size(a, 1)
    @assert size(c, 2) == size(b, 2)
    @assert size(a, 2) == size(b, 1)
    fill!(c, zero(T))
    jindeces = collect(partition(axes(b, 2), tilesize))
    @threads for j in jindeces
        for i in partition(axes(a, 1), tilesize)
            for k in partition(axes(a, 2), tilesize)
                @inbounds c_view = @views c[i, j]
                @inbounds a_view = @views a[i, k]
                @inbounds b_view = @views b[k, j]
                for lk in axes(a_view, 2)
                    for lj in axes(b_view, 2)
                        @simd for li in axes(a_view, 1)
                            @inbounds c_view[li, lj] = muladd(a_view[li, lk], b_view[lk, lj], c_view[li,lj])
                        end
                    end
                end
            end
        end
    end
end

function relative_tiled_benchmarks(T = Float64, M_max = 1030, stepsize = 100; tile_size = 16)
    rng = Xoshiro(3)

    sizes = 30:stepsize:M_max
    
    native_res = zeros(T, length(sizes))
    tile_aware_res = zeros(T, length(sizes))
    tile_aware_swap_res = zeros(T, length(sizes))

    for idx in eachindex(sizes)
        N = sizes[idx]
        println("Benchmarking N = $(N) x $(N) matrices")

        c_native = Matrix{T}(undef, N, N)
        a_native = randn(rng, T, N, N)
        b_native = randn(rng, T, N, N)

        c_tile_aware = Matrix{T}(undef, N, N)
        a_tile_aware = randn(rng, T, N, N)
        b_tile_aware = randn(rng, T, N, N)

        c_tile_aware_swap = Matrix{T}(undef, N, N)
        a_tile_aware_swap = randn(rng, T, N, N)
        b_tile_aware_swap = randn(rng, T, N, N)
        
        native_res[idx] = @belapsed mul!($c_native, $a_native, $b_native)
        
        tile_aware_res[idx] = @belapsed tile_aware!($c_tile_aware, $a_tile_aware, $b_tile_aware, $tile_size)
        tile_aware_swap_res[idx] = @belapsed tile_aware_swap!($c_tile_aware_swap, $a_tile_aware_swap, $b_tile_aware_swap, $tile_size)
    end
    y_min_plot = 0.0
    y_max_plot = 0.08
    grid_interval = 0.005
    y_ticks = y_min_plot:grid_interval:y_max_plot
    p = plot(sizes, native_res, label = "Native (BLAS) mul!", color = :black, 
            linewidth = 2, marker = :circle, yticks = y_ticks, ylim = (y_min_plot, y_max_plot),
            grid = :y, gridalpha = 0.7, gridlinewidth = 0.5, gridstyle = :dash)
    plot!(p, sizes, tile_aware_res, label = "Tiled (jilk)", color = :green, marker = :cross)
    plot!(p, sizes, tile_aware_swap_res, label = "Tiled (kjli)", color = :darkgreen, marker = :x)

    title!("Tile = $tile_size")
    xlabel!("Matrix Dimension (N)")
    ylabel!("Execution Time (seconds)")
    return p
end

#p2 = relative_tiled_benchmarks(Float64, 1030, 100, tile_size = 32)

#We have determined the inner kernel order of kji to be the fastest. Now try two method of top-level parallelism
#This method assigns 1 thread per chunk; this should be ideal.
function tile_aware_swap_big_chunks!(c::Matrix{T}, a::Matrix{T}, b::Matrix{T}, tilesize = 16) where T
    #=
    actual_tile_size = floor(Int64, cache_bytesize * load_factor / 3)
    elemsize = sizeof(T)
    #we each matrix tike to have total tile size of actual_tile_size

    tiledim = floor(Int64,sqrt(actual_tile_size / elemsize))
    =#
    @assert size(c, 1) == size(a, 1)
    @assert size(c, 2) == size(b, 2)
    @assert size(a, 2) == size(b, 1)
    fill!(c, zero(T))
    js = axes(b, 2)
    jchunks = Iterators.partition(js, length(js) ÷ Threads.nthreads())
    tasks = map(jchunks) do j
    @spawn begin
        for i in partition(axes(a, 1), tilesize)
            for k in partition(axes(a, 2), tilesize)
                @inbounds c_view = @views c[i, j]
                @inbounds a_view = @views a[i, k]
                @inbounds b_view = @views b[k, j]
                for lk in axes(a_view, 2)
                    for lj in axes(b_view, 2)
                        @simd ivdep for li in axes(a_view, 1)
                            @inbounds c_view[li, lj] = muladd(a_view[li, lk], b_view[lk, lj], c_view[li,lj])
                        end
                    end
                end
            end
        end
    end
    end
    fetch.(tasks)
    return nothing
end


function relative_tiled_benchmarks_compare_chunks(T = Float64, M_max = 1030, stepsize = 100; tile_size = 32)
    rng = Xoshiro(3)

    sizes = 30:stepsize:M_max
    
    native_res = zeros(T, length(sizes))
    tile_aware_swap_big_chunks_res = zeros(T, length(sizes))
    tile_aware_swap_res = zeros(T, length(sizes))

    for idx in eachindex(sizes)
        N = sizes[idx]
        println("Benchmarking N = $(N) x $(N) matrices")

        c_native = Matrix{T}(undef, N, N)
        a_native = randn(rng, T, N, N)
        b_native = randn(rng, T, N, N)

        c_big_chunks = Matrix{T}(undef, N, N)
        a_big_chunks = randn(rng, T, N, N)
        b_big_chunks = randn(rng, T, N, N)

        c_tile_aware_swap = Matrix{T}(undef, N, N)
        a_tile_aware_swap = randn(rng, T, N, N)
        b_tile_aware_swap = randn(rng, T, N, N)
        
        native_res[idx] = @belapsed mul!($c_native, $a_native, $b_native)
        
        tile_aware_swap_big_chunks_res[idx] = @belapsed tile_aware_swap_big_chunks!($c_big_chunks, $a_big_chunks, $b_big_chunks, $tile_size)
        tile_aware_swap_res[idx] = @belapsed tile_aware_swap!($c_tile_aware_swap, $a_tile_aware_swap, $b_tile_aware_swap, $tile_size)
    end
    y_min_plot = 0.0
    y_max_plot = 0.08
    grid_interval = 0.005
    y_ticks = y_min_plot:grid_interval:y_max_plot
    p = plot(sizes, native_res, label = "Native (BLAS) mul!", color = :black, 
            linewidth = 2, marker = :circle, yticks = y_ticks, ylim = (y_min_plot, y_max_plot),
            grid = :y, gridalpha = 0.7, gridlinewidth = 0.5, gridstyle = :dash)
    plot!(p, sizes, tile_aware_swap_big_chunks_res, label = "Tiled (kjli) - Big Chunks (J-outer parallel)", color = :blue, marker = :square)
    plot!(p, sizes, tile_aware_swap_res, label = "Tiled (kjli) - @threads j-loop", color = :darkgreen, marker = :x)

    title!("Tile = $tile_size")
    xlabel!("Matrix Dimension (N)")
    ylabel!("Execution Time (seconds)")
    return p
end

#p3 = relative_tiled_benchmarks_compare_chunks()


#It is pretty clear we are hitting the limits of single-level tiling.

#Experience suggests: 
#For the outer (macro/microtile) loops, the order of k-j-i is ideal
#The innemost kernel needs to be hand-simd optimized.
#Parallelization at the highest, continous and data race free loop is prefered. If possible, let
#Tiling size will likely need to be optimized.
using SIMD
using Polyester #for semu-reusable threads.
using LoopVectorization

#=

C[i, j] = sum_k A_ik B_kj
C[:, j] is continoous in memory
C[:, j] = A_:k B_kj

I.e. something like:

@inbounds for k in k_micro
    for j in j_micro
        BJK = B[k, j]
        @simd ivdep for i in i_micro
            @fastmath C[i, j] += A[i, k] * BJK
        end
    end
end

Of course, hand written kernels are likely to operate better.

=#

@inline function microkernel!(c, b, a, k_micro, j_micro, i_micro)
    @fastmath @inbounds for k in k_micro
        for j in j_micro
            BJK = b[k, j]
            @simd ivdep for i in i_micro
                c[i, j] += a[i, k] * BJK
            end
        end
    end
    return nothing
end

function GEMM_prototype!(c::Matrix{T}, a::Matrix{T}, b::Matrix{T}; 
                        jjsize = 128, iisize = 256, kksize = 256, 
                        jsize = 4, isize = 32, ksize = 32) where T
    @assert size(c, 1) == size(a, 1)
    @assert size(c, 2) == size(b, 2)
    @assert size(a, 2) == size(b, 1)

    j_macro_chunks = partition(axes(b, 2), jjsize)
    N = min(length(j_macro_chunks), nthreads())
    j_thread_chunks = partition(j_macro_chunks, div(length(j_macro_chunks), N))

    tasks = map(j_thread_chunks) do j_thread_chunk
        @spawn begin
            for k_macro in partition(axes(a, 2), kksize)
                #parallize across macro j loop
                for j_macro in j_thread_chunk
                    for i_macro in partition(axes(a, 1), iisize)
                        #micro-tile land.
                        
                        for k_micro in partition(k_macro, ksize)
                            for j_micro in partition(j_macro, jsize)
                                for i_micro in partition(i_macro, isize)
                                    #we are now at the micro-kernel level. indeces map 1-1 to overlaying indeces.
                                    


                                    microkernel!(c, b, a, k_micro, j_micro, i_micro)


                                end
                            end
                        end
                    end
                end
            end
        end
    end
    fetch.(tasks)
    return nothing
end

N = 1024
C = zeros(N, N)
A = randn(N, N)
B = randn(N, N)

#It is clear that we have hit some hard limit here. Further segmentation within the microkerel is required.

struct TileBind{NK, NJ, NI}
end

#Metaprogramming dark magic...
@generated function nanokernel!(c, a, b, tile::TileBind{NK, NJ, NI}) where {NK, NJ, NI}

    c_vars = NTuple{NJ*NI, Symbol}(Symbol("c_acc_$(i)_$(j)") for (i,j) in product(1:NI, 1:NJ))
    
    load_expr = NTuple{NJ*NI, Expr}(:( @inbounds $(c_vars[lindex]) = c[$(idc[1]), $(idc[2])]) for (lindex, idc) in enumerate(product(1:NI, 1:NJ)))

    store_expr = NTuple{NJ*NI, Expr}(:(@inbounds c[$(idc[1]), $(idc[2])] = $(c_vars[lindex])) for (lindex, idc) in enumerate(product(1:NI, 1:NJ)))

    k_runtime = gensym("k_runtime")

    a_vars = NTuple{NI, Symbol}(Symbol("a_var_$(i)") for i in 1:NI)
    b_vars = NTuple{NJ, Symbol}(Symbol("b_var_$(j)") for j in 1:NJ)

    a_loads = NTuple{NI, Expr}(:( @inbounds $(a_vars[i]) = a[$i, $k_runtime]) for i in 1:NI)
    #change here if its transposed to j-k access order instead.
    b_loads = NTuple{NJ, Expr}(:( @inbounds $(b_vars[j]) = b[$k_runtime, $j]) for j in 1:NJ)

    c_accums = NTuple{NJ*NI, Expr}(:(@fastmath @inbounds $(c_vars[lindex]) += $(a_vars[idc[1]]) * $(b_vars[idc[2]])) for (lindex, idc) in enumerate(product(1:NI, 1:NJ)) )

    res = quote
        $(load_expr...)

        for $k_runtime in 1:$NK
            $(a_loads...)
            $(b_loads...)
            $(c_accums...)
        end
        $(store_expr...)
        nothing
    end

    return res

end

#We have 32x128 bit simd registers. i.e. each can hold 1x full fp
#NI x NJ / 2 = 16 are required to hold C.
#NI / 2 = 4 are required to hold elements of a
#NJ / 2 = 2 are required to hold elements of b

#This in total will use 22 registers out of 32. This is not ideal! However, generating leftore blocks, for now, is overkill.
function GEMM_generated!(c::Matrix{T}, a::Matrix{T}, b::Matrix{T}; 
                        jjsize = 128, iisize = 256, kksize = 256, 
                        jsize = 4, isize = 64, ksize = 32, tile::TileBind{NK, NJ, NI} = TileBind{8,4,8}()) where {T, NK, NJ, NI}

    @assert size(c, 1) == size(a, 1)
    @assert size(c, 2) == size(b, 2)
    @assert size(a, 2) == size(b, 1)

    #add extra assertations for nanokernel...

    j_macro_chunks = partition(axes(b, 2), jjsize)
    N = min(length(j_macro_chunks), nthreads())
    j_thread_chunks = partition(j_macro_chunks, div(length(j_macro_chunks), N))

    tasks = map(j_thread_chunks) do j_thread_chunk
        @spawn begin
            for k_macro in partition(axes(a, 2), kksize)
                #parallize across macro j loop
                for j_macro in j_thread_chunk
                    for i_macro in partition(axes(a, 1), iisize)
                        #micro-tile land.
                        
                        for k_micro in partition(k_macro, ksize)
                            for j_micro in partition(j_macro, jsize)
                                for i_micro in partition(i_macro, isize)
                                    #we are now at the micro-kernel level. indeces map 1-1 to overlaying indeces.
                                    
                                    #try to generate a second nanokernel for better blockinsg....
                                    for k_n in partition(k_micro, NK)
                                        for j_n in partition(j_micro, NJ)
                                            b_l = @inbounds @views b[k_n, j_n]
                                            for i_n in partition(i_micro, NI)
                                                a_l = @inbounds @views a[i_n, k_n]
                                                c_l = @inbounds @views c[i_n, j_n]
                                                nanokernel!(c_l, a_l, b_l, tile)
                                            end
                                        end
                                    end


                                end
                            end
                        end
                    end
                end
            end
        end
    end
    fetch.(tasks)::Vector{Nothing}
    return nothing
end

#Even more reclyced benchmarking plot code...
function compare_gemm_implementations(T = Float64; 
                                       sizes = [128, 256, 384, 512, 640, 768, 896, 1024],
                                       gemm_generated_tile_params = TileBind{4,4,8}())
    rng = Xoshiro(3)
    mul_res = zeros(T, length(sizes))
    gemm_generated_res = zeros(T, length(sizes))
    gemm_prototype_res = zeros(T, length(sizes))
    max_N = maximum(sizes)
    c_mul = Matrix{T}(undef, max_N, max_N)
    a_mul = randn(rng, T, max_N, max_N)
    b_mul = randn(rng, T, max_N, max_N)
    c_gen = Matrix{T}(undef, max_N, max_N)
    a_gen = randn(rng, T, max_N, max_N)
    b_gen = randn(rng, T, max_N, max_N)
    c_proto = Matrix{T}(undef, max_N, max_N)
    a_proto = randn(rng, T, max_N, max_N)
    b_proto = randn(rng, T, max_N, max_N)

    for idx in eachindex(sizes)
        N = sizes[idx]
        println("Benchmarking N = $(N) x $(N) matrices")
        
        
        fill!(c_mul, 0)
        mul_res[idx] = @belapsed mul!($c_mul, $a_mul, $b_mul) seconds=3

        fill!(c_gen, 0)
        gemm_generated_res[idx] = @belapsed GEMM_generated!($c_gen, $a_gen, $b_gen; tile=$gemm_generated_tile_params) seconds=3

        fill!(c_proto, 0)
        gemm_prototype_res[idx] = @belapsed GEMM_prototype!($c_proto, $a_proto, $b_proto) seconds=3
    end

    p = plot(sizes, mul_res, label = "Native (BLAS) mul!", color = :black, 
            linewidth = 2, marker = :circle, markersize = 4)
    plot!(p, sizes, gemm_generated_res, label = "Custom GEMM_generated!", color = :red, 
            linewidth = 2, marker = :square, markersize = 4)
    plot!(p, sizes, gemm_prototype_res, label = "Custom GEMM_prototype!", color = :blue, 
            linewidth = 2, marker = :utriangle, markersize = 4)

    title!("GEMM Implementation Comparison")
    xlabel!("Matrix Dimension (N)")
    ylabel!("Execution Time (seconds)")
    plot!(p)
    
    return p
end

