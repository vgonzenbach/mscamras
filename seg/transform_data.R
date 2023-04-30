library(dplyr)
library(ggplot2)
library(purrr)
library(tidyr)
library(stringr)

# Name ROIs and pivot table
seg_df = read.csv('avg_tensor_by_roi.csv', colClasses = c('roi' = 'character'))
jlf_dict = readxl::read_xlsx('/home/vgonzenb/MSKIDS/data/MUSE_ROI_Dict.xlsx') %>% 
  filter(ROI_INDEX %in% 1:207)

#' Name ROIs according to Segmentation
#'
#' essentially, name_rois enables distinct recoding schemes of the 'roi' column according to the value in the 'segmentation' column.
#' for usage, split or filter a data.frame by unique segmentations and indicate the segmentation type
#' @param df a data.frame corresponding to data from one segmentation type only
#' @param seg_type the segmentation type: 'atropos', 'fast', 'first', 'jlfseg_WMGM', or 'jlfseg_thal'
#'@examples
#'\dontrun{
#' multiseg_df %>% split(seg_df$segmentation) %>% purrr::imap(name_rois) %>% dplyr::bind_rows()
#'}
#'@examples
#'\dontrun{
#' multiseg_df %>% filter(segmentation == seg_type) %>% name_rois(seg_type)
#'}
#' @return a data.frame with a recoded roi column
name_rois <- function(df, seg_type){
  roi_names_by_seg_type <- list(atropos = c(`1` = "CSF", `2` = "GM", `3` = "WM"),
                                fast = c(`1` = "CSF", `2` = "GM", `3` = "WM"),
                                first = c(`10` = "L.Thalamus", `49` = "R.Thalamus"),
                                jlfseg_WMGM = jlf_dict$ROI_NAME |> setNames(jlf_dict$ROI_INDEX),
                                jlfseg_thal = c(`1` = 'Thalamus'),
                                mimosa = c(`1` = 'Lesion'))
  roi_names <- roi_names_by_seg_type[[seg_type]]
  df %>% 
    mutate(roi = recode(roi, !!!roi_names))
}

seg_df <- seg_df %>% 
  split(seg_df$segmentation) %>% 
  imap(name_rois) %>% 
  bind_rows()

# name tissue types
add_tissue_col <- function(df, seg_type){
  tissues_by_seg_type <- list(atropos = setNames(nm = c("CSF", "GM", "WM")),
                              fast = setNames(nm = c("CSF", "GM", "WM")),
                              first = setNames(c("Thalamus", "Thalamus"), 
                                               c("L.Thalamus", "R.Thalamus")),
                              jlfseg_WMGM = jlf_dict$TISSUE_SEG |> setNames(jlf_dict$ROI_NAME),
                              jlfseg_thal = c('Thalamus' = 'Thalamus'),
                              mimosa = c('Lesion' = 'Lesion'))
  tissue_type <- tissues_by_seg_type[[seg_type]]
  df %>% 
    mutate(tissue = recode(roi, !!!tissue_type), .after = "roi")
}

seg_df <- seg_df %>% 
  split(seg_df$segmentation) %>% 
  imap(add_tissue_col) %>% 
  bind_rows()
  
# filter unused roi, aggregate WM and GM in jlf segmentation, pivot
seg_df_wide <- seg_df %>% 
  mutate(exclude = str_detect(tissue, "^[0-9]+$")) %>% 
  filter(exclude != TRUE) %>% 
  group_by(sub, tensormap, segmentation, tissue) %>% 
  summarize(mean_values = mean(values), .groups = 'drop') %>% 
  filter(!tissue %in% c('NONE', 'CSF', 'VN')) %>% 
  unite(segmentation, segmentation, tissue, tensormap) %>% # for pivot wider
  pivot_wider(names_from = segmentation, values_from = mean_values) %>% 
  rename_if(is.numeric, toupper) 

# name repair
colnames(seg_df_wide) <- colnames(seg_df_wide) %>% 
  str_replace_all("JLFSEG", "JLF") %>% 
  str_replace("WMGM_", "") %>% 
  str_replace("THAL_", "")

# parse subject
seg_df_wide <- seg_df_wide %>% 
  mutate(subject = str_extract(sub, "(?<=sub-)\\d{5}"),
         site = str_extract(sub, "(?<=sub-\\d{5})\\D+"),
         visit = str_extract(sub, "[0-9]{2}$"), 
         .after = sub) %>% 
  select(-sub)

# write
write.csv(seg_df_wide, 'avg_tensor_by_roi_wide.csv', row.names = FALSE)
message("Transformed data saved as 'avg_tensor_by_roi_wide.csv'")

seg_df_wide_no_Hopkins <- seg_df_wide %>% 
  filter(site != 'Hopkins')

write.csv(seg_df_wide_no_Hopkins , 'avg_tensor_by_roi_wide_no_Hopkins.csv', row.names = FALSE)
message("Filterd Transformed data saved as 'avg_tensor_by_roi_wide_no_Hopkins.csv'")
