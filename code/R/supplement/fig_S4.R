
# Clear environment
rm(list=ls())
gc()

# Load dependencies
deps <- c('wesanderson','vegan');
for (dep in deps){
  if (dep %in% installed.packages()[,'Package'] == FALSE){
    install.packages(as.character(dep), quiet=TRUE);
  }
  library(dep, verbose=FALSE, character.only=TRUE)
}
set.seed(42)

#--------------------------------------------------------------------------------------------------------------#

# Define variables
cefoperazone_file <- '~/Desktop/Repositories/Jenior_Transcriptomics_2015/data/mapping/cdifficile630/select_genes/cefoperazone_630.RNA_reads2select.all.norm.tsv'
clindamycin_file <- '~/Desktop/Repositories/Jenior_Transcriptomics_2015/data/mapping/cdifficile630/select_genes/clindamycin_630.RNA_reads2select.all.norm.tsv'
streptomycin_file <- '~/Desktop/Repositories/Jenior_Transcriptomics_2015/data/mapping/cdifficile630/select_genes/streptomycin_630.RNA_reads2select.all.norm.tsv'
germfree_file <- '~/Desktop/Repositories/Jenior_Transcriptomics_2015/data/mapping/cdifficile630/select_genes/germfree.RNA_reads2select.all.norm.tsv'

# Open files
cefoperazone <- read.delim(cefoperazone_file, sep='\t', header=FALSE)
colnames(cefoperazone) <- c('gene', 'Cefoperazone')
clindamycin <- read.delim(clindamycin_file, sep='\t', header=FALSE)
colnames(clindamycin) <- c('gene', 'Clindamycin')
streptomycin <- read.delim(streptomycin_file, sep='\t', header=FALSE)
colnames(streptomycin) <- c('gene', 'Streptomycin')
germfree <- read.delim(germfree_file, sep='\t', header=FALSE)
colnames(germfree) <- c('gene', 'Germfree')

# Clean up
rm(cefoperazone_file, clindamycin_file, streptomycin_file, germfree_file)

# Merge tables
combined_mapping <- merge(streptomycin, cefoperazone, by='gene')
combined_mapping <- merge(combined_mapping, clindamycin, by='gene')
combined_mapping <- merge(combined_mapping, germfree, by='gene')
combined_mapping$gene <- gsub('Clostridium_difficile_630\\|','', combined_mapping$gene)
combined_mapping$gene <- gsub('ENA\\|CDT20869\\|CDT20869.1\\|Clostridium_difficile_putative_phage_replication_protein_','', combined_mapping$gene)
combined_mapping$gene <- gsub('_',' ', combined_mapping$gene)
rownames(combined_mapping) <- combined_mapping$gene
combined_mapping$gene <- NULL
rm(cefoperazone, clindamycin, streptomycin, germfree)

#--------------------------------------------------------------------------------------------------------------#

# Define subsets of interest
sigma_keep <- c('TcdR','TcdC','CdtR','SigK', 'SigF', 'CodY', 'CcpA', 'SigH', 'Spo0A', 'PrdR', 'Rex', 'SigG', 'SigA1')

paloc_keep <- c('TcdE','TcdA','TcdB')
sporulation_keep <- c('SpoIIAB','SpoIIE','SpoVS','SpoIVA','SpoVFB','SpoVB','SpoVG','CdeC','CotJB2','CotD',
                      'SspA','SspB')
quorum_keep <- c('LuxS', 'AgrD', 'AgrB', 'AgrA', 'AgrC')
# Need to add agr A and C


select_genes <- c(sigma_keep, paloc_keep, sporulation_keep, quorum_keep)

# Pull of the genes of interest
combined_mapping <- subset(combined_mapping, rownames(combined_mapping) %in% select_genes)
rm(select_genes)

# Calculate relative abundance
combined_mapping <- t(combined_mapping)
combined_mapping <- sweep(combined_mapping, 1, rowSums(combined_mapping), '/') * 100
combined_mapping[is.na(combined_mapping)] <- 0.0
combined_mapping <- t(combined_mapping)

#--------------------------------------------------------------------------------------------------------------#

