# Check results from segmentation extraction
library(dplyr)
library(purrr)
library(tidyr)

which_seg_failed <- function(df){
  df %>% 
    filter(tensormap=='FA') %>% 
    group_by(sub, segmentation) %>% 
    summarize(n = n_distinct(roi), .groups = 'drop') %>% 
    pivot_wider(names_from='segmentation', values_from='n') %>% 
    select(-sub) %>% 
    purrr::map_int(n_distinct) %>% 
    sort(decreasing=TRUE) %>% 
    subset(. != 1)
}

# New after mimosa correction
which_seg_failed(read.csv('avg_tensor_by_roi.csv'))

df <- read.csv('avg_tensor_by_roi.csv')

get_sub_failed_seg <- function(df, seg){
  df_list <- df %>% 
    filter(tensormap == 'FA', segmentation == seg) %>% 
    group_by(sub) %>% 
    summarize(uniq = paste(unique(roi), collapse = ' '), .groups = 'drop') %>% 
    group_by(uniq) %>% 
    split(f=.$uniq) %>% 
    purrr::map(~pull(.x, sub))
  
  if(length(df_list) == 1) return("All segmentations successful.")
  
  good_segs <- df_list %>% 
    map_int(length) %>% 
    sort(decreasing=TRUE) %>% 
    names() %>% 
    .[1]
  
  bad_segs <- df_list[!names(df_list) %in% good_segs] %>% 
    reduce(c)
  return(bad_segs)
}

for (seg in unique(df$segmentation)){
  message("Checking seg: ", seg)
  print(get_sub_failed_seg(df,seg))
}