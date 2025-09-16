## Extract model fit results, write TAF output tables

## Before: 14.par, length.fit, plot-14.par.rep, test_plot_output (model)
## After:  cpue.csv, length.comps.csv, likelihoods.csv, stats.csv (output)

library(TAF)
taf.library(FLR4MFCL)
source("utilities.R")  # reading
source("read.MFCLSel.alt.r")
source("read.MFCLPar.alt.r")

mkdir("output")

# Read MFCL output files
par <- reading("parameters", read.MFCLPar.alt(finalPar("model")))
rep <- reading("model estimates", read.MFCLRep(finalRep("model")))
like <- reading("likelihoods", read.MFCLLikelihood("model/test_plot_output"))
lenfit <- reading("length fits", read.MFCLLenFit("model/length.fit"))

# Read fisheries description
fisheries <- read.taf("data/fisheries.csv")

# Model stats
npar <- n_pars(par)
objfun <- obj_fun(par)
gradient <- max_grad(par)
stats <- data.frame(npar, objfun, gradient)

# Likelihoods
likelihoods <- summary(like)
likelihoods <- as.data.frame(as.list(likelihoods$likelihood))
names(likelihoods) <- summary(like)$component
likelihoods$effort_dev <- likelihoods$age <- NULL
likelihoods$catchability_dev <- likelihoods$weight_comp <- NULL
# Read CPUE likelihood manually from test_plot_output
if(likelihoods$cpue == 0){
  dat <- readLines("model/test_plot_output")
  likelihoods$cpue <-
    sum(read.table(text=dat[grep("# Survey_index_like_by_group", dat) + 1]))}
likelihoods$penalties <- obj_fun(par) -
  sum(likelihoods[1, colnames(likelihoods)[colnames(likelihoods) != "total"]])

# CPUE
obs <- as.data.frame(cpue_obs(rep))
pred <- as.data.frame(cpue_pred(rep))
names(obs)[names(obs) == "data"] <- "obs"
names(pred)[names(pred) == "data"] <- "pred"
cpue <- cbind(obs, pred["pred"])
names(cpue)[names(cpue) == "unit"] <- "fishery"
cpue$area <- NULL
cpue <- merge(cpue, fisheries[c("fishery", "area", "flag")])
cpue <- cpue[cpue$flag == "INDEX",]
cpue$obs <- exp(cpue$obs)
cpue$pred <- exp(cpue$pred)
cpue <- cpue[c("year", "season", "fishery", "area", "obs", "pred")]
cpue <- cpue[order(cpue$fishery, cpue$year, cpue$season),]

# Length comps
length.comps <- lenfits(lenfit)
length.comps$season <- (1 + length.comps$month) / 3
names(length.comps)[names(length.comps) == "sample_size"] <- "ess"
length.comps <- length.comps[c("year", "season", "fishery", "ess",
                               "length", "obs", "pred")]

# Write TAF tables
write.taf(cpue, dir="output")
write.taf(length.comps, dir="output")
write.taf(likelihoods, dir="output")
write.taf(stats, dir="output")
