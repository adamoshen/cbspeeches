# General cleaning function is to be used last, after all country-specific cleaning functions have
# been applied
clean_general <- function(x) {
  x <- str_remove_all(x, "(?<=[:punct:]|[:digit:]) References:? .+$")
  x <- str_remove_all(x, "References (?=[:upper:]).+$")
  x <- str_remove_all(x, "References - .+$")
  x <- str_remove_all(x, "Ladies and gentlemen, thank you for your attention[.!].*$")
  x <- str_remove_all(x, "(Thank you|Thanks)( very much)?( for your attention)?[.!].*$")
  x <- str_remove_all(x, "Thank you very much[.!].*$")
  x
}

clean_australia <- function(x) {
  x <- str_remove_all(x, "Endnotes? \\[\\*\\].+$")
  x <- str_remove_all(x, "(?<=[:punct:]|[:digit:]) (Bibliography|Appendix) .+$")
  x <- str_remove_all(x, "(?<=[.!?]) 1 [:upper:](?!ntroduction).*$")
  x
}

clean_china <- function(x) {
  x <- str_remove_all(x, "[:upper:][^.!?]+all good health[.!]")
  x <- str_remove_all(x, "[:upper:][^.!?]+wish the Forum[^.!?]+[.!]")
  x <- str_remove_all(x, "[:upper:][^.!?]+wish this (conference|event)[^.!?]+[.!]")
  x <- str_remove_all(x, "Thank you\\..*$")
  x <- str_remove_all(x, "[:upper:][^.!?]+for your attention[^.!?]*[.!]")
  x <- str_remove_all(x, "[:upper:][^.!?]+any (comments|questions)[^.!?]*[.!]")
  x
}

clean_indonesia <- function(x) {
  x <- str_remove_all(x, "[^.!]+bless[^.!]+[.!]")
  x <- str_remove_all(x, "Wassalamu.+$")
  x
}

clean_saudiarabia <- function(x) {
  x <- str_remove_all(x, "[^.!?]+[.!]$")
  x
}

clean_korea <- function(x) {
  x <- str_remove_all(x, "[^.!?]+successful conference[.!]")
  x <- str_remove_all(x, "Thank you( again)? for[^.!]+[.!]")
  x <- str_remove_all(x, "[^.!?]+(health|happiness|good fortune)[^.!]+[.!]")
  x
}

clean_ecb <- function(x) {
  x <- str_remove_all(x, "[.!?] 1 [:upper:](?!ntroduction).*$")
  x
}
