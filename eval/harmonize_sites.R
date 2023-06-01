library(longCombat)
library(argparser)
library(dplyr)
library(stringr)
library(tidyr)
set.seed(1979)

# Set up
setwd(rprojroot::find_rstudio_root_file())
options(error = quote({dump.frames(to.file = TRUE); q(status = 1)}))

#' Input NA for bad Atropos segmentatinos for certain subjects
fix_failed_atropos <- function(df){

  rows <- c('04001-NIH-01', '01003-NIH-01', '03002-NIH-02', '04003-NIH-01', '04001-BWH-02', '03001-BWH-01')
  cols <- colnames(df) %>% 
    stringr::str_subset("ATROPOS")
  
  df %>% 
    unite(sub, subject, site, visit, sep = '-') %>%
    mutate(across(all_of(cols), ~ ifelse(sub %in% rows, NA, .))) %>% 
    separate(sub, c('subject', 'site', 'visit'))
}

# Apply Combat
run_combat_by_vars <- function(df, features){
  res <- longCombat::longCombat(idvar="subject", 
                       timevar="visit", 
                       batchvar="site",
                       features=features, # set vars
                       formula=NULL,
                       ranef="(1|subject)",
                       data=df)
  colnames(res$data_combat) <- colnames(res$data_combat) |> 
    stringr::str_replace_all('.combat', '')
  return(res)
}

join_results <- function(x, y){
  if(any(class(x) == "data.frame")) {
    return(left_join(x, y))
  } else {
    return(cbind(x, y))
  }
}

# Read data
argv <- commandArgs(trailingOnly = TRUE)
df <- read.csv(argv[1], 
              colClasses = c("subject" = "character", "visit" = "character")) %>% 
              fix_failed_atropos()



# 
vars <- colnames(df) %>% 
  stringr::str_subset("[A-Z]")
# non-Atropos
res1 <- run_combat_by_vars(df %>% select(-starts_with('ATROPOS')),
  vars %>% str_subset('ATROPOS', negate=TRUE))
 
# atropos
res2 <- run_combat_by_vars(df %>% select(!where(is.numeric), starts_with('ATROPOS')) %>% na.omit(),
  vars %>% str_subset('ATROPOS'))

res <- purrr::map2(res1, res2, join_results)

# Save data.frame
write.csv(res$data_combat, sprintf("results/%s_harmonized.csv", 
    tools::file_path_sans_ext(basename(argv[1]))),
    row.names = FALSE)
saveRDS(res, sprintf("results/%s_model.csv", tools::file_path_sans_ext(basename(argv[1]))))

# Save model
message("Results saved")
