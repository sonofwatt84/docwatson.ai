# Shiny Modules
valFn <- function(x){round(x,1)}
minFn <- function(x){max(round(x) - 10,0.1)}
maxFn <- function(x){min(round(x) + 10,Inf)}
