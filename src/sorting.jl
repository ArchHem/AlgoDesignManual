using Random

@inline function swap!(v, i::Int, j::Int)
    #easier than pointer magic.
    v[i], v[j] = v[j], v[i]
    return nothing
end

function hoare_partition!(X,left,right,pivotIndex)
    pivot = X[pivotIndex]
    right = right
    while true
        while X[left] < pivot
            left = left + 1
        end
        
        while X[right] > pivot
            right = right - 1
        end

        if left >= right
            return right
        end
        #dont swap equals?

        swap!(X,left,right)

        left = left + 1
        right = right - 1
    end
end

#use randomized method
function quicksort!(X, left = 1, right = length(X))
    #end condition
    if left >= right || left < 1
        return X
    end
    pivotIndex = rand(left:right)  
    partitionIndex = hoare_partition!(X, left, right, pivotIndex)
    quicksort!(X, left, partitionIndex)   
    quicksort!(X, partitionIndex + 1, right)  
end

function quicksort(X, left = 1, right = length(X))
    Xc = copy(X)
    quicksort!(Xc,left, right)
    return Xc
end

function quickselect!(X,k, left = 1, right = length(X))
    while true
        if left == right
            return X[left]
        end
        pivotIndex = rand(left:right)
        pivotIndex = hoare_partition!(X,left,right,pivotIndex)
        #shift to left
        #pivotindex is the index around which the data is now partitioned
        #i.e. beyond the new pivot there are only >= elements compares to the old one, and front, there are only ones that are <= compared 
       if k <= pivotIndex
            right = pivotIndex
        else
            left = pivotIndex + 1
        end
    end
end

function quickselect(X,k, left = 1, right = length(X))
    Xc = copy(X)
    res = quickselect!(Xc,k,left,right)
    return res
end

function lower_median(X)
    index = div(length(X),2) + 1
    return quickselect(X,index)
end