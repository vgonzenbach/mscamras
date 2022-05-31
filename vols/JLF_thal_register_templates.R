library(ANTsR)
library(extrantsr)
library(neurobase)
library(parallel)

# Run for missing only
t1s = system('find /project/mscamras/gadgetron/datasets-new/ -name *brain_n4.nii.gz | grep MPRAGE', intern=TRUE)
#THAL_MASKS=($(find /project/mscamras/gadgetron/datasets-new/ -name *reg*_mask.nii.gz))
#THAL_DIRS=($(find /project/mscamras/gadgetron/datasets-new/ -name *brain.nii.gz | grep MPRAGE))
#
#
#for dir in ${THAL_DIRS[@]}; do
#    if [ $(printf "%s\n" ${THAL_MASKS[@]} | grep $(basename $dir) | wc -l) != 10 ]; then
#        echo $dir
#    fi
#done | cut -d/ -f-6,8 | sed "s/$/.nii.gz/g"', intern=TRUE) 

do.jlf = function(i) {
  ##list all mass skull stripped images
  #imgs = list.files(path = dirs[x], pattern = "*_brain.nii.gz",
  #                  recursive = TRUE, full.names = TRUE)
  #
  ##subset imgs to get mass skull stripped mprages only
  #t1s = imgs[which(grepl("MPRAGE",imgs))]
      
    #Create JLF ouput dirs
    JLFdir = file.path(dirname(t1s[i]),"..", "JLF_thal")
    outdir_regatlas = paste0(gsub(".nii.gz","",(basename(t1s[i]))),"/template_to_t1")
    outdir_regmask = paste0(gsub(".nii.gz","",(basename(t1s[i]))),"/mask_to_t1")
    output.dir_path_atlas = file.path(JLFdir, outdir_regatlas )
    output.dir_path_mask = file.path(JLFdir, outdir_regmask)
    dir.create(output.dir_path_atlas, recursive = TRUE)
    dir.create(output.dir_path_mask, recursive = TRUE)
    print(paste0("Dirs created for ", t1s[i]))
    
    
    for(j in 1:10){
      
      t1 = readnii(t1s[i])
      
      #full brain atlases
      template = paste0("/project/MRI_Templates/OASIS-atlases/OASIS-TRT-20-", j, "/rai_t1weighted_brain.nii.gz")
      
      #Thal atlases 
      mask = paste0("/project/MRI_Templates/OASIS-atlases/OASIS-TRT-20-", j, "/rai_thalamus_atlas_20-", j, ".nii.gz")
      
      # Register template full brain atlases to camras images
      print(paste0("Registering template atlas to ", t1s[i]))
      atlas_to_image = registration(filename = template,
                                    template.file = t1,
                                    typeofTransform = "SyN", remove.warp = FALSE)
      
      # Apply registration to wm/gm atlases and full brain atlases 
      print(paste0("Applying transforms to brains and mask for ", t1s[i]))
      template_reg = antsApplyTransforms(fixed = oro2ants(t1), moving = oro2ants(readnii(template)),
                                     transformlist = atlas_to_image$fwdtransforms, interpolator = "nearestNeighbor")
      mask_reg = antsApplyTransforms(fixed = oro2ants(t1), moving = oro2ants(readnii(mask)),
                                      transformlist = atlas_to_image$fwdtransforms, interpolator = "nearestNeighbor")
      antsImageWrite(template_reg, paste0(output.dir_path_atlas, "/jlf_template_reg",j, ".nii.gz"))
      antsImageWrite(mask_reg, paste0(output.dir_path_mask, "/jlf_template_reg",j,"_mask.nii.gz"))
    }
}

mclapply(1:length(t1s), do.jlf, mc.cores = Sys.getenv('LSB_DJOB_NUMPROC')) 