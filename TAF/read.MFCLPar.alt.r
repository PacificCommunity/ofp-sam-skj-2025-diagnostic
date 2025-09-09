read.MFCLPar.alt <- function (parfile, first.yr = NA) 
{
  trim.trailing <- function(x) sub("\\s+$", "", x)
  slotcopy <- function(from, to) {
    for (slotname in slotNames(from)) {
      slot(to, slotname) <- slot(from, slotname)
    }
    return(to)
  }
  res <- new("MFCLPar")
  par <- trim.trailing(readLines(parfile))
  par <- par[nchar(par) >= 1]
  par <- par[-seq(1, length(par))[grepl("#", par) & nchar(par) < 
                                    3]]
  vsn <- as.numeric(unlist(strsplit(trimws(par[2]), split = "[[:blank:]]+")))[200]
  res <- slotcopy(read.MFCLParBits(parfile, par, first.yr), 
                  res)
  if (is.na(first_year(res))) 
    first_year(res) <- first.yr
  if (!is.na(first_year(res))) 
    first.yr <- first_year(res)
  res <- slotcopy(read.MFCLBiol(parfile, par, first.yr), res)
  res <- slotcopy(read.MFCLFlags(parfile, par, first.yr), 
                  res)
  res <- slotcopy(read.MFCLTagRep(parfile, par, first.yr), 
                  res)
  res <- slotcopy(read.MFCLRec(parfile, par, first.yr), res)
  res <- slotcopy(read.MFCLRegion(parfile, par, first.yr), 
                  res)
  res <- slotcopy(read.MFCLSel.alt(parfile, par, first.yr), res)
  slot(res, "range") <- c(min = 0, max = max(as.numeric(unlist(dimnames(fishery_sel(res))["age"]))), 
                          plusgroup = NA, minyear = min(as.numeric(unlist(dimnames(rel_rec(res))["year"]))), 
                          maxyear = max(as.numeric(unlist(dimnames(rel_rec(res))["year"]))))
  res <- checkUnitDimnames(res, nfisheries = dimensions(res)["fisheries"])
  return(res)
}