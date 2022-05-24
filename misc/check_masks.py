from glob import glob
import nibabel as nib
import numpy as np
from itertools import compress

# Edit for other segmentations
seg_path_dict = {'JLF_thal': '/project/mscamras/gadgetron/datasets/*/JLF_thal/*/mask_to_t1/jlf_template_reg*_mask.nii.gz',
                 'JLF_WMGM': '/project/mscamras/gadgetron/datasets/*/JLF_WMGM/*/muse_wmgm_to_t1/jlf_muse_reg*_wmgm.nii.gz'}

def check_segmentation(seg_type, seg_path):
    """Check if registered template masks sum to zero for multi-atlas segmentations"""
    paths = glob(seg_path)

    def check_mask(path):
        """Checks for empty masks by summing all non-zero voxels"""
        arr = nib.load(path).get_fdata()
        empty = np.sum(arr) == 0 # Return True if mask is empty
        return(empty)

    empty_fil = [check_mask(p) for p in paths] 

    # Keep paths for nonempty masks
    nonempty_masks = list(compress(paths, np.logical_not(empty_fil))) 
    n = len(nonempty_masks)
    
    # Print results
    print(f'There were {n} non-empty images out of {len(paths)} for segmentation {seg_type}.\n')
    return(nonempty_masks)

# Run 
nonzeros = {}
for seg, path in seg_path_dict.items():
    nonzeros[seg] = check_segmentation(seg, path)

with open('seg_check_JLF_thal.log', 'w') as f:
    for line in nonzeros['JLF_thal']:
        f.write("%s\n" % line)





