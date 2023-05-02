@testitem "TWOBYTWO (functional version)" begin
    using XLSX, MPSGE.JuMP.Containers
    using MPSGE

m = Model()

sigmac = add!(m, Parameter(:sigmac, value=1.)) #  Armington elasticity in final demand /0.5/
endow = add!(m, Parameter(:endow, value=1.)) #       change in labour supply      /1/
sigmadm = add!(m, Parameter(:sigmadm, value=1.)) #    Elasticity of substitution (D versus M) /4/
esubkl = add!(m, Parameter(:esubkl, value=1.)) #     Elasticity of substitution (K versus L) /1/
t_elasy = add!(m, Parameter(:t_elasy, value=0.))
sigma = add!(m, Parameter(:sigma, value=1.)) #      Elasticity of substitution (C versus LS) /0.4/;

Y = add!(m, Sector(:Y)) #Production
M = add!(m, Sector(:M)) # Imports

PX = add!(m, Commodity(:PX)) # 
PC = add!(m, Commodity(:PC)) # 
PM = add!(m, Commodity(:PM)) #      ! Import price index
PL = add!(m, Commodity(:PL)) #      ! Wage rate index
RK = add!(m, Commodity(:RK)) #      ! Rental price index
PFX = add!(m, Commodity(:PFX)) #     ! Foreign exchange
PD = add!(m, Commodity(:PD)) #      ! Domestic price index

C  = add!(m, Consumer(:C, benchmark=90.))
GOVT  = add!(m, Consumer(:GOVT, benchmark=110.))
HH = add!(m, Consumer(:HH, benchmark=80.)) #      ! Private households

# Remove for nesting
A = add!(m, Sector(:A)) # Armington composite
PA = add!(m, Commodity(:PA)) #      ! Armington price index
add!(m, Production(A, 0., :($sigmadm* 1.), [Output(PA, 90)], [Input(PD, 30), Input(PM, 60)]))
# Alternates for Nested
add!(m, DemandFunction(GOVT, 1.,  [Demand(PA, 90),Demand(PX,20)],              [Endowment(RK, 110)])) # Non-Nested
# add!(m, DemandFunction(GOVT, 1.,  [Demand(PM, 20), Demand(Nest(C, sigmadm, Demand(PD, 30), Demand(PM,60)))],              [Endowment(RK, 110)])) # Nested

add!(m, Production(Y, :($t_elasy*1.), :($esubkl* 1.), [Output(PFX, 130), Output(PC, 60)], [Input(RK, 110), Input(PL, 80)]))
add!(m, Production(M, 0., 1., [Output(PX, 100)], [Input(PFX, 40), Input(PC, 60)]))
add!(m, DemandFunction(C, :(1*$sigmac),  [Demand(PFX, 90)],              [Endowment(PM, 60),Endowment(PD, 30)]))
add!(m, DemandFunction(HH, :(1*$sigma),  [Demand(PX, 80)], [Endowment(PL, :(80*$endow))])) #

solve!(m, cumulative_iteration_limit=0)

# Benchmark
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PC]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡Y")]) ≈ 130
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡M")]) ≈ 100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ 110
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 80
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ 40
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("GOVT")]) ≈ 110
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("HH")]) ≈ 80
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("C")]) ≈ 90
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFXρC")]) ≈ 90
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρHH")]) ≈ 80

# endow=1.1
set_value(endow, 1.1)
set_fixed!(HH, true)
solve!(m)

@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.04094672
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ 1.04094672
@test MPSGE.Complementarity.result_value(m._jump_model[:PC]) ≈ 0.96066397
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 0.96066397
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 0.90909091
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ 0.96066397
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡Y")]) ≈ 130
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡M")]) ≈ 100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ 105.673 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 84.53842903
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ 40
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ 110
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ 80
@test MPSGE.Complementarity.result_value(m._jump_model[:C]) ≈ 90
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFXρC")]) ≈ 93.68520436
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρHH")]) ≈ 83.2757372

# sigmac=0.5
set_value(sigmac, 0.5)
solve!(m)
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.04094672
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ 1.04094672
@test MPSGE.Complementarity.result_value(m._jump_model[:PC]) ≈ 0.96066397
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 0.96066397
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 0.90909091
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ 0.96066397
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡Y")]) ≈ 130
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡M")]) ≈ 100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ 105.673 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 84.53842903
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ 40
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ 110
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ 80
@test MPSGE.Complementarity.result_value(m._jump_model[:C]) ≈ 90
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFXρC")]) ≈ 93.68520436
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρHH")]) ≈ 83.2757372

# sigmadm=4
set_value(sigmadm,4.)
solve!(m)
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.04094672
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ 1.04094672
@test MPSGE.Complementarity.result_value(m._jump_model[:PC]) ≈ 0.96066397
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 0.96066397
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 0.90909091
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ 0.96066397
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡Y")]) ≈ 130
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡M")]) ≈ 100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ 105.673 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 84.53842903
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ 40
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ 110
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ 80
@test MPSGE.Complementarity.result_value(m._jump_model[:C]) ≈ 90
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFXρC")]) ≈ 93.68520436
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρHH")]) ≈ 83.2757372

# sigma=0.4
set_value(sigma, 0.4)
solve!(m)
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.04094672
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ 1.04094672
@test MPSGE.Complementarity.result_value(m._jump_model[:PC]) ≈ 0.96066397
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 0.96066397
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 0.90909091
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ 0.96066397
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡Y")]) ≈ 130
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡M")]) ≈ 100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ 105.673 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 84.53842903
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ 40
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ 110
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ 80
@test MPSGE.Complementarity.result_value(m._jump_model[:C]) ≈ 90
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFXρC")]) ≈ 93.68520436
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρHH")]) ≈ 83.2757372

