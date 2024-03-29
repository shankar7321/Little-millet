##PCA_plot
library(DESeq2)
library(ggplot2)
data <- read.table("342K_TPM_28samples.txt", sep = '\t', row.names = 1,
                   head = TRUE, stringsAsFactors = FALSE)
meta <- read.table("sampleinfo.txt", sep = '\t', row.names = 1,
                   header = TRUE, stringsAsFactors = FALSE)
all(rownames(meta) == colnames(data))
countData = round(as(data, "matrix"), digits = 0)
dds <- DESeqDataSetFromMatrix(countData = countData, colData = meta, design = ~ condition)
dds <- DESeq(dds)
vsd <- vst(dds,blind=TRUE)
plotPCA(vsd,intgroup=c("condition"))

###cluster_dendrogram
cormat <- read.table("342K_TPM_28samples_Log2(TPM+1).txt", sep = '\t', row.names = 1,
                     head = TRUE, stringsAsFactors = FALSE)
head(cormat)
dists1=dist(t(cormat))
hc=hclust(dists1,method="complete")
plot(hc)

##elbow_plot

elbowplot <- read.table("60K_log2tpm_10samples_forelbow.txt", sep = '\t', row.names = 1,
                       head = TRUE, stringsAsFactors = FALSE)
scaledata <- t(scale(t(elbowplot)))
wss <- (nrow(clusters)-1)*sum(apply(clusters,2,var))
for (i in 1:15) wss[i] <- sum(kmeans(scaledata,
                                     centers=i)$withinss)
plot <- plot(1:15, wss, type="b", xlab="Number of Clusters",
             ylab="Within groups sum of squares")
plot + abline(v=4, col="blue")

###correlation_heatmap
library(dplyr)
library(pheatmap)
corr_heatmap = read.table("342K_TPM_28samples_Log2(TPM+1).txt", sep = '\t', row.names = 1,
                          head = TRUE, stringsAsFactors = FALSE)
corr_heatmap_pearson <- corr_heatmap %>% 
  cor(method = "pearson")
pheatmapM <-pheatmap(corr_heatmap_pearson, breaks = NULL, color = colorRampPalette(c("turquoise3", "black", "coral"))(50), cluster_rows = TRUE, fontsize_row=9, fontsize_col=9, border_color = FALSE, cluster_cols = TRUE)

##distribution_plot
library(tidyr)
distribution <- read.table("342K_TPM_28samples_Log2(TPM+1).txt", sep = '\t', row.names = 1,
                           head = TRUE, stringsAsFactors = FALSE)
sample_info = read.csv("sample_info.csv", header = TRUE, row.names = 1) 


distribution_long <- distribution %>% 
  pivot_longer(cols = GS1:PL3, 
               names_to = "sample", 
               values_to = "cts")

head (distribution_long)

data_new <- distribution_long                             
data_new$tissue <- factor(data_new$tissue,     
                          levels = c("GS", "RD", "PU", "YL", "YR", "CM", "VS", "PE", "PM", "PL"))
data_new$replicate <- factor(data_new$replicate,     
                          levels = c("1", "2", "3"))

ggp_new <- data_new %>%
  ggplot(aes(cts, colour = replicate)) + 
  geom_freqpoly(binwidth = 1) + 
  facet_grid(cols = vars(tissue))

ggp_new

##boxplot
library(tidyverse)
library(ggpubr)

df = read.csv("cluster 4.csv", header = TRUE, row.names = 1)
head(df)

df <- df %>% 
  pivot_longer(cols = GS:PL, 
               names_to = "sample", 
               values_to = "cts")
head(df)

df$tissue <- factor(df$sample, levels = c("PE", "PM", "PL", "YL", "PU", "CM", "VS", "GS", "RD", "YR"))

p <- ggboxplot(df, x = "tissue", y = "cts", outlier.shape = NA,
               fill = "tissue", palette =c('brown', 'purple', 'pink', 'grey', 'green3', 'salmon', 'yellow', 'blue', 'red', 'cyan'))
p <- p + grids(linetype = "solid")
p <- p + border()
p

##ion_transport_heatmap

library(pheatmap)
library(RColorBrewer)
cormat = read.csv("Ion_transport_fe_zn.csv", header = TRUE, row.names = 1)

cormat <- t(scale(t(cormat))) ##convert to zscore

