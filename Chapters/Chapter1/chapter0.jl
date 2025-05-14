using Random, Plots, StatsBase

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
    Ns = [50, 100, 200]
    dims = 1:10
    distributions = ["uniform", "normal", "exponential"]
    
    plot_grid = []

    for dist in distributions
        for N in Ns
            println(dist, " ", N)
            p = plot(title="$dist, N=$N", xlabel="Dimension", ylabel="Total Distance", legend=:bottomright)

            pairs = []
            tsps = []
            for d in dims
                Random.seed!(42)
                x = dist == "uniform"      ? rand(d, N) :
                    dist == "normal"       ? randn(d, N) : randexp(d, N)

                #presead the greedy
                mean_vec = mean(x, dims = 2)
                
                lsq = sum((mean_vec .- x).^2, dims = 1)
                index = argmin(vec(lsq))
                tsp = greedy_tsp(x, index)
                pair = greedy_pair_tsp(x)
                push!(tsps, tsp)
                push!(pairs, pair)
                
            end
            scatter!(p, dims, tsps, label="TSP Naive Greedy", color = :red)
            scatter!(p, dims, pairs, label="Pair Greedy",  color = :blue)
            push!(plot_grid, p)
        end
    end

    return plot(plot_grid..., layout=(3, 3), size=(1200, 900))
end

result = compare_heuristics_plot()