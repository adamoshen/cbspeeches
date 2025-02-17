

# (PART\*) Proof of concept - G20 {.unnumbered}

# Identifying important bigrams and trigrams (G20)

This chapter documents the identification of important bigrams and trigrams following the procedure
described in @hansen_2018 and @justeson_1995, as was
[previously done for the G7 countries](#identifying-important-bigrams-and-trigrams).

## Initialisation


``` r
library(tidyverse)
library(tidytext)
library(udpipe)
library(magrittr)
library(pins)
library(pinsqs)
library(AzureStor)

source(here::here("R", "azure_init.R"))

speeches_board <- storage_endpoint("https://cbspeeches1.dfs.core.windows.net/", token=token) %>%
  storage_container(name = "cbspeeches") %>%
  board_azure(path = "data-speeches")
```

## Tokenise the text for POS-tagging

The text was first tokenised into sentences in order to create a sentence identifier within
documents. This is required later when looking at tag sequences, as tag sequences that span across
sentences should not be considered. The text was not cast to lowercase just yet, as it appeared to
affect tagging.

Unlike the tokenising done for POS-tagging for the
[G7 speeches](#identifying-important-bigrams-and-trigrams), the speeches are also arranged by the
document ID before tokenising so that the tagged speech tokens can simply be column-bound back to
the IDs (i.e. no data joining required).


``` r
speech_tokens <- speeches_board %>%
  pin_qread("speeches-g20-cleaned") %>%
  select(doc, text) %>%
  arrange(doc) %>%
  unnest_sentences(output=sentence, input=text, to_lower=FALSE) %>%
  group_by(doc) %>%
  mutate(sentence_id = 1:n()) %>%
  ungroup() %>%
  unnest_tokens(output=token, input=sentence, to_lower=FALSE)
```

Creating a quick checkpoint:


``` r
speeches_board %>%
  pin_qsave(
    speech_tokens,
    "speeches-g20-tokens",
    title = "tokens of speeches for g20 countries, cleaned"
  )
```

## Perform the POS tagging

### Download annotated model

The model that used for tagging is the
[Universal Dependencies English GUM corpus](https://universaldependencies.org/treebanks/en_gum/index.html).
The model is included in the `inst/data-misc` folder, but can be downloaded by calling the
following:


``` r
udpipe_download_model(language="english-gum", model_dir=here::here("inst", "data-misc"))
```

The downloaded model can be loaded as follows:


``` r
english_gum <- udpipe_load_model(file = here::here("inst", "data-misc", "english-gum-ud-2.5-191206.udpipe"))
```

### Break text tokens into chunks

One of the values outputted after annotating is the
[CoNLL-U morphological annotation](https://universaldependencies.org/format.html#morphological-annotation),
While this information is not used in this analysis, it is obtained by concatenating all word tokens
with their annotation notes (see example in previous link) into a single string. This becomes
problematic for larger corpora since the maximum length of a single string is limited to
$2^{31} - 1$ characters. As such, before annotating, the text tokens must be divided into smaller
chunks such that the resulting concatenation of word tokens with their annotation notes does not
exceed the maximum allotted number of characters.

The following code breaks the word tokens into 12 chunks (as a list) while ensuring that all tokens
belonging to the same document are kept together in the proper order such that exact sentences
within documents can be recovered later for the discovery of bigrams and trigrams.


``` r
speech_token_chunks <- speech_tokens %>%
  select(doc, token) %>%
  group_by(doc) %>%
  mutate(doc_index = cur_group_id()) %>%
  ungroup() %>%
  mutate(chunk = cut(doc_index, 12)) %>%
  group_by(chunk) %>%
  group_split() %>%
  map(~ select(.x, -c(doc_index, chunk)))
```

### Tagging

The annotation code from before can be re-used and re-purposed into a function.


``` r
udpipe_annotate_tibble <- function(chunk) {
  chunk %$%
    udpipe_annotate(
      object=english_gum, x=token, doc_id=doc,
      tokenizer="vertical", parser="none", trace=5e5
    ) %>%
    as_tibble() %>%
    select(doc_id, token, lemma, upos) %>%
    rename(upos_gum = upos)
}
```

The text chunks are annotated individually before being bound back together with the original
document ids and sentence ids.


``` r
tags_gum <- speech_token_chunks %>%
  map(udpipe_annotate_tibble) %>%
  list_rbind()

tags_gum <- tags_gum %>%
  bind_cols(
    speech_tokens %>%
      select(sentence_id)
  ) %>%
  select(doc_id, sentence_id, token, lemma, upos_gum)
```

Creating a checkpoint as usual:


``` r
speeches_board %>%
  pin_qsave(
    tags_gum,
    "gum-tagged-tokens-g20",
    title = "gum tagged tokens of speeches for g20 countries"
  )
```

## Determine bigrams and trigrams

As before, from @hansen_2018, trigram sequences of interest with frequencies greater than or equal
to 50 are:

- adjective - adjective - noun
- adjective - noun - noun
- noun - adjective - noun
- noun - noun - noun
- noun - preposition - noun

Proper nouns were treated as nouns.


``` r
trigrams <- tags_gum %>%
  select(-lemma) %>%
  rename(token1=token, upos_gum1=upos_gum) %>%
  group_by(doc_id, sentence_id) %>%
  mutate(
    token2 = lead(token1),
    token3 = lead(token2),
    upos_gum1 = if_else(upos_gum1 == "PROPN", "NOUN", upos_gum1),
    upos_gum2 = lead(upos_gum1),
    upos_gum3 = lead(upos_gum2)
  ) %>%
  ungroup() %>%
  drop_na() %>%
  select(token1, token2, token3, upos_gum1, upos_gum2, upos_gum3) %>%
  unite(col="pos_pattern", upos_gum1, upos_gum2, upos_gum3) %>%
  filter(
    str_detect(
      pos_pattern,
      "ADJ_ADJ_NOUN|ADJ_NOUN_NOUN|NOUN_ADJ_NOUN|NOUN_NOUN_NOUN|NOUN_ADP_NOUN"
    )
  ) %>%
  count(token1, token2, token3, pos_pattern) %>%
  filter(n >= 50) %>%
  arrange(desc(n))
```

From @hansen_2018, bigram sequences of interest with frequencies greater than or equal to 100 are:

- adjective - noun
- noun - noun

Proper nouns were treated as nouns.


``` r
bigrams <- tags_gum %>%
  select(-lemma) %>%
  rename(token1=token, upos_gum1=upos_gum) %>%
  group_by(doc_id) %>%
  mutate(
    token2 = lead(token1),
    upos_gum1 = if_else(upos_gum1 == "PROPN", "NOUN", upos_gum1),
    upos_gum2 = lead(upos_gum1)
  ) %>%
  ungroup() %>%
  drop_na() %>%
  select(token1, token2, upos_gum1, upos_gum2) %>%
  unite(col="pos_pattern", upos_gum1, upos_gum2) %>%
  filter(
    str_detect(
      pos_pattern,
      "ADJ_NOUN|NOUN_NOUN"
    )
  ) %>%
  count(token1, token2, pos_pattern) %>%
  filter(n >= 100) %>%
  arrange(desc(n))
```

### Prune bigrams

Bigrams whose frequencies fall below the required threshold after consideration for their
appearances in trigrams should be removed. For example, consider the following n-gram counts:

- `rising oil prices`: 339
- `falling oil prices`: 275
- `oil prices`: 642

Since the bigram `oil prices` only appears 642 - 339 - 275 = 28 times on its own, it does not meet
the bigram frequency threshold and should be removed from the list of bigrams.


``` r
trigram_token_counts <- trigrams %>%
  select(token1, token2, token3, n)

bigram_token_counts <- bigrams %>%
  select(token1, token2, n)

bigrams_to_remove <- bind_rows(
  trigram_token_counts %>%
    select(token1, token2, n) %>%
    inner_join(bigram_token_counts, by=c("token1", "token2"), suffix=c("_tri", "_bi")
  ),
  trigram_token_counts %>%
    select(token2, token3, n) %>%
    rename(token1=token2, token2=token3) %>%
    inner_join(bigram_token_counts, by=c("token1", "token2"), suffix=c("_tri", "_bi"))
) %>%
  group_by(token1, token2) %>%
  summarise(
    n_tri = sum(n_tri),
    n_bi = unique(n_bi)
  ) %>%
  ungroup() %>%
  mutate(n_diff = n_bi - n_tri) %>%
  filter(n_diff < 100) %>%
  select(token1, token2)

bigrams <- anti_join(bigrams, bigrams_to_remove, by=c("token1", "token2"))
```

## Save the data

Writing the data to the pin board:


``` r
speeches_board %>%
  pin_qsave(
    trigrams,
    "gum-trigrams-g20",
    title = "gum trigrams from g20 speeches"
  )

speeches_board %>%
  pin_qsave(
    bigrams,
    "gum-bigrams-g20",
    title = "gum bigrams from g20 speeches"
  )
```
