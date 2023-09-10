#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH --partition=day

## Extract ITS subregions from the UNITE database

## Please find the latest UNITE classifiers with ITS regions extracted (ITS1_classifier.qza and ITS2_classifier.qza) in the 'reference_datasets' folder
## This script has been priovded to update the classifier with future datasets

echo "Starting at: $(date)"

NCORES=8
## Organise directories and subdirectories
path='path/to/your/project'                             # Path to the project's main directory
cd $path/reference_datasets/UNITE_QIIME_18_07_2023

#########################################################
######################################################### Scrub lowercase and blank spaces from UNITE database
######################################################### 

awk '/^>/ {print($0)}; /^[^>]/ {print(toupper($0))}' \
	sh_refs_qiime_ver9_dynamic_18.07.2023.fasta | tr -d ' ' > \
	sh_refs_qiime_ver9_dynamic_18.07.2023_uppercase.fasta

#########################################################
######################################################### Extract ITS subregions
#########################################################

module load ITSx/1.1.3-GCCcore-10.3.0
module load HMMER/3.3.2-gompi-2020b

ITSx \
  -i sh_refs_qiime_ver9_dynamic_18.07.2023_uppercase.fasta \
  --complement T \
  --save_regions all \
  --graphical F \
  --positions T \
  -E 1e-1 \
  -t all \
  --cpu $NCORES \
  --preserve T \
  -o ITSX

module purge

#########################################################
######################################################### Train classifier
#########################################################

module load QIIME2/2022.8

### Import data

qiime tools import \
    --type FeatureData[Sequence] \
    --input-path sh_refs_qiime_ver9_dynamic_18.07.2023_uppercase.fasta \
    --output-path ITS.qza

qiime tools import \
    --type FeatureData[Sequence] \
    --input-path sh_refs_qiime_ver9_dynamic_18.07.2023_uppercase.fasta \
    --output-path ITS1.qza

qiime tools import \
    --type FeatureData[Sequence] \
    --input-path sh_refs_qiime_ver9_dynamic_18.07.2023_uppercase.fasta \
    --output-path ITS2.qza

qiime tools import \
    --type FeatureData[Taxonomy] \
    --input-path sh_taxonomy_qiime_ver9_dynamic_18.07.2023.txt \
    --output-path sh_taxonomy_qiime_ver9_dynamic_18.07.2023.qza \
    --input-format HeaderlessTSVTaxonomyFormat

### Train classifier

qiime feature-classifier fit-classifier-naive-bayes \
   --i-reference-reads ITS.qza \
   --i-reference-taxonomy sh_taxonomy_qiime_ver9_dynamic_18.07.2023.qza \
   --o-classifier unite_classifier_ver8_dynamic_18.07.2023.qza

qiime feature-classifier fit-classifier-naive-bayes \
   --i-reference-reads ITS1.qza \
   --i-reference-taxonomy sh_taxonomy_qiime_ver9_dynamic_18.07.2023.qza \
   --o-classifier unite_classifier_ver8_dynamic_18.07.2023.qza

qiime feature-classifier fit-classifier-naive-bayes \
   --i-reference-reads ITS2.qza \
   --i-reference-taxonomy sh_taxonomy_qiime_ver9_dynamic_18.07.2023.qza \
   --o-classifier unite_classifier_ver8_dynamic_18.07.2023.qza

echo "Finished at: $(date)"