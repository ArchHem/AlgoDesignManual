#A common problem for compilers and text editors is determining whether the
#((())())() contains properly nested pairs of parentheses, which the strings )()( and
#()) do not. Give an algorithm that returns true if a string contains properly nested
#and balanced parentheses, and false if otherwise. For full credit, identify the position
#of the first oﬀending parenthesis if the string is not properly nested and balanced.

# This one seems fairly simple: 
# Initita a counter at 0
# Cycle thru the string per character; if its a (, add +1 to the counter
# If its a ), subtract one. If the counter becomes negative , the string is invalid.

function parantheses_order(x::String)
    counter = 0
    for i in eachindex(x)
        local_char = x[i]
        if local_char == '('
            counter += 1
        elseif local_char == ')'
            counter -= 1
        else
            continue
        end
        if counter < 0
            return false, i
        end
    end
    return true, nothing
end

#Examples 

ex1 = "((())())()"
ex2 = ")()("
ex3 = "())"

println(parantheses_order(ex1))
println(parantheses_order(ex2))
println(parantheses_order(ex3))

#[3] Write a program to reverse the direction of a given singly-linked list. In other
#words, after the reversal all pointers should now point backwards. Your algorithm
#should take linear time.

#We have implemented the interfqce for this. Simply iterate the linked list, and build it up from behind recusively

elements = 1:10

include("../../src/BasicLists.jl")
using .BasicLists

list = StaticListNode(elements...)
reversed_list = reverse(list)
#collect...
reversed_vector = collect(reversed_list)
println(reversed_vector)
#However, if we want to do this in O(1) memory, we most use the mutable version.
#This is achieved by creating an emtpy node , say prev_node, then going thru the list from the beginning
# At each iteration, get the next node (next_node)
#Update the current nodes pointer to point to the prev_node
#Update prev_node to be the current node
#Update the current_node to be next_node
#Repeat until teh current node remains a non-end-node
#Return the new head.

#This operates in-place and thus only uses O(1) aux memory at any moment.

mlist = MListNode(elements...)
y = reverse!(mlist)
reversed_list = collect(y)
println(reversed_list)

#= 
We have seen how dynamic arrays enable arrays to grow while still achieving
constant-time amortized performance. This problem concerns extending dynamic
arrays to let them both grow and shrink on demand.

(a) Consider an underflow strategy that cuts the array size in half whenever the
array falls below half full. Give an example sequence of insertions and deletions
where this strategy gives a bad amortized cost.
(b) Then, give a better underflow strategy than that suggested above, one that
achieves constant amortized cost per deletion.
=#

#a) Consider an array odf length 2*N, which currently has N + 1 elements. Removing an element would trigger a resize to N; 
# however an immiddiate adition would trigger a resize to 2N again. Thus, for a series of such removal/aditions J times, 
# approx J N / 2 allocations/copies would take place.

#b) If we use any ratio that significantly lower than N/2, this problem goes away, i.e. we resize when we hit N/4.

#= 
[3] Design a dictionary data structure in which search, insertion, and deletion can
all be processed in O(1) time in the worst case. You may assume the set elements
are integers drawn from a finite set 1, 2, .., n, and initialization can take O(n) time.
=#

#= 
This is fairly trivial. We may use a (dense) boolean vector of N elements, since indexing (membership checks) is O(1) 
and we are never resizing. Insertion/deletion is just flipping the boolean flags. The hash is just identity in this case.
=#

#=
3] Find the overhead fraction (the ratio of data space over total space) for each
of the following binary tree implementations on n nodes:
(a) All nodes store data, two child pointers, and a parent pointer. The data field
requires four bytes and each pointer requires four bytes.
(b) Only leaf nodes store data; internal nodes store two child pointers. The data
field requires four bytes and each pointer requires two bytes.
=#

#= Assume that N is a power of two - 1 (i.e. tree is full). 
First case: 1/4, assuming that the leaf nodes also have pointers (even if left as garbage), since each node has 12 bits of aux pointers, and just
4 bytes of data.
Second case: I would be interetsed in how we can avoid storing data in internal nodes, but alas. If we accept this as grand truth:
N/2 -1 of the nodes story only 8 bytes of pointers: N/2 nodes store only store data of 8 bytes, 
putting us at t 1/2  for sufficently large N.
=#

#=
[5] Describe how to modify any balanced tree data structure such that search,
insert, delete, minimum, and maximum still take O(log n) time each, but successor
and predecessor now take O(1) time each. Which operations have to be modified
to support this?
=#

#= The O(1) requriement strongly suggests that we need to some form of doubly-linked list.
During construction, we can sort the array, and do an O(n) construction from teh sorted array. This allows for O(1)
identification of predeccsor/successor. 

Let each BST node further maintain its in-order predecessor and sucessor as pointers.

Deletion: Identify the key via lg(N) search. Remove it from the tree (logN to rotate everything up), while setting its predecessor's successor 
pointer to point to the now-deleted node's successor, and vica versa (effectiely a DLL deletion in O(1))

For insertion: Idenetify the new node's location via regular search in log(N) time. 
We may then update it's parent predecssor/sucessor ndes in lg(N) time, via re-computing its predecessor and post-node:
to find predecessor: find maximum element in its left' subtree. For post, find the minium element in its right subtree (both takes lg(N) time.
Once such are found, we can update the 4x pointers in O(1) time.

If it lacks either subtree, just use the already maintained pointers. 

=#


#=
[5] Suppose you have access to a balanced dictionary data structure, which supports
each of the operations search, insert, delete, minimum, maximum, successor, and
predecessor in O(log n) time. Explain how to modify the insert and delete operations
so they still take O(log n) but now minimum and maximum take O(1) time. (Hint:
think in terms of using the abstract dictionary operations, instead of mucking about
with pointers and the like.)
=#

#Just maintain a minimum-maximum auxillary data in the tree head. Once inserting a node, these can be updated in O(1) tine,
#whereas during deletetion, if node matches the min/max, we can find its predecessor/succesor in log(N) time and update the min/max values.
#Retriving these two auxiallry values is just O(1) as requested, and none of the operatons incur dditional cost.

#=

[6] Design a data structure to support the following operations:
• insert(x,T) – Insert item x into the set T.
• delete(k,T) – Delete the kth smallest element from T.
• member(x,T) – Return true iﬀ x ∈ T.
All operations must take O(log n) time on an n-element set.

=#

#= This sounds like set design using a DST and an underlying secondary structure
Aside from the delete operation, all such can be done in log(N) time in a BST. 

This strongly suggests that this will be yet another BST variant with some metadata.
Maintain the size of each subtree rooted at a node. This can be initially be constructed during construction.

When inserting a node, as we traverse down the tree, increase the "size" attribute of each visited node by +1. (log(N) operation).
When we wish to delete the k-th smallest element


=#