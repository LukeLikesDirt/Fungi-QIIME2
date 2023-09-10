#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH --partition=day

## Prepare paired-end Illumina data for denoising in QIIME2 using DADA2:
##  - This script has been developed for the Applied and Environmental Microbiology Group, La Trobe University, Melbourne, Australia. 
##  - This script is for data that has been demultiplexed.
##  - This script is for ITS2 data; change to ITS1 if analysing the ITS1 region.
##  - This script is for paired-end Illumina data; change to single-end mode if quality does not permit merging for paired-end analysis.
##  - NOTE: Paring reads is recommended as a critical quality filter step to remove erroneous sequences, such as chimeras and sequences that have been subjected to index bleeding.
##  - This first step is done on your local computer because of issues in having ITSxpress installed on the La Trobe HPC; change to HPC if you have ITSxpress installed there. 

## Required software:
##  - miniconda (or conda): https://docs.conda.io/projects/miniconda/en/latest/
##  - micromamba (or mamba): https://mamba.readthedocs.io/en/latest/user_guide/micromamba.html (mamba is optional and can be replaced with conda, but mamba is recommended for faster package installations)
##  - fastqc: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
##  - multiqc: https://multiqc.info/
##  - cutadapt: https://cutadapt.readthedocs.io/en/stable/
##  - ITSxpress: https://github.com/usda-ars-gbru/itsxpress

## Create a conda environment for ITS extraction
#micromamba env create -f environment.yml   # Alternatively, use 'conda env create -f environment.yml', but micromamba is faster

## Activate the conda environment
#micromamba activate Extract_ITS            # Alternatively, use 'conda activate Extract_ITS'; $eval "$(micromamba shell hook --shell bash)" may be required to activate micromamba
conda activate Extract_ITS

## Organise directories
path='path/to/your/project'                      # Path to the project directory, which contains a 'data' subdirectory with a'01.Raw_data' subdirectory with demultiplexed 'fastq' files
cd $path
raw_data=$path/data/01.Raw_data                  # Subdirectory containing the raw data
mkdir -p $path/data/02.Quality_check             # Subdirectory for quality check output
qualityCheck=$path/data/02.Quality_check     
mkdir -p $path/data/03.Primers_cut               # Subdirectory for cutadapt output
mkdir -p $path/data/03.Primers_cut/log           # Subdirectory for cutadapt log files
primersCut=$path/data/03.Primers_cut          
mkdir -p $path/data/04.ITS_extracted             # Subdirectory for ITSxpress output
ITSx=$path/data/04.ITS_extracted             

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