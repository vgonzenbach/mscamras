suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(purrr))
set.seed(1979)

setwd(rprojroot::find_rstudio_root_file())
options(error = quote({dump.frames(to.file = TRUE); q(status = 1)}))


argv <- commandArgs(trailingOnly = TRUE)
seg_df = read.csv(argv[1], 
                  colClasses = c("subject" = "character", "visit" = "character"))

get_ratio_stat = function(seg_df){
  
  get_mean_intersite_diff = function(subj_df) {
    #' Calculates mean inter-site difference for a "subjects" data.frame
    
    mean_diffs = data.frame()
    for (i in 1:nrow(subj_df)){ # iterate over rows 
      diffs = data.frame()
      ref_site = subj_df[i, "site"] # save site of current row as reference site
      comp_df = subj_df %>% filter(site != ref_site) # select rows from other sites
      for (j in 1:nrow(comp_df)) { # iterate over these
        # substract row i from row j, taking absolute value
        diffs = rbind(diffs, 
                      (select(subj_df[i, ], where(is.numeric)) - select(comp_df[j, ], where(is.numeric)))^2)
      }
      mean_diffs = rbind(mean_diffs, data.frame(t(sapply(diffs, mean, na.rm = TRUE))))
    }
    return(data.frame(t(sapply(mean_diffs, mean, na.rm = TRUE))))
  }
  
  # get intrasite differences
  mean_intrasite_diffs = seg_df %>% 
    split(list(seg_df$subject, seg_df$site)) %>% # split dataset by subject and site, i.e. generate list of data.frames
    lapply(function (x) select(x, where(is.numeric))) %>% # select volumes (in each df)
    lapply(function (x) sapply(x, function(x) diff(x)^2)) %>% # take absolute value of row-wise difference in all columns
    bind_rows (.id = "subj-site") %>% # put all data.frame elements of the list into a single data.frame
    select(where(is.numeric)) %>% 
    colMeans(na.rm = TRUE) %>% t() %>% data.frame()
  
  # get intersite differences
  mean_intersite_diffs = seg_df %>% 
    split (seg_df$subject) %>% 
    lapply(get_mean_intersite_diff) %>% 
    bind_rows() %>% 
    colMeans(na.rm = TRUE) %>% t() %>% data.frame()
  
  diff_ratio = mean_intersite_diffs / mean_intrasite_diffs
  return(diff_ratio)
}

permute_ratio_stat = function(seg_df, n.perms = 10000){
    
  seq_len(n.perms) %>% 
    parallel::mclapply(mc.cores = future::availableCores(),
                       function(i){
                         seg_df %>% 
                           split(seg_df$subject) %>% 
                           map(~ mutate(.x, site = sample(site, nrow(.)))) %>% 
                           bind_rows() %>%
                           get_ratio_stat()
                         }) %>% 
    bind_rows()
}

ratio.stat = cbind(seg_df %>%
                 select(!is.numeric, starts_with('ATROPOS')) %>% 
                 unite(sub, subject, site, visit, sep = '-') %>% 
                 filter(!sub %in% c('04001-NIH-01', '01003-NIH-01', '03002-NIH-02', '04003-NIH-01', '04001-BWH-02', '03001-BWH-01')) %>% 
                 separate(sub, c('subject', 'site', 'visit')) %>% 
                 get_ratio_stat(),
               seg_df %>%
                 select(-starts_with('ATROPOS')) %>% 
                 get_ratio_stat()
               )

null.dists = cbind(seg_df %>%
                 select(-starts_with('ATROPOS')) %>% 
                 permute_ratio_stat(),
               seg_df %>%
                 select(!is.numeric, starts_with('ATROPOS')) %>% 
                 unite(sub, subject, site, visit, sep = '-') %>% 
                 filter(!sub %in% c('04001-NIH-01', '01003-NIH-01', '03002-NIH-02', '04003-NIH-01', '04001-BWH-02', '03001-BWH-01')) %>% 
                 separate(sub, c('subject', 'site', 'visit')) %>% 
                 permute_ratio_stat()
               )

saveRDS(ratio.stat, sprintf("results/%s_ratio_stat.rds", tools::file_path_sans_ext(basename(argv[1]))))
saveRDS(null.dists, sprintf("results/%s_null.rds", tools::file_path_sans_ext(basename(argv[1]))))

message("Results saved")

