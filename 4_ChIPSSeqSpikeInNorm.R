#setwd("/path/to/allAlignmentsCountsTable.txt")
library(tidyverse)

# import counts and metadata
allCounts <- as.data.frame(read.csv("allAlignmentsCountsTable.txt", header = F, sep = "\t"))
sampleInfo <- as.data.frame(read.csv("sampleInfo.csv", header = T, sep = ","))

# label count columns appropriately 
colnames(allCounts) <- c("Sample", "Sc_Counts", "Sp_Counts")

# label count row as INPUT or IP
allCounts$INPUT <- case_when(str_detect(allCounts$Sample, "INPUT") ~ "INPUT",
                             str_detect(allCounts$Sample, "INPUT", negate = TRUE) ~ "IP")

# lops of last 5 characters of sample name then keeps the last 3 of what remains
allCounts$IPBatch <- str_sub(allCounts$Sample,1,nchar(allCounts$Sample)-5) %>% str_sub(., -3, -1)
RepsandIPID <- str_sub(allCounts$Sample, -8, -1)
# assigns appropriate condition per row
allCounts$Condition <- sampleInfo[match(allCounts$Sample, sampleInfo$fastqID), "Condition"]
# produces a unique IPID to match inputs with their appropriate IPs
allCounts$IPID <- paste(sep = "_", allCounts$Condition, RepsandIPID)

# separate input from IP counts then match them with their corresponding IP (should work for multiple IPs from same input)
# then pastes the input spike in and sample counts to the matching IP row
inputCounts <- allCounts[allCounts$INPUT == "INPUT",]
IPCounts <- allCounts[allCounts$INPUT != "INPUT",]
# use this if just doing one spike in
# inputCounts <- inputCounts[match(IPCounts$IPID,inputCounts$IPID ), 1:3]
inputCounts <- inputCounts[match(IPCounts$IPID,inputCounts$IPID ), 1:4]
colnames(inputCounts) <- paste0("INPUT_", colnames(inputCounts))
allCountsIPINPUTGrouped <- cbind(IPCounts, inputCounts)

attach(allCountsIPINPUTGrouped)

# Francois-Robert style normalziation is done by dividing the number of spike-in counts of Input (N_spIN) by the product of 
# the number of spike in counts in the IP (N_spIP) and the number of cerevisiae counts in the input (N_scIN)
allCountsIPINPUTGrouped$Sp_spikeInNormFactor <- (INPUT_Sp_Counts/100000000)/((Sp_Counts/100000000) * (INPUT_Sc_Counts/100000000))


# view(allCountsIPINPUTGrouped)
attach(allCountsIPINPUTGrouped)

# Select the IPs that used Sp to use the Sp counts for the norm factor
allCountsIPINPUTGrouped$spikeInNormFactor <- case_when( str_detect(IPBatch, "IP1|IP2|IP3|IP4|IP5|IP6|IP7|IP8|IP9|P10|P11|P12|P13|P14|P15|P16|P17|P18") ~ Sp_spikeInNormFactor)

# calculates fraction of each sample that were aligned to Sp  
allCounts$SpFraction_IP <- allCounts$Sp_Counts/(allCounts$Sp_Counts + allCounts$Sc_Counts)

# write out results files
write.csv(cbind(allCountsIPINPUTGrouped$Sample, allCountsIPINPUTGrouped$spikeInNormFactor), "spikeInNormFactorTable.txt", quote = F, row.names = F)
write.csv(allCounts, "countsAnalysis.csv", quote = F, row.names = F)
write.csv(allCountsIPINPUTGrouped, "countsAnalysisGrouped.csv", quote = F, row.names = F)




