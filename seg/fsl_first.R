library(fslr)
library(neurobase)
library(ANTsR)
library(extrantsr)
library(scales)
library(parallel)

##FSL First segmentation for deep grey structures

t1s = system("find /project/mscamras/gadgetron/datasets-new -name *brain_n4.nii.gz | grep 'MPRAGE'",intern=TRUE) 

# imgs = list.files(path = ".", pattern = "mp2rage_UNI_fslbet_stripped.nii.gz",full.names = TRUE, recursive = TRUE)

do.first = function(i){

   output.dir_path = file.path(dirname(t1s[i]), "FIRST")
   dir.create(output.dir_path)
   print(paste0("Directory created for: ", t1s[i]))

   system(paste("module load fsl; run_first_all -b -s L_Accu,L_Amyg,L_Caud,L_Hipp,L_Pall,L_Puta,L_Thal,R_Accu,R_Amyg,R_Caud,R_Hipp,R_Pall,R_Puta,R_Thal -i", 
                t1s[i], "-o", file.path(output.dir_path, gsub(".nii.gz", "", basename(t1s[i])))
                )
         )
}

mclapply(1:length(t1s), do.first, mc.cores = Sys.getenv("LSB_DJOB_NUMPROC"))