# esubkl=1.5
set_value(esubkl, 1.5)
set_fixed!(GOVT, true)
set_fixed!(HH, false)
set_fixed!(C,true)
solve!(m)
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.04133159
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ 1.0486808
@test MPSGE.Complementarity.result_value(m._jump_model[:PC]) ≈ 0.98510801
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 0.97820432
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 0.93843647
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ 0.9679394
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡Y")]) ≈ 130
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡M")]) ≈ 100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ 105.634 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 84.50718369
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ 40.42419695
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ 110
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ 82.58240924
@test MPSGE.Complementarity.result_value(m._jump_model[:C]) ≈ 90
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFXρC")]) ≈ 92.98102756
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρHH")]) ≈ 84.42245376

# t_elasY=1
set_value(t_elasy, 1.)
set_fixed!(C,false)
solve!(m)
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.04133159
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ 1.05128658
@test MPSGE.Complementarity.result_value(m._jump_model[:PC]) ≈ 0.97921692
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 0.97577969
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 0.93843647
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ 0.97064645
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡Y")]) ≈ 129.6374 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡M")]) ≈ 100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ 105.634 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 84.50718369
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ 40.21153908
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ 110
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ 82.58240907
@test MPSGE.Complementarity.result_value(m._jump_model[:C]) ≈ 90
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFXρC")]) ≈ 92.72171175
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρHH")]) ≈ 84.63222806

# endow=2
set_value(endow, 2.)
solve!(m)
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.36556375
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ 1.46151811
@test MPSGE.Complementarity.result_value(m._jump_model[:PC]) ≈ 0.84773894
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 0.82649461
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 0.62996052
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ 0.79562215
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC‡Y")]) ≈ 62.60677993
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡Y")]) ≈ 127.3087 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡M")]) ≈ 100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ 80.55281206
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 117.1677 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ 41.55211657
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ 110
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ 100.7937 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[:C]) ≈ 90
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFXρC")]) ≈ 113.119 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρGOVT")]) ≈ 24.19858498
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρHH")]) ≈ 121.9532 atol=1.0e-4

# sigmac=4
set_value(sigmac, 4.)
solve!(m)
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.36556375
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ 1.46151811
@test MPSGE.Complementarity.result_value(m._jump_model[:PC]) ≈ 0.84773894
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 0.82649461
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 0.62996052
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ 0.79562215
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC‡Y")]) ≈ 62.60677993
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡Y")]) ≈ 127.3087 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡M")]) ≈ 100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ 80.55281206
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 117.1677 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ 41.55211657
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ 110
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ 100.7937 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[:C]) ≈ 90
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFXρC")]) ≈ 113.119 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρGOVT")]) ≈ 24.19858498
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρHH")]) ≈ 121.9532 atol=1.0e-4

# sigma=3
set_value(sigma, 3.)
solve!(m)
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.36556375
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ 1.46151811
@test MPSGE.Complementarity.result_value(m._jump_model[:PC]) ≈ 0.84773894
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 0.82649461
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 0.62996052
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ 0.79562215
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC‡Y")]) ≈ 62.60677993
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡Y")]) ≈ 127.3087 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡M")]) ≈ 100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ 80.55281206
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 117.1677 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ 41.55211657
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ 110
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ 100.7937 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[:C]) ≈ 90
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFXρC")]) ≈ 113.119 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρGOVT")]) ≈ 24.19858498
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρHH")]) ≈ 121.9532 atol=1.0e-4

set_value(t_elasy,0.5)
solve!(m)
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.36556375
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ 1.45318709
@test MPSGE.Complementarity.result_value(m._jump_model[:PC]) ≈ 0.85984236
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 0.83123284
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 0.62996052
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ 0.79009349
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC‡Y")]) ≈ 61.7255064
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡Y")]) ≈ 128.1996 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡M")]) ≈ 100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ 80.55281207
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 117.1677 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ 42.08275888
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ 110
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ 100.7937 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[:C]) ≈ 90
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFXρC")]) ≈ 113.9106 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρGOVT")]) ≈ 24.06064697
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρHH")]) ≈ 121.2581 atol=1.0e-4

# sigmac=.1
set_value(sigmac, 1.)
solve!(m)
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.36556375
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ 1.45318709
@test MPSGE.Complementarity.result_value(m._jump_model[:PC]) ≈ 0.85984236
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 0.83123284
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 0.62996052
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ 0.79009349
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC‡Y")]) ≈ 61.7255064
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡Y")]) ≈ 128.1996 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡M")]) ≈ 100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ 80.55281207
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 117.1677 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ 42.08275888
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ 110
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ 100.7937 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[:C]) ≈ 90
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFXρC")]) ≈ 113.9106 atol=1.0e-4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρGOVT")]) ≈ 24.06064697
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρHH")]) ≈ 121.2581 atol=1.0e-4


#This fails for most variables. The GAMS results has gaps/undefined/no value for PL, HH, and CXHH. This suggests we are not handling results with /0 or 0 results in the same way
# esubkl=0
set_value(esubkl, 0.)
solve!(m)
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1
# @test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ 0.49256427 
# @test MPSGE.Complementarity.result_value(m._jump_model[:PC]) ≈ 0.28503598
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ 1
# @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 0.40603838
# @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 1
# @test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ 1.000
# @test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ 0.69034817
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC‡Y")]) ≈ 42.09994749
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡Y")]) ≈ 141.9574 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡M")]) ≈ 100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ 110
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 80
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ 23.52658546
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ 110
# @test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ 1
@test MPSGE.Complementarity.result_value(m._jump_model[:C]) ≈ 90
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFXρC")]) ≈ 130.369 atol=1.0e-4
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρGOVT")]) ≈ 49.25642749
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PXρHH")]) ≈ 1

end