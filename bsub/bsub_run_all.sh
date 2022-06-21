# Run skull stripping on n4 images
module load ANTs2/2.2.0-111
module load afni_openmp/17.1.07
module load fsl
module load MASS
module load dramms/1.4.1
export BSUB_QUIET=Y

pair_t1_to_flair () {
    local mode=$1 #orig, n4, mimosa
    local t1=$2

    case $mode in
        orig)
        if [[ "$t1" =~ 'MPRAGE_SAG_TFL_ND.nii.gz' ]]; then
            flair=$(find $(dirname "$t1") -name *FLAIR_SAG_VFL_ND.nii.gz)
        elif [[ "$t1" =~ 'MPRAGE_SAG_TFL_NDa.nii.gz' ]]; then
            flair=$(find $(dirname "$t1") -name *FLAIR_SAG_VFL_NDa.nii.gz)
        fi;;

        n4) # Not sure this is needed
        if [[ "$t1" =~ 'MPRAGE_SAG_TFL_ND_n4.nii.gz' ]]; then
            flair=$(find $(dirname "$t1") -name *FLAIR_SAG_VFL_ND_n4.nii.gz)
        elif [[ "$t1" =~ 'MPRAGE_SAG_TFL_NDa_n4.nii.gz' ]]; then
            flair=$(find $(dirname "$t1") -name *FLAIR_SAG_VFL_NDa_n4.nii.gz)
        fi;;

        mimosa)
        if [[ "$t1" =~ 'MPRAGE_SAG_TFL_ND_' ]]; then
            flair=$(find $(dirname "$t1") -name *FLAIR_SAG_VFL_ND_reg_brain_n4.nii.gz)
        elif [[ "$t1" =~ 'MPRAGE_SAG_TFL_NDa' ]]; then
            flair=$(find $(dirname "$t1") -name *FLAIR_SAG_VFL_NDa_reg_brain_n4.nii.gz)
        fi;;
    esac

    echo $flair
}

get_onscanner_t1 () {
    local t1=$1
    local dir=$(echo $(dirname $t1) | sed 's/gadgetron\/datasets-new/Data/g')
    local onsc_t1="$dir"/NIFTI/$(basename $t1 | sed 's/^.*\(MPRAGE\)/\1/g')
    echo $onsc_t1
}

get_onscanner_brainmask () {
    local t1=$1
    # Pair to onscanner brainmask
    local dir=$(echo $(dirname $t1) | sed 's/gadgetron\/datasets-new/Data/g')
    local brainmask="$dir"/analysis/mass/$(basename $t1 .nii.gz | sed 's/^.*\(MPRAGE\)/\1/g')_n4_brainmask.nii.gz
    echo $brainmask
}

bsub_reg_onscanner_mask () {

    local t1=$1
    local outfile=$(dirname $t1)/brain/$(basename $t1 .nii.gz)_brainmask.nii.gz

    if [ ! -e $outfile ]; then
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -J reg_mask_"$i" \
        -o logs/reg_mask.log -e logs/reg_mask.log \
        Rscript preproc/reg_onscanner_mask.R $t1 $(get_onscanner_t1 $t1) $(get_onscanner_brainmask $t1) >> logs/run_all.log
    fi

    echo $outfile
}

bsub_reg_flair () {

    local t1=$1
    local flair=$(pair_t1_to_flair orig $t1)
    local parent_job=reg_mask_$i

    local outfile=$(dirname $flair)/reg/$(basename $flair .nii.gz)_reg.nii.gz
    if [ ! -e $outfile ]; then
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -w "done(${parent_job})" -J reg_flair_$i \
        -o logs/reg_flair.logs -e logs/reg_flair.log Rscript preproc/reg_flair2mprage.R $flair $t1 >> logs/run_all.log
    fi

    echo $outfile
}

bsub_mask_img () {
    local img=$1
    local mask=$2

    case $img in 
        *MPRAGE*)
        local parent_job=reg_mask_$i # bsub onscanner mask
        local job_name=mask_t1_$i
        local outfile=$(dirname $img)/brain/$(basename $img .nii.gz)_brain.nii.gz;;

        *FLAIR*)
        local parent_job=reg_flair_$i # reg flair
        local job_name=mask_flair_$i
        local outfile=$(dirname $img)/../brain/$(basename $img .nii.gz)_brain.nii.gz;;
    esac

    if [ ! -e $outfile ]; then
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -w "done(${parent_job})" -J $job_name \
        -o logs/mask_img.log -e logs/mask_img.log Rscript preproc/apply_brainmask.R $img $mask $(dirname $outfile) >> logs/run_all.log
    fi
    
    echo $outfile
}

bsub_n4 (){
    local img=$1

    case $img in 

        *MPRAGE*)
        local parent_job=mask_t1_$i
        local job_name=n4_t1_$i;;

        *FLAIR*)
        local parent_job=mask_flair_$i
        local job_name=n4_flair_$i;;

    esac

    local outfile=$(dirname $img)/../n4/$(basename $img .nii.gz)_n4.nii.gz
    if [ ! -e $outfile ]; then
        mkdir -p $(dirname $img)/../n4
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -w "done(${parent_job})" -J $job_name \
        -o logs/n4.log -e logs/n4.log N4BiasFieldCorrection -d 3 -i $img -o $outfile >> logs/run_all.log
    fi

    echo $outfile
}

