

# Final pre-processing

This chapter documents the final pre-processing steps before the text can be transformed into the
required document-term matrices and term-document matrices.

## Initialisation


``` r
library(tidyverse)
library(tidytext)
library(stringa)
library(SnowballC)
library(pins)
library(pinsqs)
library(AzureStor)

source(here::here("R", "azure_init.R"))

speeches_board <- storage_endpoint("https://cbspeeches1.dfs.core.windows.net/", token=token) %>%
  storage_container(name = "cbspeeches") %>%
  board_azure(path = "data-speeches")
```


``` r
speeches <- speeches_board %>%
  pin_qread("speeches-g7-with-ngrams")
```

The list of stop words used was derived from the Snowball stop word lexicon (obtained from
`tidytext::stop_words`), but with negation terms removed. The full data set of stop words with
negation terms removed (includes stop words from other lexicons) can be found in
`stringa::nonneg_stop_words`. The code used to obtain this stop word list can be found
[here](https://github.com/adamoshen/stringa/blob/main/data-raw/nonneg_stop_words.R).


``` r
nonneg_snowball <- nonneg_stop_words %>%
  filter(lexicon == "snowball") %>%
  select(-lexicon)
```

## Pre-processing

The usual pre-processing steps were performed, including:

- Unnesting into tokens. Lowercasing occurs at this step.
- Removal of non-negative stop words.
- Stemming of words.


``` r
speeches <- speeches %>%
  unnest_tokens(output=word, input=text) %>%
  anti_join(nonneg_snowball, by="word") %>%
  mutate(wordstem = wordStem(word))
```

A final check was performed to verify that there were no stemmed tokens that were spaces or empty
strings, as this can result in unusable models downstream.


``` r
speeches %>%
  filter(wordstem == " ")

speeches %>%
  filter(stringi::stri_isempty(wordstem))
```

Making a quick checkpoint:


``` r
speeches_board %>%
  pin_qsave(
    speeches,
    "processed-speeches-g7",
    title = "processed speeches for g7 countries. ready for dtm/tdm conversion."
  )
```

## Create document-term matrix

The document-term matrix is required for topic models via the `{topicmodels}` package.


``` r
speeches_dtm <- speeches %>%
  count(doc, wordstem) %>%
  cast_dtm(doc, wordstem, n)
```


``` r
speeches_board %>%
  pin_qsave(
    speeches_dtm,
    "speeches-g7-dtm",
    title = "dtm of speeches for g7 countries"
  )
```

## Create term-document matrix

The term-document matrix (as a plain matrix) is required for NMF models.


``` r
speeches_tdm <- speeches %>%
  count(doc, wordstem) %>%
  cast_tdm(wordstem, doc, n) %>%
  as.matrix()
```


``` r
speeches_board %>%
  pin_qsave(
    speeches_tdm,
    "speeches-g7-tdm",
    title = "tdm of speeches for g7 countries"
  )
```