newnames <- lapply(
  
  rownames(cormat),
  
  function(x) bquote(italic(.(x))))
pheatmapM <-pheatmap(cormat, border_color = "black", breaks = NULL, color = colorRampPalette(c("yellow", "white", "red"))(50), cluster_rows = TRUE, cluster_cols = TRUE, labels_row = as.expression(newnames))


##enhanced_volcano_plot
library(EnhancedVolcano)
res = read.csv("Gr2vGr4.csv", header = TRUE, row.names = 1)
head(res)

EnhancedVolcano(res,
                lab = rownames(res),
                x = 'log2FoldChange',
                y = 'padj',
                selectLab = c("AMY1","MAGL1","HEXO3","PTOX"),##include genes for visualization
                title = 'Gr2vsgr4',
                boxedLabels = TRUE,
                FCcutoff = 8.0,
                pCutoff = .01)

##scatterplot
library(ggplot2)
df = read.csv("housekeeping_genes_CV.csv", header = TRUE, row.names = 1)
df$category <- as.factor(df$category)
head(df)
geom_point(size, color, shape)
ggplot(df, aes(x=mean, y=SD, shape=category, color=category)) +
  geom_point()

####DESeq2_pairwise_differential_gene_expression

library(DESeq2)
library(DESeq)
library(apeglm)

data <- read.table("counts_104K_anovaP05fromTPM.txt", sep = '\t', row.names = 1,
                   head = TRUE, stringsAsFactors = FALSE)
meta <- read.table("104K_4cluster_sampleinfo.txt", sep = '\t', row.names = 1,
                   header = TRUE, stringsAsFactors = FALSE)
all(rownames(meta) == colnames(data))
countData = round(as(data, "matrix"), digits = 0)
head(countData)
dds <- DESeqDataSetFromMatrix(countData = countData, colData = meta, design = ~ condition)
dds <- DESeq(dds)
res <- results(dds, contrast=c("condition","CL3","CL4"))

#select only having log2foldchange>2, <-2 and padj 0.01
resSigind = res[ which(res$padj < 0.01 & res$log2FoldChange > 2), ]
resSigrep = res[ which(res$padj < 0.01 & res$log2FoldChange < -2), ]
resSig = rbind(resSigind, resSigrep)
resSig
summary(resSig)


##complex_heatmap
require(RColorBrewer)
require(digest)
require(cluster)
require(ComplexHeatmap)
require(circlize)



mat <- read.table("60K_log2tpm_10samples_forelbow.txt", sep = '\t', row.names = 1,
                  head = TRUE, stringsAsFactors = FALSE)
metadata <- read.table("meta2.txt", sep = '\t', row.names = 1,
                       header = TRUE, stringsAsFactors = FALSE)

all(rownames(metadata) == colnames(mat))

heat <- t(scale(t(mat)))

write.table(heat, file = "zscores_4clust.txt", sep = "\t", row.names = TRUE, col.names = NA)##to be used for downstream analysis


myCol <- colorRampPalette(c("turquoise1", "black", "coral"))(100)
myBreaks <- seq(-3, 3, length.out = 100)
ann <- data.frame(Tissue = metadata$Tissue, stringsAsFactors = FALSE)
colours <- list(Tissue = c('GS' = 'blue', 'RD' = 'red', 'PU' = 'green3', 'YL' = 'grey', 'YR' = 'cyan', 'CM' = 'pink', 'VS' = 'yellow', 'PE' = 'brown', 'PM' = 'purple', 'PL' = 'salmon'))
colAnn <- HeatmapAnnotation(
  df = ann,
  which = 'col', 
  na_col = 'white', 
  col = colours,
  annotation_height = 0.6,
  annotation_width = unit(1, 'cm'),
  gap = unit(0, 'mm'),
  annotation_legend_param = list(
    Tissue = list(
      nrow = 10, 
      title = 'Tissue',
      title_position = 'topcenter',
      legend_direction = 'vertical',
      title_gp = gpar(fontsize = 12, fontface = 'bold'),
      labels_gp = gpar(fontsize = 12, fontface = 'bold'))))

