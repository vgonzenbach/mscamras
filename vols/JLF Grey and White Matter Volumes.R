library(ANTsR)
library(extrantsr)
library(neurobase)
library(parallel)

t1s = system("find /project/mscamras/gadgetron/datasets-new -name *n4_brain.nii.gz | grep 'MPRAGE'", intern=TRUE) 

do.jlf = function(i) {

   #Create JLF ouput dirs
    JLFdir = file.path(dirname(t1s[i]), "..", "JLF_WMGM") # Include '..' b/c *brain.ni.gz are in mass/ 
    outdir_regatlas = file.path(gsub(".nii.gz","",basename(t1s[i])),"muse_to_t1")
    outdir_regwmgm = file.path(gsub(".nii.gz","",basename(t1s[i])),"muse_wmgm_to_t1")
    output.dir_path_atlas = file.path(JLFdir, outdir_regatlas)
    output.dir_path_wmgm = file.path(JLFdir, outdir_regwmgm)
    dir.create(output.dir_path_atlas, recursive = TRUE)
    dir.create(output.dir_path_wmgm, recursive = TRUE)
    print(paste0("Dirs created for ", t1s[i]))

    for(j in 1:10){

      t1 = readnii(t1s[i])

      #full brain atlases
      muse = paste0("/project/MRI_Templates/MUSE_Templates/WithCere/Template", j, ".nii.gz")

      #WM/GM atlases 
      wmgm = paste0("/project/MRI_Templates/MUSE_Templates/WithCere/Template", j, "_label.nii.gz")
      
      # Register muse full brain atlases to camras images
      print(paste0("Registering muse atlas to ", t1s[i]))
      atlas_to_image = registration(filename = muse,
                                    template.file = t1,
                                    typeofTransform = "SyN", remove.warp = FALSE)
      
      # Apply registration to wm/gm atlases and full brain atlases 
      print(paste0("Applying transforms to brains and wmgm for ", t1s[i]))
      muse_reg = antsApplyTransforms(fixed = oro2ants(t1), moving = oro2ants(readnii(muse)),
                                     transformlist = atlas_to_image$fwdtransforms, interpolator = "nearestNeighbor")
      muse_wmgm = antsApplyTransforms(fixed = oro2ants(t1), moving = oro2ants(readnii(wmgm)),
                                      transformlist = atlas_to_image$fwdtransforms, interpolator = "nearestNeighbor")
      antsImageWrite(muse_reg, file.path(output.dir_path_atlas, sprintf("jlf_muse_reg%s.nii.gz", j)))
      antsImageWrite(muse_wmgm, file.path(output.dir_path_wmgm, sprintf("jlf_muse_reg%s_wmgm.nii.gz", j)))
    }
}

mclapply(1:length(t1s), do.jlf, mc.cores = Sys.getenv('LSB_DJOB_NUMPROC')) 
