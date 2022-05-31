library(fslr)
library(neurobase)
library(ANTsR)
library(extrantsr)
library(scales)
library(parallel)

#ATROPOS for GM, WM, and CSF

t1s = system("find /project/mscamras/gadgetron/datasets-new -name *brain_n4.nii.gz | grep 'MPRAGE'", intern=TRUE) 

do.atropos = function(i){
  #imgs = list.files(path = dirs[j], pattern = "*_brain.nii.gz",full.names = TRUE)
  #t1s = imgs[which(grepl("MPRAGE",imgs))]

  output.dir_path = file.path(dirname(t1s[i]), "Atropos")
  dir.create(output.dir_path)

  img = readnii(t1s[i])
  otropos_img = otropos(img, make_mask = TRUE)
  seg = otropos_img$segmentation

  writenii(seg, file.path(output.dir_path,
                       gsub(".nii.gz", "_atropos_seg.nii.gz", basename(t1s[i]))
                      )
          )
  #writenii(seg, paste0(output.dir_path,"/atropos_seg.nii.gz"))
  #tab_ants = table(seg[seg != 0])
  #names(tab_ants) = c("CSF","GM","WM")
  # write.csv(tab_ants, paste0(output.dir_path,"/atropos_voxel_count.csv"))
  #vres = voxres(img, units = "cm")
  #vol_ants = tab_ants * vres
  # write.csv(vol_ants, paste0(output.dir_path,"/atropos_volumes.csv"))
  #vol_total_brain = vol_ants["CSF"] + vol_ants["GM"] + vol_ants["WM"]   
}
mclapply(1:length(t1s), do.atropos, mc.cores = Sys.getenv("LSB_DJOB_NUMPROC"))
