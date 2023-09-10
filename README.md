# Fungal metabarcoding pipeline in QIIME2 for Illumina paired-end reads

## Introduction

In this repository, you will find a QIIME2 pipeline for the processing of ITS (fungi) paired-end reads. This pipeline has been optimised for fungi, considering particularly the high levels of within-species variability in the composition and length of the ITS region compared to the 16S region.

This pipeline is loosely based on the recommendations from the following publications:
 - [Best practices in metabarcoding of fungi: From experimental design to results](https://onlinelibrary.wiley.com/doi/full/10.1111/mec.16460)
 - [ITS alchemy: On the use of ITS as a DNA marker in fungal ecology](https://www.sciencedirect.com/science/article/pii/S175450482300051X)

## Programs used
 - [FastQC v0.12.1](https://github.com/s-andrews/FastQC)
 - [MultiQC v1.15](https://github.com/s-andrews/FastQC)
 - [Cutadapt v4.4](https://cutadapt.readthedocs.io/en/stable/)
 - [ITSxpress v2.0.0](https://github.com/USDA-ARS-GBRU/itsxpress)
 - [VSEARCH v2.22.1](https://github.com/torognes/vsearch)
 - [QIIME2 v2022.8](https://qiime2.org/)

## Repository map

## Additional information

This script has been developed for the Applied and Environmental Microbiology Group, La Trobe University, Melbourne, Australia. The code is ready to run on the LIMS-HPC at La Trobe University. However, as the LIMS-HPC does not have the 'ITSxprss' package installed, the ITS extraction step needs to either be run in the 'Extract_ITS' environment or on your local computer. To create the 'Extract_ITS' environment on the HPC run the following line: `conda env create -f environment.yml`. Otherwise, create the 'Extract_ITS' environment on your local computer using either conda or preferably mamaba. See the '01.Extract_ITS.sh' script for more details.