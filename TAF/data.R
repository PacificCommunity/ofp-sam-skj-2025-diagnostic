## Preprocess data, write TAF data tables

## Before: fdesc.txt, skj.frq, skj.tag (boot/data),
##         length.fit (boot/model_results)
## After:  cpue.csv, fisheries.csv, length_comps.csv,
##         tag_recaptures.csv, tag_releases.csv (data)

library(TAF)
taf.library(FLR4MFCL)
source("utilities.R")  # reading

mkdir("data")

# Read data
frq <- reading("catch data", read.MFCLFrq("boot/data/skj.frq"))
fisheries <- reading("fisheries description",
                     read.table("boot/data/fdesc.txt", fill=TRUE, header=TRUE))
tag <- reading("tagging data", read.MFCLTag("boot/data/skj.tag"))

# Fisheries description
names(fisheries)[names(fisheries) == "num"] <- "fishery"
names(fisheries)[names(fisheries) == "region"] <- "area"

# CPUE data
cpue <- realisations(frq)
cpue <- merge(cpue, fisheries[c("fishery", "area", "flag")])
cpue <- cpue[cpue$flag == "INDEX",]
cpue$season <- (1 + cpue$month) / 3
cpue$index <- cpue$catch / cpue$effort
cpue <- cpue[c("year", "season", "fishery", "area", "index")]

# Size data
size <- freq(frq)
size <- size[size$freq != -1,]

# Length compositions
length.comps <- size[!is.na(size$length),]
length.comps$season <- (1 + length.comps$month) / 3
length.comps <- length.comps[c("year", "season", "fishery", "length", "freq")]

# Tag releases and recaptures
tag.releases <- releases(tag)
names(tag.releases)[names(tag.releases) == "region"] <- "area"
tag.releases$season <- (1 + tag.releases$month) / 3
tag.releases <- tag.releases[c("rel.group", "area", "year", "season", "program",
                               "length", "lendist")]
tag.recaptures <- recaptures(tag)
names(tag.recaptures)[names(tag.recaptures) == "region"] <- "rel.area"
names(tag.recaptures)[names(tag.recaptures) == "year"] <- "rel.year"
names(tag.recaptures)[names(tag.recaptures) == "month"] <- "rel.month"
names(tag.recaptures) <- sub("recap", "rec", names(tag.recaptures))
tag.recaptures$rel.season <- (1 + tag.recaptures$rel.month) / 3
tag.recaptures$rec.season <- (1 + tag.recaptures$rec.month) / 3
tag.recaptures <- tag.recaptures[
  c("rel.group", "rel.area", "rel.year", "rel.season", "program", "rel.length",
    "rec.fishery", "rec.year", "rec.season", "rec.number")]

# Write TAF tables
write.taf(fisheries, dir="data")
write.taf(cpue, dir="data")
write.taf(length.comps, dir="data")
write.taf(tag.releases, dir="data")
write.taf(tag.recaptures, dir="data")
