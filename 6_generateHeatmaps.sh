#!/bin/bash

module purge
module load deeptools/3.3.0
module load parallel/2017-05-22

mkdir matrix
mkdir heatmap

#generate txt file with bedfiles
echo BEDFILE > bedFileIDs.txt
ls path/to/bedfiles/*.bed >> bedFileIDs.txt

echo bedFiles are: 
cat bedFileIDs.txt

# specify bigwig folder to be used. In this case, we use the log2FC difference heatmaps with FR normalization
bigwigFolder_FR_Rep=difference_bigwig_FR_byRep
bigwigFolder_FR_mean=difference_bigwig_FR_meanRep

# make directories to store intermediate matricies 
parallel mkdir matrix/difference_bigwig_FR_byRep_log2_{1}_Ut_{2}_matricies -p ::: DMSO Thio1 Thio2 Thio4 Thio8 ::: Rep1 Rep2 Rep3
parallel mkdir matrix/difference_bigwig_FR_meanRep_log2_{1}_Ut_mean_matricies -p ::: DMSO Thio1 Thio2 Thio4 Thio8

# build matricies of bigwig signal over annotations specified by bed file in -R, set distance to include before (-b) and after (-a) annotation start and stop. 

# comment out what you dont need, but this script can build

# unscaled matrices for individual rep fold change centered at TSS sorted by locus length
###generate sample-bw.txt file with list of bigwig prefixes that are individual reps
###keep the header SAMPLESET by the following
#echo SAMPLESET > sample-bw.txt
#ls path/to/bigwigs/* >> sample-bw.txt

echo building log2 FC matrices by rep for all genes combined bedfile

parallel --header : computeMatrix reference-point \
	--referencePoint "TSS" -b 500 -a 5000 \
	-S difference_bigwig_FR_byRep/{SAMPLESET}.bw\
	-R bedfiles/{BEDFILE}.bed \
	--binSize 50 --missingDataAsZero --sortUsing region_length --averageTypeBins mean \
	-out matrix/difference_bigwig_FR_byRep_{SAMPLESET}_matricies/matrix_difference_bigwig_FR_byRep_{SAMPLESET}_{BEDFILE}_wholegene.gz \
	:::: bedFileIDs.txt :::: sample-bw.txt

# unscaled matrices for mean fold change centered at TSS sorted by locus length
###generate mean-bw.txt file with list of bigwig prefixes for mean bigwigs the header being SAMPLESET2

echo building mean log2 FC matrices for all genes in combined bedfile

parallel --header : computeMatrix reference-point \
	--referencePoint "TSS" -b 500 -a 5000 \
	-S difference_bigwig_FR_meanRep/{SAMPLESET2}.bw\
	-R bedfiles/{BEDFILE}.bed \
	--binSize 50 --missingDataAsZero --sortUsing region_length --averageTypeBins mean \
	-out matrix/difference_bigwig_FR_meanRep_{SAMPLESET2}_matricies/matrix_difference_bigwig_FR_meanRep_{SAMPLESET2}_{BEDFILE}_wholegene.gz \
	:::: bedFileIDs.txt :::: mean-bw.txt

#matrix generated for absolute Pol II occupancy for Ut sample for figure 5 where genes were split into quintiles

computeMatrix reference-point \
	--referencePoint "TSS" -b 500 -a 5000 \
	-S combined_bigwig_FR/Ut_mean.bw \
	-R bedfiles/quintile/Q1.bed bedfiles/quintile/Q2.bed bedfiles/quintile/Q3.bed bedfiles/quintile/Q4.bed bedfiles/quintile/Q5.bed \
	--binSize 50 --missingDataAsZero --sortUsing region_length --averageTypeBins mean \
	-out matrix/paper_figure/matrix_Ut-mean_absolute_wholegene.gz 

#matrix generated for log2 fold change for figure 5 where genes were split into quintiles
mkdir -p matrix/paper_figure

echo building wholegene matrix for all log2_FC_mean samples vs Ut split by quintile

computeMatrix reference-point \
	--referencePoint "TSS" -b 500 -a 5000 \
	-S difference_bigwig_FR_meanRep/log2_DMSO_Ut_mean.bw differencecp_bigwig_FR_meanRep/log2_Thio1_Ut_mean.bw differencecp_bigwig_FR_meanRep/log2_Thio2_Ut_mean.bw differencecp_bigwig_FR_meanRep/log2_Thio4_Ut_mean.bw differencecp_bigwig_FR_meanRep/log2_Thio8_Ut_mean.bw \
	-R bedfiles/quintile/Q1.bed bedfiles/quintile/Q2.bed bedfiles/quintile/Q3.bed bedfiles/quintile/Q4.bed bedfiles/quintile/Q5.bed \
	--binSize 50 --missingDataAsZero --sortUsing region_length --averageTypeBins mean \
	-out matrix/paper_figure/matrix_log2FC_all_wholegene.gz




# unscaled matrices sorted by locus length while removing signal after end of annotation
# Whole gene starting at TSS NAafterend
# for bigwig fold change



# >------END MATRIX GENERATION------------<


# generating heatmap eps directory structure to keep things organized
mkdir -p heatmap/paper_figure
mkdir -p sortorder/paper_figure

# >----------SPECIFY HEATMAPS TO GENERATE --------------<
#absolute heatmap for figure 5
echo plotting absolute mean Ut heatmap

plotHeatmap \
	-m matrix/paper_figure/matrix_Ut-mean_absolute_wholegene.gz \
	-out heatmap/paper_figure/heatmap_Ut_mean_absolute_wholegene.eps --dpi 600 \
	--sortUsing region_length --missingDataColor 1 --sortRegions ascend \
	--whatToShow 'plot, heatmap and colorbar' \
	--heatmapWidth 10 \
	--plotTitle Mean_Untreated \
	--outFileSortedRegions sortorder/paper_figure/sortorder_Q_Ut_mean_wholegene_absolute.bed


# Difference log2 fc heatmaps for figure 5
echo plotting mean log2 FC treatment vs Ut heatmap

plotHeatmap \
	-m matrix/paper_figure/matrix_log2FC_all_wholegene.gz \
	-out heatmap/paper_figure/heatmap_log2FC_all_wholegene.eps --dpi 600 \
	--sortUsing region_length --missingDataColor 1 --sortRegions ascend \
	--colorMap 'seismic' \
	--whatToShow 'plot, heatmap and colorbar' \
	--heatmapWidth 10 \
	--zMin -4 --zMax 4 \
	--plotTitle Mean_log2_FC_treatment_to_untreated \
	--outFileSortedRegions sortorder/paper_figure/sortorder_Q_mean-log2-FC_wholegene_absolute.bed
	

# >----------END HEATMAPS --------------<


# metaplot png output directory
mkdir -p metaplots/paper_figure

########Plotprofile with flag --perGroup to generate metaplots per bed file

plotProfile -m matrix/paper_figure/matrix_log2FC_all_wholegene.gz -out metaplots/paper_figure/medianofmean-log2FC_all_wholegene_metaplot.eps --averageType median --color \#e0e5f8 \#a7b7f3 \#3b61f2 \#0227c2 \#041d87 --yAxisLabel Median_log2-FC --perGroup --dpi 600 --plotHeight 7

exit 