# Sigma factors
# Integration of Metabolism and Virulence by Clostridium difficile CodY
# Global transcriptional control by glucose and carbon regulator CcpA in Clostridium difficile.
# Proline-Dependent Regulation of Clostridium difficile Stickland Metabolism
# The Clostridium difficile spo0A Gene Is a Persistence and Transmission Factor
sigma <- subset(combined_mapping, rownames(combined_mapping) %in% sigma_keep)
rownames(sigma) <- c('ccpA', 'cdtR', 'codY', 'rex', 'prdR', 'sigA1', 'sigF', 
                     'sigG', 'sigH', 'sigK', 'spo0A', 'tcdC', 'tcdR')
sigma <- t(sigma)
sigma <- cbind(sigma[,3], sigma[,1], sigma[,2], sigma[,12], sigma[,13], sigma[,11], 
               sigma[,6], sigma[,7], sigma[,8], sigma[,9], sigma[,10], sigma[,5], sigma[,4])
sigma[sigma == 0] <- NA

# Pathogenicity
paloc <- subset(combined_mapping, rownames(combined_mapping) %in% paloc_keep)
rownames(paloc) <- c('tcdA', 'tcdB', 'tcdE')
paloc <- t(paloc)
paloc[paloc == 0] <- NA

# Quorum sensing
quorum <- subset(combined_mapping, rownames(combined_mapping) %in% quorum_keep)
rownames(quorum) <- c('agrA', 'agrB', 'agrC', 'agrD', 'luxS')
quorum <- t(quorum)
quorum[quorum == 0] <- NA

# Sporulation
# Genes with >0.01 variance included in final analysis
sporulation <- subset(combined_mapping, rownames(combined_mapping) %in% sporulation_keep)
rownames(sporulation) <- c('cdeC','cotD','cotJB2','spoIIAB','spoIIE',
                           'spoIVA','spoVB','spoVFB','spoVG','spoVS','sspA','sspB')
sporulation <- t(sporulation)
sporulation <- cbind(sporulation[,4], sporulation[,5], sporulation[,9], sporulation[,1], 
                     sporulation[,2], sporulation[,3], sporulation[,6], sporulation[,7], 
                     sporulation[,10], sporulation[,8], sporulation[,11], sporulation[,12])
colnames(sporulation) <- c('spoIIAB', 'spoIIE', 'spoVG', 'cdeC', 'cotD', 'cotJB2', 
                           'spoIVA', 'spoVB', 'spoVS', 'spoVFB', 'sspA', 'sspB')
sporulation[sporulation == 0] <- NA

# Clean up
rm(combined_mapping, sigma_keep, paloc_keep, sporulation_keep, quorum_keep)

#--------------------------------------------------------------------------------------------------------------#

# Set the color palette and plotting environment
select_palette <- c(wes_palette('FantasticFox')[1], wes_palette('FantasticFox')[3], wes_palette('FantasticFox')[5], 'forestgreen')
plot_file <- '~/Desktop/Repositories/Jenior_Transcriptomics_2015/results/supplement/figures/figure_S4.pdf'
make.italic <- function(x) as.expression(lapply(x, function(y) bquote(italic(.(y)))))
pdf(file=plot_file, width=12, height=10)
layout(matrix(c(1,1,2,
                3,4,4),
              nrow=2, ncol=3, byrow = TRUE))

#--------------------------------------------------------------------------------------------------------------#

# Sporulation
par(las=1, mar=c(4.5,6,1,1), mgp=c(4, 1, 0))
barplot(sporulation, col=select_palette, space=c(0,1.5),  beside=TRUE, xaxt='n', yaxt='n', 
        ylab='Relative Transcript Abundance', ylim=c(0,30), cex.lab=1.4)
box()
axis(side=2, at=c(0,10,20,30), c('0%','10%','20%','30%'), tick=TRUE, las=1, cex.axis=1.3)
text(x=seq(3.7,66,5.5), y=par()$usr[3]-0.035*(par()$usr[4]-par()$usr[3]),
     labels=make.italic(c('spoIIAB', 'spoIIE', 'spoVG', 'cdeC', 'cotD', 'cotJB2', 'spoIVA', 'spoVB', 'spoVS', 'spoVFB', 'sspA', 'sspB')), 
     srt=45, adj=1, xpd=TRUE, cex=1.5)
