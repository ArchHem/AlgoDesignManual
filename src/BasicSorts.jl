module BasicSorts
include("./sorting.jl")
include("./KDTrees.jl")
include("./BasicHeaps.jl")

export quicksort!, quickselect, quicksort, quickselect!, KDTreeMatrix, nn_search, lazydelete!, rebuild, double_tree
export NodeKDTree, remove_node!, find_min, add_point!
export BasicHeap, heapsort, heapsort!, _shift_up!, _shift_down!
end