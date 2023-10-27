# This program primarily handles completing an author database
# - find institutional affiliations, also productivity
# - code metaregions
# Output:
# - authors.completed.df.rds
# Intermediate:
# - input/output: affiliation.impute.Rds

source(file.path(rprojroot::find_rstudio_root_file(),"pathconfig.R"),echo=FALSE)
source(file.path(basepath,"global-libraries.R"),echo=FALSE)
source(file.path(programs,"libraries.R"), echo=FALSE)
source(file.path(programs,"config.R"), echo=FALSE)

library(openalexR)

# If you want to overwrite files, set the following to TRUE

override = TRUE

# Unpack the citations data for the authors field -> au_id
# These files come from 42
authors.df.rds   <- file.path(interwrk,"authors.df.Rds")
citations.df.rds <- file.path(interwrk,"citations.df.Rds")
authors.completed.df.rds <- file.path(interwrk,"authors.completed.df.Rds")

if ( file.exists(authors.df.rds) ) {
  message(paste0("File already exists: ",authors.df.rds))
  message("Loading file from previous version.")
} else {
  stop(paste0("File should have been present: ",authors.df.rds))
}

## load the file from disk
authors.df <- readRDS(authors.df.rds)
nrow(authors.df %>% distinct(au_id))

# Now let's create an author DB

author_year <- authors.df %>%
  select(article_id,doi.url,starts_with("au_"),starts_with("institution"),
         publication_year) %>%
  mutate(is_nber=str_detect(au_affiliation_raw,"NBER"))
skim(author_year)
nrow(author_year %>% distinct(au_id))

# ==================== Institutional imputations ==============================
# some of the author affiliations are empty. Let's fill those in.

## First, let's try those within this sample

author_year %>% filter(is.na(institution_id)) %>%
  arrange(au_affiliation_raw,publication_year) %>%
  select(article_id,doi.url,starts_with("au_"),is_nber,institution_id) -> empty_institution

## For simplicity, we hand-match them.

affiliation.edit   <- file.path(openalexloc,"affiliation-impute.csv")
affiliation.edited <- file.path(openalexloc,"affiliation-impute.xlsx")
affiliation.exist  <- file.path(openalexloc,"affiliations.csv")
affiliation.impute.Rds <- file.path(openalexloc,"affiliations-imputed.Rds")
affiliation.aej.Rds <- file.path(openalexloc,"openalex-institutions-aejae.Rds")

if ( file.exists(affiliation.edit) ) {
  message(paste0("File already exists: ",affiliation.edit))
  message("Not overwriting from previous version.")
} else {
  write_excel_csv(empty_institution,file=affiliation.edit)
}

## Also output the list of existing institutions with their ID

author_year %>% filter(!is.na(institution_id)) %>%
  select(starts_with("institution")) %>%
  distinct() %>%
  arrange(institution_display_name) %>%
  select(institution_display_name,institution_id,
         starts_with("institution")) -> institutions
write_excel_csv(institutions,file=affiliation.exist)


## Coding guidelines

# Code the closest match = openalex ID (full URL)
# If none, search using the API: https://api.openalex.org/institutions?search=name here
# If none, put into categories (company, nonprofit, education).
# Any empty will go into "other"

## Now we read it back in.


if ( file.exists(affiliation.edited) ) {
  message(paste0("File already exists: ",affiliation.edited))
  message("Loading file from previous version.")
} else {
  warning(paste0("File does not exist: ",affiliation.edited))
  warning("Proceeding without imputations.")
}

imputations <- read_excel(affiliation.edited)
skim(imputations)

## Let's look up the info on these via openalex

if ( file.exists(affiliation.impute.Rds) & !override ) {
  message(paste0("File already exists: ",affiliation.impute.Rds))
  message("Loading file from previous version.")
} else {
  tic.clear()
  tic("Query to openAlex")
  imputations %>% filter(!is.na(institution_id)) %>%
    filter(str_detect(institution_id,"openalex")) -> institutions.openalex
  imputations %>% filter(!is.na(institution_id)) %>%
    filter(str_detect(institution_id,"ror")) -> institutions.ror
  # Get openalex ids first
    institutions_toget <- unique(c(institutions.openalex$institution_id))
    institutions_from_ids <- oa_fetch(entity = "institutions",
                                      id = institutions_toget, verbose = FALSE)
  # now get any ror ones
    institutions_toget <- unique(c(institutions.ror$institution_id))
    institutions_from_ror <- oa_fetch(entity = "institutions",
                                      ror = institutions_toget, verbose = FALSE)
    toc(log=TRUE)
    # 1.348 sec elapsed
  # combine
  institutions_openalex <- bind_rows(institutions_from_ids,
                                     institutions_from_ror) %>%
    select(id,display_name,ror,country_code,type,works_count,cited_by_count) %>%
    # tidyverse can sometimes be strange
    rename_with(~ paste0("institution_", .x, recycle0 = TRUE))
  # merge them back on
  imputations.rds <- imputations %>%
    left_join(institutions_openalex) %>%
    mutate(institution_type = case_when(
      !is.na(institution_type) ~ institution_type,
      institution_id == "company" ~ "company",
      institution_id == "education" ~ "education",
      institution_id == "nonprofit" ~ "nonprofit",
      .default = "other"
    ))
  saveRDS(imputations.rds,affiliation.impute.Rds)
}

affiliation.impute <- readRDS(affiliation.impute.Rds) %>%
  mutate(imputed=TRUE)
skim(affiliation.impute)

# get the completment as well