boxplotCol <- HeatmapAnnotation(
  boxplot = anno_boxplot(
    heat,
    border = TRUE,
    gp = gpar(fill = c('GS' = 'blue', 'RD' = 'red', 'PU' = 'green3', 'YL' = 'grey', 'YR' = 'cyan', 'CM' = 'pink', 'VS' = 'yellow', 'PE' = 'brown', 'PM' = 'purple', 'PL' = 'salmon')),
    pch = '.',
    size = unit(2, 'mm'),
    axis = TRUE,
    axis_param = list(
      gp = gpar(fontsize = 12),
      side = 'left')),
  annotation_width = unit(c(2.0), 'cm'),
  which = 'col')

boxplotRow <- HeatmapAnnotation(
  boxplot = row_anno_boxplot(
    heat,
    border = TRUE,
    gp = gpar(fill = c('GS' = 'blue', 'RD' = 'red', 'PU' = 'green3', 'YL' = 'grey', 'YR' = 'cyan', 'CM' = 'pink', 'VS' = 'yellow', 'PE' = 'brown', 'PM' = 'purple', 'PL' = 'salmon')),
    pch = '.',
    size = unit(2, 'mm'),
    axis = TRUE,
    axis_param = list(
      gp = gpar(fontsize = 12),
      side = 'top')),
  annotation_width = unit(c(2.0), 'cm'),
  which = 'row')


genelabels <- rowAnnotation(
  Genes = anno_mark(
    at = seq(1, nrow(heat), 40),
    labels = rownames(heat)[seq(1, nrow(heat), 40)],
    labels_gp = gpar(fontsize = 10, fontface = 'bold'),
    padding = 0.75),
  width = unit(2.0, 'cm') +
    
    max_text_width(
      rownames(heat)[seq(1, nrow(heat), 40)],
      gp = gpar(fontsize = 10,  fontface = 'bold')))

pamClusters <- cluster::pam(heat, k = 4) # pre-select k = 4 centers

pamClusters

pamClusters$clustering <- paste0('Cluster ', pamClusters$clustering)

pamClusters$clustering <- factor(pamClusters$clustering,
                                 levels = c('Cluster 1', 'Cluster 2', 'Cluster 3', 'Cluster 4'))
pamClusters$clustering

write.table(pamClusters$clustering, file = "pamclusters_4clust.txt", sep = "\t", row.names = TRUE, col.names = NA)


#create the actual heatmap object
hmap <- Heatmap(heat,split = pamClusters$clustering,
                cluster_row_slices = FALSE,
                name = 'Z-score',
                col = colorRamp2(myBreaks, myCol),
                
                # parameters for the colour-bar that represents gradient of expression
                heatmap_legend_param = list(
                  color_bar = 'continuous',
                  legend_direction = 'vertical',
                  legend_width = unit(8, 'cm'),
                  legend_height = unit(5.0, 'cm'),
                  title_position = 'topcenter',
                  title_gp=gpar(fontsize = 12, fontface = 'bold'),
                  labels_gp=gpar(fontsize = 12, fontface = 'bold')),
                
                # row (gene) parameters
                cluster_rows = TRUE,
                show_row_dend = TRUE,
                #row_title = 'Statistically significant genes',
                row_title_side = 'left',
                row_title_gp = gpar(fontsize = 12,  fontface = 'bold'),
                row_title_rot = 90,
                show_row_names = FALSE,
                row_names_gp = gpar(fontsize = 10, fontface = 'bold'),
                row_names_side = 'left',
                row_dend_width = unit(25,'mm'),
                
                # column (sample) parameters
                cluster_columns = TRUE,
                show_column_dend = TRUE,
                column_title = '',
                column_title_side = 'bottom',
                column_title_gp = gpar(fontsize = 12, fontface = 'bold'),
                column_title_rot = 0,
                show_column_names = FALSE,
                column_names_gp = gpar(fontsize = 10, fontface = 'bold'),
                column_names_max_height = unit(10, 'cm'),
                column_dend_height = unit(25,'mm'),
                
                # cluster methods for rows and columns
                clustering_distance_columns = function(x) as.dist(1 - cor(t(x))),
                clustering_method_columns = 'ward.D2',
                clustering_distance_rows = function(x) as.dist(1 - cor(t(x))),
                clustering_method_rows = 'ward.D2',
                
                # specify top and bottom annotations
                top_annotation = colAnn,
                bottom_annotation = boxplotCol)

draw(hmap,
     heatmap_legend_side = 'left',
     annotation_legend_side = 'right',
     row_sub_title_side = 'left')
