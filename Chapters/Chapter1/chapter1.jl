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