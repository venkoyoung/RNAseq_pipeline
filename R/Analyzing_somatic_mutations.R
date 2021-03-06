#---
#title: "Analyzing somatic mutations in RNA-seq data"
#author: "Yang Hu"
#date: "2017/5/3"
#output:
#html_document: default
#---

## Abstract

#It is part of a workflow for analyzing RNA-seq data from Waldenstrom Macroglobulinemia patients, in a cohort called "zhunter," from Harvard University. After Alignment, samtools sort, VarScan and Annotation, an annotated zhunter_Annotated.eff(data).vcf is generated like below:

#|#CHROM	| POS	 | ID	    | REF	|ALT	|QUAL |FILTER |INFO       |FORMAT|ZH10_NWM07_CTTGTA_L005_R1_001              |...|
#|:-----:|:------:|:--------:|:-----:|:-----:|:---:|:-----:|:---------:|:---:|:-----------------------------:|:-:|
#|chr11	|47376915|.|G	    |C      |.	  |PASS   |..EFF=missense_variant..|GT:GQ:SDP:DP:RD:AD:FREQ:PVAL:RBQ:ABQ:RDF:RDR:ADF:ADR|0/0:22:11:11:11:0:0%:1E0:39:0:7:4:0:0||...|

#In part A, script will add gene name, label "MISSENSE/NONSENSE" , extract FREQ%, add counts, and filter out SNP like below:

#|CHROM	| POS	 |Gene_POS	|gene	| ID| REF	|ALT	|QUAL |FILTER |INFO      |counts|ZH10_NWM07_CTTGTA_L005_R1_001|...|
#|:-----:|:------:|:--------:|:-----:|:-----:|:---:|:-----:|:---------:|:---:|:-----------------------------:|:-:|:-----:|:------:|
#|chr11	|47376915	|SPI1 47376915	|SPI1	|.	|G	|C	|.	|PASS	|MISSENSE	|9	|0|..|

#In part B, script will read FPKM results and cluster somatic mutations.

## A) Reading Annotated vcf, add gene names and annotations
#### A-1) Setup enviroment
Project = "zhunter"
data_dir = paste(getwd(),"data",Project,"Mutation",sep = "/")
#Double check to sort sample_table_zhunter$SampleList_zhunter_ID, must be the same order as zhunter_Annotated.eff.vcf
sample_table_zhunter<- read.csv(paste0(data_dir,"/sample_table_zhunter.csv"),sep=",",header =T)
zhunter_Sample_name <- as.data.frame(sample_table_zhunter$Sample_name)
zhunter_Sample_ID<- as.data.frame(sample_table_zhunter$Sample_ID)
AnnotatedVcf_zhunter <- read.csv(paste0(data_dir,"/zhunter_Annotated.eff.vcf"),sep="\t",header =T) #Get zhunter_Annotated.eff.vcf
dim(AnnotatedVcf_zhunter)
#rename AnnotatedVcf_zhunter
for (i in 1:nrow(zhunter_Sample_name)){
        names(AnnotatedVcf_zhunter)[9+i]<- as.character(zhunter_Sample_name[i,1])#renmae after column 9
}
#Generate a new file `AnnotatedVcf_zhunter_new.csv`.

AnnotatedVcf_zhunter_new <-AnnotatedVcf_zhunter[,1:2]


#### A-2) Add gene names

