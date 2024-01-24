struct new_Production
    sector::SectorRef
    input::input_tree
    output::output_tree
end

function Production(sector::SectorRef,input::input_tree,output::output_tree)

    return new_Production(sector,input,output)
end

struct new_DemandFunction
    consumer::ConsumerRef
    demands::Vector{Tuple{CommodityRef,Float64}}
    endowments::Vector{Tuple{CommodityRef,Float64}}
end

function DemandFunction(consumer::ConsumerRef,
                        demands::Vector{Tuple{CommodityRef,Float64}},
                        endowments::Vector{Tuple{CommodityRef,Float64}},
    )
    
    return new_DemandFunction(consumer,demands,endowments)
end


mutable struct MPSGEModel <: abstract_mpsge_model
    _object_dict::Dict{Symbol,Any}

    _productions::Vector{new_Production}
    _demands::Vector{new_DemandFunction}


    _jump_model::Union{Nothing,JuMP.Model}
    _status

    _nlexpressions::Dict{Symbol,Any}

    MPSGEModel() = new(Dict{Symbol,Any}(), [],[],nothing,nothing,Dict{Symbol,Any}())
end


function add!(m::MPSGEModel, p::new_Production)
    m._jump_model = nothing

    push!(m._productions, p)
    return m
end

function add!(m::MPSGEModel, c::new_DemandFunction)
    m._jump_model = nothing

    push!(m._demands, c)
    return m
end


###########
## Taxes ##
###########
function get_taxes(P::Union{input_tree{CommodityRef},output_tree{CommodityRef}})
    return [(P.name,P.tax)]
end

function get_taxes(P::netput_tree)
    out = []
    for T in P.children
        push!(out, get_taxes(T)...)
    end
    return out
end

function get_taxes(P::new_Production)
    out = get_taxes(P.input)
    push!(out, get_taxes(P.output)...)
    return [(a,t) for (a,t) in out if t!=[]]
end