#%% set up
import os
import sys
import json
from bids import BIDSLayout
import pandas as pd

# Set working directory
WORKDIR = os.path.join(os.path.dirname(__file__), '..')
os.chdir(WORKDIR)

"""Check which jsons are missing 'PhaseEncodingDirection' attribute"""
# read in all filename
layout = BIDSLayout('data')
dwi_filenames = [ BIDSJSONFile.path for BIDSJSONFile in layout.get(suffix='dwi', extension='.json') ]
dwi_jsons = {}
for fn in dwi_filenames:
    with open(fn) as f:
        dwi_jsons[os.path.basename(fn)] = json.load(f)

# get phase encoding direction and num. of steps for each image
get_phase_info = lambda x: [x.get('PhaseEncodingDirection'), x.get('PhaseEncodingSteps')]
img_info = [img.split('_')[:4] + get_phase_info(dwi_jsons[img]) for img in dwi_jsons.keys()]

df = pd.DataFrame.from_records(img_info)
df.columns = ['subj', 'site', 'dir', 'visit', 'PhaseEncodingDirection', 'PhaseEncodingSteps']
#df.to_csv(sys.stdout, index=False)

# %%
# Hopkins data is missing 'PhaseEncodingDirection' attribute"
# NIH data shows discrepancy in PhaseEncodingDirection was assigned
df.pivot_table(columns='PhaseEncodingDirection', index=['site', 'dir'], aggfunc='size')
