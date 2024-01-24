"""
    convert_mpsge_expr_to_jump_nonlinearexpr(jm, expr)

This function takes an expression tree and replaces all instances of
MPSGE types with corresponding JuMP types and converts `Expr`s into
`JuMP.NonlinearExpr`.
"""
function convert_mpsge_expr_to_jump_nonlinearexpr(jm, expr)
    return MacroTools.postwalk(expr) do x
        if x isa Expr
            if x.head==:call
                JuMP.NonlinearExpr(x.args[1], x.args[2:end])
            else
                error("Found illegal Expr in tree: $x.")
            end
        else
            get_jump_variable(jm,x)
        end
    end
end

"""
swap_our_param_with_val(expr)

This function takes an expression tree and replaces all instances of
`ParameterRef` with its value.
"""
function swap_our_param_with_val(expr)
    return MacroTools.postwalk(expr) do x
        if x isa MPSGERef
            return get_value(x)
        else
            return x
        end
    end
end

"""
contains_our_param(expr)

This function takes an expression tree and tests whether it contains
a `ParameterRef` or `CommodityRef`
"""
function contains_our_param(expr)
    if expr isa Expr
        for x in expr.args
            if contains_our_param(x)
                return true
            end
        end

        return false
    elseif expr isa ParameterRef || expr isa CommodityRef
        return true
    else
        return false
    end
end



function get_jump_variable(jm, V::MPSGERef)
    if V.subindex===nothing
        return jm[get_name(V)]
    else
        return jm[get_name(V)][V.subindex]
    end
end

function get_jump_variable(jm, S::MPSGEVariable)
    return jm[get_name(S)]
end


function get_jump_variable(jm, x)
    return x
end


function get_expression_for_commodity_producer_price(jm, pf, commodity::CommodityRef)

    taxes = []
        for output in pf.outputs
            if output.commodity == commodity
                for tax in output.taxes
                    push!(taxes, tojump(jm, tax.rate))
                end
            end
        end

    return tojump(jm, commodity) * (1. - +(0., taxes...))
end

function get_expression_for_commodity_consumer_price(jm, pf, commodity::CommodityRef)

    taxes = []
    for input in pf.inputs
        if input.commodity == commodity
            for tax in input.taxes
                push!(taxes, tojump(jm, tax.rate))
            end
        end
    end

    return tojump(jm, commodity) * +(1., taxes...)
end



# function get_tax_revenue_for_consumer(jm, m, consumer::ScalarConsumer)
#     taxes = []
#     for pf in productions(m)
#         for output in pf.outputs
#             for tax in output.taxes
#                 if get_full(tax.agent) == consumer
#                     push!(taxes, tojump(jm, tax.rate) * tojump(jm, output.quantity) * tojump(jm, output.commodity) * tojump(jm, pf.sector) )
#                 end
#             end
#         end
#         for input in pf.inputs
#             for tax in input.taxes
#                 if get_full(tax.agent) == consumer
#                     push!(taxes, tojump(jm, tax.rate) * tojump(jm, input.quantity) * tojump(jm, input.commodity) * tojump(jm, pf.sector) )
#                 end
#             end
#         end
#     end

#     tax = +(0., taxes...)

#     return tax
# end

function get_tax_revenue_for_consumer(jm, m, cr::ConsumerRef)
    taxes = []
    for pf in productions(m)
        for output in pf.outputs
            for tax in output.taxes
                if cr.subindex === nothing
                    if get_full(tax.agent) == get_full(cr)    
                        push!(taxes, tojump(jm, tax.rate) * jm[get_comp_supply_name(output)] * tojump(jm, output.commodity) * tojump(jm, pf.sector))
                    end
                else
                    if jm[get_full(cr).name][tax.agent.subindex] ==  jm[get_full(cr).name][cr.subindex]
                        push!(taxes, tojump(jm, tax.rate) * jm[get_comp_supply_name(output)] * tojump(jm, output.commodity) * tojump(jm, pf.sector))
                    end
                end    
            end
        end
        for input in pf.inputs
            for tax in input.taxes
                if cr.subindex === nothing
                    if get_full(tax.agent) == get_full(cr)    
                        push!(taxes, tojump(jm, tax.rate) * jm[get_comp_demand_name(input)] * tojump(jm, input.commodity) * tojump(jm, pf.sector))
                    end
                else
                    if jm[get_full(cr).name][tax.agent.subindex] ==  jm[get_full(cr).name][cr.subindex]
                        push!(taxes, tojump(jm, tax.rate) * jm[get_comp_demand_name(input)] * tojump(jm, input.commodity) * tojump(jm, pf.sector))
                    end
                end    
            end
        end
    end

    tax = +(0., taxes...)

    return tax
