using Random

#compare nearest vs nearest pair heuretic, 
#we dont care about performance only relative distance

function greedy_tsp(x, index = 1)
    D, N = size(x)
    mask = trues(N)
    remains = N - 1
    totdist = 0
    point = @views x[:, index]
    mask[index] = false

    while remains >= 1
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