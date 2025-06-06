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

function relative_tiled_benchmarks(T = Float64, M_max = 1030, stepsize = 100)
    rng = Xoshiro(3)

    sizes = 30:stepsize:M_max
    
    native_res = zeros(T, length(sizes))
    tile_aware_res = zeros(T, length(sizes))
    tile_aware_swap_res = zeros(T, length(sizes))
    thread_simd_res = zeros(T, length(sizes))

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

        c_thread_simd = Matrix{T}(undef, N, N) # Added for thread_simd_matrix_mult!
        a_thread_simd = randn(rng, T, N, N) # Added for thread_simd_matrix_mult!
        b_thread_simd = randn(rng, T, N, N) # Added for thread_simd_matrix_mult!
        
        native_res[idx] = @belapsed mul!($c_native, $a_native, $b_native)
        
        actual_tilesize = min(46, N)
        tile_aware_res[idx] = @belapsed tile_aware!($c_tile_aware, $a_tile_aware, $b_tile_aware, $actual_tilesize)
        tile_aware_swap_res[idx] = @belapsed tile_aware_swap!($c_tile_aware_swap, $a_tile_aware_swap, $b_tile_aware_swap, $actual_tilesize)
        thread_simd_res[idx] = @belapsed thread_simd_matrix_mult!($c_thread_simd, $a_thread_simd, $b_thread_simd) # Added benchmark
    end

    p = plot(sizes, native_res, label = "Native (BLAS) mul!", color = :black, linewidth = 2, marker = :circle)
    plot!(p, sizes, tile_aware_res, label = "Tiled (jilk)", color = :green, marker = :cross)
    plot!(p, sizes, tile_aware_swap_res, label = "Tiled (kjli)", color = :darkgreen, marker = :x)
    plot!(p, sizes, thread_simd_res, label = "Naive, Multithreaded & SIMD", color = :blue, marker = :star) # Added to plot

    title!("Tiled Matrix Multiplication Performance Comparison (Time vs. Matrix Size)")
    xlabel!("Matrix Dimension (N)")
    ylabel!("Execution Time (seconds)")
    return p
end

p2 = relative_tiled_benchmarks()