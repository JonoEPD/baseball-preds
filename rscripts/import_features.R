library(readr)
library(tidyverse)

batting <- read_csv('batting.csv')

pl <- player_list(batting, 2009)

# exclude players outside of the selected range
batting <- batting[batting$player_id %in% pl,]

# merge all stints after the first from the same year/player into the first
bat_cols <- c('g','ab','r','h','double','triple','hr','rbi','sb','cs','bb','so','ibb')
batting <- merge_stints(batting, bat_cols)

# merge first 6 years for players
m_bat <- merge_years(batting, bat_cols)
m_bat <- data.frame(t(m_bat)) # flip result back into a data frame

# build basic features 