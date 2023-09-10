#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=168:00:00
#SBATCH --partition=week

## Assign taxonomy based on UNITE classifier

echo "Starting at: $(date)"

module load QIIME2/2022.8

## Organise directories and subdirectories
path='path/to/your/project'                    # Path to the project's main directory
cd $path
clustered=$path/data/06.Clustered              # Path to clustered representative sequences
output=$path/output
## Load qqime2
module load QIIME2/2022.8

UNITE_ITS2=$path/data/reference_datasets/ITS2_classifier.qza

#########################################################
######################################################### Assign taxonomy
######################################################### 

echo Assigning taxonomy

qiime feature-classifier classify-sklearn \
    --i-classifier $UNITE_ITS2 \
    --i-reads $clustered/rep_seqs_97.qza \
    --o-classification $clustered/taxa.qza

# Export to tsv
qiime tools export \
	--input-path $clustered/taxa.qza \
	--output-path $output

sed '1d' $output/taxonomy.tsv > $output/taxa.tsv
sed -i '1s/^/OTU_ID\tkingdom;phylum;class;order;family;genus;species\tconfidence\n/' $output/taxa.tsv

echo "Finished at: $(date)"