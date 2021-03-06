# ========================================================================
# CREATED: 2015-05-21                                    
# Functions for Illumina 450k beadchip                                     
# ========================================================================

# ------------------------------------------------------------------------
# CONTENTS

# 1.  DMRfind()
# 2.  DMRfind.v1()  # original function
# 3.  DMRauc()
# 4.  filterCrossReactiveProbes()


# ------------------------------------------------------------------------
# DMRfind() --------------------------------------------------------------
# ------------------------------------------------------------------------

DMRfind <- function(dat, k) {

	# Find overlapping position
	# data must be ordered by chromosome then position; done within function
	# columns are c('cg','chr','position','statistic')
	# suggest filter cg's by univariate statistic (p,q, 5/95 percentile)
	# dat is data.frame; k is max distance between CpGs

  count <- 1
  out <- data.frame(region=NA, chr=NA, start=NA, stop=NA, length=NA, num_cpg=NA, pos_coef=NA, neg_coef=NA)
  clean <- TRUE
  chr.curr <- 1

  # sort temp
  temp <- dat[,c('cg','chr','position','statistic','coef')]
  temp <- temp[order(temp$chr, temp$position),]
  #names(temp) <- c('cg','chr','position','statistic','coef')

  for (i in 1:dim(temp)[1]) {
    #initialize a new region here

    # start a new DMR
    if (clean) {
      new <- data.frame(region=NA, chr=NA, start=NA, stop=NA, length=NA, num_cpg=NA, pos_coef=0, neg_coef=0)    
      cpgs <- 1
      new$region <- count
      new$chr <- temp[i,'chr']
      new$start <- temp[i,'position']
      new$stop <- temp[i,'position']
      new$length <- new$stop - new$start
      new$num_cpg <- 1
      new$pos_coef <- new$pos_coef + ifelse(temp[i,'coef'] >= 0, 1, 0)
      new$neg_coef <- new$neg_coef + ifelse(temp[i,'coef'] < 0, 1, 0)  
      point <- temp[i,'position']
    }

    # end if last CpG
    if (i==dim(temp)[1]) {
      out <- rbind(out, new)
      out <- out[-1,]
      break
    }

    # end if next CpG on a new chr
    if (temp[i+1,'chr'] != chr.curr) {
      out <- rbind(out, new)    
      clean <- TRUE
      count <- count + 1
      chr.curr <- temp[i+1,'chr']
      next
    }

    # if within k then add to current DMR; if not then write record to out
    if (point+k >= temp[i+1,'position']) {
      new$stop <- temp[i+1,'position']
      new$length <- new$stop - new$start
      new$num_cpg <- new$num_cpg + 1
      new$pos_coef <- new$pos_coef + ifelse(temp[i+1,'coef'] >= 0, 1, 0)
      new$neg_coef <- new$neg_coef + ifelse(temp[i+1,'coef'] < 0, 1, 0)  
      point <- new$stop
      clean <- FALSE
  
    } else {
      out <- rbind(out, new)    
      clean <- TRUE
      count <- count + 1
    }
  }

  return(out)
}
# ------------------------------------------------------------------------





# ------------------------------------------------------------------------
# DMRfind.v1() -----------------------------------------------------------
# ------------------------------------------------------------------------

DMRfind.v1 <- function(dat, k) {

    # NB: does not include DMR summary of positive or negative coefficients
	# Find overlapping position
	# data must be ordered by chromosome then position
	# columns are c('cg','chr','position','statistic')
	# suggest filter cg's by univariate statistic (p,q, 5/95 percentile)
	# dat is data.frame; k is max distance between CpGs

  count <- 1
  out <- data.frame(region=NA, chr=NA, start=NA, stop=NA, length=NA, num_cpg=NA)
  clean <- TRUE
  chr.curr <- 1

  # sort temp
  temp <- dat[,c('cg','chr','position','statistic')]
  temp <- temp[order(temp$chr, temp$position),]

  for (i in 1:dim(temp)[1]) {
    #initialize a new region here

    # start a new DMR
    if (clean) {
      new <- data.frame(region=NA, chr=NA, start=NA, stop=NA, length=NA, num_cpg=NA)    
      cpgs <- 1
      new$region <- count
      new$chr <- temp[i,'chr']
      new$start <- temp[i,'position']
      new$stop <- temp[i,'position']
      new$length <- new$stop - new$start
      new$num_cpg <- 1
      point <- temp[i,'position']
    }

    # end if last CpG
    if (i==dim(temp)[1]) {
      out <- rbind(out, new)
      out <- out[-1,]
      break
    }

    # end if next CpG on a new chr
    if (temp[i+1,'chr'] != chr.curr) {
      out <- rbind(out, new)    
      clean <- TRUE
      count <- count + 1
      chr.curr <- temp[i+1,'chr']
      next
    }

    # if within k then add to current DMR; if not then write record to out
    if (point+k >= temp[i+1,'position']) {
      new$stop <- temp[i+1,'position']
      new$length <- new$stop - new$start
      new$num_cpg <- new$num_cpg + 1
      point <- new$stop
      clean <- FALSE
  
    } else {
      out <- rbind(out, new)    
      clean <- TRUE
      count <- count + 1
    }
  }

  return(out)
}
# ------------------------------------------------------------------------




