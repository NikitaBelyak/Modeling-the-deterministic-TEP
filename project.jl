# For loading module PrintResults
if (pwd() in LOAD_PATH) == false
    push!(LOAD_PATH, pwd())
end

# Three different objectives
@enum Objective OBJECTIVE_A OBJECTIVE_B OBJECTIVE_C

# Select objective A, B, or C
otype = OBJECTIVE_A

using JuMP
using Cbc
using Formatting
using PrintResults

m = Model(solver = CbcSolver())  # Declare solver when creating model
#setsolver(m, CbcSolver())       # Or declare solver like this


#### Input Data ####

# Player scores
c = [77, 62, 58, 41, 33, 33, 29, 28, 20, 18]
A = [1,2,3,4,5,9]   # Attackers
D = [6,7,8,10]      # Defenders
M = length(c)       # M = number of players
N = 5               # N = number of games


#### Decision variables ####

# x[i,j] = 1 if player i plays in game j
@variable(m, x[1:M, 1:N], Bin)

# Variable to model total accumulated penalty
@variable(m, p[1:M, 1:N] >= 0)

# Variable to model OR constraint
@variable(m, y, Bin)

# Variable to model max of min game score (Objective B)
otype == OBJECTIVE_B &&
@variable(m, z >=0)

# Variables to model piece-wise concave objective (Objective C)
otype == OBJECTIVE_C &&
@variable(m, λ[1:N] >= 0)


#### Expressions ####

# Compute Player fatigues as an expression
@expression(m, f[i=1:M,j=1:N], j == 1 ? 0 : sum(0.2*x[i,k] for k = 1:(j-1)) + 0.1*x[i,j-1])

# Player scores
@expression(m, PlayerScore[i=1:M,j=1:N], c[i]*(x[i,j] - p[i,j]))

# Game scores
@expression(m, GameScore[j=1:N], sum(PlayerScore[i=1:M,j]))

# Total score of all games
@expression(m, TotalScore, sum(GameScore[1:N]))

# Lineup for each game
@expression(m, Lineup[j=1:N], sum(x[1:M,j]))

# Marginal game scores
if otype == OBJECTIVE_C
    # Marginal game scores if GameScore >= 150
    @expression(m, MarginalScore[j=1:N], 75 .+ 0.5*GameScore[j])
    # Sum of lambda variables modeling marginal game scores
    @expression(m, TotalMarginalScore, sum(λ[1:N]))
end


#### Objectives for cases A, B, and C ####

otype == OBJECTIVE_A &&
@objective(m, Max, TotalScore)

otype == OBJECTIVE_B &&
@objective(m, Max, z)

otype == OBJECTIVE_C &&
@objective(m, Max, TotalMarginalScore)


#### Constraints ####

# Each starting lineup must contain exactly five players.
#@constraint(m, sum(x[i,1:N] for i = 1:M) .== 5)
@constraint(m, Lineup[1:N] .== 5)

# There must be at least two defenders in each lineup
@constraint(m, sum(x[i,1:N] for i in D) .>= 2)

# Constraint for player fatigues
@constraint(m, p[1:M,2:N] .>= f[1:M,2:N] .- 1 .+ x[1:M,2:N])


# In the last game, the starting lineup should
# include either (i) at least two of the attackers
# 4,5,9 and at most one of the players 6,7; or
# (ii) exactly three of the players 1,2,3,6,7

A1 = [4,5,9]
A2 = [6,7]
B  = [1,2,3,6,7]

@constraint(m, sum(x[i,N] for i in A1) >= 2 - 2*y)
@constraint(m, sum(x[i,N] for i in A2) <= 1 + y)
@constraint(m, sum(x[i,N] for i in B)  >= 3 - 3*(1-y))
@constraint(m, sum(x[i,N] for i in B)  <= 3 + 2*(1-y))

# Constraints for min game score z
otype == OBJECTIVE_B &&
@constraint(m, z .<= GameScore[1:N])

# Constraints for the piece-wise linear function
if otype == OBJECTIVE_C
    @constraint(m, λ[j=1:N] .<= GameScore[j])
    @constraint(m, λ[j=1:N] .<= MarginalScore[j])
end

# Solve the problem
status = solve(m)

# writeLP(m, "modelA.lp", genericnames=false)
# writeMPS(m, "modelA.mps")

obj = getobjectivevalue(m)
printfmt("\nObjective value: {:5.2f}\n\n", obj)

x = round.(Int, getvalue(x))
p = getvalue(p)
f = getvalue(f)

PlayerScore = getvalue(PlayerScore)
GameScore   = getvalue(GameScore)
TotalScore  = getvalue(TotalScore)

# Print results to standard output
PrintResults.printresults(x, p, f, PlayerScore, GameScore, TotalScore)

# Print results to file
if otype == OBJECTIVE_A
    printstats("resultsA.txt", x, p, f, PlayerScore, GameScore, TotalScore)
elseif otype == OBJECTIVE_B
    printstats("resultsB.txt", x, p, f, PlayerScore, GameScore, TotalScore)
else
    printstats("resultsC.txt", x, p, f, PlayerScore, GameScore, TotalScore)
end
