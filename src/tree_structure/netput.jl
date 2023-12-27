abstract type netput_tree end;

mutable struct input_tree{T} <: netput_tree
    name::T
    children::vector{input_tree}
    elasticity::Float64
    quantity::Float64
    reference_price::Float64
    input::Bool
    tax::Vector{Tuple{ConsumerRef,Float64}}
    input_tree(name::CommodityRef; quantity=1,reference_price=1,tax=[]) = new{CommodityRef}(name,[],0,quantity,reference_price,true,tax)
    input_tree(name::Symbol, elasticity = 0; children = []) = new{Symbol}(name,children,elasticity, sum(e.quantity for e∈children;init=0) ,1,false,[])
end


mutable struct output_tree{T} <: netput_tree
    name::T
    children::vector{output_tree}
    elasticity::Float64
    quantity::Float64
    reference_price::Float64
    input::Bool
    tax::Vector{Tuple{ConsumerRef,Float64}}
    output_tree(name::CommodityRef; quantity=1,reference_price=1,tax=[]) = new{CommodityRef}(name,[],0,quantity,reference_price,false,tax)
    output_tree(name::Symbol, elasticity = 0; children = []) = new{Symbol}(name,children,elasticity, sum(e.quantity for e∈children;init=0) ,1,false,[])
end




function update_quantities!(node::netput_tree{CommodityRef})
    return node.quantity
end


function update_quantities!(node::netput_tree)
    node.quantity = sum(update_quantities!(child) for child∈node.children)
    return node.quantity
end

function add_child!(parent::netput_tree,child::netput_tree)
    push!(parent.children,child)
end



##########
## Show ##
##########

function tree_string(m::netput_tree{Symbol};tab_level=0)
    out = ":$(m.name) = $(m.elasticity)\n"
    tab_level+=1
    for child in m.children
        out *= "  "^tab_level*"$(tree_string(child;tab_level = tab_level))\n"
    end
    return out
end


function tree_string(m::netput_tree{CommodityRef};tab_level=0)
    out = "I:$(m.name.name)    Q: $(m.quantity)"
    return out
end


function Base.show(io::IO, m::netput_tree{Symbol})
    out = tree_string(m)
    print(io,out)
    return
    
end

function Base.show(io::IO, m::netput_tree{CommodityRef})
    out = tree_string(m)
    print(io,out)
    return
end