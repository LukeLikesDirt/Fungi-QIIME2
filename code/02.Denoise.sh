#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH --partition=day

echo "Starting at: $(date)"

## Organise directories and subdirectories
path='path/to/your/project'                       # Path to the project's main directory, in which the '04.ITS_Extracted' subdirectory is located
cd $path
ITSx=$path/data/04.ITS_extracted                  # Path to the '04.ITS_Extracted' subdirectory, where the ITS extracted files are stored
denoised=$path/data/05.Denoised                   # Path to the output subdirectory for denoised data
ref_seqs=$path/data/reference_datasets

## Load qqime2
module load QIIME2/2022.8

#########################################################
######################################################### Denoise data using DADA2
######################################################### 

## NOTE: 'maxEE=2' is a relaxed error rate for programs such as VSEARCH/UNOISE2, where 'maxEE=1' is a more appropriate error parameter.
## The more 'relaxed' filtering approach in DADA2 of 'maxEE=2' is appropriate as that algorithm DADA2 accounts for sequence quality in its error model.

## There should be no need to trim or truncate if ITS subregions have been extracted as ITSxpress implements a VSEARCH quality filtering step.
## However, you can check the 'ITS_extracted_reads.qzv' file in the '04.ITS_Extracted' folder to ensure quality is good at the distal ends.

## DADA2 gives you the option of two types of chimera filtering: 
## 'consensus' (default) does de novo identification in each sample, takes a vote across samples, and removes all ASVs identified as chimeras in a high enough fraction of the samples in which they were present
## 'pooled' lumps all ASVs in the data into one big sample and identifies and removes chimeras that way.
## The 'consensus' method performs better for typical datasets/workflows.

qiime dada2 denoise-paired \
    --i-demultiplexed-seqs $ITSx/ITS_extracted_reads.qza \
    --p-trunc-len-f 0 \
    --p-trunc-len-r 0 \
    --p-trim-left-f 0 \
    --p-trim-left-r 0 \
    --p-max-ee-f 2 \
    --p-max-ee-r 3 \
    --output-dir $denoised \
    --verbose

qiime tools export \
    --input-path $denoised/denoising_stats.qza \
    --output-path $denoised

qiime feature-table summarize \
    --i-table $denoised/table.qza \
    --o-visualization $denoised/table.qzv

#########################################################
######################################################### Reference-based chimera filtering with vsearch
######################################################### 

## This step is optional but recommended as most reference-based chimeras tend to be true chimeras.

## Import refernece dataset into qiime2
## This step has been commented out because it has already been completed (see the available 'uchimeRef_ITS2.qza' file in the 'reference_datasets' folder
## Uncomment and re-run this step to update the reference dataset
## See the 'README.md' file in the 'data' folder for instructions on where to find the latest UNITE database
#uchimeRef_ITS2_fasta=$ref_seqs/uchime_reference_dataset_16_20_2022_ITS2.fasta
#qiime tools import \
    --type FeatureData[Sequence] \
    --input-path $uchimeRef_ITS2_fasta \
    --output-path $ref_seqs/uchimeRef_ITS2.qza

## Run VSEARCH reference-based chimera filtering

## Path to reference dataset in qza format
uchimeRef_ITS2=$ref_seqs/uchimeRef_ITS2.qza

qiime vsearch uchime-ref \
  --i-table $denoised/table.qza \
  --i-sequences $denoised/representative_sequences.qza \
  --i-reference-sequences $uchimeRef_ITS2 \
  --output-dir $denoised/uchime_output

qiime metadata tabulate \
  --m-input-file $denoised/uchime_output/stats.qza \
  --o-visualization $denoised/uchime_output/stats.qzv

## Filter chimeras from the table and representative sequences

## OPTION 1: Exclude chimeras and 'borderline chimeras' - likely to result in few false positives
## This option is active by default in the script

qiime feature-table filter-features \
  --i-table $denoised/table.qza \
  --m-metadata-file $denoised/uchime_output/nonchimeras.qza \
  --o-filtered-table $denoised/uchime_output/table_nonchimeric.qza
qiime feature-table filter-seqs \
  --i-data $denoised/representative_sequences.qza \
  --m-metadata-file $denoised/uchime_output/nonchimeras.qza \
  --o-filtered-data $denoised/uchime_output/rep_seqs_nonchimeric.qza
qiime feature-table summarize \
  --i-table $denoised/uchime_output/table_nonchimeric.qza \
  --o-visualization $denoised/uchime_output/table_nonchimeric.qzv

## OPTION 2: Exclude chimeras but retain 'borderline chimeras' - likely to result in some false negatives
## Uncomment the following lines to activate this option, and comment out the lines in OPTION 1 above to deactivate that option

#qiime feature-table filter-features \
  --i-table atacama-table.qza \
  --m-metadata-file $denoised/uchime_output/chimeras.qza \
  --p-exclude-ids \
  --o-filtered-table $denoised/uchime_output/table-nonchimeric-w-borderline.qza
#qiime feature-table filter-seqs \
  --i-data atacama-rep-seqs.qza \
  --m-metadata-file $denoised/uchime_output/chimeras.qza \
  --p-exclude-ids \
  --o-filtered-data $denoised/uchime_output/rep-seqs-nonchimeric-w-borderline.qza
#qiime feature-table summarize \
  --i-table $denoised/uchime_output/table-nonchimeric-w-borderline.qza \
  --o-visualization $denoised/uchime_output/table-nonchimeric-w-borderline.qzv

echo "Finished at: $(date)"