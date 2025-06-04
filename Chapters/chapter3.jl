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
When we wish to delete the k-th smallest element, we traverse as it follows: Keep note of the total size of the tree (i.e. size at head node)
The left subtree at each location include the "smaller" elements. By keeping track of how many of the smallest and largest elements (i.e. size of left and right subtree)
we ignored, we can keep that what range does our subtree include (i.e. from i-th smallest to j-th smallest).

Let the initial range be 1 to N
This is achieved as follows: At each node, with count 
-if we traverse left, we now update our range as: (i, j) = i, min(j, N_left)
-if we traverse right, we now update our range as: (i, j) = max(i, N_right), j

#That is, we traverse to the k-th element, we always want to keep in range. 

We do this via: 

find_kth(k, node)
    if k <= node.left.size
        find_kth(k,node.left)
    elseif k == node.leftt.size + 1 #current node is k-th
        return node
    else
        find_kth(k - node.right.size - 1, k.right) #array had been shifted to right, and the current node can also be discounted.

#Once the node is deleted, the node that we visite during travelsal (i.e., via storing their pointers 
for instance) need to have their count to be decreased by 1.

=#

#=
3-9. [8] A concatenate operation takes two sets S1 and S2, where every key in S1
is smaller than any key in S2, and merges them together. Give an algorithm to
concatenate two binary search trees into one binary search tree. The worst-case
running time should be O(h), where h is the maximal height of the two trees.
=#

#=
In other words, this must must have log(N_max) time complexity.... this means we cant extract a sorted list and 
merge, and re-insert soreted lists.

Let the tree with the strictly smaller indeces be S1. We can then traverse S2 to its minima (log(N) time) and 
insert the full S1 tree there as the "left" pointer. This results in an unbalanced tree, but the BST property is fullfilled. 

Full rebalancing would incur an O(n) cost.

Option b) 

Get the maximum node of the smaller-keyed set, and detach it. Let it be the head of the a new BST, 
whose left subtree is the smaller-keyes bst, and its right is the larger-keyed bst. Such is less unbalanced.

#We could similarly get the minimnum node of the larger-keyed BST to serve as separator.

=#

#=
[5] In the bin-packing problem, we are given n metal objects, each weighing between
zero and one kilogram. Our goal is to find the smallest number of bins that will
hold the n objects, with each bin holding one kilogram at most.
• The best-fit heuristic for bin packing is as follows. Consider the objects in the
order in which they are given. For each object, place it into the partially filled
bin with the smallest amount of extra room after the object is inserted.. If
no such bin exists, start a new bin. Design an algorithm that implements the
best-fit heuristic (taking as input the n weights w1, w2, ..., wn and outputting
the number of bins used) in O(n log n) time.
• Repeat the above using the worst-fit heuristic, where we put the next object in
the partially filled bin with the largest amount of extra room after the object
is inserted.
=#

#=
This sounds a lot like a heap/BST problem.

Let a BST have nodes that store the currently used space in a bin as their keys, node.key. 
That is, by default, a node has a key of 0.

When we have a new weight, W, coming in, we want to find (if it exists)
the node with the the node with maximal key st. its key its smaller-or-equel-than U = 1-W still.

find_node(node, U)
    if node == nothing
        return nothing
    if node.key > U
        #search the smaller subtree
        return find_node(node.left, U)
    else
        candidate = find_node(node.right, U)
        if candidate != nothing
            return candidate
        else #current node is best so far
            return node

The above function can be used to find the node st. W + node.key (i.e. the reminaing space after insertion) is minimized. 
    The above search runs in log(N) time. 
    In case it return a node, we delete it, and insert a new one with a key of old key + W.
    In case it does not return a node, we insert a new node of value W.
    
Given N nodes, and a balanaced BST, the entire above procedure is bounded by log(N), and thus for N wiegths, by N log(N)

For the worst-fit heuretic, we need to find the key st. W + key is minimized, that is, we need to recourse the other way.
=#

#=
[5] Suppose that we are given a sequence of n values x1, x2, ..., xn and seek to
quickly answer repeated queries of the form: given i and j, find the smallest value
in xi, . . . , xj.
(a) Design a data structure that uses O(n2) space and answers queries in O(1)
time.
(b) Design a data structure that uses O(n) space and answers queries in O(log n)
time. For partial credit, your data structure can use O(n log n) space and have
O(log n) query time.
=#

#=
For a), we preocumpte all n^2 possible queries, and map them to a key (xi, xj). Construction of such takes O(n^2) space and time,
but answers querries in constant time.

b) strongly suggests using a BST/sorted array. 
TODO: Likely segment tree or smth? Never used them before.

=#

#=
[5] Suppose you are given an input set S of n numbers, and a black box that if
given any sequence of real numbers and an integer k instantly and correctly answers
whether there is a subset of input sequence whose sum is exactly k. Show how to
use the black box O(n) times to find a subset of S that adds up to k.
=#

#=
Clearly, checking all subsets is non-feasible.

Let us sort the input array. We can quickly turn it into an ordered hashset.

For each element, at index i, check if the rest of the set can still add up to k. If yes, delete the current element. 
If no, retain it (it is needed) 

After the last query, the remaining elements should form a subset which adds up to K.

Proof by contradiction: 
    Consider that after processing the last element, we still have an extra element at index j, which could be deleted from the current set, 
    so that the rest (set U) still adds up to K. 
    This is impossible. When we visited the earlier index j, all the elements in U, hence it would have been deleted.
    ->Proven.
=#