# Getting in-scope articles
# Code derived from another project
# NOTE: THIS REQUIRES R 4.2.0 and newer packages!
#

source(file.path(rprojroot::find_rstudio_root_file(),"pathconfig.R"),echo=FALSE)
source(file.path(basepath,"global-libraries.R"),echo=FALSE)
source(file.path(programs,"libraries.R"), echo=FALSE)
source(file.path(programs,"config.R"), echo=FALSE)

library(rcrossref)

# filenames in config.R


# Each journal has a ISSN
if (!file.exists(issns.file)) {
  issns <- data.frame(matrix(ncol=3,nrow=9))
  names(issns) <- c("journal","issn","lastdate")
  tmp.date <- c("2000-01")
issns[1,] <- c("American Economic Journal: Applied Economics","1945-7790",tmp.date)
issns[2,] <- c("American Economic Journal: Economic Policy","1945-774X",tmp.date)
issns[3,] <- c("American Economic Journal: Macroeconomics", "1945-7715",tmp.date)
issns[4,] <- c("American Economic Journal: Microeconomics", "1945-7685",tmp.date)
issns[5,] <- c("The American Economic Review","1944-7981",tmp.date)
issns[6,] <- c("The American Economic Review","0002-8282",tmp.date)  # print ISSN is needed!
issns[7,] <- c("Journal of Economic Literature","2328-8175",tmp.date)
issns[8,] <- c("Journal of Economic Perspectives","1944-7965",tmp.date)
issns[9,] <- c("American Economic Review: Insights","2640-2068",tmp.date)

  saveRDS(issns, file= issns.file)
}

issns <- readRDS(file = issns.file)

if (!file.exists(doi.file.Rds) ) {
  new.df <- NA
  for ( x in 1 ) {
    new <- cr_journals(issn=issns[x,"issn"], works=TRUE,
                       filter=c(from_pub_date=issns[x,"lastdate"]),
                       select=c("DOI","title","published-print","volume","issue","container-title","author"),
                       .progress="text",
                       cursor = "*")
    if ( x == 1 ) {
      new.df <- as.data.frame(new$data)
      new.df$issn = issns[x,"issn"]
    } else {
      tmp.df <- as.data.frame(new$data)
      tmp.df$issn = issns[x,"issn"]
      new.df <- bind_rows(new.df,tmp.df)
      rm(tmp.df)
    }
  }
  # filters
  new.df %>%
    filter(title!="Front Matter") %>%
    filter(!str_detect(title,"Volume")) %>%
    filter(!str_detect(title,"Forthcoming")) %>%
    # filter(title!="Editor's Note") %>%
    # More robust
    filter(str_sub(doi, start= -1)!="i")-> filtered.df
  saveRDS(filtered.df, file=  doi.file.Rds)
  rm(new)
}


# clean read-back
aejdois <- readRDS(file= doi.file.Rds)
nrow(aejdois)

# subset to the years in-scope: 2009-2018.
aejdois %>%
  mutate(year=substr(published.print,1,4)) %>%
  filter(year < 2019 ) %>%
  filter(published.print < '2018-07-01') %>%
  group_by(year) %>%
  summarise(Published=n())    -> aejdois.by.year

aejdois.by.year

aejdois.by.year %>% ungroup() %>% summarize(n=sum(Published)) -> aejdois.total

aejdois.total

#  Some nnumbers for the text
cat(as.numeric(aejdois.total),
    file=file.path(TexIncludes,"aejdoistotal.tex"))




###################################################
### code chunk number 5: tab1_1
###################################################
# Print yearly breakdown of article count table
# This redoes Table 1, after R&R

complete_sample <- readRDS(file=file.path(dataloc,"00_complete_sample.Rds"))
nrow(complete_sample)

# test: match to complete sample by DOI, should be no missing (complete_rate = 1)

left_join(complete_sample,aejdois %>% mutate(match=TRUE),by=c("DOI"="doi")) %>% select(match) %>% skim()

# create the table

complete_sample %>%
  group_by(year) %>%
  summarize(Selected=n()) %>%
  right_join(aejdois.by.year) -> t_entry



# Add sum row
t_entry[11,1] = c("Total")
t_entry[11,2] = colSums(t_entry[,2],na.rm=TRUE)
t_entry[11,3] = colSums(t_entry[,3],na.rm=TRUE)

t_entry %>%
  select(year,Published,Selected) %>%
  mutate(`Percent` = round(Selected/Published*100,2)) %>%
  pivot_longer(cols = -1 ) %>%
  pivot_wider(names_from = "year",values_from = "value") %>%
  rename(` `=name) -> t_entry_t

print(t_entry_t)

# Transpose table
#t_entry_t <- transpose(t_entry)
#colnames(t_entry_t) <- t_entry_t[1, ] # the first row will be the header
#t_entry_t = t_entry_t[-1, ]


stargazer(t_entry_t,
          type="latex",title = "Articles Published and Selected by Year",label="tab:Selection",
          style="aer",
          flip=FALSE,summary=FALSE, rownames = FALSE,
          font.size = fs,column.sep.width = cw,
          out=file.path(TexIncludes,"table_article_selection.tex"),
          notes=c("Notes: Assessments made using the entry questionnaire by replicators,",
                  "prior to attempting to reproduce any tables or figures. The sample of assessed",
                  "papers comprises those for which we had complete assessment questionnaires."))
