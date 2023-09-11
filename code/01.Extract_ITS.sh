#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH --partition=day

## Prepare paired-end Illumina data for denoising in QIIME2 using DADA2:
##  - This script is for data that has been demultiplexed.
##  - This script is for ITS2 data; change to ITS1 if analysing the ITS1 region.
##  - This script is for paired-end Illumina data; change to single-end mode if quality does not permit merging for paired-end analysis.
##  - NOTE: Paring reads is recommended as a critical quality filter step to remove erroneous sequences, such as chimeras and sequences that have been subjected to index bleeding.

## This pipeline has been developed for use on La Trobe University's HPC, LIMS.
## The LIMS-HPC does not currently have the required software installed for this initial ITS extraction step, so the following steps are required to install the software and create a conda environment for this pipeline
## Create a conda environment on the HPC: 
##  - Install mambforge into your root directory: see https://github.com/conda-forge/miniforge#mambaforge for details
##  - Create a conda environment using by running th following code: `mamba env create -f environemt.yml`

## Activate the conda environment
root='your/user/root'                           # Path to user root e.g. /data/group/'lab_name'/home/'user_name'/
source $root/mambaforge/etc/profile.d/conda.sh  # This line needs to be run because activating envionemnts in bash scrpits causes errors  
conda activate Extract_ITS

## Organise directories
path='path/to/your/project'                     # Your project path, which should contain 'data/01.Raw_data/' folders with demultiplexed 'fastq' files
raw_data=$path/data/01.Raw_data                 # Path to raw data
mkdir -p $path/data/02.Quality_check            # Create directory for quality check output
qualityCheck=$path/data/02.Quality_check        # Path to quality check output
mkdir -p $path/data/03.Primers_cut              # Create directory for cutadapt output
mkdir -p $path/data/03.Primers_cut/log          # Create directory for cutadapt log files
primersCut=$path/data/03.Primers_cut            # Path to cutadapt output
mkdir -p $path/data/04.ITS_extracted            # Create directory for ITSxpress output
ITSx=$path/data/04.ITS_extracted                # Path to ITSxpress output
## Set working directory
cd $path             

###################################################
################################################### FastQC and MultiQC - quality check
###################################################

echo Checking quality

## Unzip raw data if necessary
gzip -d $raw_data/*.gz

## Run FastQC
fastqc \
    -t $raw_data/*.fastq \
    -o $qualityCheck

## Combine FastQC reports into a single report
multiqc $qualityCheck/. \
    -o $qualityCheck

## Clean up FastQC output - delete individual reports
rm $qualityCheck/*fastqc.html $qualityCheck/*fastqc.zip

###################################################
################################################### Cutadapt - trim primers
###################################################

echo Trimming primers

## Remove primers using cutadapt
## NOTES:
##  - Anchor '^' the forward primer to start the read. This tells cutadapt where to look for the forward and improves primer detection, as cutadapt can be a bit fussy.
##  - Use the linked adapter option '...' with the reverse complement of the reverse primer. The length of the ITS region is highly variable, and many reads will include the reverse complement of the reverse primer as well as the index, which is not biological. 
##  - Do not anchor the reverse primer so that cutadapt can remove it from anywhere within the read.
##  - Discard untrimmed reads to remove reads that do not contain the forward primer. This is an important quality filtering step

cd $raw_data

fwd='your forward primer'
fwdRC='reverse compliment of your forward primer'
rev='your reverse primer'
revRC='reverse compliment of your reverse primer'

## Trim forward reads

for f in *R1.fastq; do

cutadapt \
	-a ^$fwd...$revRC \
    -e 0.1 \
	--overlap 16 \
    --discard-untrimmed \
	--cores 1 \
    --report full \
    --json $primersCut/log/${f}.json \
	-o $primersCut/${f} ${f}

done

# Trim reverse reads

for f in *_R2.fastq; do

cutadapt \
	-a ^$rev...$fwdRC \
    -e 0.1 \
	--overlap 16 \
    --discard-untrimmed \
	--cores 1 \
    --report full \
    --json $primersCut/log/${f}.json \
	-o $primersCut/${f} ${f}

done

## Create cutadapt summary report
multiqc $primersCut/log/*.json
rm $primersCut/log/*.json

###################################################
################################################### ITSxpress - extract ITS region
###################################################

echo Extracting the ITS region

## Extract ITS regions using ITSxpress
## NOTE: If you are using alternative quality filtering methods other than DADA2, such as VSEARCH, you can return a single merged file rather than unmerged files

for f in *_R1.fastq; do

    r=$(sed -e "s/_R1/_R2/" <<< "$f")

itsxpress \
    --fastq ${f} \
    --fastq2 ${r} \
    --cluster_id 1.0 \
    --region ITS2 \
    --taxa Fungi \
    --log $ITSx/logfile.txt \
    --outfile $ITSx/${f} \
    --outfile2 $ITSx/${r} \
    --threads 2

done

conda deactivate

###################################################
################################################### QIIME2 - import data into QIIME2
###################################################

echo Importing fastq files into QIIME2 

module load QIIME2/2022.8

qiime tools import \
    --type 'SampleData[PairedEndSequencesWithQuality]' \
    --input-path $path/data/manifest.csv \
    --output-path $ITSx/ITS_extracted_reads.qza \
    --input-format PairedEndFastqManifestPhred33

qiime demux summarize \
    --i-data $ITSx/ITS_extracted_reads.qza \
    --o-visualization $ITSx/ITS_extracted_reads.qzv

echo "Finished at: $(date)"