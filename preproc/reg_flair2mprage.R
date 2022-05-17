library(neurobase)
library(ANTsR)
library(extrantsr)
library(fslr)
library(stringr)

#' Registers flair to mprage

argv = commandArgs(trailingOnly = TRUE)
flair_path = argv[1]
mprage_path = argv[2]

print('Computing transformation...')
flair2mprage = antsRegistration(fixed = extrantsr::oro2ants(neurobase::readnii(mprage_path)), 
                                moving = extrantsr::oro2ants(neurobase::readnii(flair_path)),
                                typeofTransform = "Rigid",
                                verbose = TRUE)

print('Applying transformation...')                            
flair_reg = antsApplyTransforms(fixed=extrantsr::oro2ants(neurobase::readnii(mprage_path)), 
                                moving=extrantsr::oro2ants(neurobase::readnii(flair_path)),
                                transformlist = flair2mprage$fwdtransforms,
                                interpolator ="WelchWindowedSinc",
                                verbose = TRUE)

print('Saving transformed image...')

outdir = file.path(dirname(flair_path), "..", "reg")
dir.create(outdir)
outpath = file.path(outdir, stringr::str_replace(basename(flair_path), '.nii.gz', '_reg.nii.gz'))
antsImageWrite(flair_reg, outpath)
print('Registration complete.')