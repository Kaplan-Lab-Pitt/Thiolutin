#!/bin/bash

module load gcc/8.2.0
module load bowtie2/2.4.5
module load samtools/1.14
module load parallel/2017-05-22
module load bamtools/2.5.1
module load picard/2.18.12

mkdir sam
mkdir unmappedfastq
mkdir pombeBam
mkdir bam
mkdir hybridBam
mkdir QC
mkdir bowtie2_stats

sampleIDFile=fastq_paired/cp_paired_rename/sampleIDs.txt
echo sampleFile is "$sampleIDFile"

## PARAMETER JUSTIFICATION 
# aligning to hybrid Sc/Sp genome receiving input in form of a fastQ file (-q) allowing 1 mismatch (-N) not allowing more than 1000 bp insert size (-X)
parallel --header : bowtie2 -q -N 1 -X 1000 -x \
	additionalFiles/bowtie2_S288C_R64-3-1_Pombe2018-9-4_HybridGenomeBuild/bowtie2_S288C_R64-3-1_Pombe2018-9-4_HybridGenomeBuild \
	-1 fastq_paired/cp_paired_rename/{SAMPLE}_R1_paired.fastq \
	-2 fastq_paired/cp_paired_rename/{SAMPLE}_R2_paired.fastq \
	-S sam/{SAMPLE}_hybrid.sam 2> bowtie2_stats/{SAMPLE}_bowtie2.txt ::::  "$sampleIDFile" 

# converts sam to bam
parallel --header : samtools view -S -bh -q10 sam/{SAMPLE}_hybrid.sam '>' \
hybridBam/{SAMPLE}_hybrid.bam :::: "$sampleIDFile" 

# sorts bam file by name for picard duplicate removal
parallel --header : samtools sort -o hybridBam/{SAMPLE}_hybrid.namesorted.bam \
hybridBam/{SAMPLE}_hybrid.bam :::: "$sampleIDFile" 

# generates bai
parallel --header : samtools index hybridBam/{SAMPLE}_hybrid.namesorted.bam :::: "$sampleIDFile" 

mkdir QC/duplicateAssessment
# removing duplicates w/ picard
parallel --header : java -jar /ihome/crc/install/picard/2.18.12/picard.jar MarkDuplicates \
      I=hybridBam/{SAMPLE}_hybrid.namesorted.bam \
      O=hybridBam/{SAMPLE}_hybrid_noDups.bam \
      M=QC/duplicateAssessment/{SAMPLE}_hybrid_dupAnalysis.txt \
      REMOVE_DUPLICATES=true :::: "$sampleIDFile"

parallel --header : samtools index hybridBam/{SAMPLE}_hybrid_noDups.bam :::: "$sampleIDFile" 


# separate Sc bam from Sp bam
# note in custom hybrid genome build all Sp chromosomes have "lac"
# in the name, we can simply exclude or restrict to chromosomes that
# have names containing a string matching "lac"

# Sc only
parallel --header : samtools idxstats hybridBam/{SAMPLE}_hybrid_noDups.bam '|' cut -f 1 '|' grep -v pom_ '|' xargs samtools view -b hybridBam/{SAMPLE}_hybrid_noDups.bam '>' bam/{SAMPLE}.bam :::: "$sampleIDFile" 

parallel --header : samtools index bam/{SAMPLE}.bam :::: "$sampleIDFile" 

#Sp only
parallel --header : samtools idxstats hybridBam/{SAMPLE}_hybrid_noDups.bam '|' cut -f 1 '|' grep pom_ '|' xargs samtools view -b hybridBam/{SAMPLE}_hybrid_noDups.bam '>' pombeBam/{SAMPLE}_pombe.bam :::: "$sampleIDFile" 


parallel --header : samtools index pombeBam/{SAMPLE}_pombe.bam :::: "$sampleIDFile" 

