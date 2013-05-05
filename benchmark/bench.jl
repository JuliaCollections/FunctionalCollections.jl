using Benchmark

function printresults(descriptions, df)
    replications = df["Replications"][1]
    results = zip(df["Elapsed"], df["Relative"], descriptions)
    @printf("%8s%12s    %s\n", "Elapsed", "Relative", "Description")
    for (elapsed, relative, desc) in results
        @printf("%8f%12f    %s\n", elapsed, relative, desc)
    end
end

macro bench(title, iterations, fns)
    descriptions = map(string, fns.args)
    quote
        df = compare($(esc(fns)), $iterations)
        println(string($title, "\n", repeat("-", $(length(title)))))
        printresults($descriptions, df)
        println()
    end
end
