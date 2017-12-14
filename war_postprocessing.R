bats = read.csv('batting_war.csv')
bats = bats[,c(3,5,2,4,1)]
comb_war = aggregate(bats$WAR, by=list(player_id = bats$player_id, year = bats$year, age = bats$age, position = bats$position), FUN=sum)
colnames(comb_war) = c('player_id', 'year', 'age', 'position', 'WAR')
comb_war$WAR = round(comb_war$WAR, 1)
comb_war = comb_war[(order(comb_war$player_id)),]
write.csv(comb_war, 'updated_batting_war.csv', row.names=FALSE)

pitchers = read.csv('pitching_war.csv')
pitchers = pitchers[,c(3,4,2,1)]
p_war = aggregate(pitchers$WAR, by=list(player_id = pitchers$player_id, year = pitchers$year, age = pitchers$age), FUN=sum)
colnames(p_war) = c('player_id', 'year', 'age', 'WAR')
p_war$WAR = round(p_war$WAR, 1)
p_war = p_war[(order(p_war$player_id)),]
write.csv(p_war, 'pitching_war.csv', row.names=FALSE)