AnnotatedVcf_zhunter_new[,"Gene_POS"]<-NA #add a empty column to a dataframe
colnames(AnnotatedVcf_zhunter_new)[1]<-"CHROM" # was #CHORM previously
for(i in 1:(nrow(AnnotatedVcf_zhunter)-1)){
        if (AnnotatedVcf_zhunter_new[i,"POS"] >= 27022522 && AnnotatedVcf_zhunter_new[i,"POS"] <=27108601 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr1")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("ARID1A ",AnnotatedVcf_zhunter_new[i,"POS"])
        AnnotatedVcf_zhunter_new[i,"gene"] <- "ARID1A"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 136871919 && AnnotatedVcf_zhunter_new[i,"POS"] <=136873813 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr2")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("CXCR4 ",AnnotatedVcf_zhunter_new[i,"POS"])
        AnnotatedVcf_zhunter_new[i,"gene"] <- "CXCR4"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 38179969 && AnnotatedVcf_zhunter_new[i,"POS"] <=38184512 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr3")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("MYD88 ",AnnotatedVcf_zhunter_new[i,"POS"]);
        AnnotatedVcf_zhunter_new[i,"gene"] <- "MYD88"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 2743387 && AnnotatedVcf_zhunter_new[i,"POS"] <=2757752 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr4")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("TNIP2 ",AnnotatedVcf_zhunter_new[i,"POS"]);
        AnnotatedVcf_zhunter_new[i,"gene"] <- "TNIP2"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 78432907 && AnnotatedVcf_zhunter_new[i,"POS"] <=78532988 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr4")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("CXCL13 ",AnnotatedVcf_zhunter_new[i,"POS"]);
        AnnotatedVcf_zhunter_new[i,"gene"] <- "CXCL13"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 121613068 && AnnotatedVcf_zhunter_new[i,"POS"] <=121844021 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr4")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("PRDM5 ",AnnotatedVcf_zhunter_new[i,"POS"]);
        AnnotatedVcf_zhunter_new[i,"gene"] <- "PRDM5"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 122052564 && AnnotatedVcf_zhunter_new[i,"POS"] <=122137782 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr4")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("TNIP3 ",AnnotatedVcf_zhunter_new[i,"POS"]);
        AnnotatedVcf_zhunter_new[i,"gene"] <- "TNIP3"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 150409504 && AnnotatedVcf_zhunter_new[i,"POS"] <=150460645 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr5")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("TNIP1 ",AnnotatedVcf_zhunter_new[i,"POS"])
        AnnotatedVcf_zhunter_new[i,"gene"] <- "TNIP1"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 143072604 && AnnotatedVcf_zhunter_new[i,"POS"] <=143266338 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr6")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("HIVEP2 ",AnnotatedVcf_zhunter_new[i,"POS"]);
        AnnotatedVcf_zhunter_new[i,"gene"] <- "HIVEP2"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 95947212 && AnnotatedVcf_zhunter_new[i,"POS"] <=96081655 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr22")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("IGLL5 ",AnnotatedVcf_zhunter_new[i,"POS"])
        AnnotatedVcf_zhunter_new[i,"gene"] <- "IGLL5"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 38177969 && AnnotatedVcf_zhunter_new[i,"POS"] <=38186512 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr9")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("WNK2 ",AnnotatedVcf_zhunter_new[i,"POS"])
        AnnotatedVcf_zhunter_new[i,"gene"] <- "WNK2"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 44953899 && AnnotatedVcf_zhunter_new[i,"POS"] <=44971759 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr11")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("TP53I11 ",AnnotatedVcf_zhunter_new[i,"POS"])
        AnnotatedVcf_zhunter_new[i,"gene"] <- "TP53I11"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 47376409 && AnnotatedVcf_zhunter_new[i,"POS"] <=47400127 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr11")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("SPI1 ",AnnotatedVcf_zhunter_new[i,"POS"])
        AnnotatedVcf_zhunter_new[i,"gene"] <- "SPI1"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 53773979 && AnnotatedVcf_zhunter_new[i,"POS"] <=53810226 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr12")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("SP1 ",AnnotatedVcf_zhunter_new[i,"POS"])
        AnnotatedVcf_zhunter_new[i,"gene"] <- "SP1 "}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 43699412 && AnnotatedVcf_zhunter_new[i,"POS"] <=43785354 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr15")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("TP53BP1 ",AnnotatedVcf_zhunter_new[i,"POS"])
        AnnotatedVcf_zhunter_new[i,"gene"] <- "TP53BP1"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 7571720 && AnnotatedVcf_zhunter_new[i,"POS"] <=7590868 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr17")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("TP53 ",AnnotatedVcf_zhunter_new[i,"POS"])
        AnnotatedVcf_zhunter_new[i,"gene"] <- "TP53"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 20715727 && AnnotatedVcf_zhunter_new[i,"POS"] <=20840434 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr18")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("CABLES1 ",AnnotatedVcf_zhunter_new[i,"POS"])
        AnnotatedVcf_zhunter_new[i,"gene"] <- "CABLES1"}
        else if(AnnotatedVcf_zhunter_new[i,"POS"] >= 23229960 && AnnotatedVcf_zhunter_new[i,"POS"] <=23238013 && AnnotatedVcf_zhunter_new[i,"CHROM"]=="chr22")
        {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0("IGLL5 ",AnnotatedVcf_zhunter_new[i,"POS"])
        AnnotatedVcf_zhunter_new[i,"gene"] <- "IGLL5"}
        else {AnnotatedVcf_zhunter_new[i,"Gene_POS"] <- paste0(" ",AnnotatedVcf_zhunter_new[i,"POS"])
        AnnotatedVcf_zhunter_new[i,"gene"] <- NA}
}
AnnotatedVcf_zhunter<-AnnotatedVcf_zhunter[!is.na(AnnotatedVcf_zhunter_new[,"gene"]),]
AnnotatedVcf_zhunter_new<-AnnotatedVcf_zhunter_new[!is.na(AnnotatedVcf_zhunter_new[,"gene"]),]
rownames(AnnotatedVcf_zhunter_new)<-AnnotatedVcf_zhunter_new[,"Gene_POS"]

