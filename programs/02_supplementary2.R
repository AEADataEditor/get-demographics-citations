# Read citations per year for each of the AEJ:AE DOIs.
# Outputs:
#  - openalex.Rds - mostly unmodified pull by works
#  - citations.latest - a file with per-DOI-year cumulative and within-year citations

source(file.path(rprojroot::find_rstudio_root_file(),"pathconfig.R"),echo=FALSE)
source(file.path(basepath,"global-libraries.R"),echo=FALSE)
source(file.path(programs,"libraries.R"), echo=FALSE)
source(file.path(programs,"config.R"), echo=FALSE)

library(openalexR)

# First, get the DOIs from the previous program

if ( file.exists(doi.file.Rds)) {
  filtered.df <- readRDS(file= doi.file.Rds)
  nrow(filtered.df)
} else {
  stop(paste0("File missing: ",doi.file.Rds))
  }

# now pass these to openAlex


if ( file.exists(openalex.Rds) ) {
  message(paste0("File already exists: ",openalex.Rds))
  message("Loading file from previous version.")
} else {

  tic.clear()
  tic("Query to openAlex")
  dois_toget <- unique(c(filtered.df$doi))
  works_from_dois <- oa_fetch(entity = "works", doi = dois_toget, verbose = FALSE)
  toc(log=TRUE)
  saveRDS(works_from_dois %>%
          rename(doi.url = doi) %>%
          mutate(DOI = str_remove(doi.url,"https://doi.org/")),
          file=openalex.Rds)
}

# load the file from disk
works_from_dois <- readRDS(openalex.Rds)
skim(works_from_dois %>% select(id,publication_date,doi.url,DOI,type))

# unpack the citation data

works_from_dois %>%
  # Filter to the in-scope articles
  filter(publication_year < 2019 ) %>%
  filter(publication_date < '2018-07-01') %>%
  rename(max_cited_by_count = cited_by_count) %>%
  select(DOI,doi.url,max_cited_by_count,counts_by_year)  %>%
  tidyr::unnest(counts_by_year) -> works.step1
  # we now have:
  # [1] "DOI"                "doi.url"            "max_cited_by_count" "year"               "cited_by_count"
  #
  # It turns out, not all publications have citations in all years... those years are missing.
works.step1 %>%
  distinct(DOI,year) %>%
  expand(DOI,year) -> works.expanded
works.step1 %>%
  right_join(works.expanded) %>%
  # now to compute year-to-date cumulative citations, given early truncation
  # max 10 years
  arrange(DOI,desc(year)) %>%
  group_by(DOI) %>%
  mutate(max_cited_by_count  = max(max_cited_by_count,na.rm = TRUE),
         cited_by_count      = replace_na(cited_by_count,0),
         neg_cum_citations   = cumsum(replace_na(cited_by_count,0)),
         ytd_cited_by_count  = max_cited_by_count - neg_cum_citations + cited_by_count) %>%
  fill(doi.url,.direction = "updown") %>%
  select(-neg_cum_citations) %>%
  ungroup() ->
    works.df

names(works.df)
# > names(works.df)
# [1] "DOI"                "doi.url"            "max_cited_by_count" "year"               "cited_by_count"
# [6] "ytd_cited_by_count"
skim(works.df) %>% filter(n_missing >0)
# # A tibble: 0 × 17

saveRDS(works.df,citations.latest)

# Get overall h-index as of 2023 and h-index by year

# see next program


