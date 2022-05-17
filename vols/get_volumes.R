suppressMessages(library(neurobase))
suppressMessages(library(fslr))
suppressMessages(library(parallel))
suppressMessages(library(dplyr))

# Get all MPRAGES
#file_list = system('ls /project/mscamras/gadgetron/datasets-new/*/*/*.nii.gz | grep MPRAGE', intern=TRUE)

# Dictionary of all
jlf_dict = readxl::read_xlsx('/home/vgonzenb/MSKIDS/data/MUSE_ROI_Dict.xlsx')
jlf_dict = jlf_dict[jlf_dict$ROI_INDEX %in% 1:200, ]
tissue_ind = lapply(c("GM","WM"), function(x) jlf_dict$ROI_INDEX[jlf_dict$TISSUE_SEG == x])

load.t1.df = function(){
    df = read.csv('file_list.csv')
    df = df[df$img_source == 'gadgetron' & 
            grepl("MPRAGE", df$img_type) & 
            !is.na(df$orig) & 
            df$orig != "",]
    rownames(df) = 1:nrow(df)
    #df[, "original"] = NULL
    colnames(df)[length(df)] = 'source_path'
    df[, 'source_path'] = sprintf("%s_n4_brain.nii.gz", neurobase::nii.stub(df$source_path))
    return(df)
}

get.vol = function(path, type="Atropos"){

    # Transform input path
    if (type == "Atropos"){

        seg_path = file.path(dirname(path), "Atropos", paste0(neurobase::nii.stub(basename(path)), "_atropos_seg.nii.gz"))
        out = tryCatch({
            seg = neurobase::readnii(seg_path) # Load image
            vol_table = table(seg)[-1] * voxres(seg, units = "cm") # Get volumes for each label
            vol_df = data.frame(t(matrix(vol_table)))
            colnames(vol_df) = paste(type, c("CSF", "GM", "WM"), sep="_") 
            vol_df
        
        }, error = function(cond){
            vol_df = data.frame(matrix(NA, 1,3))
            colnames(vol_df) = paste(type, c("CSF", "GM", "WM"), sep="_")
            return(vol_df)
        })
    } else if (type == "FAST"){

        seg_path = file.path(dirname(path), "FAST", paste0(neurobase::nii.stub(basename(path)), "_seg.nii.gz"))
        out = tryCatch({
            seg = neurobase::readnii(seg_path) # Load image
            vol_table = table(seg)[-1] * voxres(seg, units = "cm") # Get volumes for each label
            vol_df = data.frame(t(matrix(vol_table)))
            colnames(vol_df) = paste(type, c("CSF", "GM", "WM"), sep="_")
            vol_df

        }, error = function(cond) {
            vol_df = data.frame(matrix(NA, 1, 3))
            colnames(vol_df) = paste(type, c("CSF", "GM", "WM"), sep="_")
            return(vol_df)
        })
    } else if (type == "JLF"){

        seg_path = file.path(dirname(path), "JLF_WMGM", neurobase::nii.stub(basename(path)), "fused_wmgm_labels.nii.gz")
        out = tryCatch({
            seg = neurobase::readnii(seg_path) # Load image
            vol_table = table(seg)[-1] * voxres(seg, units = "cm") # Get volumes for each label

            vols = c()
            for (i in tissue_ind) vols = c(vols, sum(vol_table[as.character(i)]))
            vol_df = data.frame(t(matrix(vols)))
            colnames(vol_df) = paste(type, c("GM", "WM"), sep="_")
            vol_df
        
        }, error = function(cond) {
            vol_df = data.frame(matrix(NA, 1, 2))
            colnames(vol_df) = paste(type, c("GM", "WM"), sep="_")
            return(vol_df)
        })
    } else if (type == "FIRST"){

        seg_path = file.path(dirname(path), "FIRST", paste0(neurobase::nii.stub(basename(path)), "_all_none_firstseg.nii.gz"))
        out = tryCatch({
            seg = neurobase::readnii(seg_path) # Load image
            vol_table = table(seg)[-1] * voxres(seg, units = "cm")
            vol_df = data.frame(FIRST_thal = sum(vol_table[c('10', '49')]))
        
        }, error = function(cond) {
            vol_df = data.frame(FIRST_thal = NA)
        })
    } else if (type == "JLF_thal"){

        seg_path = file.path(dirname(path), "JLF_thal", neurobase::nii.stub(basename(path)), "fused_thal_mask.nii.gz")
        out = tryCatch({
            seg = neurobase::readnii(seg_path) # Load image
            vol_table = table(seg)[-1] * voxres(seg, units = "cm") # Get volumes for each label
            vol_df = data.frame(JLF_thal = vol_table)
        
        }, error = function(cond) {
            vol_df = data.frame(JLF_thal = NA)
        })
    } else if (type == "mimosa"){

        seg_path = file.path(dirname(path), "mimosa", neurobase::nii.stub(basename(path)), "bin_mask_0.2.nii.gz")
        out = tryCatch({
            seg = neurobase::readnii(seg_path) # Load image
            vol_table = table(seg)[-1] * voxres(seg, units = "cm") # Get volumes for each label
            vol_df = data.frame(mimosa = vol_table)
        
        }, error = function(cond) {
            vol_df = data.frame(mimosa = NA)
        })
    } else {
        stop("Specify a valid segmentation type")
    }
    return(out)
}

get.vols = function(path){
    df = data.frame(source_path = path,
               get.vol(path, "Atropos"),
               get.vol(path, "FAST"),
               get.vol(path, "JLF"),
               get.vol(path, "FIRST"),
               get.vol(path, "JLF_thal"),
               get.vol(path, "mimosa"),
               row.names = NULL)
    return(df)
}

# Load input data
df = load.t1.df()
#df = df[file.exists(df$source_path),] # Filter out inexistent files

vol_df = dplyr::bind_rows(parallel::mclapply(df$source_path, get.vols, mc.cores = Sys.getenv('LSB_DJOB_NUMPROC')))

vol_df_merged = cbind(df, vol_df)
vol_df_merged[, "source_path"] = NULL

# Save merged data.frame
write.csv(vol_df_merged, "gadgetron_volumes.csv", row.names = FALSE) # TODO: change output path based on argument 'out'
message(sprintf("Volumes saved to %s", "gadgetron_volumes.csv"))