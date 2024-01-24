function build(m::MPSGEModel)

    m._jump_model = JuMP.Model()

    build_variables!(m)

    for v in JuMP.all_variables(m._jump_model)
        set_start_value(v,1)
    end

    m._nlexpressions[:A] = build_A_matrix(m)
    m._nlexpressions[:taxes] = build_tax_matrix(m)
    m._nlexpressions[:tau] = build_tau_matrix(m)
    m._nlexpressions[:endowments] = build_endowment_matrix(m)
    m._nlexpressions[:demands] = build_demand_matrix(m)

    build_constraints(m)
end


function build_variables!(m::MPSGEModel)
    
    jm = m._jump_model

    #This may be a bit much
    for (name,var) in m._object_dict
        add_variable!(jm, var)
    end


end

"""
    build_A_matrix(M::MPSGEModel)

Currently this returns a commodity X sector matrix containing the recursively created 
equations.

This should change to be a commodity X sector X nest matrix. Currently we sum over nests 
upon creation.
"""
function build_A_matrix(M::MPSGEModel)

    A = Containers.DenseAxisArray{Union{Float64,JuMP.NonlinearExpr}}(undef,commodities(M),sectors(M))
    fill!(A,0.)
    
    for P in M._productions
        S = get_full(P.sector)
        for (C,nest,eqn) in build_equations(M,P)
            A[get_full(C.name),S] += eqn
        end
    end

    return A
end


"""
    build_tax_matrix(M::MPSGEModel)

Return a commodity X sector X consumer matrix containing the taxes. 

This may need a nest dimension, but we're currently summing over the nests.
"""
function build_tax_matrix(m::MPSGEModel)

    taxes = Containers.DenseAxisArray{Float64}(undef,commodities(m),sectors(m),consumers(m))
    fill!(taxes,0.)

    for P in m._productions
        for (commodity,tax) ∈ get_taxes(P)
            for (consumer,t) in tax
                taxes[get_full(commodity),get_full(P.sector),get_full(consumer)] += t
            end
        end
    end
    return taxes
end


function build_tau_matrix(m::MPSGEModel)

    tau = Containers.DenseAxisArray{Union{Float64,JuMP.NonlinearExpr}}(undef,sectors(m),consumers(m))#,commodities)

    jm = m._jump_model

    A = m._nlexpressions[:A]
    taxes = m._nlexpressions[:taxes]

    for s∈sectors(m),h∈consumers(m)
        tau[s,h] = -sum(A[c,s]*taxes[c,s,h]*get_jump_variable(jm,c) for c∈commodities(m) if taxes[c,s,h]>0;init=0.0);
    end
    return tau
end


function build_endowment_matrix(m::MPSGEModel)
    endowments = Containers.DenseAxisArray{Float64}(undef,consumers(m),commodities(m))
    fill!(endowments,0)
    
    
    for demand in m._demands
        consumer = get_full(demand.consumer)
        for (commodity,endowment) in demand.endowments
            endowments[consumer,get_full(commodity)] = endowment
        end
    end
    return endowments

end

function build_demand_matrix(m::MPSGEModel)
    demands = Containers.DenseAxisArray{Union{Float64,JuMP.NonlinearExpr}}(undef,consumers(m),commodities(m))
    fill!(demands,0.)

    jm = m._jump_model

    for demand in m._demands
        consumer = get_full(demand.consumer)
        (commodity,quantity) = demand.demands[1]
        demands[consumer,get_full(commodity)] = get_jump_variable(jm,consumer)/get_jump_variable(jm,commodity)
        set_start_value(get_jump_variable(jm,consumer),quantity)
    end
    return demands
end


function build_constraints(m::MPSGEModel)
    jm = m._jump_model
    A = m._nlexpressions[:A]
    taxes = m._nlexpressions[:taxes]
    tau = m._nlexpressions[:tau]
    endowments = m._nlexpressions[:endowments]
    demands = m._nlexpressions[:demands]

    @constraint(jm, zero_profit[s = sectors(m)],
    -sum(A[c,s]*get_jump_variable(jm,c) for c∈commodities(m)) + sum(tau[s,h] for h∈consumers(m)) ⟂ get_jump_variable(jm,s)
    )
    
    
    @constraint(jm, market_clearance[c= commodities(m)],
    sum(A[c,s]*get_jump_variable(jm,s) for s∈sectors(m)) + sum(endowments[h,c] - demands[h,c] for h∈consumers(m)) ⟂ get_jump_variable(jm,c)
    )
    
    
    @constraint(jm, income_balance[h = consumers(m)],
    get_jump_variable(jm,h) - ( sum(endowments[h,c]*get_jump_variable(jm,c) for c∈commodities(m)) + sum(tau[s,h]*get_jump_variable(jm,s) for s∈sectors(m))) ⟂ get_jump_variable(jm,h)
    )

    return 
end


########################
## Building Equations ##
########################

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

#######################
## Utility Functions ##
#######################

function cobb_douglass(jm::JuMP.Model, m::netput_tree)
    prod(build_equation(jm,child)^(child.quantity/m.quantity) for child in m.children)
end

function Lp(jm::JuMP.Model, m::netput_tree)
    sum( child.quantity/m.quantity*build_equation(jm,child)^(1-m.elasticity) for child in m.children)^(1/(1-m.elasticity))
end

####################
## Tree Traversal ##
####################

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


