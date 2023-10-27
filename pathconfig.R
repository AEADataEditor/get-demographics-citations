# ###########################
# CONFIG: define paths and filenames for later reference
# ###########################

# Change the basepath depending on your system

basepath <- rprojroot::find_rstudio_root_file()

# Main directories
dataloc     <- file.path(basepath, "data","replication_data")
interwrk    <- file.path(basepath, "data","interwrk")
hindexloc   <- file.path(basepath, "data","h_index_data")
crossrefloc <- file.path(basepath,"data","crossref")
openalexloc <- file.path(basepath,"data","openalex")
auxilloc    <- file.path(basepath,"data","auxiliary")

TexBase <- file.path(basepath, "text")
TexIncludes <- file.path(basepath, "text","includes" )
Outputs <- file.path(basepath, "text","analysis" )
notes <- file.path(basepath, "text","hautahi_notes" )

programs <- file.path(basepath,"programs")

for ( dir in list(dataloc,interwrk,hindexloc,crossrefloc,openalexloc,TexIncludes,Outputs)){
	if (file.exists(dir)){
	} else {
	dir.create(file.path(dir))
	}
}

# Package lock in
# This is done in global-libraries.
#MRAN.snapshot <- "2019-01-03"
#options(repos = c(CRAN = paste0("https://packagemanager.posit.co/cran/__linux__/focal/",MRAN.snapshot)))


