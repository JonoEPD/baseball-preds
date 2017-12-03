
# get list of players who had 6 seasons AND started after the min year
player_list <- function(dat, min_year = 1970, seasons = 6) {
  ps <- player_starts(dat)
  pn <- names(ps)[ps >= min_year]
  p_dat <- dat[dat$player_id %in% pn,]
  m_dat <- p_dat[p_dat$stint == 1,] # get only first stint for year
  pc <- rowSums(table(m_dat$player_id, m_dat$year))
  p <- pc[pc >= seasons]
  names(p)
}

# get list of first year player was in data set
# pretty slow, could optimize a lot w/ a hash or something
player_starts <- function(dat) {
  up <- unique(dat$player_id)
  sapply(up, function(player){
    min(dat[dat$player_id == player,]$year)
  })
}

merge_stints <- function(dat, merge_cols){
  stints <- dat[dat$stint > 1,]
  m_dat <- dat[dat$stint == 1,]
  # add all stints >= 1 to stint 1 of the same player/year
  for(i in 1:length(stints)) {
    stint <- stints[i,]
    idx <- which(m_dat$player_id == stint$player_id & m_dat$year == stint$year)
    m_dat[idx,] = merge_vectors(m_dat[idx,], stint, merge_cols)
  }
  m_dat
}

merge_years <- function(dat, merge_cols){
  up <- unique(dat$player_id)
  sapply(up, function(player_id){
    pdat <- dat[dat$player_id == player_id,]
    pdat <- pdat[order(pdat$year),] # make sure player's data frame is ordered
    v1 <- pdat[1,]
    for(i in 2:6){ # add years 2-6 to the vector
      v2 <- pdat[i,]
      v1 <<- merge_vectors(v1, v2, merge_cols)
    }
    v1
  })
}

# add together specified values from the listed vectors
# otherwise default to v1
merge_vectors <- function(v1, v2, merge_cols) {
  for(col in merge_cols) {
    v1[col] = v1[col] + v2[col]
  }
  v1
}