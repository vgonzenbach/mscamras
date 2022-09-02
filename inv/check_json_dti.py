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

# Hopkins data is missing 'PhaseEncodingDirection' attribute"
# NIH data shows discrepancy in PhaseEncodingDirection was assigned
df.pivot_table(columns='PhaseEncodingDirection', index=['site', 'dir'], aggfunc='size')

# Fix the direction in Hopkins
# TODO: generalize to all .json files not only Hopkins ?
for fn in dwi_filenames:
    if 'Hopkins' in fn:
        with open(fn, 'r') as f:
            hopkins_json = json.load(f)
        
        if 'PhaseEncodingDirection' not in hopkins_json.keys():
            if 'AX' in fn: # assign direction according to dir field
                hopkins_json['PhaseEncodingDirection'] = 'j'
            elif 'XPhase' in fn:
                hopkins_json['PhaseEncodingDirection'] = 'j-'
        
        if 'TotalReadoutTime' not in hopkins_json.keys():
            hopkins_json['TotalReadoutTime'] = 0.031185
            
        with open(fn, 'w') as f:
            json.dump(hopkins_json, f, indent=1)