end

function get_tax_revenue_for_consumer_old(jm, m, consumer::ScalarConsumer)
    taxes = []
    for pf in productions(m)
        for output in pf.outputs
            for tax in output.taxes
                if get_full(tax.agent) == consumer
                    push!(taxes, :($(tax.rate) * $(output.quantity) * $(output.commodity) * $(pf.sector) ))
                end
            end
        end
        for input in pf.inputs
            for tax in input.taxes
                if get_full(tax.agent) == consumer
                    push!(taxes, :($(tax.rate) * $(input.quantity) * $(input.commodity) * $(pf.sector) ))
                end
            end
        end
    end

    tax = :(+(0., $(taxes...)))

    return tax
end

function get_tax_revenue_for_consumer_old(jm, m, cr::ConsumerRef)
    taxes = []
    for pf in productions(m)
        for output in pf.outputs
            for tax in output.taxes
                if cr.subindex === nothing
                    if get_full(tax.agent) == get_full(cr)    
                        push!(taxes, :($(tax.rate) * $(jm[get_comp_supply_name(output)]) * $(output.commodity) * $(pf.sector)))
                    end
                else
                    if jm[get_full(cr).name][tax.agent.subindex] ==  jm[get_full(cr).name][cr.subindex]
                        push!(taxes, :($(tax.rate) * $(jm[get_comp_supply_name(output)]) * $(output.commodity) * $(pf.sector)))
                    end
                end    
            end
        end
        for input in pf.inputs
            for tax in input.taxes
                if cr.subindex === nothing
                    if get_full(tax.agent) == get_full(cr)    
                        push!(taxes, :($(tax.rate) * $(jm[get_comp_demand_name(input)]) * $(input.commodity) * $(pf.sector)))
                    end
                else
                    if jm[get_full(cr).name][tax.agent.subindex] ==  jm[get_full(cr).name][cr.subindex]
                        push!(taxes, :($(tax.rate) * $(jm[get_comp_demand_name(input)]) * $(input.commodity) * $(pf.sector)))
                    end
                end    
            end
        end
    end

    tax = :(+(0., $(taxes...)))

    return tax
end


function get_prod_func_name(x::Production)
    return Symbol("$(get_name(x.sector, true))")
end

function get_demand_func_name(x::DemandFunction)
    return Symbol("$(get_name(x.consumer, true))")
end

function get_comp_supply_name(o::Output)
    p = o.production_function::Production
    return Symbol("$(get_name(o.commodity, true))‡$(get_prod_func_name(p))")
end

function get_final_demand_name(demand::Demand)
    demand_function = demand.demand_function::DemandFunction
    return Symbol("$(get_name(demand.commodity, true))ρ$(get_demand_func_name(demand_function))")
end

function get_comp_demand_name(i::Input)
    p = i.production_function::Production 
    return Symbol("$(get_name(i.commodity, true))†$(get_prod_func_name(p))")
end

function tojump(jm, x::Float64)
    x
end

function tojump(jm, x::Expr)
    convert_mpsge_expr_to_jump_nonlinearexpr(jm, x)
end

function tojump(jm, x::MPSGERef)
    get_jump_variable(jm, x)
end

function tojump(jm, x::ImplicitvarRef)
    get_jump_variable(jm, x)
end

function tojump(jm, x::JuMP.VariableRef)
    x
end