#### A-3) Add MISSENSE & NONSSENSE annotations

AnnotatedVcf_zhunter_new<-cbind(AnnotatedVcf_zhunter_new,AnnotatedVcf_zhunter[,3:7])

AnnotatedVcf_zhunter_new[,"INFO"]<-NA #add a empty column to a dataframe
AnnotatedVcf_zhunter_new[grep("MISSENSE",AnnotatedVcf_zhunter[,"INFO"]),"INFO"]<-"MISSENSE"  #Add MISSENSE INFO
AnnotatedVcf_zhunter_new[grep("NONSENSE",AnnotatedVcf_zhunter[,"INFO"]),"INFO"]<-"NONSENSE" #Add MISSENSE INFO
intersect <- intersect(grep("NONSENSE",AnnotatedVcf_zhunter[,"INFO"]),grep("MISSENSE",AnnotatedVcf_zhunter[,"INFO"])) #find intersect
AnnotatedVcf_zhunter_new[intersect,"INFO"]<-"MISSENSE & NONSENSE" #Add both


#### A-4) Extract FREQ% data from column 10 to 84


library(stringr)
AnnotatedVcf_zhunter_new[,"counts"]<-NA #add a empty column to a dataframe
Sample<-AnnotatedVcf_zhunter[,c(10,11)] #Generate a temp dataframe with correct dimension
colnames(Sample)<-c("Sample1","Sample2")
for(i in 1:nrow(zhunter_Sample_ID)){
        Sample[,"Sample1"]<-str_split_fixed(AnnotatedVcf_zhunter[,i+9], ":", 14)[,7] #Split column and only extract FREQ%
        Sample[,"Sample1"]<-as.numeric(sub("%","",Sample[,"Sample1"])) #convert character of percentage into numeric
        Sample[,"Sample1"][is.na(Sample[,"Sample1"])]<- 0 #replace NA values with zeros
        AnnotatedVcf_zhunter_new <- cbind(AnnotatedVcf_zhunter_new, Sample[,"Sample1"])
        colnames(AnnotatedVcf_zhunter_new)[i+11] <-as.character(zhunter_Sample_ID[i,]) #rename columns
}

#### A-5) Add counts
#`Counts` are the total occurrence in 75 samples for one specific mutation.

counting <-function(x){#input is [1,85] vector
        c = 0
        for(i in 1:(ncol(x)-11)){ #"Counts" is at column 11
                if(x[1,i+11]>0) # total occurrence of >0%
                        c<-c+1
        }
        return(c)
}
for(i in 1:nrow(AnnotatedVcf_zhunter_new)){
        AnnotatedVcf_zhunter_new[i,"counts"]<-counting(AnnotatedVcf_zhunter_new[i,]) #
}

