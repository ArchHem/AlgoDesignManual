using Random, Plots, StatsBase
using BenchmarkTools, Plots
#compare nearest vs nearest pair heuretic, 
#we dont care about performance only relative distance

function greedy_tsp(x, index = 1)
    D, N = size(x)
    mask = trues(N)
    remains = N - 1
    totdist = 0
    point = @views x[:, index]
    mask[index] = false

    while remains > 1
        mindist = Inf
        newindex = -1
        for i in 1:N
            if mask[i]
                newdist = sum(@. (point - @view(x[:,i]))^2)
                if newdist < mindist
                    mindist = newdist
                    newindex = i
                end
            end
        end
        point = x[:, newindex]
        mask[newindex] = false
        totdist += sqrt(mindist)
        remains -= 1
    end
    return totdist
end

function greedy_pair_tsp(x, index = 1)
    D, N = size(x)

    totdist = 0
    dist(i,j) = @views sum(@. (x[:,i]- x[:,j])^2)
    pars = Set([(i,i) for i in 1:N])
    while length(pars) > 1
        mindist = Inf
        minpair = ()
        external_vertices= ()
        for p1 in pars
            for p2 in pars
                if p1 != p2
                    a1, a2 = p1
                    b1, b2 = p2

                    for (end1, end2) in [(a1, b1), (a1, b2), (a2, b1), (a2, b2)]
                        d = dist(end1, end2)
                        if d < mindist
                            mindist = d
                            minpair = (p1, p2)
                            
                            new_start = if end1 == a1 a2 else a1 end
                            new_end   = if end2 == b1 b2 else b1 end
                            external_vertices = (new_start, new_end)
                        end
                    end
                end
            end
        end
        delete!(pars, minpair[1])
        delete!(pars, minpair[2])
        push!(pars, external_vertices)
        totdist += sqrt(mindist)
    end
    return totdist
end


function compare_heuristics_plot()
    Ns = [10, 25, 50]
    dims = 1:10
    distributions = ["uniform", "normal", "exponential"]
    num_runs = 30

    plot_grid = []

    for dist in distributions
        for N in Ns
            println(dist, " ", N)
            p = plot(title="$dist, N=$N", xlabel="Dimension", ylabel="Total Distance", legend=:bottomright)

            pairs = []
            tsps = []

            pairs_std = []
            tsp_std = []
            for d in dims
                tsp_results = Float64[]
                pair_results = Float64[]

                for _ in 1:num_runs
                    Random.seed!(42)
                    x = dist == "uniform"      ? rand(d, N) :
                        dist == "normal"       ? randn(d, N) :
                        dist == "exponential"  ? randexp(d, N) : error("Unknown distribution")

                    mean_vec = mean(x, dims = 2)
                    lsq = sum((mean_vec .- x).^2, dims = 1)
                    index = argmin(vec(lsq))

                    tsp = greedy_tsp(x, index)
                    pair = greedy_pair_tsp(x)
                    push!(tsp_results, tsp)
                    push!(pair_results, pair)
                end
                mean_tsp = mean(tsp_results)
                std_tsp = std(tsp_results)
                mean_pair = mean(pair_results)
                std_pair = std(pair_results)
                
                push!(tsps, mean_tsp)
                push!(pairs, mean_pair)

                push!(tsp_std, std_tsp)
                push!(pairs_std, std_pair)
            end
            scatter!(p, dims, tsps, label="TSP Naive Greedy", color = :red, markersize = 3, yerr=tsp_std)
            scatter!(p, dims, pairs, label="Pair Greedy",  color = :blue, markersize = 3, yerr=pairs_std)
            push!(plot_grid, p)
        end
    end

    return plot(plot_grid..., layout=(3, 3), size=(1200, 900))
end

result = compare_heuristics_plot()


#pure greed kind of beter in Low-D,
#pair much better in higher dimensions.   

#could use a relaxation algo 

#Interview problems

#1 integer division

function naive_floor_div(a, b)
    remains = a
    n = 0
    while remains >= b
        
        remains -= b
        n += 1
    end
    return n, remains
end



function fast_floor_div(n::T, d::T) where {T<:UInt}
    q = zero(T)
    r = zero(T)

    width = sizeof(T) * 8
    for i in reverse(0:width-1)
        r <<= 1 #shift left by one bit (multiply by 2)
        r |= (n >> i) & 1 #get i-th bit
        if r >= d #if still bigger than divisor then....
            r -= d
            q |= T(1) << i #write into n-th digit of quotient via shifting and OR-ing 
        end
    end
    return q, r
end

function benchmark_divisions_3d()
    quotients = UInt64.(round.(LinRange(1, 10^7, 20)))
    divisors = UInt64.(round.(LinRange(1, 10^6, 5)))

    naive_times = zeros(Float64, length(quotients), length(divisors))
    fast_times = zeros(Float64, length(quotients), length(divisors))

    for (i, q) in enumerate(quotients)
        for (j, d) in enumerate(divisors)
            naive_times[i, j] = @belapsed naive_floor_div($q, $d) samples=20
            fast_times[i, j] = @belapsed fast_floor_div($d, $d) samples=20
        end
    end

    naive_times_ms = naive_times .* 1e3
    fast_times_ms = fast_times .* 1e3

    p1 = surface(divisors, quotients, naive_times_ms,
        xlabel="Divisor (d)", ylabel="Quotient (q)", zlabel="Time (ms)",
        title="Naive Division Time", legend=false)

    p2 = surface(divisors, quotients, fast_times_ms,
        xlabel="Divisor (d)", ylabel="Quotient (q)", zlabel="Time (ms)",
        title="Fast Bitwise Division Time", legend=false)

    plot(p1, p2, layout=(1, 2), size=(1000, 400))
end

#res = benchmark_divisions_3d()

#25 horses, find 3 fastest (in order), we can 

#race all 25 horses in groups of 5 (+5) (1)

#This reduces the potential location of the 3 fastest to 15 indeces

#Race the fastest 5 horses from their respective races: the winner by definition is the fastest horse (+1) (2)

#To get the second. 
#it is either the second fastest in the previous race, or the horse that came in second in race (1) and was in the same group as the fastest horse.
#Similarly, the third fastest row is either one of teh above 2 horses, or one of the three that came 3rd in the top race, 2nd in the 2nd race or first in the 3rd race
#So, we put these fice horses in the race and determine teh 2nd and 3rd (+1)

#7 races in total