module PrintResults

export printresults, printstats

using Formatting

# Function to print results to standard output
function printresults(x::Matrix{Int}, p::Matrix{Float64}, f::Matrix{Float64}, PlayerScore::Matrix{Float64}, GameScore::Vector{Float64}, TotalScore::Float64)

    const (M, N) = size(x)

    println("Players:\n")
    for i = 1:M
        for j = 1:N
            #@printf("%5d ", x[i,j])
            printfmt("{:5d} ", x[i,j])
        end
        println()
    end

    println("\nActive Player Fatigue:\n")
    for i = 1:M
        for j = 1:N
            @printf("%6.1f ", p[i,j])
        end
        println()
    end

    println("\nOverall Player Fatigue:\n")
    for i = 1:M
        for j = 1:N
            @printf("%6.1f ", f[i,j])
        end
        println()
    end

    println("\nActive Player Scores:\n")
    for i = 1:M+1
        for j = 1:N
            if i <= M
                @printf("%6.1f ", PlayerScore[i,j])
            else
                @printf("%6.1f ", GameScore[j])
                j == N ? @printf("%8.1f", TotalScore) : ()
            end
        end
        println()
        i == M ? @printf("%41s\n", "SUM") : ()
    end
end

# Function to print results to a file
function printstats(filename::String, x::Matrix{Int}, p::Matrix{Float64}, f::Matrix{Float64},
                    PlayerScore::Matrix{Float64}, GameScore::Vector{Float64}, TotalScore::Float64)

    const (M, N) = size(x)

    file = open(filename, "w")

    println(file, "Players:\n")
    for i = 1:M
        for j = 1:N
            #@printf("%5d ", x[i,j])
            printfmt(file, "{:5d} ", x[i,j])
        end
        println(file)
    end

    println(file, "\nActive Player Fatigue:\n")
    for i = 1:M
        for j = 1:N
            @printf(file, "%6.1f ", p[i,j])
        end
        println(file)
    end

    println(file, "\nOverall Player Fatigue:\n")
    for i = 1:M
        for j = 1:N
            @printf(file, "%6.1f ", f[i,j])
        end
        println(file)
    end

    println(file, "\nActive Player Scores:\n")
    for i = 1:M+1
        for j = 1:N
            if i <= M
                @printf(file, "%6.1f ", PlayerScore[i,j])
            else
                @printf(file, "%6.1f ", GameScore[j])
                j == N ? @printf(file, "%8.1f", TotalScore) : ()
            end
        end
        println(file)
        i == M ? @printf(file, "%41s\n", "SUM") : ()
    end
    close(file)
end

end
