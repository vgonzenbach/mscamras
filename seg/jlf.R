suppressMessages(library(ANTsR))
suppressMessages(library(extrantsr))
suppressMessages(library(neurobase))
suppressMessages(library(parallel))

argv = commandArgs(trailingOnly=TRUE)
mode = argv[1]
t1 = argv[2]
outdir = argv[3]

JLF.dir = file.path(outdir, sprintf("JLF_%s", mode))
out_atlas_dir = file.path(JLF.dir, neurobase::nii.stub(basename(t1)), "atlas_to_t1")
out_seg_dir = file.path(JLF.dir, neurobase::nii.stub(basename(t1)), "seg_to_t1")
dir.create(out_atlas_dir, recursive = TRUE)
dir.create(out_seg_dir, recursive = TRUE)
message(sprintf("Directories created for %s", t1))

if (mode == 'WMGM'){
    in_atlas = "/project/MRI_Templates/MUSE_Templates/WithCere/Template%s.nii.gz"
    in_seg = "/project/MRI_Templates/MUSE_Templates/WithCere/Template%s_label.nii.gz"


} else if (mode == 'thal'){
    in_atlas = "/project/MRI_Templates/OASIS-atlases/OASIS-TRT-20-%s/rai_t1weighted_brain.nii.gz"
    in_seg = "/project/MRI_Templates/OASIS-atlases/OASIS-TRT-20-%s/rai_thalamus_atlas_20-%s.nii.gz"

}

reg_atlas_and_seg = function(j){
    t1.nii = neurobase::readnii(t1)
    atlas = sprintf(in_atlas, j)
    
    n = stringr::str_count(in_seg, "%s")
    seg = do.call("sprintf", c(list(in_seg), as.list(rep(j, stringr::str_count(in_seg, "%s")))))

    message(sprintf("Registering atlas to %s", t1))
    atlas_to_image = registration(filename = atlas,
                                    template.file = t1.nii,
                                    typeofTransform = "SyN", remove.warp = FALSE)

    message(sprintf("Applying transforms"))
    atlas_reg = antsApplyTransforms(fixed = oro2ants(t1.nii), moving = oro2ants(readnii(atlas)),
                                   transformlist = atlas_to_image$fwdtransforms, interpolator = "nearestNeighbor")
    seg_reg = antsApplyTransforms(fixed = oro2ants(t1.nii), moving = oro2ants(readnii(seg)),
                                   transformlist = atlas_to_image$fwdtransforms, interpolator = "nearestNeighbor")
    
    antsImageWrite(atlas_reg, file.path(out_atlas_dir, sprintf("jlf_template_reg%s.nii.gz", j)))
    antsImageWrite(seg_reg, file.path(out_seg_dir, sprintf("jlf_%s_reg%s.nii.gz", mode, j)))
}

for(j in 1:10){
    # Run registration only if files are not found
    if(!file.exists(file.path(out_atlas_dir, sprintf("jlf_template_reg%s.nii.gz", j))) ||
       !file.exists(file.path(out_seg_dir,sprintf("jlf_%s_reg%s.nii.gz", mode, j)))){
           reg_atlas_and_seg(j)
       } 
}