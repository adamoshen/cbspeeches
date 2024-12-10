

# Cleaning text for G7 countries

This chapter documents the cleaning of the text for speeches given by a G7 country.

## Initialisation


```r
library(tidyverse)
library(readxl)
library(pins)
library(pinsqs)
library(AzureStor)

source(here::here("R", "azure_init.R"))

speeches_board <- storage_endpoint("https://cbspeeches1.dfs.core.windows.net/", token=token) %>%
  storage_container(name = "cbspeeches") %>%
  board_azure(path = "data-speeches")
```

## Filter speeches to G7 countries


```r
g7_members <- c("Canada", "France", "Germany", "Italy", "Japan", "United Kingdom", "United States")

speeches <- speeches_board %>%
  pin_qread("speeches-with-country") %>%
  filter(country %in% g7_members)
```

## Fix one date

There was one speech whose date should be December 2023, not December 2024, as this corpus only goes
up to January 2024.


```r
data_update <- tribble(
  ~doc, ~date,
  "r240109a", ymd("2023-12-08")
)

speeches <- speeches %>%
  rows_update(data_update, by="doc")
```

## Repairs and removals

### Remove introductions

The introductory remarks of each speech were removed using the same pattern previously used to
identify the first sentence of each speech.


```r
speeches <- speeches %>%
  mutate(
    text = str_remove(text, pattern="^[^.]+\\."),
    text = str_squish(text)
  )
```

The "Introduction" headers were also removed, identified by the presence of the word "Introduction"
in title case, followed by another word in title case.


```r
speeches <- speeches %>%
  mutate(text = str_remove(text, "Introduction (?=[:upper:])"))
```

### Remove references section


```r
speeches <- speeches %>%
  mutate(
    text = str_remove_all(text, "(?<=[:punct:]|[:digit:]) References:? .+$"),
    text = str_remove_all(text, "References (?=[:upper:]).+$")
  )
```

### Repair typos

As mentioned in the section on [normalising institution names](#normalise-institution-names), some
country names were incorrectly entered and require repair. Of the G7 countries, Italy was the only
one affected.


```r
speeches <- speeches %>%
  mutate(text = str_replace_all(text, "Italty", "Italy"))
```

### Remove own institution and country names

It is of greater interest when a central bank mentions another central bank or another country.
Therefore, all self-mentions of the bank, country, and inhabitants were removed. For example, for
Canada, words to remove would include: `Bank of Canada`, `Canada`, `Canada's`, and `Canadian`. The
removal patterns corresponding to each bank are stored in
`inst/data-misc/bank_country_regex_patterns.xlsx`.


```r
bank_country_regex_patterns <- read_xlsx("inst/data-misc/bank_country_regex_patterns.xlsx") %>%
  filter(country %in% g7_members) %>%
  select(country, regex_pattern)

speeches <- speeches %>%
  left_join(bank_country_regex_patterns, by="country") %>%
  mutate(text = str_remove_all(text, regex_pattern)) %>%
  select(-regex_pattern)
```

## General cleaning

### Normalisaion of COVID related terms


```r
speeches <- speeches %>%
  mutate(text = str_replace_all(text, "(?i)COVID|COVID19|COVID-19|coronavirus", "COVID"))
```

### Normalisation of select ngrams into acronyms

"Central Bank Digital Currency" is a particular 4-gram of interest and can be converted to its
abbreviated form.


```r
speeches <- speeches %>%
  mutate(text = str_replace_all(text, "(?i)Central Bank Digital Currency", "CBDC"))
```

### Remove non-ascii characters, emails, social media handles, and links


```r
speeches <- speeches %>%
  mutate(
    text = str_remove_all(text, "[:^ascii:]"),
    text = str_remove_all(text, "([[:alnum:]_.\\-]+)?@[[:alnum:]_.\\-]+"),
    text = str_remove_all(text, "https?://\\S+"),
    text = str_remove_all(text, "www\\.\\S+")
  )
```

### Remove/replace stray/excessive punctuation


```r
speeches <- speeches %>%
  mutate(
    text = str_remove_all(text, "(\\* )+"),
    text = str_replace_all(text, "\\?|!", "."),
    text = str_remove_all(text, ","),
    text = str_remove_all(text, "\""),
    text = str_replace_all(text, "'{2,}", "'"),
    text = str_remove_all(text, "\\B'(?=[:alpha:])"),
    text = str_remove_all(text, "(?<=[:alpha:])'\\B"),
    text = str_remove_all(text, "\\B'\\B"),
    text = str_replace_all(text, "\\.{3}", "."),
    text = str_remove_all(text, " \\. "),
    text = str_remove_all(text, "-"),
    text = str_remove_all(text, "_"),
    text = str_remove_all(text, "\\(|\\)|\\{|\\}|\\[|\\]|\\||;|:|\\+")
  )
```

### Remove numerical quantities

This included dollar signs, percent signs, punctuation separated numbers, and whole numbers.


```r
speeches <- speeches %>%
  mutate(
    text = str_remove_all(text, "\\$"),
    text = str_remove_all(text, "%"),
    text = str_remove_all(text, "[:digit:]+([.,]+[:digit:]+)*"),
    text = str_remove_all(text, "[:digit:]")
  )
```

### Remove stray letters


```r
speeches <- speeches %>%
  mutate(text = str_remove_all(text, "\\b[A-Za-z]\\b"))
```

### Final squish

Excessive whitespace resulting from previous removals/replacements was removed.


```r
speeches <- speeches %>%
  mutate(text = str_squish(text))
```

### Remove unneeded columns


```r
speeches <- speeches %>%
  select(-first_sentence)
```

## Save the data

Writing the data to the pin board:


```r
speeches_board %>%
  pin_qsave(
    speeches,
    "speeches-g7-cleaned",
    title = "speeches for g7 countries, cleaned"
  )
```

Make a separate copy of the metadata as well:


```r
speeches_metadata <- speeches %>%
  select(doc, date, institution, country)

speeches_board %>%
  pin_qsave(
    speeches_metadata,
    "speeches-g7-metadata",
    title = "metadata for g7 speeches"
  )
```
