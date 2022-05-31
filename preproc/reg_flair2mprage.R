library(neurobase)
library(ANTsR)
library(extrantsr)
library(fslr)
library(stringr)

#' Registers flair to mprage
if (!exists(argv)){
    argv = commandArgs(trailingOnly = TRUE)
    flair2map = argv[1]
    mprage_path = argv[2]
    flair2transform = argv[3]
}


print('Computing transformation...')
flair2mprage = antsRegistration(fixed = extrantsr::oro2ants(neurobase::readnii(mprage_path)), 
                                moving = extrantsr::oro2ants(neurobase::readnii(flair2map)),
                                typeofTransform = "Rigid",
                                verbose = TRUE)

print('Applying transformation...')                            
flair_reg = antsApplyTransforms(fixed=extrantsr::oro2ants(neurobase::readnii(mprage_path)), 
                                moving=extrantsr::oro2ants(neurobase::readnii(flair2transform)),
                                transformlist = flair2mprage$fwdtransforms,
                                interpolator ="WelchWindowedSinc",
                                verbose = TRUE)

print('Saving transformed image...')

outdir = file.path(dirname(flair2transform), "reg")
dir.create(outdir)
outpath = file.path(outdir, stringr::str_replace(basename(flair2transform), '.nii.gz', '_reg.nii.gz'))
antsImageWrite(flair_reg, outpath)
print('Registration complete.')