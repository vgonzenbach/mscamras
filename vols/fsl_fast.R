library(fslr)
library(neurobase)
library(ANTsR)
library(extrantsr)
library(scales)
library(parallel)

##FSL FAST segmentation for GM, WM, and CSF

t1s = system(paste("find /project/mscamras/gadgetron/datasets-new -name *brain_n4.nii.gz | grep 'MPRAGE'"),intern=TRUE) 

do.fast = function(i){

    output.dir_path = file.path(dirname(t1s[i]), "FAST")
    dir.create(output.dir_path)

    MPRAGE_fast = fast(file = t1s[i],
                        outfile = file.path(output.dir_path, basename(nii.stub(t1s[i]))),
                        bias_correct = FALSE)
}

mclapply(1:length(t1s), do.fast, mc.cores = Sys.getenv("LSB_DJOB_NUMPROC"))