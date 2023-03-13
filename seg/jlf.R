suppressMessages(library(ANTsR))
suppressMessages(library(extrantsr))
suppressMessages(library(neurobase))
suppressMessages(library(parallel))
suppressMessages(library(argparser))

reg_atlas_and_seg = function(img, atlas, seg){
    #' Compute registration of atlas to image, apply registration to segmentation
    img.nii = neurobase::readnii(img)
    message(sprintf("Registering atlas to %s", img))
    atlas_to_image = registration(filename = atlas,
                                    template.file = img.nii,
                                    typeofTransform = "SyN", remove.warp = FALSE)

    message("Applying transforms")
    atlas_reg = antsApplyTransforms(fixed = oro2ants(img.nii), moving = oro2ants(readnii(atlas)),
                                   transformlist = atlas_to_image$fwdtransforms, interpolator = "nearestNeighbor")
    seg_reg = antsApplyTransforms(fixed = oro2ants(img.nii), moving = oro2ants(readnii(seg)),
                                   transformlist = atlas_to_image$fwdtransforms, interpolator = "nearestNeighbor")
    
    # create temporary files for atlas
    atlas_reg_path = tempfile(pattern = "jlf_template_reg", tmpdir = here::here("tmp"), fileext = ".nii.gz")
    seg_reg_path = tempfile(pattern = "jlf_seg_reg", tmpdir = here::here("tmp"), fileext = ".nii.gz")
    antsImageWrite(atlas_reg, atlas_reg_path)
    antsImageWrite(seg_reg, seg_reg_path)
    
    # return paths to temporary files
    return(c(atlas_reg_path, seg_reg_path))
}

main = function() {

    p <- argparser::arg_parser("Run JLF segmentation", hide.opts = FALSE)
    p <- argparser::add_argument(p, "--mode", short = "-m", help = "Select 'WMGM' or 'thal' segmentation", default='WMGM')
    p <- argparser::add_argument(p, "img", help = "Input image")
    p <- argparser::add_argument(p, "out", help = "Output path")
    p <- argparser::add_argument(p, "--num", short ="-n", help = "Number of templates to use", default=10)
    argv <- argparser::parse_args(p)

    if (argv$mode == 'WMGM'){
        in_atlas = "/project/MRI_Templates/MUSE_Templates/WithCere/Template%s.nii.gz"
        in_seg = "/project/MRI_Templates/MUSE_Templates/WithCere/Template%s_label.nii.gz"
    
    } else if (argv$mode == 'thal'){
        in_atlas = "/project/MRI_Templates/OASIS-atlases/OASIS-TRT-20-%s/rai_t1weighted_brain.nii.gz"
        in_seg = "/project/MRI_Templates/OASIS-atlases/OASIS-TRT-20-%s/rai_thalamus_atlas_20-%s.nii.gz"
    }
    # Set up
    dir.create(dirname(argv$out), recursive=TRUE)

    # Set up inputs
    input.df = data.frame  (img=argv$img,
                            atlas=sapply(1:argv$num, function(j) sprintf(in_atlas, j)),
                            seg=sapply(1:argv$num, function(j) do.call("sprintf", c(list(in_seg), as.list(rep(j, stringr::str_count(in_seg, "%s"))))))
                            )
    # Run registrations
    regs =  parallel::mclapply(1:nrow(input.df), function(i) reg_atlas_and_seg (img = input.df[i, "img"], 
                                                                                atlas = input.df[i, "atlas"], 
                                                                                seg = input.df[i, "seg"]),
                                                                                mc.cores = future::availableCores())
    
    # Run JointLabel Fusion
    reg_atlases = paste(sapply(regs, function(x) x[1]), collapse=" ")
    reg_segs = paste(sapply(regs, function(x) x[2]), collapse=" ")
    jlf_cmd = sprintf("/appl/ANTs-2.3.5/bin/antsJointFusion -t %s -g %s -l %s -b 4.0 -c 0 -o %s -v 0", argv$img, reg_atlases, reg_segs, argv$out)
    system(jlf_cmd)
}

main()
