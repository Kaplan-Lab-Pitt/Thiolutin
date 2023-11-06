#!/bin/bash

moduel purge
module load deeptools/3.3.0
module load parallel/2017-05-22
module load kentutils/v370
module load wiggletools/1.2.11

#sampleIDFile=fastq_paired/cp_paired_rename/sampleIDs.txt
#echo sampleFile is "$sampleIDFile"

module restore

# modify the following files according to your filenames
##We initialy had sample sample named C1 through C18 each IP and INPUT that we renamed the submitted fastq files to
awk -F '[,]' '{print $1}' alignmentCountData/spikeInNormFactorTable_ICPM.txt | tail -n +2 > alignmentCountData/sampleOrder.txt

awk -F '[,]' '{print $2}' alignmentCountData/spikeInNormFactorTable_ICPM.txt | tail -n +2 > alignmentCountData/scalingFactor.txt


# set target output bigwig folder name for francois robert normalized bigwig
bigwigFolder=bigwig_FR


# make normalized bigwigs from scaling factors calculated in R
# with extended reads
mkdir "$bigwigFolder"
parallel bamCoverage \
	--bam bam/{1}*.bam \
	--outFileName "$bigwigFolder"/{1}*.bw \
	--outFileFormat bigwig \
	--scaleFactor {2} \
	--extendReads \
	--binSize 1 :::: alignmentCountData/sampleOrder.txt :::: alignmentCountData/scalingFactor.txt



##rename files such that following commands work
####We initialy had sample sample named C1 through C18 each IP and INPUT that we renamed the submitted fastq files to

####using wiggletools to find average of bigwig files with output in bedgraph
mkdir combined"$bigwigFolder"
parallel wiggletools \
	write_bg combined"$bigwigFolder"/{1}_mean.bedgraph mean strict \
	"$bigwigFolder"/{1}_Rep1.bw \
	"$bigwigFolder"/{1}_Rep2.bw \
	"$bigwigFolder"/{1}_Rep3.bw \
	::: Ut DMSO Thio1 Thio2 Thio4 Thio8
	


#####convert mean bedgraph to bigwig

parallel bedGraphToBigWig \
	combined_"$bigwigFolder"/{1}_mean.bedgraph \
	chrom.txt\
	combined_"$bigwigFolder"/{1}_mean.bw\
	::: Ut DMSO Thio1 Thio2 Thio4 Thio8


# calculate log2 fold change between conditions by individual reps
#This can be used for difference heatmaps or metaplots

mkdir difference_"$bigwigFolder"_byRep
 parallel bigwigCompare \
	-b1 "$bigwigFolder"/{1}_{2}.bw \
	-b2 "$bigwigFolder"/Ut_{2}.bw \
	--operation log2 \
	-o difference_"$bigwigFolder"_byRep/log2_{1}_Ut_{2}.bw \
	--binSize 1 \
	:::  DMSO Thio1 Thio2 Thio4 Thio8 ::: Rep1 Rep2 Rep3
 

# calculate log2 fold change between conditions by mean of reps
##the bigwigs here were used for generating difference heatmaps

mkdir difference_"$bigwigFolder"_meanRep
 parallel bigwigCompare \
	-b1 combined_"$bigwigFolder"/{1}_mean.bw \
	-b2 combined_"$bigwigFolder"/Ut_mean.bw \
	--operation log2 \
	-o difference_"$bigwigFolder"_meanRep/log2_{1}_Ut_mean.bw \
	--binSize 1 \
	:::  DMSO Thio1 Thio2 Thio4 Thio8

exit



