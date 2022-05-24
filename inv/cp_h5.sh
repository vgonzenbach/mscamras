#!/bin/bash

for h5 in $(ls /project/mscamras/gadgetron/datasets-old/*/raw_data/*.h5); do 

    dir=$(echo $h5 | cut -d/ -f6)
    subj=$(echo $dir | cut -d- -f1,2)
    site=$(echo $dir | cut -d- -f3)

    cp $h5 /project/mscamras/gadgetron/datasets-new/${subj}/${site}/raw_data/
done