

# Incorporating the found n-grams

This chapter documents the incorporation of the previously found n-grams into the speech text.

## Initialisation


```r
library(tidyverse)
library(tidytext)
library(pins)
library(pinsqs)
library(AzureStor)

source(here::here("R", "azure_init.R"))

speeches_board <- storage_endpoint("https://cbspeeches1.dfs.core.windows.net/", token=token) %>%
  storage_container(name = "cbspeeches") %>%
  board_azure(path = "data-speeches")
```


```r
speeches <- speeches_board %>%
  pin_qread("speeches-g7-cleaned")

bigrams <- speeches_board %>%
  pin_qread("gum-bigrams-g7")

trigrams <- speeches_board %>%
  pin_qread("gum-trigrams-g7")
```

## Text replacement

The identified n-grams were replaced in the text via regex. The `str_replace_all()` function allows
for multiple replacements by supplying a named vector whose names are the regex patterns and whose
values are the replacements. The regex patterns used were case insensitive and underscores were
added between words and at the end of the n-gram to prevent its stemming (at a later stage). In
addition, trigrams were replaced in the text before bigrams to ensure that the longest n-gram was
captured.


```r
trigram_replacements <- trigrams %>%
  mutate(across(c(token1, token2, token3), str_to_lower)) %>%
  distinct(token1, token2, token3) %>%
  mutate(
    pattern = str_c("(?i)\\b", token1, " ", token2, " ", token3, "\\b"),
    replacement = str_c(token1, "_", token2, "_", token3, "_")
  ) %>%
  pull(replacement, name=pattern)

bigram_replacements <- bigrams %>%
  mutate(across(c(token1, token2), str_to_lower)) %>%
  distinct(token1, token2) %>%
  mutate(
    pattern = str_c("(?i)\\b", token1, " ", token2, "\\b"),
    replacement = str_c(token1, "_", token2, "_")
  ) %>%
  pull(replacement, name=pattern)

speeches <- speeches %>%
  mutate(
    text = str_replace_all(text, trigram_replacements),
    text = str_replace_all(text, bigram_replacements)
  )
```

## Save the data

Writing the data to the pin board:


```r
speeches_board %>%
  pin_qsave(
    speeches,
    "speeches-g7-with-ngrams",
    title = "speeches for g7 countries, with ngrams"
  )
```
