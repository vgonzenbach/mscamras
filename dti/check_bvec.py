import os 
import numpy as np
from glob import glob 

WORKDIR = os.path.join(os.path.dirname(__file__), '..')
os.chdir(WORKDIR)

bvecs = []
for f in glob('data/sub-*/dwi/sub-*_dwi.bvec'):
    bvec = np.loadtxt(f)
    #print(f.split('/')[2]) # print site
    #print(np.sum(bvec.shape))
    bvecs.append(bvec)

# take first array as a benchmark
uniques = [bvecs[0]]
# compare nth array to benchmark list
for arr in bvecs:
    # if equal continue to next array
    if all([np.allclose(arr, unique) and arr.shape == unique.shape for unique in uniques]):
        continue
    else:
        uniques.append(arr)
        break

print(f'There are {len(uniques)} unique bvec files in mscamras.')
# if not equal append nth array to benchmark list