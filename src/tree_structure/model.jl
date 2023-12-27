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

function DemandFunction(    consumer::ConsumerRef,
    demands::Vector{Tuple{CommodityRef,Float64}},
    endowments::Vector{Tuple{CommodityRef,Float64}},
    )
    
    return new_DemandFunction(consumer,demands,endowments)
end


mutable struct MPSGEModel <: abstract_mpsge_model
    _object_dict::Dict{Symbol,Any}

    _productions::Vector{new_Production}
    _demands::Vector{new_DemandFunction}
    MPSGEModel() = new(Dict{Symbol,Any}(), [],[])

    _jump_model::Union{Nothing,JuMP.Model}
    _status

    _nlexpressions::Any
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
