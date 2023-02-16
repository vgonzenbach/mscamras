#%% set up
import os
import json
from bids import BIDSLayout
import argparse

def set_wd():
    """Set working directory"""
    WORKDIR = os.path.join(os.path.dirname(__file__), '..')
    os.chdir(WORKDIR)   
    return None

def get_dwi_json_paths(dataset, site=None):
    """Return all paths to dwi .json files"""
    layout = BIDSLayout(dataset)
    dwi_json_paths = [ BIDSJSONFile.path for BIDSJSONFile in layout.get(suffix='dwi', extension='.json')]
    if site:
        return list(filter(lambda path: site in path, dwi_json_paths))
    return dwi_json_paths

def fix_json(dataset, site=None, fix_direction=False, fix_readout=False):
    """Impute missing or incorrect fields in dwi json"""
    for fn in get_dwi_json_paths(dataset, site):
            # open file
            with open(fn, 'r') as f:
                ajson = json.load(f)

            # impute fields
            if fix_direction:
                if 'AX' in fn: # assign direction according to dir field
                    ajson['PhaseEncodingDirection'] = 'j'
                elif 'XPhase' in fn:
                    ajson['PhaseEncodingDirection'] = 'j-'

            if fix_readout:
                ajson['TotalReadoutTime'] = 0.031185
            #save file
            with open(fn, 'w') as f:
                json.dump(ajson, f, indent=1)
    return None
    
if __name__ == '__main__':
    # parse command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("dataset", type=str, help="Path to dataset")
    parser.add_argument("--fix-hopkins", action='store_true', help="Change .json fields in Hopkins data")
    parser.add_argument("--fix-nih", action='store_true', help="Change .json fields in NIH data")
    args = parser.parse_args()
    
    if not os.path.exists(args.dataset): 
        raise Exception(f'Dataset {args.dataset} does not exist.')
        
    if args.fix_hopkins:
        fix_json(args.dataset, 'Hopkins', fix_direction=True, fix_readout=True)
    if args.fix_nih:
        fix_json(args.dataset, 'NIH', fix_direction=True)
