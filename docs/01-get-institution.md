

# Extracting the institution from the text


```r
library(tidyverse)
library(readxl)
library(pins)
library(pinsqs)
library(cld2)
library(AzureStor)

source(here::here("R", "azure_init.R"))

speeches_board <- storage_endpoint("https://cbspeeches1.dfs.core.windows.net/", token=token) %>%
  storage_container(name = "cbspeeches") %>%
  board_azure(path = "data-speeches")
```


```r
speeches <- speeches_board %>%
  pin_qread("speeches-raw")
```

Speeches where the dominant language is not English, are removed. Of the 18,827 speeches, 18,813
(99.93%) are English and 14 (0.7%) are not English.


```r
speeches <- speeches %>%
  mutate(lang_cld2 = detect_language(text)) %>%
  filter(lang_cld2 == "en") %>%
  select(-lang_cld2)
```

An attempt to extract the institution from the first sentence of each speech is performed as
follows:


```r
extract_pattern1 <- "(?<=(?:Board of Governors|Governing Board|Executive Board|Chief Executive Officer) of the )[^[:punct:]]+"
extract_pattern2 <- "(?<=(?:Governor|President|Chairman|Director|Executive|Manager|Directorate) of the )[^[:punct:]]+"
extract_pattern3 <- "(?<=Governor of )[^[:punct:]]+" # for Philippines
extract_pattern4 <- "(?:Central|Reserve) Bank of (?:[:upper:][:lower:]+\\s?)+"
extract_pattern5 <- "Bank of (?:[:upper:][:lower:]+\\s?)+"
extract_pattern6 <- "(?i)National Bank of Serbia|Swiss National Bank|Hong Kong Monetary Authority|Monetary Authority of Singapore|Banco de Espana|Banco de Portugal|Banco de Mexico|South African Reserve Bank|Sveriges Riksbank|Oesterreichische Nationalbank"
extract_pattern7 <- "Federal Reserve System"
extract_pattern8 <- "(?i)Bank of [:alpha:]+"

speeches <- speeches %>%
  mutate(
    # Remove periods after salutations, initials, and credentials
    text = str_remove_all(text, "(?<=Mr|Ms|Mrs|PhD|Dr|Dott|Prof|Jr|Sig|\\bp|\\bm|\\ba|\\bh|\\bc|\\bmult|vs|[A-Z0-9])\\."),
    text = str_replace_all(text, "Member Board of Governors", "Member of the Board of Governors"),
    text = str_replace_all(text, "Govenor", "Governor"),
    # Extract first sentence before looking for patterns.
    first_sentence = str_extract(text, "^[^.]+\\."),
    institution = str_extract(first_sentence, extract_pattern1),
    institution = if_else(is.na(institution), str_extract(first_sentence, extract_pattern2), institution),
    institution = if_else(is.na(institution), str_extract(first_sentence, extract_pattern3), institution),
    institution = if_else(is.na(institution), str_extract(first_sentence, extract_pattern4), institution),
    institution = if_else(institution == "People", "People's Bank of China", institution),
    institution = if_else(is.na(institution), str_extract(first_sentence, extract_pattern5), institution),
    institution = if_else(is.na(institution), str_extract(first_sentence, extract_pattern6), institution),
    institution = if_else(is.na(institution), str_extract(first_sentence, extract_pattern7), institution),
    institution = if_else(is.na(institution), str_extract(first_sentence, extract_pattern8), institution)
  )
```

Of the remaining speeches whose institutions could not be extracted from the above process, the
authors' names were Googled to obtain their affiliation, and recorded in
`inst/data-misc/author_affiliations.xlsx`. This list is then used as a reference to populate the
missing institution values where an author name is present.


```r
author_affiliations <- read_xlsx(here::here("inst", "data-misc", "author_affiliations.xlsx")) %>%
  pull(affiliation, name=author) %>%
  as.list()

speeches <- speeches %>%
  mutate(
    institution = if_else(
      is.na(institution),
      map_chr(author, ~ pluck(author_affiliations, .x, .default=NA)),
      institution
    )
  )
```

Two rows remain with missing values for author and institution. These missing values can be filled
in as follows:


```r
data_update <- tribble(
  ~doc, ~author, ~institution,
  "r180725i", "Pablo Hernandez de Cos", "Bank of Spain",
  "r180810b", "Jorgovanka Tabakovic", "National Bank of Serbia"
)

speeches <- speeches %>%
  rows_update(data_update, by="doc")
```

Writing the data to the pin board:


```r
speeches_board %>%
  pin_qsave(
    speeches,
    "speeches-with-institution",
    title = "Speeches with institution column populated"
  )
```