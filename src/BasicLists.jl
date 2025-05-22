module BasicLists
include("./LinkedList.jl")
export AbstractList, LinkedList, StaticLinkedList, MLinkedList
export LinkedList, StaticListEnd, StaticListNode, value, next, MListEnd, MListNode, insertfull!, insertnext!, popnext!, cat!
end