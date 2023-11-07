# ###########################
# CONFIG: define paths and filenames for later reference
# ###########################

# Change the basepath depending on your system

basepath <- rprojroot::find_rstudio_root_file()

# Main directories
dataloc     <- file.path(basepath, "data")
interwrk    <- file.path(basepath, "data","interwrk")
crossrefloc <- file.path(basepath,"data","crossref")
openalexloc <- file.path(basepath,"data","openalex")
auxilloc    <- file.path(basepath,"data","auxiliary")
Outputs	    <- file.path(basepath,"outputs")


programs <- file.path(basepath,"programs")

for ( dir in list(dataloc,interwrk,crossrefloc,openalexloc,Outputs)){
	if (file.exists(dir)){
	} else {
	dir.create(file.path(dir))
	}
}

# Package lock in
# This is done in global-libraries.
#MRAN.snapshot <- "2019-01-03"
#options(repos = c(CRAN = paste0("https://packagemanager.posit.co/cran/__linux__/focal/",MRAN.snapshot)))


