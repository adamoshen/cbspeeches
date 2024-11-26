

# Data setup

## Initialisation


```r
library(tidyverse)
library(pins)
library(pinsqs)
library(AzureStor)

source(here::here("R", "azure_init.R"))

speeches_board <- storage_endpoint("https://cbspeeches1.dfs.core.windows.net/", token=token) %>%
  storage_container(name = "cbspeeches") %>%
  board_azure(path = "data-speeches")
```

## Minor adjustments to raw data

Read in speeches from the Dropbox:


```r
speeches <- read_csv("~/boc_speeches/lda/iteration_04/speeches_processed.csv")
```

Perform some minor adjustments:

- Rename the column `processed_text` to simply `text`.
- Remove the time component of the dates.
- Perform normalization of text and author names to their ASCII form.
- Encode in utf-8.
- Remove excessive spaces in `text` and `author` fields.
- Fix select author names for consistency.


```r
speeches <- speeches %>%
  rename(text = processed_text) %>%
  mutate(
    date = as_date(date),
    text = stringi::stri_trans_general(text, "Greek-Latin"),
    text = stringi::stri_trans_general(text, "Latin-ASCII"),
    text = utf8::as_utf8(text),
    text = str_squish(text),
    author = stringi::stri_trans_general(author, "Greek-Latin"),
    author = stringi::stri_trans_general(author, "Latin-ASCII"),
    author = utf8::as_utf8(author),
    author = str_squish(author)
  ) %>%
  mutate(
    author = str_replace_all(author, "Angelovska-Bezoska", "Angelovska-Bezhoska"),
    author = str_replace_all(author, "Angelovska Bezhoska", "Angelovska-Bezhoska"),
    text = str_replace_all(text, "Angelovska-Bezoska", "Angelovska-Bezhoska"),
    text = str_replace_all(text, "Angelovska Bezhoska", "Angelovska-Bezhoska")
  )
```

## Save the data

Writing the data to the pin board:


```r
speeches_board %>%
  pin_qsave(
    speeches,
    "speeches-raw",
    title = "speeches from dropbox with minor tweaks"
  )
```
