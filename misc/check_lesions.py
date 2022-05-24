import subprocess
import nibabel as nib
import numpy as np
import pandas as pd

"""Code checks aggrement in segmentations"""


path = "/project/mscamras/Data/Manual_Segmentations_2021-10-27/registered_FLAIRS_and_FLAIR_segmentations/"

command = "find /project/mscamras/Data/Manual_Segmentations_2021-10-27/registered_FLAIRS_and_FLAIR_segmentations/ -name '*binary_mask*'"
process = subprocess.Popen(command)
output, error = process.communicate()

