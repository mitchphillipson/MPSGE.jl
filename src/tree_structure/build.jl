function build(m::MPSGEModel)

    m._jump_model = JuMP.Model()

    build_variables!(m)


end



function build_variables!(m::MPSGEModel)
    
    jm = m._jump_model

    #This may be a bit much
    for (name,var) in m._object_dict
        add_variable!(jm, var)
    end


end




function build_equations(M::MPSGEModel, P::new_Production)
    jm = M._jump_model
    out = find_path_to_leaves(jm, P.input)
    push!(out,find_path_to_leaves(jm,P.output)...)

    return out

end

function build_equation(jm::JuMP.Model, m::netput_tree)
    if m.elasticity == 1
        out = cobb_douglass(jm,m)
    else
        out = Lp(jm,m)
    end
    return out
end


function build_equation(jm::JuMP.Model, m::input_tree{CommodityRef})
    return jm[get_name(m.name)]*(1+ sum(tax for (_,tax) in m.tax; init=0))/m.reference_price
end

function build_equation(jm::JuMP.Model, m::output_tree{CommodityRef})
    return jm[get_name(m.name)]*(1+ sum(tax for (_,tax) in m.tax; init=0))/m.reference_price
end

function cobb_douglass(jm::JuMP.Model, m::netput_tree)
    prod(build_equation(jm,child)^(child.quantity/m.quantity) for child in m.children)
end

function Lp(jm::JuMP.Model, m::netput_tree)
    sum( child.quantity/m.quantity*build_equation(jm,child)^(1-m.elasticity) for child in m.children)^(1/(1-m.elasticity))
end



function find_path_to_leaves(jm::JuMP.Model, T::netput_tree)
    parent = T.name
    return find_paths(jm, parent, T, 1)
end
    
function find_path_to_leaves(jm::JuMP.Model, T::Union{input_tree{CommodityRef},output_tree{CommodityRef}})
    return T.quantity
end


function find_paths(jm::JuMP.Model,parent::Symbol, T::netput_tree,eqn)
    out = []
    parent = T.name
    for child in T.children
        if T.elasticity == 0
            e = eqn
        else
            e = eqn*(build_equation(jm, T)/build_equation(jm, child))^T.elasticity
        end
        push!(out, find_paths(jm, parent, child,e)...)
    end
    return out
end

function find_paths(jm::JuMP.Model, parent::Symbol, T::input_tree{CommodityRef},eqn)
    return [(T, parent, -1 * eqn*T.quantity)]
end

function find_paths(jm::JuMP.Model, parent::Symbol, T::output_tree{CommodityRef},eqn)
    return [(T, parent, 1 * eqn*T.quantity)]
end


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