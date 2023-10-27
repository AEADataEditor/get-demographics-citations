# Get author and institution information
# Output files:
#  - openalex.authors.Rds - all works for in-scope authors
#  - openalex.hindex - per-author-year hindex
# Intermediate files:
# - file.path(interwrk,"authors.df.Rds"))
# - file.path(interwrk,"citations.df.Rds"))
# - file.path(interwrk,"authorlist.aej.df.Rds"))
# Auxiliary files:
# - file.path(openalexloc,"blacklist.xlsx")
# Requires 16GB of memory at least.

source(file.path(rprojroot::find_rstudio_root_file(),"pathconfig.R"),echo=FALSE)
source(file.path(basepath,"global-libraries.R"),echo=FALSE)
source(file.path(programs,"libraries.R"), echo=FALSE)
source(file.path(programs,"config.R"), echo=FALSE)

library(openalexR)

# Get list of articles for in-scope authors
# Vector of DOIs

# First, get the DOIs from the previous program

if ( file.exists(doi.file.Rds)) {
  filtered.df <- readRDS(file= doi.file.Rds)
  nrow(filtered.df)
} else {
  stop(paste0("File missing: ",doi.file.Rds))
}


# utility function

get_works <- function(list,filter="doi") {
  if ( filter == "doi" ) {
  works <- oa_fetch(entity = "works", doi = list, verbose = FALSE)
  }
  if ( filter == "author") {
    works <- oa_fetch(entity = "works", author.id = list,
                      verbose = FALSE)
  }
  return(works)
}
# Get metadata for each DOI


if ( file.exists(openalex.Rds) ) {
  message(paste0("File already exists: ",openalex.Rds))
  message("Loading file from previous version.")
} else {

  stop(paste0("File missing: ",openalex.Rds))
}

works_from_dois <- readRDS(file=openalex.Rds)
nrow(works_from_dois)

# unpack the author data


authorlist.aej.df <- works_from_dois %>%
  select(author,article_id=id) %>%
  tidyr::unnest(author) %>%
  filter(!is.na(au_id)) %>%
  select(au_id,au_display_name,institution_display_name,article_id) %>%
  distinct(au_id,.keep_all = TRUE)
nrow(authorlist.aej.df)

saveRDS(authorlist.aej.df,file.path(interwrk,"authorlist.aej.df.Rds"))
# Extract author IDs: au_id
author_ids <- unique(c(authorlist.aej.df$au_id))

# Get works for each author ID
if ( file.exists(openalex.authors.Rds) ) {
  message(paste0("File already exists: ",openalex.authors.Rds))
  message("Loading file from previous version.")
} else {

  tic.clear()
  tic("Query to openAlex for authors")
  works_list <- get_works(author_ids,filter="author")
  toc(log=TRUE)

  # Query to openAlex for authors: 3601.608 sec elapsed
  # 179,606 obs
  # There are duplicates!
  nrow(works_list %>% distinct(id))
  # [1] 165949
  saveRDS(works_list %>%
            distinct(id,.keep_all = TRUE) %>%
           select(id,doi.url=doi,display_name,author,
                   so,so_id,cited_by_count,counts_by_year,
                   publication_date,publication_year,
                   type),file=openalex.authors.Rds)
}

# We now have authors data, with all citations

works_list <- readRDS(file=openalex.authors.Rds)
nrow(works_list)
names(works_list)
table(works_list$type)

#
# article            book    book-chapter
# 140698            2794            7328
# book-series         dataset    dissertation
# 1            5309             583
# editorial         erratum          letter
# 54              78              10
# other        paratext     peer-review
# 261             433             135
# reference-entry          report
# 162            8205

# we have a blacklist of known bad matches
blacklist.au_id <- read_excel(file.path(openalexloc,"blacklist.xlsx")) %>%
  select(au_id)
nrow(blacklist.au_id %>% distinct(au_id))

# citations per year
authors.df.all <- works_list %>%
  tidyr::unnest(author) %>%
  # au_id now exists
  # remove blacklist authors
  # note that this COMPLETE removes them, because of full bad match
  anti_join(blacklist.au_id) %>%
  select(article_id=id,starts_with("au"),
         institution_id,institution_ror,institution_display_name,
         institution_country_code,cited_by_count,type,
         doi.url,publication_year,publication_date,counts_by_year) %>%
  distinct(article_id,au_id,.keep_all = TRUE)
nrow(authors.df.all)
nrow(authors.df.all %>% distinct(au_id))
# > nrow(authors.df.all)
# [1] 751532 (was: 779935 before blacklist)
# > nrow(authors.df.all %>% distinct(au_id))
# [1] 232069 (was: 231886 before blacklist)

# But this gets us all the data for ALL the co-authors on papers that are out of scope.
# We only want the data for the authors in our sample.

authors.df <- right_join(authors.df.all,
                         authorlist.aej.df %>% select(au_id),
                         by="au_id") %>%
              #### This gets us 1138 (minus blacklist) authors as of Oct 2023 #####
              filter(publication_year < 2019 ) %>%
              filter(publication_date < '2018-07-01') %>%
              filter(!is.na(article_id))
# double-check
authors.df %>% distinct(au_id) %>% nrow()
# [1] 1114

# clean up
rm(authors.df.all)
# save it
saveRDS(authors.df,file=file.path(interwrk,"authors.df.Rds"))

