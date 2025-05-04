module MyImpl
include("./sorting.jl")
include("./KDTrees.jl")

export quicksort!, quickselect, quicksort, quickselect!, KDTreeMatrix, nn_search
end