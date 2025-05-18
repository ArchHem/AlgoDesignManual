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

#We have implemented the interafce for this. Simply iterate the linked list, and build it up from behind recusively

elements = 1:10

include("../../src/BasicLists.jl")
using .BasicLists

list = SimpleLinkedList(elements...)
reversed_list = reverse(list)
#collect...
reversed_vector = collect(reversed_list)
