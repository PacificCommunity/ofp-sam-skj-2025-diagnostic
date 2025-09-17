## Prepare plots and tables for report

## Before: biology.csv, summary.csv (output)
## After:  biology.csv, summary.csv (report)

library(TAF)

mkdir("report")

# Read tables
biology <- read.taf("output/biology.csv")
summary <- read.taf("output/summary.csv")

# Format tables
biology <- rnd(biology, 2:5, c(1, 1, 3, 3))
summary <- div(summary, 2:6, 10^c(6,3,3,3,3))
summary <- rnd(summary, 2:8, c(0, 0, 0, 0, 0, 2, 2))
biology <- format(biology)  # retain trailing zeros
summary <- format(summary)  # retain trailing zeros

# Write tables
write.taf(biology, dir="report")
write.taf(summary, dir="report")
