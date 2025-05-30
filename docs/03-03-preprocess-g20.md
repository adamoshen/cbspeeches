

# Final pre-processing (G20)

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
  pin_qread("speeches-g20-with-ngrams")
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

### Removal of whitespace tokens and empty strings

A check was performed to verify that there were no stemmed tokens that were spaces or empty strings,
as this can result in unusable models downstream.


``` r
speeches %>%
  filter(wordstem == " ")

speeches %>%
  filter(stringi::stri_isempty(wordstem))
```

This time, there were empty wordstems that needed to be removed.


``` r
speeches <- speeches %>%
  filter(!stringi::stri_isempty(wordstem))
```

### Reduction of vocabulary size

After some exploration, it was found that many words appearing across three or fewer documents were
nonsense words, potential typos, or non-English words. As such, words appearing across three or
fewer documents were removed in an attempt to reduce the vocabulary size.


``` r
n_docs <- speeches %>%
  select(doc, wordstem) %>%
  distinct() %>%
  count(wordstem) %>%
  arrange(n)

low_doc_wordstems <- n_docs %>%
  filter(n <= 3) %>%
  select(wordstem)

speeches <- speeches %>%
  anti_join(low_doc_wordstems, by="wordstem")
```

Making a checkpoint:


``` r
speeches_board %>%
  pin_qsave(
    speeches,
    "processed-speeches-g20",
    title = "processed speeches for g20 countries. ready for dtm/tdm conversion."
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
    "speeches-g20-tdm",
    title = "tdm of speeches for g20 countries"
  )
```

## Create text input for keyATM

For Keyword-Assisted Topic Models in the {keyATM} package, a data frame containing on document per
row is required. As such, each document's tokens are re-joined together to form a single string.


``` r
speeches <- speeches %>%
  group_by(doc) %>%
  summarise(
    date = first(date),
    author = first(author),
    institution = first(institution),
    country = first(country),
    text = str_c(wordstem, collapse=" ")
  )
```


``` r
speeches_board %>%
  pin_qsave(
    speeches,
    "speeches-g20-keyATM",
    title = "processed speeches for keyATM"
  )
```
