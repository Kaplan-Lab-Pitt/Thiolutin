#!/bin/bash

# loading modules
module load gcc/8.2.0
module load java/1.8.0_181-oracle
module load trimmomatic/0.38
module load fastqc/0.11.9
module load parallel/2017-05-22

mkdir fastq
# copying fastq files to analysis directory
cp path/to/fastq-files/* fastq/

## this here was used to build a list of sample IDs that was used throughout pipeline
###sampleIDs are the sample prefixes
###following can be modified according to your fastq filename

echo SAMPLE > sampleIDs.txt
ls fastq/*R1* | awk -F '[/]' '{print $2}' | awk -F '[_]' '{print $1 "_" $2 "_" $3 }' >> sampleIDs.txt

mkdir fastq_paired
mkdir fastq_unpaired


# first we trim the reads to remove adaptor sequences 
# Feed it the input FQs then the output FQ names for R1 and R2 files
# note that that the mate pair of a paired end read might be discared in the unpaired file 
# retains those lonely reads while the paired fastq discards them

parallel --header : java -jar ../trimmomatic/trimmomatic-0.38.jar \
	PE fastq/{SAMPLE}*_R1.fastq.gz \
	fastq/{SAMPLE}*_R2.fastq.gz \
	fastq_paired/{SAMPLE}_R1_paired.fastq \
	fastq_unpaired/{SAMPLE}_R1_unpaired.fastq \
	fastq_paired/{SAMPLE}_R2_paired.fastq \
	fastq_unpaired/{SAMPLE}_R2_unpaired.fastq \
	ILLUMINACLIP:../TruSeq3-PE-2.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 :::: sampleIDs.txt 


# run fastqc on every fastq file
fastqc fastq/*

# generate a summary report of all of the fastq file qcs in your folder
multiqc fastq/.

