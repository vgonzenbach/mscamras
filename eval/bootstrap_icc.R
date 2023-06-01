library(dplyr)
library(tidyr)
library(purrr)
library(performance)
library(parallel)
library(future)
library(lme4)

setwd(here::here())
options(error = quote({dump.frames(to.file = TRUE); q(status = 1)}))

get_icc <- function(df){
  
    tryCatch({
      outcomes <- df %>% 
              dplyr::select_if(is.numeric) %>% 
              colnames()
      result <- outcomes %>% 
        map(~lmer(reformulate("(1|subject) + (1|site)", .x), data=df)) %>% 
        purrr::map(~ performance::icc(.x, by_group = TRUE) %>% as.data.frame) %>% 
        setNames(outcomes) %>% 
        bind_rows(.id = "outcome") %>% 
        select_if(~ !all(is.na(.))) %>% # eliminate column of NAs
        na.omit() %>% # eliminate rows with NA
        pivot_wider(names_from = 'Group', values_from = 'ICC', names_prefix = 'ICC_') %>% 
        relocate(ICC_site, .after = 'outcome') %>%
        arrange(desc(ICC_site))
    return(result)
  }, error = function(e) {
    # Task failed, return NA
    return(NA)
  })

}
  

boot_icc <- function(df, n.iter = 5000){
  
  # get unique subjects (to sample from)
  subjects <- df %>% 
    pull(subject) %>% 
    unique()
  
  # extract icc from `n.iter` different models in parallel
  seq_len(n.iter) %>% 
    parallel::mclapply(function(i) sample(subjects, replace = TRUE) %>%
                         map_dfr(~filter(df, subject %in% .x)) %>%
                         get_icc(),
                       mc.cores = future::availableCores()) %>% 
    # exclude calls that return NA
    subset(!is.na(.)) %>% 
    bind_rows() %>% 
    # create list columns to get 2.5 and 97.5 percentiles
    group_by(outcome) %>%
    summarize_all(.funs = ~ list(.)) %>% 
    mutate(lwr_site = map_dbl(ICC_site, quantile, probs=0.025),
           uppr_site = map_dbl(ICC_site, quantile, probs=0.975),
           lwr_subject = map_dbl(ICC_subject, quantile, probs=0.025),
           uppr_subject = map_dbl(ICC_subject, quantile, probs=0.975))
  
}

filter_failed_atropos <- function(df){
  df %>% 
    unite(sub, subject, site, visit, sep = '-') %>% 
    filter(!sub %in% c('04001-NIH-01', '01003-NIH-01', '03002-NIH-02', '04003-NIH-01', '04001-BWH-02', '03001-BWH-01')) %>% 
    separate(sub, c('subject', 'site', 'visit')) 
}

argv <- commandArgs(trailingOnly = TRUE)
df <- read.csv(argv[1],
              colClasses = c("subject" = "character", "visit" = "character"))
# get variable names (for get_icc to work)

atropos_df <- df %>% 
    select(!where(is.numeric), starts_with('ATROPOS')) %>% 
    filter_failed_atropos()
nonatropos_df <-  df %>% 
    select(-starts_with('ATROPOS'))

boot_df <- rbind(boot_icc(atropos_df),
                boot_icc(nonatropos_df))

saveRDS(boot_df, sprintf("results/%s_boot_icc.rds", tools::file_path_sans_ext(basename(argv[1]))))
message("Results saved")