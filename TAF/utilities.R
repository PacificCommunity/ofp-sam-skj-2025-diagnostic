# Show progress while reading file
reading <- function(string, action)
{
  cat("  Reading", string, "... ")
  x <- action
  cat("done\n")
  x
}

# Special read.MFCLPar function for SKJ 2025 selectivity blocks
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

# Special read.MFCLSel function for SKJ 2025 selectivity blocks
read.MFCLSel.alt <- function (parfile, parobj = NULL, first.yr = NA)
{
  trim.leading <- function(x) sub("^\\s+", "", x)
  trim.trailing <- function(x) sub("\\s+$", "", x)
  splitter <- function(ff, tt, ll = 1, inst = 1) unlist(strsplit(trim.leading(ff[grep(tt,
                                                                                      ff)[inst] + ll]), split = "[[:blank:]]+"))
  res <- new("MFCLSel")
  if (is.null(parobj)) {
    par <- trim.leading(readLines(parfile))
    par <- par[nchar(par) >= 1]
    par <- par[-seq(1, length(par))[grepl("# ", par) & nchar(par) <
                                      3]]
  }
  if (!is.null(parobj))
    par <- parobj
  parversion <- as.numeric(splitter(par, "# The parest_flags"))[200]
  nseasons <- length(splitter(par, "# season_flags"))
  nregions <- length(splitter(par, "# region parameters"))
  nagecls <- as.numeric(par[grep("# The number of age classes",
                                 par) + 1])
  nfish <- length(splitter(par, "# q0_miss"))
  xfish <- sum(matrix(as.numeric(splitter(par, "# fish flags",
                                          ll = 1:nfish, inst = 1)), ncol = nfish)[71, ])
  nqgroups <- max(array(as.numeric(splitter(par, "# fish flags",
                                            1:nfish)), dim = c(100, nfish))[29, ], na.rm = T)
  dims1 <- list(age = as.character(seq(0, (nagecls/nseasons) -
                                         1)), year = "all", unit = "unique", season = c(as.character(1:nseasons)),
                area = "all")
  dims2 <- list(age = as.character(seq(0, (nagecls/nseasons) -
                                         1)), year = "all", unit = c(as.character(1:nfish)),
                season = c(as.character(1:nseasons)), area = "all")
  dims2a <- dims2
  dims2a$unit <- as.character(1:(nfish + xfish))
  dims3 <- list(age = "all", year = "all", unit = as.character(1:nfish),
                season = "all", area = "all")
  qdc <- lapply(1:nfish, function(x) as.numeric(splitter(par,
                                                         "# catchability deviation coefficients", x)))
  edc <- lapply(1:nfish, function(x) as.numeric(splitter(par,
                                                         "# effort deviation coefficients", x)))
  cdc <- lapply(1:nqgroups, function(x) as.numeric(splitter(par,
                                                            "# The grouped_catch_dev_coffs", x, inst = 2)))
  sdc_end <- cumsum(lapply(qdc, length)) + seq(length(qdc))
  sdc_start <- c(1, sdc_end[-length(sdc_end)] + 1)
  sdc_lines <- lapply(seq(nfish), function(x) seq(sdc_start[x],
                                                  sdc_end[x]))
  sdc <- lapply(sdc_lines, function(x) matrix(as.numeric(splitter(par,
                                                                  "# sel_dev_coffs", x)), ncol = nagecls))
  slot(res, "availability_coffs") <- FLQuant(aperm(array(as.numeric(splitter(par,
                                                                             "# availability coffs")), dim = c(nseasons, nagecls/nseasons,
                                                                                                               1, 1, 1)), c(2, 3, 4, 1, 5)), dimnames = dims1)
  fish_flags <- matrix(as.numeric(splitter(par, "# fish flags",
                                           ll = 1:nfish, inst = 1)), ncol = nfish)
  no_sel_block_breaks <- fish_flags[71, ]
  no_sel_seasons <- fish_flags[74, ]
  no_rows_in_fishery_sel_block <- sum(no_sel_block_breaks *
                                        no_sel_seasons) + sum(no_sel_seasons)
  dims3a <- dims2
  dims3a$unit <- as.character(1:no_rows_in_fishery_sel_block)
  slot(res, "fishery_sel") <- FLQuant(aperm(array(as.numeric(splitter(par,
                                                                      "# fishery selectivity", 1:no_rows_in_fishery_sel_block)),
                                                  dim = c(nseasons, nagecls/nseasons, no_rows_in_fishery_sel_block,
                                                          1, 1)), c(2, 4, 3, 1, 5)), dimnames = dims3a)
  slot(res, "fishery_sel_age_comp") <- FLQuant(aperm(array(as.numeric(splitter(par,
                                                                               "# age-dependent component of fishery selectivity",
                                                                               1:nfish)), dim = c(nseasons, nagecls/nseasons, nfish,
                                                                                                  1, 1)), c(2, 4, 3, 1, 5)), dimnames = dims2)
  slot(res, "av_q_coffs") <- FLQuant(aperm(array(as.numeric(splitter(par,
                                                                     "# average catchability coefficients")), dim = c(1,
                                                                                                                      1, 1, nfish, 1)), c(2, 3, 4, 1, 5)), dimnames = dims3)
  slot(res, "ini_q_coffs") <- FLQuant(aperm(array(as.numeric(splitter(par,
                                                                      "# initial trend in catchability coefficients")), dim = c(nfish,
                                                                                                                                1, 1, 1, 1)), c(2, 3, 1, 4, 5)), dimnames = dims3)
  slot(res, "q0_miss") <- FLQuant(aperm(array(as.numeric(splitter(par,
                                                                  "# q0_miss")), dim = c(nfish, 1, 1, 1, 1)), c(2, 3,
                                                                                                                1, 4, 5)), dimnames = dims3)
  slot(res, "sel_dev_corr") <- FLQuant(aperm(array(as.numeric(splitter(par,
                                                                       "# correlation in selectivity deviations")), dim = c(nfish,
                                                                                                                            1, 1, 1, 1)), c(2, 3, 1, 4, 5)), dimnames = dims3)
  slot(res, "season_q_pars") <- matrix(as.numeric(splitter(par,
                                                           "# seasonal_catchability_pars", 1:nfish)), ncol = 12,
                                       byrow = T)
  slot(res, "q_dev_coffs") <- qdc
  slot(res, "effort_dev_coffs") <- edc
  slot(res, "catch_dev_coffs") <- cdc
  slot(res, "catch_dev_coffs_flag") <- as.numeric(par[grep("# The grouped_catch_dev_coffs flag",
                                                           par) + 1])
  slot(res, "sel_dev_coffs") <- matrix(as.numeric(splitter(par,
                                                           "# selectivity deviation coefficients", 1:sum(unlist(lapply(qdc,
                                                                                                                       length))))), ncol = nagecls, byrow = T)
  slot(res, "sel_dev_coffs2") <- sdc
  getfishparms <- function(xx, vsn) {
    if (vsn > 1040 & vsn <= 1049)
      mm <- matrix(as.numeric(splitter(xx, "# extra fishery parameters",
                                       1:20)), ncol = nfish, byrow = T)
    if (vsn >= 1050)
      mm <- matrix(as.numeric(splitter(xx, "# extra fishery parameters",
                                       1:50)), ncol = nfish, byrow = T)
    return(mm)
  }
  slot(res, "fish_params") <- getfishparms(par, parversion)
  if (parversion >= 1052)
    slot(res, "spp_params") <- matrix(as.numeric(splitter(par,
                                                          "# species parameters", 1:20)), ncol = 1, byrow = T)
  slot(res, "range") <- c(min = 0, max = nagecls/nseasons,
                          plusgroup = NA, minyear = 1, maxyear = 1)
  res <- checkUnitDimnames(res, nfisheries = nfish)
  return(res)
}