####  A-6) Filter out regular SNP
#Generate file `AnnotatedVcf_zhunter_COSM.csv` contains COSM mutations only.<br />
#Generate file `AnnotatedVcf_zhunter_novel.csv` contains "COSM || MISSENSE || NONSENSE" mutations only.

AnnotatedVcf_zhunter_COSM <- AnnotatedVcf_zhunter_new[grep("COSM",AnnotatedVcf_zhunter_new[,"ID"]),]
AnnotatedVcf_zhunter_novel <- AnnotatedVcf_zhunter_new[AnnotatedVcf_zhunter_new[,"ID"] %in% ".",]
AnnotatedVcf_zhunter_novel<- AnnotatedVcf_zhunter_novel[c(grep("MISSENSE",AnnotatedVcf_zhunter_novel[,"INFO"]),
                                                      grep("NONSENSE",AnnotatedVcf_zhunter_novel[,"INFO"])),]
AnnotatedVcf_zhunter_novel<- rbind(AnnotatedVcf_zhunter_COSM,AnnotatedVcf_zhunter_novel)
AnnotatedVcf_zhunter_novel<- AnnotatedVcf_zhunter_novel[order(rownames(AnnotatedVcf_zhunter_novel)),]
AnnotatedVcf_zhunter_novel<- AnnotatedVcf_zhunter_novel[unique(AnnotatedVcf_zhunter_novel[,"Gene_POS"]),]

### A-7) Run t-test (mutation type vs Healthy/Cancer Conditions) to find out biomarker
sample_zhunter.table <- read.csv(paste0(data_dir,"/sample_table_zhunter.csv"))
Conditions<-sample_zhunter.table$Condition
clear_Conditions <- Conditions[Conditions %in% c("Cancer","Healthy")]
clear_Samples <- sample_zhunter.table[Conditions %in% c("Cancer","Healthy"),"Sample_ID"]
AnnotatedVcf_zhunter_df <- AnnotatedVcf_zhunter_new[,colnames(AnnotatedVcf_zhunter_new) %in% clear_Samples]
dim(AnnotatedVcf_zhunter_df)

t_test <-data.frame()
for(i in 1:nrow(AnnotatedVcf_zhunter_df)){
        t_test[i,1]<-rownames(AnnotatedVcf_zhunter_df)[i]
        mut<-as.double(AnnotatedVcf_zhunter_df[i,])
        t_test[i,2]<-t.test(mut ~ clear_Conditions)[['p.value']]
        tmp<-t.test(mut ~ clear_Conditions)[['estimate']]
        t_test[i,3]<-tmp[1]-tmp[2]
        t_test[i,4]<-AnnotatedVcf_zhunter_new[i,"counts"] 
}
t_test<-t_test[(order(t_test[,3],decreasing=TRUE)),]
colnames(t_test)<-c("Gene_POS","p.value","Cancer.mean - Healthy.mean","counts")
rownames(t_test)<-1:nrow(AnnotatedVcf_zhunter_df)
head(t_test)
### A-8) demostrate t-test 
library(DESeq2)
library(ggplot2)
Gene_maker<-c(t_test[1:8,"Gene_POS"],"SPI1 47376915",t_test[9:99,"Gene_POS"]) # pick top 8 gene and SPI1 47376915
countData <- AnnotatedVcf_zhunter_df[Gene_maker,]
countData<-round(countData,digits=0)
countData<-countData+1 #remove zero
# Construct sample.table
sample_zhunter.table <- read.csv(paste0(data_dir,"/sample_table_zhunter.csv"))
fileName <-paste0(sample_zhunter.table$Sample_ID, ".bam.count")
sample_zhunter.table <- data.frame(sampleName = sample_zhunter.table$Sample_name,
                                 fileName = fileName,
                                 Conditions= sample_zhunter.table$Condition,
                                 SPI1=sample_zhunter.table$SPI1,
                                 Sample_ID = sample_zhunter.table$Sample_ID)

