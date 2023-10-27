#!/bin/bash
#
# Bash script to run all the paper analyses
# Alternatively:
# - cd into programs, and run the 00_main.R
# - open the "replication-paper.Rproj" in Rstudio, and "knit" the README.Rmd

cd programs
R CMD BATCH 00_main.R