if ( file.exists(affiliation.aej.Rds) & ! override ) {
  message(paste0("File already exists: ",affiliation.aej.Rds))
  message("Loading file from previous version.")
} else {
  tic.clear()
  tic("Query to openAlex")
  institutions_toget <- unique(c(institutions$institution_id))
  institutions_complete <- oa_fetch(entity = "institutions",
                                    id = institutions_toget, verbose = FALSE)
  toc(log=TRUE)
  # Query to openAlex: 38.708 sec elapsed
  institutions_complete %>%
    select(id,display_name,ror,country_code,type,works_count,cited_by_count) %>%
    # tidyverse can sometimes be strange
    rename_with(~ paste0("institution_", .x, recycle0 = TRUE)) %>%
    saveRDS(file=affiliation.aej.Rds)

}

affiliation_complete <- readRDS(file=affiliation.aej.Rds)
skim(affiliation_complete)

# Now combine it with the rest

author_year %>%
  select(article_id,au_id,au_display_name,institution_id,publication_year) %>%
  # re-attach complete information
  left_join(affiliation_complete,by="institution_id") %>%
  #filter(str_detect(au_display_name,"Hendren")) %>%
  left_join(affiliation.impute %>%
                            select(-is_nber,-au_affiliation_raw),
                          by=c("article_id", "au_id")) %>%
  mutate(institution_id           = coalesce(institution_id.x,institution_id.y),
         institution_display_name = coalesce(institution_display_name.x,institution_display_name.y),
         institution_ror          = coalesce(institution_ror.x,institution_ror.y),
         institution_country_code = coalesce(institution_country_code.x,institution_country_code.y),
         institution_works_count  = coalesce(institution_works_count.x,institution_works_count.y),
         institution_type         = coalesce(institution_type.x,institution_type.y)) %>%
    # cleanup
  rename(au_display_name = au_display_name.x)    %>%
  select(-ends_with(".x"),-ends_with(".y"),-au_display_name.y) %>%
  # now fill up and down
  arrange(au_id,publication_year) %>%
  group_by(au_id,publication_year) %>%
  fill(institution_id,.direction = "updown") %>%
  fill(institution_display_name,.direction = "updown") %>%
  fill(institution_ror,.direction = "updown") %>%
  fill(institution_country_code,.direction = "updown") %>%
  fill(institution_works_count,.direction = "updown") %>%
  fill(institution_type,.direction = "updown") %>%
  ungroup() ->
  author_year_institutions
skim(author_year_institutions)
nrow(author_year_institutions %>% distinct(institution_id))
message(paste0(" Unique authors: ",nrow(author_year_institutions %>% distinct(au_id))))

# there seem to be too many institutions.
# 3220
# We will grab the first one

author_year_institutions %>%
  filter(!is.na(institution_id)) %>%
  arrange(au_id,publication_year) %>%
  group_by(au_id) %>%
  filter(row_number()==1) %>%
  ungroup() %>%
  filter(!is.na(institution_country_code)) %>%
  select(-article_id) %>%
  rename(year_observation = publication_year) -> author_first_institution.step1
nrow(author_first_institution.step1 %>% distinct(au_id))
# [1] 1093 - we are missing a few authors
author_first_institution.step1 %>%
  right_join(authors.df %>% distinct(au_id),by="au_id") %>%
  mutate(institution_country_code= replace_na(institution_country_code,"ZZ"),
         institution_works_count = replace_na(institution_works_count,0),
         institution_type = replace_na(institution_type,"other")) ->
  author_first_institution
skim(author_first_institution)
table(author_first_institution$institution_country_code,useNA="always")
table(author_first_institution$institution_type,useNA="always")
message(paste0(" Unique authors: ",nrow(author_first_institution %>% distinct(au_id))))


# One last thing:

# - map countries to regions (Europe, US, RestNA, SA, ROW)
# - map universities into big/small publications (works_count)
#   we already have this for the imputed ones, lets attach it to the others


# Map countries to regions

isoregions <- read_csv("https://raw.githubusercontent.com/lukes/ISO-3166-Countries-with-Regional-Codes/master/all/all.csv")

## collapse

isoregions %>%
  select(name,country2=`alpha-2`,region,`intermediate-region`) %>%
  mutate(metaregion = case_when(
    region == "Europe" ~ "Europe",
    country2 == "US"    ~ "US",
    country2 == "CA"    ~ "RestNA",
    country2 == "MX"    ~ "RestNA",
    `intermediate-region` == "South America" ~ "SA",
    .default = "ROW"
  )) %>%
  select(country2,metaregion)-> metaregion

## merge on

author_first_institution %>%
  left_join(metaregion,by=c("institution_country_code"="country2")) %>%
  mutate(metaregion = replace_na(metaregion,"ROW"))-> tmp2
table(tmp2$metaregion,useNA="always")
skim(tmp2)

###### Add other information on institutions

###### Limit to the AEJ:AE authors

authors.df <- readRDS(file=file.path(interwrk,"authors.df.Rds"))

tmp2 %>%
  inner_join(authors.df %>% distinct(au_id)) -> tmp3
message(paste0(" Unique authors: ",nrow(tmp3 %>% distinct(au_id))))


saveRDS(tmp3,file=authors.completed.df.rds)

## Clean read-back

authors.completed.df <- readRDS(authors.completed.df.rds)
skim(authors.completed.df)
message(paste0(" Unique authors: ",nrow(authors.completed.df %>% distinct(au_id))))

ninstitutions <- nrow(authors.completed.df %>% distinct(institution_id))
ncountries    <- nrow(authors.completed.df %>% distinct(institution_country_code))

message(paste0(" Unique institutions: ",ninstitutions))
message(paste0(" Unique countries.  : ",ncountries))

cat(ninstitutions,
    file=file.path(TexIncludes,"ninstitutionsOA.tex"))
cat(ncountries,
    file=file.path(TexIncludes,"ncountriesOA.tex"))