sample_zhunter.table1 = sample_zhunter.table[sample_zhunter.table$Sample_ID %in% clear_Samples,]
ddsHTSeq <- DESeqDataSetFromMatrix(countData=countData,
                                   colData = sample_zhunter.table1,
                                   design= ~ Conditions)

dds <- DESeqDataSet(ddsHTSeq, design= ~ Conditions)
design(dds)
design(dds) <- ~Conditions+SPI1
levels(dds$Conditions)<-c("Healthy","Cancer")
levels(dds$Conditions)
dds <- DESeq(dds)
res_cancer <- results(dds,contrast = c("Conditions","Cancer","Healthy"))

par(mfrow=c(3,3))
for (i in 1:8)  plotCounts(dds, order(res_cancer$padj)[i], intgroup="Conditions",
                           cex.main = 3,cex=1.5,cex.axis=1.5)
plotCounts(dds, gene="SPI1 47376915", intgroup="Conditions",cex.main = 3,cex=1.5,cex.axis=1.5)


####  A-9) Export csv files


write.csv(AnnotatedVcf_zhunter_df,"./output/AnnotatedVcf_zhunter_df.csv")
write.csv(AnnotatedVcf_zhunter_COSM,"./output/AnnotatedVcf_zhunter_COSM.csv")
write.csv(AnnotatedVcf_zhunter_novel,"./output/AnnotatedVcf_zhunter_novel.csv")
write.csv(t_test,"./output/zhunter_t_test.csv")


## B) Analyzing somatic mutations using FPKM
#### B-1) Get FPKM_zhunter Data
#Read each `genes.FPKM_tracking` data into the file `FPKM_zhunter_temp.csv`.<br />
#Generate file `FPKM_zhunter` contains FPKM data from 1st sample only.


#detect OS and set enviroment
#if (Sys.info()[['sysname']]=="Darwin"){
#        FPKM_zhunter_files_path <-paste0("./data", 
#                                       zhunter_Sample_ID[,1],"_CuffLinks/genes.FPKM_tracking")
#}
#if(Sys.info()[['sysname']]=="Windows"){
#        FPKM_zhunter_files_path <-paste0("C:/Users/User/Documents/Programs/R/FPKM/", 
#                                       zhunter_Sample_ID[,1],"_CuffLinks/genes.FPKM_tracking")
#}
#FPKM_zhunter <-data.frame(x= str(0), y= integer(0)) #Generate empty FPKM_zhunter dataframe
#FPKM_zhunter_temp  <- read.csv(FPKM_zhunter_files_path[1], header=T, sep="\t") #Read data from 1st sample
#FPKM_zhunter_temp <- FPKM_zhunter_temp[order(FPKM_zhunter_temp$tracking_id),] #Reorder the gene name
#FPKM_zhunter<-FPKM_zhunter_temp$FPKM #Fill up FPKM_zhunter dataframe with tracking id


#Generate file `FPKM_zhunter` contains FPKM data from all samples. This might take less than one minute.

#for(i in 2:nrow(zhunter_Sample_name)){ #skip the first one, which is added already
#        FPKM_zhunter_temp  <- read.csv(FPKM_zhunter_files_path[i], header=T, sep="\t")
#        FPKM_zhunter_temp <- FPKM_zhunter_temp[order(FPKM_zhunter_temp$tracking_id),] #Reorder the gene name
#        FPKM_zhunter<-cbind(FPKM_zhunter,FPKM_zhunter_temp$FPKM)
#}
FPKM_zhunter  <- read.csv(paste0(data_dir,"/FPKM_zhunter~.csv"))

#Rename rows and columns of`FPKM_zhunter`

dim(FPKM_zhunter)
dup <- duplicated(FPKM_zhunter$NAME)
FPKM_zhunter <- FPKM_zhunter[!dup,]
rownames(FPKM_zhunter) <-FPKM_zhunter$NAME
FPKM_zhunter <- FPKM_zhunter[,colnames(FPKM_zhunter) %in% sample_zhunter.table1$sampleName]

