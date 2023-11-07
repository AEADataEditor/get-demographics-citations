# ###########################
# CONFIG: define  and filenames for later reference
# ###########################

# environment variables for other APIs

if (file.exists(file.path(basepath,".Renviron"))) {
readRenviron(file.path(basepath,".Renviron"))
}

# Crossref-related filenames

issns.file <- file.path(crossrefloc,paste0("issns.Rds"))

doi.file <- file.path(crossrefloc,"crossref_dois")
doi.file.Rds <- paste(doi.file,"Rds",sep=".")
doi.file.csv <- paste(doi.file,"csv",sep=".")

# openAlex related filenames


openalex.file <- file.path(openalexloc,"openalex-aea")
openalex.Rds <- paste0(openalex.file,".Rds")
citations.latest <- file.path(openalexloc,"citations-per-paper.Rds")

openalex.authors     <- file.path(openalexloc,"openalex-aea-authors")
openalex.authors.Rds <- paste0(openalex.authors,".Rds")
openalex.hindex      <- file.path(openalexloc,"openalex-hindex.Rds")


