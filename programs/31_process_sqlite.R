# Download ONET and BLS OES data
# Data is about 50MB - depending on your connection, this might take a while.

source(file.path(rprojroot::find_root(rprojroot::has_file("pathconfig.R")),"pathconfig.R"),echo=FALSE)
source(file.path(programs,"config.R"), echo=FALSE)
source(file.path(programs,"global-libraries.R"), echo=FALSE)

# exclusions to not consider

exclusions.ext <- c("eps","pdf","doc","docx","ps","csv","dta","tex")

files_db <- dbConnect(RSQLite::SQLite(), kranz.sql)
articles_db <- dbConnect(RSQLite::SQLite(), kranz.sql2)

# ingest the articles db
dbGetQuery(articles_db,"SELECt id,journ,title,year,date,vol,issue,artnum,article_url,has_data,data_url,article_doi,data_doi FROM article  ;") %>%
  group_by(journ) -> articles

# Test
articles %>%  distinct(journ,.keep_all = TRUE)

# transform by journal specific pattern (in the absence of DOI)
articles %>%
  mutate(publisher = case_when(
    str_detect(article_url,fixed("aeaweb")) ~ "aea",
    str_detect(article_url,fixed("oup.com")) ~ "oup",
    str_detect(article_url,fixed("uchicago")) ~ "ucp",
    str_detect(article_url,fixed("econometric")) ~ "ecta",
    TRUE ~ "unknown"),
    article_doi = case_when(
      !is.na(article_doi) ~ article_doi,
      # https://www.aeaweb.org/articles?id=10.1257/aer.20150361  
      publisher == "aea" ~ str_remove(article_url,fixed("https://www.aeaweb.org/articles?id=")),
      # https://academic.oup.com/restud/article/81/1/1/1727641
      # publisher == "oup" ~ cannot be transformed
      # https://www.journals.uchicago.edu/doi/abs/10.1086/704494     
      publisher == "ucp" ~ str_remove(article_url,fixed("https://www.journals.uchicago.edu/doi/abs/"))
      # https://www.econometricsociety.org/publications/econometrica/2019/01/01/aggregate-betting-data-individual-risk-preferences
      # publisher == "ecta" ~ cannot be transformed
    )
  )

# We may need to match on vol/issue/artnum instead for other journals



# by journal
analysis_main %>% 
        group_by(journ,id) %>%
        summarize( present_main=max(present_main),
                         present_master=max(present_master)) %>%
        ungroup() %>%
        group_by(journ) %>%
	summarize(n=n(),
                         main_n=sum(present_main),
                         master_n=sum(present_master),
	                 any_n = sum(present_master | present_main)) %>%
       mutate(any_pct = 100 * any_n/n)
