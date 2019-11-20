using JuMP, Gurobi, CSV, DataFrames, PyPlot#, Net
close("all")

lines = CSV.read("lines.csv")
demands = CSV.read("demands.csv")
generators = CSV.read("generators.csv")
n_lines = size(lines,1)
n_demands = size(demands,1)
n_generators = size(generators,1)
new_lines = collect(find(i->(lines[i,end]>0),lines[1]))
old_lines = collect(find(i->(lines[i,end]==0),lines[1]))
n_nodes = 6
nodes = collect(1:n_nodes)
σ = 8760

an_budget = 3.0*10e5

#construction of the model
m = Model(solver = GurobiSolver())
@variables m begin
    x[1:size(new_lines,1)], Bin #binary variable that corresponds to the investment decision
    pL[1:n_lines] #power flow through the transmission line i
    pE[1:n_generators] #power produced by gnerating unit i
    pLS[1:n_demands] #load shed by demand d
    θ[1:n_nodes] #volatge angle at the node i
end
@objective(m, Min, lines[new_lines,end]'*x + σ*(generators[end]'*pE + demands[end]'*pLS))
@constraint(m, mycon, lines[new_lines,end]'*x <= an_budget)
@constraint(m, [n in nodes], sum(pE[i] for i in generators[:,1] if generators[i,2] == n)- sum(pL[i] for i in lines[:,1] if lines[i,2]==n) +
sum(pL[i] for i in lines[:,1] if lines[i,3]==n) == sum(demands[i,3]-pLS[i] for i in demands[:,1] if demands[i,2] == n))
@constraint(m, [l in old_lines], pL[l]==lines[l,4]*(θ[lines[l,2]]-θ[lines[l,3]]))
#@constraint(m, [l in old_lines], -lines[l,5]<= pL[l] <=lines[l,5])
@constraint(m, [l in old_lines], pL[l] >= -lines[l,5])
@constraint(m, [l in old_lines], pL[l] <=lines[l,5])
@constraint(m, [l in new_lines], -x[l-size(old_lines,1)]*lines[l,5]<= pL[l])
@constraint(m, [l in new_lines], pL[l]<=x[l-size(old_lines,1)]*lines[l,5])
#@constraint(m, [g in generators[:,1]], 0<=pE[g]<=generators[g,3])
@constraint(m, [g in generators[:,1]], pE[g]>=0)
@constraint(m, [g in generators[:,1]], pE[g]<=generators[g,3])
#@constraint(m, [d in demands[:,1]], 0<=pLS[d]<=demands[d,3])
@constraint(m, [d in demands[:,1]], pLS[d]>=0)
@constraint(m, [d in demands[:,1]], pLS[d]<=demands[d,3])
#@constraint(m, [n in nodes], -pi<=θ[n]<=pi)
@constraint(m, [n in nodes], θ[n]>=-pi)
@constraint(m, [n in nodes], θ[n]<=pi)
setvalue(θ[1],0)

budget = collect(0:0.1:5)
#complementary matrix
intervals = [0 0.7 1.4 1.6 2.3 3.0 3.4 4.8 4];
result = Matrix(size(intervals,2)-1, size(new_lines,1)+2)
result[:,1] = [["["*string(intervals[i])*", "*string(intervals[i+1])*")" for i = 1:size(intervals,2)-2];  "[4.0, ∞)"]
interval_ind = 1;
#complementary matrix. first row is total cost, second investment cost, third is generating cost
cost = zeros(4,size(budget,1))


for i = 1:size(budget,1)
    JuMP.setRHS(mycon, budget[i]*10e5)
    ## Solve Model
    #println(m)
    status = solve(m);
    res_x = getvalue(x)
        println(res_x)
    cost[:,i] = [getobjectivevalue(m) σ*(getvalue(pE)'*generators[:,end]) σ*(getvalue(pLS)'*demands[:,end]) res_x'*lines[new_lines[1]:new_lines[end],end]]
    println(res_x)

    if budget[i] >= intervals[interval_ind] && budget[i] <= intervals[interval_ind+1] && interval_ind <= size(intervals,2)-2
        result[interval_ind,2:end] = hcat(res_x', cost[1,i]);
        interval_ind+=1;
    elseif budget[i] >= intervals[interval_ind] && interval_ind == size(intervals,2)-1
        result[interval_ind,2:end] = hcat(res_x', cost[1,i]);
    end
end
result = vcat(hcat("interval", collect(new_lines[1]:new_lines[end])', "cost"), result)
#plot
figure("total cost and generation_cost")
plot(budget,cost[1,:], "--", label = "total_cost")
plot(budget,cost[2,:], "--", label = "generation_cost")
xlabel("annualized investment budget")
ylabel("annualized cost")
legend()

figure("load shedding cost and investment cost")
plot(budget,cost[3,:], "--", label = "load shedding cost")
plot(budget,cost[4,:], "--", label = "investment cost")
xlabel("annualized investment budget")
ylabel("annualized cost")
legend()

#Net.print_net(lines)