bsub_atropos () {
    local t1=$1
    local parent_job=n4_t1_$i
    local outfile=$(dirname $t1)/Atropos/$(basename .nii.gz)_atropos_seg.nii.gz

    if [ ! -e $outfile ]; then
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -J atropos_"$i" -w "done(${parent_job})" \
        -o logs/atropos.log -e logs/atropos.log Rscript vols/atropos.R $t1 $(dirname $t1)/.. >> logs/run_all.log
    fi

    echo $outfile
}

bsub_first () {
    local t1=$1
    local parent_job=n4_t1_$i
    local outfile=$(dirname $t1)/../FIRST/$(basename $t1 .nii.gz)_all_none_firstseg.nii.gz

    if [ ! -e $outfile ]; then
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -w "done(${parent_job})" -J first_"$i" -o logs/first.log -e logs/first.log \
            run_first_all -b -s L_Accu,L_Amyg,L_Caud,L_Hipp,L_Pall,L_Puta,L_Thal,R_Accu,R_Amyg,R_Caud,R_Hipp,R_Pall,R_Puta,R_Thal \
            -i "$t1" -o $(dirname $outfile)/$(basename $t1 .nii.gz) >> logs/run_all.log
    fi

    echo $outfile
}

bsub_fast () {
    local t1=$1
    local parent_job=n4_t1_$i

    local outfile=$(dirname $t1)/../FAST/$(basename $t1 .nii.gz)_seg.nii.gz
    if  [ ! -e $outfile ]; then 
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -J fast_"$i" -w "done(${parent_job})" \
        -o logs/fast.log -e logs/fast.log Rscript vols/fsl_fast.R $t1 $(dirname $t1)/.. >> logs/run_all.log
    fi

    echo $outfile
}

bsub_mimosa () {

    local t1=$1
    local flair=$2
    local mask=$3

    local parent_job=n4_t1_$i
    local outfile=$(dirname $t1)/../mimosa/$(basename $t1 .nii.gz)/bin_mask_0.2.nii.gz
    
    if [ ! -e $outfile ]; then 
         bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -w "done(${parent_job})" -J mimosa_"$i" \
         -o logs/mimosa.log -e logs/mimosa.log Rscript vols/run_mimosa.R "$t1" "$flair" "$mask" >> logs/run_all.log
    fi
    
    echo $outfile
}

bsub_jlf_seg () {
    local mode=$1
    local t1=$2
    local parent_job=n4_t1_$i

    local outfile=$(dirname $t1)/../JLF_${mode}/$(basename $t1 .nii.gz) # a directory really
    if [ ! -e $outfile ]; then
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -w "done(${parent_job})" -J jlf${mode}_"$i" \
            -o logs/jlf${mode}.log -e logs/jlf${mode}.log Rscript vols/jlf.R ${mode} "$t1" $(dirname $t1)/.. >> logs/run_all.log
    fi

    echo $outfile 
}

bsub_jlf_fusion () {
    local mode=$1
    local t1=$2

    local parent_job=jlf${mode}_$i
    local jlf_dir="$(dirname $t1)"/../JLF_${mode}/"$(basename $t1 .nii.gz)"
    
    local outfile=${jlf_dir}/fused_${mode}_seg.nii.gz
    if [ ! -e $outfile ]; then
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -w "done(${parent_job})" -J fuse${mode}_"$i" \
            -o logs/fuse${mode}.log -e logs/fuse${mode}.log bash vols/fuse_jlf_seg.sh ${mode} "$t1" >> logs/run_all.log  
    fi
   echo $outfile
    
}

i=0
for t1 in $(find /project/mscamras/gadgetron/datasets-new/ -maxdepth 3 -type f | grep MPRAGE); do

    # get corresponding flair according to visit number
    flair=$(pair_t1_to_flair orig $t1)
    
    # register t1 to onscanner t1. apply transform to brainmask w NN interpolation

    brainmask=$(bsub_reg_onscanner_mask $t1) 

    # register flair to t1. save reg flair
    reg_flair=$(bsub_reg_flair $t1) 
    
    # apply mask to t1
    t1_brain=$(bsub_mask_img $t1 $brainmask)
    
    # apply mask to flair
    flair_brain=$(bsub_mask_img $reg_flair $brainmask)

    # apply n4 to both flair and t1
    t1_n4=$(bsub_n4 $t1_brain)
    flair_n4=$(bsub_n4 $flair_brain)
    
    # run volumetrics and mimosa
    atropos_seg=$(bsub_atropos $t1_n4)
    fast_seg=$(bsub_fast $t1_n4)
    first_seg=$(bsub_first $t1_n4)
    jlf_thal_seg=$(bsub_jlf_seg thal $t1_n4)
    jlf_wmgm_seg=$(bsub_jlf_seg WMGM $t1_n4)
    mimosa_seg=$(bsub_mimosa $t1_n4 $flair_n4 $brainmask)

    # fuse
    jlf_thal_fusion=$(bsub_jlf_fusion thal $t1_n4)
    jlf_WMGM_fusion=$(bsub_jlf_fusion WMGM $t1_n4)
    ((++i))
done