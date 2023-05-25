library(neurobase)
library(stringr)
library(purrr)
library(dplyr)
library(parallel)
library(future)

#' get subject given a img filepath
get_subject <- function(path) stringr::str_extract(path, 'sub-[0-9A-Za-z]+')

#' get tensor map type from img filepath
get_tensor_type <- function(path) stringr::str_extract(path, '(FA|MD|RD|AD).nii.gz') |> neurobase::nii.stub()

#' map suffix to each segmentation directory
get_seg_path <- function(dwi_path, seg_type){ # TODO: create the inverse function (rather add feature to make an inverse)
    sub <- get_subject(dwi_path)
    if (seg_type == 'atropos'){
        suffix <- 'desc-sanslesion_dseg.nii.gz'

    } else if (seg_type == 'first'){
        suffix <- 'desc-sanslesion_T1w_all_none_firstseg.nii.gz'

    } else if (seg_type == 'fast'){
        suffix <- 'desc-sanslesion_T1w_seg.nii.gz'

    } else if (seg_type == 'jlfseg_WMGM'){
        suffix <- 'desc-sanslesion_space-T1w_dseg.nii.gz'

    } else if (seg_type == 'jlfseg_thal'){
        suffix <- 'desc-sanslesion_space-T1w_dseg.nii.gz'

    } else if (seg_type == 'mimosa'){
        suffix <- 'desc-n4regmasked_label-lesion_mask.nii.gz'
    }
    cmd <- sprintf('find data/v5/derivatives/%s -name %s*%s', seg_type, sub, suffix)
    system(cmd, intern=TRUE)
}

#' apply a function mean over image by roi
#' 
#' @param dwi_path TODO: name it img; take also images
#' @param seg_type TODO: change to seg_path and 
#' @param seg_name TODO: add this parameter (for row)
#' @param img_name TODO: add this parameter
#' @return a dataframe of avg TODO: generalize to other functions
avg_tensormap_by_roi <- function(dwi_path, seg_type){

    seg_path <- get_seg_path(dwi_path, seg_type) # TODO: take img path instead of seg_type

    dwi_img <- neurobase::readnii(dwi_path) # TODO: also take img as arg
    seg_img <- neurobase::readnii(seg_path) # TODO:

    voxel_df <- data.frame(dwi_vox = as.vector(dwi_img), seg_vox = as.vector(seg_img)) |> 
                filter(dwi_vox != 0)
    values <- split(voxel_df$dwi_vox, voxel_df$seg_vox) |> 
                    purrr::map_dbl(mean) # TODO: generalize to other statistics
    data.frame(sub = get_subject(dwi_path), # TODO: get rid of this argument?
               tensormap = get_tensor_type(dwi_path), # TODO: generalize this to img_name
               segmentation = seg_type, # TODO: generalize this to segmentation name
               roi = names(values), 
               values = values) # TODO: name this according to function
}

# set up inputs
dwi_paths <- system(" find data/v5/derivatives/dtifit -name '*resampledreg*FA.nii.gz' -or -name '*resampledreg*MD.nii.gz' -or -name '*resampledreg*RD.nii.gz' -or -name '*resampledreg*AD.nii.gz' ", intern=TRUE)
inputs_df <- expand.grid(dwi_path = dwi_paths, 
                         seg_type = c('atropos', 'fast', 'first', 'jlfseg_WMGM', 'jlfseg_thal', 'mimosa'),
                         stringsAsFactors = FALSE)

# test with reduced data
system.time(df <- seq_len(nrow(inputs_df)) |>
                    parallel::mclapply(function(i) avg_tensormap_by_roi(inputs_df[i,"dwi_path"], inputs_df[i,"seg_type"]), 
                                        mc.cores = future::availableCores()) |>
                    dplyr::bind_rows()
            )
write.csv(df, 'avg_tensor_by_roi.csv', row.names = FALSE)


#message('Sequential run time:')
#system.time(df <- purrr::map2(inputs$dwi_path, inputs$seg_type, ~ avg_tensormap_by_roi(.x, .y)))
#system.time(df <- df |> bind_rows())
#write.csv(df, 'extraction_sequential.csv')

# Parallel test
# create the future backend
#plan(future.batchtools::batchtools_lsf, workers = availableCores())
#
#message('Parallel run time:')
#system.time(df <- furrr::future_map2(inputs$dwi_path, inputs$seg_type, ~ avg_tensormap_by_roi(.x, .y)))
#system.time(df <- df |> bind_rows())
#write.csv(df, 'extraction_parallel.csv')

#system.time(df <- df |> bind_rows())
