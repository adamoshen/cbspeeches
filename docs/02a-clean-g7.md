

# Cleaning text for G7 countries

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
g7_members <- c("Canada", "France", "Germany", "Italy", "Japan", "England", "United States")

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

## Remove introductions

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

## Remove references section


```r
speeches <- speeches %>%
  mutate(
    text = str_remove_all(text, "(?<=[:punct:]|[:digit:]) References:? .+$"),
    text = str_remove_all(text, "References (?=[:upper:]).+$")
  )
```

### Repair typos

As mentioned in the section on [normalising institution names](#normalise-institution-names), some
country names were incorrectly entered and require repair. Of the G7 countries, Italy is the only
one affected.


```r
speeches <- speeches %>%
  mutate(text = str_replace_all(text, "Italty", "Italy"))
```

### Remove own institution and country names

It is of greater interest when a central bank mentions another central bank or another country.
Therefore, all self-mentions of the bank, country, and inhabitants are removed. For example, for
Canada, we would remove words such as Bank of Canada, Canada, Canada's, and Canadian. The patterns
corresponding to each bank are store in `inst/data-misc/bank_country_regex_patterns.xlsx`.


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
    text = str_replace_all(text, "\\.{3}", "."),
    text = str_remove_all(text, " \\. "),
    text = str_remove_all(text, "-"),
    text = str_remove_all(text, "_"),
    text = str_remove_all(text, "\\(|\\)|\\{|\\}|\\[|\\]|\\||;|:|\\+")
  )
```

### Remove numbers


```r
speeches <- speeches %>%
  mutate(
    text = str_remove_all(text, "[:digit:]"),
    text = str_remove_all(text, "\\$")
  )
```

### Final squish

To remove any excessive whitespace resulting from previous removals/replacements.


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