legend('topright', legend='Sporulation', pt.cex=0, bty='n', cex=1.8)
mtext('A', side=2, line=2, las=2, adj=2.9, padj=-11, cex=1.5)
text(x=c(21.5,25,27,30.6,32.6,54.5), y=0.5, labels='*', cex=1.7, font=2) # Add symbol for undetectable

legend('topleft', legend=c('Streptomycin (SPF)', 'Cefoperazone (SPF)', 'Clindamycin (SPF)', 'No antibiotics (GF)'), pt.cex=3.5, cex=1.7,
       pch=22, col='black', pt.bg=select_palette, ncol=1, bty='n')

# Pathogenicity
barplot(paloc, col=select_palette, space=c(0,1.5),  beside=TRUE, xaxt='n', yaxt='n', 
        ylab='Relative Transcript Abundance', ylim=c(0,1), cex.lab=1.4)
box()
axis(side=2, at=c(0,0.333,0.666,1.0), c('0%','0.3%','0.6%','1.0%'), tick=TRUE, las=1, cex.axis=1.3)
text(x=seq(3.7,16.5,5.5), y=par()$usr[3]-0.035*(par()$usr[4]-par()$usr[3]),
     labels=make.italic(c('tcdA', 'tcdB', 'tcdE')), 
     srt=45, adj=1, xpd=TRUE, cex=1.6)
legend('topright', legend='Toxin Production', pt.cex=0, bty='n', cex=1.8)
mtext('B', side=2, line=2, las=2, adj=3, padj=-11, cex=1.5)
text(x=c(5,10.5,13,15,16), y=0.025, labels='*', cex=1.7, font=2) # Add symbol for undetectable

# Quorum sensing
barplot(quorum, col=select_palette, beside=TRUE, xaxt='n', yaxt='n', 
        ylab='Relative Transcript Abundance', ylim=c(0,2.5), cex.lab=1.4)
box()
axis(side=2, at=c(0,0.833,1.666,2.5), c('0%','0.83%','1.66%','2.5%'), tick=TRUE, las=1, cex.axis=1.3)
text(x=c(2.7,8.2,13.7,18.7,23.5), y=par()$usr[3]-0.035*(par()$usr[4]-par()$usr[3]),
     labels=make.italic(colnames(quorum)), srt=45, adj=1, xpd=TRUE, cex=1.6)
legend('topright', legend='Quorum sensing', pt.cex=0, bty='n', cex=1.8)
mtext('C', side=2, line=2, las=2, adj=2.7, padj=-11, cex=1.5)
text(x=c(9.6,12.6,13.4,24.6), y=0.05, labels='*', cex=1.7, font=2) # Add symbol for undetectable

# Sigma factors
barplot(sigma, col=select_palette, space=c(0,1.5), beside=TRUE, xaxt='n', yaxt='n', 
        ylab='Relative Transcript Abundance', ylim=c(0,25), cex.lab=1.4)
box()
axis(side=2, at=c(0,8,17,25), c('0%','8%','17%','25%'), tick=TRUE, las=1, cex.axis=1.3)
text(x=seq(3.7,71.5,5.5), y=par()$usr[3]-0.035*(par()$usr[4]-par()$usr[3]),
     labels=make.italic(c('codY', 'ccpA', 'cdtR', 'tcdC', 'tcdR', 'spo0A', 'sigA1', 
                          'sigF', 'sigG', 'sigH', 'sigK', 'rex', 'prdR')), 
     srt=45, adj=1, xpd=TRUE, cex=1.6)
legend('topright', legend='Sigma factors', pt.cex=0, bty='n', cex=1.8)
mtext('D', side=2, line=2, las=2, adj=3, padj=-11, cex=1.5)
text(x=c(21.7,23.5,24.5,25.5,26.5,71.3), y=0.5, labels='*', cex=1.7, font=2) # Add symbol for undetectable

dev.off()


#--------------------------------------------------------------------------------------------------------------#

# Clean up
for (dep in deps){
  pkg <- paste('package:', dep,sep='')
   detach(pkg, character.only = TRUE)
}
rm(list=ls())
gc()

