# ###########################
# CONFIG: define  and filenames for later reference
# ###########################

# H-index files
HindexRaw <- "h-index-assignment1.2019.csv"
HindexClean <- "hindex.csv"

# Zenodo DOI
# Generic DOI - resolves to the latest
zenodo.id <- "2639919"
# Specific DOI - resolves to a fixed version
zenodo.id <- "2639920"
# We will recover the rest from Zenodo API
zenodo.api = "https://zenodo.org/api/records/"

# environment variables for other APIs

readRenviron(file.path(basepath,".Renviron"))

# Crossref-related filenames

issns.file <- file.path(crossrefloc,paste0("issns.Rds"))

doi.file <- file.path(dataloc,"crossref_aejdois")
doi.file.Rds <- paste(doi.file,"Rds",sep=".")
doi.file.csv <- paste(doi.file,"csv",sep=".")

# openAlex related filenames


openalex.file <- file.path(openalexloc,"openalex-aejae")
openalex.Rds <- paste0(openalex.file,".Rds")
citations.latest <- file.path(openalexloc,"citations-per-paper.Rds")

openalex.authors     <- file.path(openalexloc,"openalex-aejae-authors")
openalex.authors.Rds <- paste0(openalex.authors,".Rds")
openalex.hindex      <- file.path(openalexloc,"openalex-hindex.Rds")


# Name of the bib file with all the tested articles

#bibtex_all = file.path(TexIncludes,"replication_papers.bib")
bibtex_all = file.path(TexIncludes,"Replication_write.bib")

# output the config.tex with paths we need

config.tex <- tibble("String" = "% Automatically created, do not edit")
config.tex[2,] <- ("String" = paste("\\newcommand{\\TexIncludes}{",TexIncludes,"}",sep=""))
config.tex[3,] <- ("String" = paste("\\newcommand{\\ROutputs}{",Outputs,"}",sep=""))
config.tex[4,] <- ("String" = paste("\\newcommand{\\Rprograms}{",programs,"}",sep=""))
write.table(config.tex,file=file.path(TexIncludes,"config.tex"),quote = FALSE,col.names = FALSE,row.names = F)

# Set knitr settings
options(scipen = 1, digits = 1,width=50)
cw = "0.4pt"
fs = 'footnotesize'



