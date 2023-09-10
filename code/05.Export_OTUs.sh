#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH --partition=day

echo "Starting at: $(date)"

## Organise directories and subdirectories
path='path/to/your/project'                             # Path to the project directory
cd $path
clustered=$path/data/06.Clustered                       # Path to the subdirectory containing clustered data
output=$path/output
## Load qqime2
module load QIIME2/2022.8

#########################################################
######################################################### Export OTU tables
#########################################################

qiime tools export \
    --input-path $clustered/table_97.qza \
    --output-path $output

biom convert \
    -i $output/feature-table.biom \
    -o $output/feature-table.tsv \
    --to-tsv

sed '1d' $output/feature-table.tsv > $output/OTUs.tsv
rm $output/feature-table.tsv
sed -i -e '1s/#OTU ID/OTU_ID/' $output/OTUs.tsv

echo "Finished at: $(date)"