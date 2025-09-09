## Run analysis, write model results

## Before: 13.par, skj.frq, skj.tag, doitall.sh, mfcl.cfg (boot/data),
##         mfclo64 (boot/software)
## After:

library(TAF)

mkdir("model")

# Software
cp("boot/software/mfclo64", "model")

# Input files
cp("boot/data/13.par",         "model")
cp("boot/data/skj.tag",        "model")
cp("boot/data/skj.frq",        "model")
cp("boot/data/doitall.sh",     "model")
cp("boot/data/mfcl.cfg",       "model")

# Run model
setwd("model")
system("doitall.sh")
setwd("..")
