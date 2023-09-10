#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH --partition=day

echo "Starting at: $(date)"

# Organise directories and subdirectories
path='path/to/your/project'             # Path to the project's main directory
cd $path
mkdir data/06.Clustered                 # Output directory for clustered data
clustered=$path/data/06.Clustered       # Path to the output subdirectory for clustered data
denoised=$path/data/05.Denoised         # Path to the output subdirectory for denoised data
## Load qqime2
module load QIIME2/2022.8

#########################################################
######################################################### OPTION 1: Cluster non-chimeric sequences after VSEARCH reference-based chimera removal
#########################################################

## This option is active by default in the script

qiime vsearch cluster-features-de-novo \
    --i-sequences $denoised/uchime_output/rep_seqs_nonchimeric.qza \
    --i-table $denoised/uchime_output/table_nonchimeric.qza \
    --p-perc-identity 0.97 \
    --o-clustered-table $clustered/table_97.qza \
    --o-clustered-sequences $clustered/rep_seqs_97.qza \
    --verbose

qiime feature-table summarize \
    --i-table $clustered/table_97.qza \
    --o-visualization $clustered/table_97.qzv

#########################################################
######################################################### OPTION 2: Cluster non-chimeric sequences after DADA2
#########################################################

## Uncomment the following lines to cluster non-chimeric sequences after DADA2 (without reference-based chimera detection), and comment out the lines above

#qiime vsearch cluster-features-de-novo \
    --i-sequences $denoised/representative_sequences.qza \
    --i-table $denoised/table.qza\
    --p-perc-identity 0.97 \
    --o-clustered-table $clustered/table_97.qza \
    --o-clustered-sequences $clustered/rep_seqs_97.qza \
    --verbose

#qiime feature-table summarize \
    --i-table $clustered/table_97.qza \
    --o-visualization $clustered/table_97.qzv

echo "Finished at: $(date)"