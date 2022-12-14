suppressMessages(library(dplyr))
set.seed(1979)

setwd(rprojroot::find_rstudio_root_file())

argv = commandArgs(trailingOnly = TRUE)
vol_df = read.csv(argv[1])

get_ratio_stat = function(vol_df){
  
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
                      abs(select(subj_df[i, ], where(is.numeric)) - select(comp_df[j, ], where(is.numeric))))
      }
      mean_diffs = rbind(mean_diffs, data.frame(t(sapply(diffs, mean, na.rm = TRUE))))
    }
    return(data.frame(t(sapply(mean_diffs, mean, na.rm = TRUE))))
  }
  
  # get intrasite differences
  mean_intrasite_diffs = vol_df %>% 
    split(list(vol_df$ID, vol_df$site)) %>% # split dataset by subject and site, i.e. generate list of data.frames
    lapply(function (x) select(x, where(is.numeric))) %>% # select volumes (in each df)
    lapply(function (x) sapply(x, function(x) abs(diff(x)))) %>% # take absolute value of row-wise difference in all columns
    bind_rows (.id = "subj-site") %>% # put all data.frame elements of the list into a single data.frame
    select(where(is.numeric)) %>% 
    colMeans(na.rm = TRUE) %>% t() %>% data.frame()
  
  # get intersite differences
  mean_intersite_diffs = vol_df %>% 
    split (vol_df$ID) %>% 
    lapply(get_mean_intersite_diff) %>% 
    bind_rows() %>% 
    colMeans(na.rm = TRUE) %>% t() %>% data.frame()
  
  diff_ratio = mean_intersite_diffs / mean_intrasite_diffs
  return(diff_ratio)
}

permute_ratio_stat = function(vol_df, n.perms = 10000){
  perm_ratio_stats = list()
  
  for (n.perm in 1:n.perms){
    perm_df = select(vol_df, ID, site, img_type, img_source)
    perm_ind = sample(1:nrow(perm_df), nrow(perm_df), replace = FALSE)
    perm_df = cbind(perm_df, 
                    select(vol_df[perm_ind, ], where(is.numeric)))
    perm_ratio_stats = c(perm_ratio_stats, list(get_ratio_stat(perm_df)))
  }
  
  return(perm_ratio_stats %>% bind_rows())
}

test_ratio_stat = function(ratio.stats, null.dists){
  p.vals = c()
  for (col in colnames(ratio.stat)){
    ratio.stat = ratio.stats[, col]
    null.dist = null.dists[, col]
    
    percentile = ecdf(null.dist)
    p.vals = c(p.vals, percentile(ratio.stat))
  }
  names(p.vals) = colnames(ratio.stats)
  return(p.vals)
}

ratio.stat = get_ratio_stat(vol_df)
null.dists = permute_ratio_stat(vol_df, 10000)

saveRDS(ratio.stat, sprintf("results/%s_ratio_stat.rds", tools::file_path_sans_ext(basename(argv[1]))))
saveRDS(null.dists, sprintf("results/%s_null.rds", tools::file_path_sans_ext(basename(argv[1]))))

message("Results saved")

