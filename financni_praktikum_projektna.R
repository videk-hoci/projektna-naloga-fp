library(readr)
library(tidyverse)
library(rvest)
library(stringr)

data <- read_csv("data/grafi.csv") %>%
  mutate(obseg = str_replace(obseg,"\\+Infinity", "Inf")) %>%
  rename(alpha_kvadrat = "alpha^2") %>%
  filter(alpha_kvadrat != alpha) %>%
  filter(str_detect(graf, "^[0-9]")) %>%
  filter(as.numeric(str_extract(graf, "\\d+")) > kromaticno_stevilo + 1) %>%
  filter(max_stopnja > 2) %>%
  mutate(tricikli = tricikli / (as.numeric(str_extract(graf, "\\d+"))),
         stiricikli = stiricikli / (as.numeric(str_extract(graf, "\\d+"))))

alpha <- data[data$alpha == data$alpha_od,] %>% select(-5)
alpha_kvadrat <- data[data$alpha_kvadrat == data$alpha_od,] %>% select(-4)

enakost1 <- data[data$alpha_od == data$alpha_kvadrat,] %>%
  filter(alpha_od == 1)

write.csv(data, "vsi_podatki.csv", row.names = FALSE)
write.csv(alpha,"alpha.csv", row.names = FALSE)
write.csv(alpha_kvadrat,"alpha_kvadrat.csv", row.names = FALSE)

