# Thiolutin
Scripts for manuscript on thiolutin treatment of yeast
The scripts work sequentially on samples working from fastq through generating heatmaps generated for figures
The scripts are run sequentially with input being the output of the preceding script
Order of scripts is annotated by the prefixes. Scripts also require additional files to run, such as bedFileIDs.txt and sampleInfo.csv
Examples of above files are also provided

1_fastq_trimming.sh performs FastQC on fastq files and trims adaptors with paired and unpaired read output
2_bowtie2alignment_Pom1.sh aligns paired reads to reference S.cerevisiae-S.pombe hybrid genome
3_bamSpikeInSampleCount.sh counts total number of reads in spike in and S.cereveisiae in both input and IP samples
4_ChIPSSeqSpikeInNorm.R generates normalization factors from total read counts estimated by the previous script
5_bamcoverage.sbatch spike-in normalized bigwigs, combines bigwigs to generate average bigwigs and performs log2fc on bigwigs between conditions for difference heatmaps
6_generateHeatmaps.sh generates matrices from bigwigs to and then generates heatmaps and metaplots.
