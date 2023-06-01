# calculates F statistic for fully crossed design
library(dplyr)
library(tidyr)
library(purrr)

# read parameter

#' calculate F statistic for a single column
#' 
#' returns the mean squared differences for all (within-subject) intersite and intrasite pairs
#' @param outcome name of colums
#' @param data data.frame
#' @return a data.frame of one row and three columns: F, MS_B, MS_W
get_F <- function(outcome, df){
    MS_B_i = c()
    MS_W_i = c()
    for (sub in unique(df$subject)){
        subj_df <- df[df$subject == sub,]

        for (i in seq_len(nrow(subj_df))){
        
            y = subj_df[i, outcome] # get metric for current row
            ref_site = subj_df[i, 'site'] # get site for current row

            # get metrics not in current site
            y_c = subj_df %>% 
                filter(site != ref_site) %>% 
                pull(outcome) 

            intersite_sq_diffs = (y - y_c)^2 # take squared differences
            MS_B_i = c(MS_B_i, mean(intersite_sq_diffs, na.rm = TRUE)) # take mean before concatenating

            # get metrics from other visit in current site 
            ref_visit = subj_df[i, 'visit']
            y_c = subj_df %>% 
                filter(site == ref_site, visit != ref_visit) %>% 
                pull(outcome) 
            intrasite_sq_diff = (y - y_c)^2 #
            MS_W_i = c(MS_W_i,  mean(intrasite_sq_diff, na.rm = TRUE))

        }

    }
    
    MS_B = mean(MS_B_i, na.rm = TRUE)
    MS_W = mean(MS_W_i, na.rm = TRUE)
    
    F = MS_B / MS_W
    data.frame(outcome, F, MS_B, MS_W)
}

#' apply `get_F` across all numeric columns
get_F_df <- function(df){

    outcomes <- df %>% 
        select(where(is.numeric)) %>% 
        colnames()

    F_df <- purrr::map_df(outcomes, get_F, df=df)
    return(F_df)
}

filter_failed_atropos <- function(df){
  df %>% 
    unite(sub, subject, site, visit, sep = '-') %>% 
    filter(!sub %in% c('04001-NIH-01', '01003-NIH-01', '03002-NIH-02', '04003-NIH-01', '04001-BWH-02', '03001-BWH-01')) %>% 
    separate(sub, c('subject', 'site', 'visit')) 
}

permute_F_df <- function(df, n.iter = 10000){

  seq_len(n.iter) %>% 
    parallel::mclapply(mc.cores = future::availableCores(),
                       function(i){
                         df %>% 
                           split(df$subject) %>% 
                           map(~ mutate(.x, site = sample(site, nrow(.x)))) %>% 
                           bind_rows() %>%
                           get_F_df()
                         }) %>% 
    map(tibble::rownames_to_column) %>% 
    bind_rows() %>% 
    group_by(rowname) %>% 
     summarize_all(.funs = ~ list(.))
}

argv <- commandArgs(trailingOnly = TRUE)
df <- read.csv(argv[1], colClasses = c("subject" = "character", "visit" = "character")) 

atropos_df <- df %>% 
    select(!where(is.numeric), starts_with('ATROPOS')) %>% 
    filter_failed_atropos()
nonatropos_df <-  df %>% 
    select(-starts_with('ATROPOS'))
message("Computing observed F")
F_df <- rbind(get_F_df(atropos_df), 
              get_F_df(nonatropos_df))

message("Saving F")
saveRDS(F_df, sprintf("results/%s_F_df.rds", tools::file_path_sans_ext(basename(argv[1]))))

message("Computing Permutations")
null.dists <- rbind(permute_F_df(atropos_df), 
                    permute_F_df(nonatropos_df))
message("Saving Null Fs")
saveRDS(null.dists, sprintf("results/%s_null_F_df.rds", tools::file_path_sans_ext(basename(argv[1]))))

message("Results saved")