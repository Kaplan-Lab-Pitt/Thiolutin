#!/bin/bash


module load deeptools/3.3.0
module load gcc/8.2.0
module load samtools/1.14
module load bamtools/2.5.1
module load parallel/2017-05-22 

# cat fastqIDs.txt | tail -n +2 > "$sampleIDFile"
# sort "$sampleIDFile" | tail -n +2 > sampleIDsNames
# cat SAMPLE sampleIDsNames > "$sampleIDFile"
# cat "$sampleIDFile"

sampleIDFile=fastq_paired/cp_paired_rename/sampleIDs.txt
echo sampleFile is "$sampleIDFile"

mkdir alignmentCountData 
mkdir alignmentCountData/pombeBam
#mkdir alignmentCountData/lactisBam
mkdir alignmentCountData/bam
mkdir bigwig

# run counts for S.c. and spike in
# note -F 260 indicates that reads unmapped and or not primary alignment are excluded from counting
parallel --header :  samtools view -c -F 260 bam/{SAMPLE}.bam  '>' alignmentCountData/bam/{SAMPLE}_counts.txt :::: "$sampleIDFile" 

parallel --header :  samtools view -c -F 260 pombeBam/{SAMPLE}_pombe.bam '>' alignmentCountData/pombeBam/{SAMPLE}_counts.txt :::: "$sampleIDFile" 

#parallel --header :  samtools view -c -F 260 lactisBam/{SAMPLE}_lactis.bam '>' alignmentCountData/lactisBam/{SAMPLE}_counts.txt :::: "$sampleIDFile" 

# prints the counts for every entry in alignmentCountData folder, chooses every 1st or 2nd line to print out the file name and the count respectively
# note if the sample doesn't have a correlating bam file for the spike in counted, then it will generate an empty line where the counts should be
tail -n +1  `ls alignmentCountData/bam/*` | grep "=" | awk -F '[/]' '{print $3}' | sed 's/...............$//' > alignmentCountData/cerevisiaeCountOrder.txt
tail -n +1  `ls alignmentCountData/bam/*` | sed -n '/=/{n;p}'  > alignmentCountData/cerevisiaeCounts.txt
tail -n +1  `ls alignmentCountData/pombeBam/*` | grep "=" | awk -F '[/]' '{print $3}' | sed 's/...............$//' > alignmentCountData/pombeCountOrder.txt
tail -n +1  `ls alignmentCountData/pombeBam/*` | sed -n '/=/{n;p}'  > alignmentCountData/pombeCounts.txt
#tail -n +1  `ls alignmentCountData/lactisBam/*` | grep "=" | awk -F '[/]' '{print $3}' | sed 's/...............$//' > alignmentCountData/lactisCountOrder.txt
#tail -n +1  `ls alignmentCountData/lactisBam/*` | sed -n '/=/{n;p}'   > alignmentCountData/lactisCounts.txt

# checks if the count orders are indeed the same for both spike in and cerevisiae
diff alignmentCountData/cerevisiaeCountOrder.txt alignmentCountData/pombeCountOrder.txt
#diff alignmentCountData/cerevisiaeCountOrder.txt alignmentCountData/lactisCountOrder.txt

# combines pombe, lactis, and cerevisiae counts into one matrix
#paste alignmentCountData/cerevisiaeCountOrder.txt alignmentCountData/cerevisiaeCounts.txt alignmentCountData/pombeCounts.txt alignmentCountData/lactisCounts.txt > alignmentCountData/allAlignmentsCountsTable.txt
paste alignmentCountData/cerevisiaeCountOrder.txt alignmentCountData/cerevisiaeCounts.txt alignmentCountData/pombeCounts.txt > alignmentCountData/allAlignmentsCountsTable.txt

# specifically pull out input and IP counts 
grep "INPUT" alignmentCountData/allAlignmentsCountsTable.txt > alignmentCountData/allInputsCountsTable.txt
grep -v "INPUT" alignmentCountData/allAlignmentsCountsTable.txt > alignmentCountData/allIPsCountsTable.txt

# from here import allAlignmentsCountsTable.txt to R to calculate Scaling Factor 


