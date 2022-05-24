import pandas as pd
import numpy as np
import nibabel as nib
from operator import itemgetter
import sys, re

def get_origin(path):
        if (pd.isna(path)):
            origin = np.nan
        else: 
            origin = itemgetter(['qoffset_x', 'qoffset_y', 'qoffset_z'])(nib.load(path).header)
            origin = origin.item()
        return origin

df = pd.read_csv('file_list.csv')
df['img_type'] = df['img_type'].apply(lambda x: x.replace('_ND', ''))

subjects = set(df.ID)
sites = set(df.site)
img_types = [r'FLAIR_SAG_VFL$', r'MPRAGE_SAG_TFL$', r'FLAIR_SAG_VFLa$', r'MPRAGE_SAG_TFLa$']

results = []
for subj in subjects:
    for site in sites:
        for img_type in img_types:

            result = {'ID': subj, 'site': site, 'img_type': img_type, 
                      'origin_match': None, 'onscanner_origin': None, 'gadgetron_origin': None}

            sel_rows =  df[(df.ID == subj) & (df.site == site) & (df.img_type.apply(lambda x: bool(re.match(img_type, x))))]
            if sel_rows.empty: continue
            
            for img_source in ('onscanner', 'gadgetron'):
                img = sel_rows[sel_rows.img_source == img_source].original.tolist().pop()
                result[img_source + '_origin'] = origin = get_origin(img)

            origins = [result['onscanner_origin'], result['gadgetron_origin']]
            result['origin_match'] = len(set(origins)) == 1 
            results.append(result)
            sys.stdout.write(str(result))

match_df = pd.DataFrame.from_records(results)      
match_df.to_csv(sys.stdout, index=False)   
            
            
           