# ------------------------------------------------------------------------
# DMRauc() ---------------------------------------------------------------
# ------------------------------------------------------------------------

DMRauc <- function(temp) {

	# Calculate area of multiple trapezoids
	# temp contains only cg's that make up a single DMR
	# Columns of temp are: c('cg','chr','position','statistic')
	# DMRs can be identified from a relaxed threshold of univariate tests

  temp <- temp[order(temp$position),]
  auc.out <- 0

  for (i in dim(temp)[1]:1) {
    h <- temp[i,'position'] - temp[i-1,'position']
    auc <- round(0.5*(temp[i,'statistic'] + temp[i-1,'statistic'])*h,4)
    auc.out <- auc.out + auc
    if (i==2) break
  }

  return(auc.out)
}
# ------------------------------------------------------------------------




# ------------------------------------------------------------------------
# filterCrossReactiveProbes() --------------------------------------------
# ------------------------------------------------------------------------

filterCrossReactiveProbes <- function(gset) {
  #INPUT: RGset or GenomicRatioSet object
  #OUTPUT: same object with the 29233 cross-reactive probes removed; identified in PMID: : 23314698 
  # crp <- read.table("/Users/timothyyork/Documents/Projects/methylation450k/crossReactiveProbes_450k/crossReactiveProbes_450k.txt", sep="\t", header=T)
  # save(crp, file="/Users/timothyyork/Dropbox/R_FXNs/support_files/crossReactiveProbes_450k.Rdata")

  load("/Users/timothyyork/Dropbox/R_FXNs/support_files/crossReactiveProbes_450k.Rdata")

  gset2 <- gset[!is.element(rownames(gset), crp$TargetID), ]
  gset2
}
# ------------------------------------------------------------------------


# ------------------------------------------------------------------------
# Verify Sample IDs-------------------------------------------------------
# ------------------------------------------------------------------------

# This function is tailored to how PREG IDs work. Can be made more general if desired.
# Pass in an RGset containing a pData column called "Sample_Name", which should be the 
# iid + visit number.
# Function will return a histogram of all correlation values, a data.frame of correlations (duplicates removed),
# a list of samples that have the same ID number but low correlation (lowMatch), and a list of samples that
# have nonmatching IDs have higher than expected correlations (highMatch)

snpCheckMySamples <- function(x){ 
  
  
  RGset2 <- x
  
  mySnpBeta <- getSnpBeta(RGset2)
  colnames(mySnpBeta) <- pData(RGset2)$Sample_Name   
  
  snp.cors <- cor(mySnpBeta)                         # make correlation matrix
  snp.cors[upper.tri(snp.cors, diag = TRUE)] <- NA   # convert upper triangle of matrix to NA (i.e., the duplicate corrs)
  cor.df <- as.data.frame.table(snp.cors, stringsAsFactors = FALSE)
  names(cor.df) <- c("ID1", "ID2", "Corr")
  cor.df <- subset(cor.df, !is.na(Corr))             # remove duplicates
  
  
  # Create Histogram of Relatedness---------
  hist(cor.df$Corr, breaks = "Scott", col = "dark grey", main = "Histogram of Distribution of Correlated SNP Beta Values for PREG")
  
  
  # Change IDs to simple iids for comparison below
  cor.df$ID1a <- substr(cor.df$ID1, 1, 4)
  cor.df$ID2a <- substr(cor.df$ID2, 1, 4)
  
  # Identify samples that do not match closely enough
  sameID <- cor.df[which(cor.df$ID1a == cor.df$ID2a),]
  problem1 <- sameID[which(sameID$Corr < .90), ]
  
  
  # Identify samples that match too closely
  problem2 <- cor.df[which(cor.df$ID1a != cor.df$ID2a & cor.df$Corr > .6), ]
  
  alist <- list(matrix = cor.df, lowMatch = problem1, highMatch = problem2)
  
  return(alist)
}