#set up cut off `FPKM_zhunter`
FPKM_zhunter<-FPKM_zhunter[rowSums(FPKM_zhunter)>1,] #set cut off >1
dim(FPKM_zhunter)

####  B-2) creat GCT file for GSEA
#creat "na" description
na_description<-data.frame(rep(NA,nrow(FPKM_zhunter)))
suppressWarnings(FPKM_zhunter.gct<-cbind(rownames(FPKM_zhunter),na_description,FPKM_zhunter))#Duplicated rownames will be lost during cbind
colnames(FPKM_zhunter.gct)[1:2]<-c("NAME","Description")
write.csv(FPKM_zhunter.gct,"./output/FPKM_zhunter.csv") # open file with excel, delete first column, save as tab delimited text file
####  B-3) creat cls file for GSEA
#need use terminal to %s/,/ /g

#### B-4) Charaterize somatic mutations

#Run quanlity control with boxplot
par(mfrow = c(1,1),oma=c(6,3,3,3))  # all sides have 3 lines of space
boxplot(log10(FPKM_zhunter + 1),xlab="all test samples",cex=0.05, cex.axis=0.5, ylab = "log (base 10) RPKM + 1",main="Quanlity control for FPKM",las=2)
FPKM_zhunter_clean <- FPKM_zhunter[,!(colnames(FPKM_zhunter) %in% c("ZH2_rnaWT2","ZH4_rnaWT4"))] #which sample to be excluded based on bad quanlity
boxplot(log10(FPKM_zhunter_clean + 1),xlab="all test samples",cex=0.05, cex.axis=0.5, ylab = "log (base 10) RPKM + 1",main="Quanlity control for FPKM",las=2)


#Group sample with hclust
par(oma=c(2,2,2,2))
lm <-log(FPKM_zhunter_clean+1)
dm<-as.dist(1-cor(lm))
hm<-hclust(dm,method = "average")
p<-plot(hm,col = "black",cex = 0.75,main="Cluster Dendrogram for FPKM")


#Generate heatmap<br />
#Prepare palette

my_palette1 <- colorRampPalette(c("antiquewhite2", "green", "blue"))(n = 100)
my_palette2 <- colorRampPalette(c("red", "green"))(n = 2)
my_palette3 <- colorRampPalette(c("lightblue2", "orange", "red","green","blue","purple"))(n = 6)

#rename samples
clear_Samples2 <- colnames(FPKM_zhunter)[!(colnames(FPKM_zhunter) %in% c("ZH2_rnaWT2","ZH4_rnaWT4"))]
AnnotatedVcf_zhunter_df_novel <- AnnotatedVcf_zhunter_novel[,-c(1:11)]
mut_gene <- AnnotatedVcf_zhunter_df_novel[,sample_zhunter.table$sampleName %in% clear_Samples2]
colnames(mut_gene) = clear_Samples2

#Generate heatmap

library(gplots)
library(ComplexHeatmap)
par(oma=c(3,3,3,3))
par(mar=c(2,2,2,2)+1)

Heatmap(mut_gene,
        column_title = "Cluster of RNA expression vs DNA mutation genes in WM",
        show_row_names = TRUE,
        col=my_palette1,
        row_title_gp = gpar(fontsize = 14),
        row_names_gp = gpar(fontsize = 5),
        column_names_gp = gpar(fontsize = 8),
        clustering_distance_columns = "euclidean",
        cluster_rows = FALSE,
        cluster_columns =  TRUE,
        row_dend_width = unit(5, "cm"),
        column_dend_height = unit(30, "mm"),
        heatmap_legend_param = list(title = "mutation rate %")
)
        Heatmap(Conditions,
                show_row_names = TRUE,
                col=my_palette2, 
                width = unit(1, "cm"),
                heatmap_legend_param = list(title = "Disease")
        ) +
        Heatmap(Population,
                show_row_names = FALSE,
                col=my_palette3, 
                width = unit(1, "cm"),
                heatmap_legend_param = list(title = "Population")
        )
