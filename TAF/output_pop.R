## Extract population results, write TAF output tables

## Before: 14.par, catch.rep, plot-14.par.rep, (model), fisheries.csv (data)
## After:  biology.csv, biomass.csv, catch.csv, f_aggregate.csv, f_annual.csv,
##         f_stage.csv, natage.csv, selectivity.csv, summary.csv (output)

library(TAF)
taf.library(FLR4MFCL)
source("utilities.R")  # reading

mkdir("output")

# Read MFCL output files
par <- reading("parameters", read.MFCLPar(finalPar("model")))
rep <- reading("model estimates", read.MFCLRep(finalRep("model")))
catches <- reading("catches", read.MFCLCatch("model/catch.rep",
                                             dimensions(par), range(par)))

# Read fisheries description
fisheries <- reading("fisheries description", read.taf("data/fisheries.csv"))

# Biology
laa <- as.data.frame(mean_laa(rep))
names(laa)[names(laa) == "data"] <- "length"
waa <- as.data.frame(mean_waa(rep))
names(waa)[names(waa) == "data"] <- "weight"
biology <- cbind(laa, waa["weight"])
biology$age <- biology$age + 1 ## first age is 1 not 0
biology$year <- biology$unit <- biology$area <- biology$iter <- NULL
biology$season <- NULL
biology <- biology[order(biology$age),]
biology$maturity <- mat(par)
biology$natmort <- m_at_age(rep)

# Biomass
biomass <- as.data.frame(adultBiomass(rep))
biomass$age <- biomass$unit <- biomass$iter <- biomass$season <- NULL
names(biomass)[names(biomass) == "data"] <- "ssb"

# Catch
catch <- as.data.frame(fishery_catch(catches))
catch$age <- catch$iter <- NULL
names(catch)[names(catch) == "unit"] <- "fishery"
names(catch)[names(catch) == "data"] <- "t"
catch$area <- fisheries$area[catch$fishery]
catch <- catch[c("year", "fishery", "area", "t")]

# Fishing mortality: annual
f.annual.all <- as.data.frame(seasonSums(fm_aggregated(rep)))
f.annual.reg <- as.data.frame(seasonSums(fm(rep)))
f.annual <- rbind(f.annual.reg, f.annual.all)
names(f.annual)[names(f.annual) == "data"] <- "f"
f.annual$unit <- f.annual$season <- f.annual$iter <- NULL

# Fishing mortality: adult and juvenile
p.adult <- mat(par)
p.adult[which.max(p.adult):length(p.adult)] <- 1  # once adult, stay adult
p.juven <-  1 - p.adult
f.adult <- aggregate(f~year+area, f.annual, weighted.mean, w=p.adult)
f.juven <- aggregate(f~year+area, f.annual, weighted.mean, w=p.juven)
f.adult$stage <- "adult"
f.juven$stage <- "juvenile"
f.stage <- rbind(f.adult, f.juven)[c("year", "area", "stage", "f")]

# Fishing mortality: aggregate
f.aggregate <- as.data.frame(AggregateF(rep))
names(f.aggregate)[names(f.aggregate) == "data"] <- "f"
f.aggregate <- f.aggregate[c("year", "f")]

# Numbers at age
natage <- as.data.frame(popN(rep))
natage$unit <- natage$iter <- NULL
names(natage)[names(natage) == "data"] <- "n"
natage <- natage[c("year", "area", "age", "n")]

# Selectivity
selectivity <- as.data.frame(sel(rep))
names(selectivity)[names(selectivity) == "unit"] <- "fishery"
names(selectivity)[names(selectivity) == "data"] <- "sel"
selectivity <- selectivity[c("fishery", "age", "sel")]

# Summary
rec <- aggregate(data~year, as.data.frame(popN(rep)), sum, subset=age==1)
y <- as.data.frame(seasonSums(total_catch(catches)))
tb <- aggregate(data~year, as.data.frame(seasonMeans(totalBiomass(rep))), sum)
sb <- as.data.frame(SB(rep))
sbf0 <- as.data.frame(SBF0(rep))
dep <- as.data.frame(SBSBF0(rep))
f <- as.data.frame(seasonSums(AggregateF(rep)))
summary <- data.frame(year=sb$year, rec=rec$data, catch=y$data, tb=tb$data,
                      sb=sb$data, sbf0=sbf0$data, dep=dep$data, f=f$data)

# Write TAF tables
write.taf(biology, dir="output")
write.taf(biomass, dir="output")
write.taf(catch, dir="output")
write.taf(f.aggregate, dir="output")
write.taf(f.annual, dir="output")
write.taf(f.stage, dir="output")
write.taf(natage, dir="output")
write.taf(selectivity, dir="output")
write.taf(summary, dir="output")
