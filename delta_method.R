bat_feats = read.csv('training_batters.csv')
colnames(bat_feats) = c('row', 'player_id')
bat_war = read.csv('updated_batting_war.csv')

bat_war_yrs = bat_war[bat_war$player_id %in% bat_feats$player_id,]
ages = sort(unique(bat_war_yrs$age))

deltas = rep(0, length(ages) - 1)

for (startage in ages[-length(ages)]) {
  delta_wars = bat_war_yrs[bat_war_yrs$age == startage | bat_war_yrs$age == startage + 1,]
  players_both = delta_wars[delta_wars$player_id %in% delta_wars[duplicated(delta_wars$player_id),]$player_id,]
  deltas[startage + 1 - ages[1]] = (sum(players_both[players_both$age == startage + 1,]$WAR) - sum(players_both[players_both$age == startage,]$WAR))*2/nrow(players_both)
}

age_deltas = data.frame(ages[-length(ages)], deltas)
colnames(age_deltas) = c('age','delta')

debutages = aggregate(bat_war_yrs$age, by = list(bat_war_yrs$player_id), FUN = min)
colnames(debutages) = c('player_id', 'debutage')

bat_war_yrs = merge(bat_war_yrs, debutages)
bat_war_yrs$year_num = bat_war_yrs$age - bat_war_yrs$debutage + 1

year_range = 7:11

train_r2s = rep(0, length(year_range))
test_r2s = rep(0, length(year_range))

test_players = read.csv('test_batters.csv')
colnames(test_players) = c('row', 'player_id')
test_bat_war_yrs = bat_war[bat_war$player_id %in% test_players$player_id,]

debutages_test = aggregate(test_bat_war_yrs$age, by = list(test_bat_war_yrs$player_id), FUN = min)
colnames(debutages_test) = c('player_id', 'debutage')
test_bat_war_yrs = merge(test_bat_war_yrs, debutages_test)
test_bat_war_yrs$year_num = test_bat_war_yrs$age - test_bat_war_yrs$debutage + 1


for (yearnum in year_range) {
  prev_train = bat_war_yrs[bat_war_yrs$year_num == yearnum - 1, c('player_id', 'age', 'WAR')]
  next_train = bat_war_yrs[bat_war_yrs$year_num == yearnum, c('player_id', 'WAR')]
  colnames(next_train) = c('player_id', 'WAR_next')
  prev_next_train = merge(prev_train, next_train)
  prev_next_train = merge(prev_next_train, age_deltas)
  prev_next_train$WAR_next_pred = prev_next_train$WAR + prev_next_train$delta
  train_r2s[yearnum - year_range[1] - 1] = with(prev_next_train, cor(WAR_next_pred, WAR_next)^2)
  
  prev_test = test_bat_war_yrs[test_bat_war_yrs$year_num == yearnum - 1, c('player_id', 'age', 'WAR')]
  next_test = test_bat_war_yrs[test_bat_war_yrs$year_num == yearnum, c('player_id', 'WAR')]
  colnames(next_test) = c('player_id', 'WAR_next')
  prev_next_test = merge(prev_test, next_test)
  prev_next_test = merge(prev_next_test, age_deltas)
  prev_next_test$WAR_next_pred = prev_next_test$WAR + prev_next_test$delta
  test_r2s[yearnum - year_range[1] - 1] = with(prev_next_test, cor(WAR_next_pred, WAR_next)^2)
}

results = data.frame(year_range, train_r2s, test_r2s)
colnames(results) = c('year_num', 'train_r2', 'test_r2')
#write.csv(results, 'batting_delta_results.csv', row.names = FALSE)

#### PITCHING

p_feats = read.csv('training_pitchers.csv')
colnames(p_feats) = c('row', 'player_id')
p_war = read.csv('pitching_war.csv')

p_war_yrs = p_war[p_war$player_id %in% p_feats$player_id,]
p_ages = sort(unique(p_war_yrs$age))

p_deltas = rep(0, length(p_ages) - 1)

for (startage in p_ages[-length(p_ages)]) {
  delta_wars = p_war_yrs[p_war_yrs$age == startage | p_war_yrs$age == startage + 1,]
  players_both = delta_wars[delta_wars$player_id %in% delta_wars[duplicated(delta_wars$player_id),]$player_id,]
  p_deltas[startage + 1 - ages[1]] = (sum(players_both[players_both$age == startage + 1,]$WAR) - sum(players_both[players_both$age == startage,]$WAR))*2/nrow(players_both)
}

p_age_deltas = data.frame(p_ages[-length(p_ages)], p_deltas)
colnames(p_age_deltas) = c('age','delta')

p_debutages = aggregate(p_war_yrs$age, by = list(p_war_yrs$player_id), FUN = min)
colnames(p_debutages) = c('player_id', 'debutage')

p_war_yrs = merge(p_war_yrs, p_debutages)
p_war_yrs$year_num = p_war_yrs$age - p_war_yrs$debutage + 1

ptrain_r2s = rep(0, length(year_range))
ptest_r2s = rep(0, length(year_range))

ptest_players = read.csv('test_pitchers.csv')
colnames(ptest_players) = c('row', 'player_id')
tp_war_yrs = p_war[p_war$player_id %in% ptest_players$player_id,]

debutages_tp = aggregate(tp_war_yrs$age, by = list(tp_war_yrs$player_id), FUN = min)
colnames(debutages_tp) = c('player_id', 'debutage')
tp_war_yrs = merge(tp_war_yrs, debutages_tp)
tp_war_yrs$year_num = tp_war_yrs$age - tp_war_yrs$debutage + 1

ptest_players = ptest_players[order(ptest_players$player_id),]

for (yearnum in year_range) {
  pprev_train = p_war_yrs[p_war_yrs$year_num == yearnum - 1, c('player_id', 'age', 'WAR')]
  pnext_train = p_war_yrs[p_war_yrs$year_num == yearnum, c('player_id', 'WAR')]
  colnames(pnext_train) = c('player_id', 'WAR_next')
  pprev_next_train = merge(pprev_train, pnext_train)
  pprev_next_train = merge(pprev_next_train, p_age_deltas)
  pprev_next_train$WAR_next_pred = pprev_next_train$WAR + pprev_next_train$delta
  ptrain_r2s[yearnum - 6] = with(pprev_next_train, cor(WAR_next_pred, WAR_next)^2)
  
  pprev_test = tp_war_yrs[tp_war_yrs$year_num == yearnum - 1, c('player_id', 'age', 'WAR')] #will need to select out debutage
  pnext_test = tp_war_yrs[tp_war_yrs$year_num == yearnum, c('player_id', 'WAR')]
  colnames(pnext_test) = c('player_id', 'WAR_next')
  pprev_next_test = merge(pprev_test, pnext_test)
  pprev_next_test = merge(pprev_next_test, p_age_deltas)
  pprev_next_test$WAR_next_pred = pprev_next_test$WAR + pprev_next_test$delta
  ptest_r2s[yearnum - 6] = with(pprev_next_test, cor(WAR_next_pred, WAR_next)^2)
}

presults = data.frame(year_range, ptrain_r2s, ptest_r2s)
colnames(presults) = c('year_num', 'train_r2', 'test_r2')
#write.csv(presults, 'pitching_delta_results.csv', row.names = FALSE)

### PLAYER BY PLAYER RESULTS

WAR_MISSING_VAL = -1

ptest_players$war6 = WAR_MISSING_VAL
ptest_players$war7 = WAR_MISSING_VAL
ptest_players$war8 = WAR_MISSING_VAL
ptest_players$war9 = WAR_MISSING_VAL
ptest_players$war10 = WAR_MISSING_VAL
ptest_players$war11 = WAR_MISSING_VAL

ptest_players$predwar7 = WAR_MISSING_VAL
ptest_players$predwar8 = WAR_MISSING_VAL
ptest_players$predwar9 = WAR_MISSING_VAL
ptest_players$predwar10 = WAR_MISSING_VAL
ptest_players$predwar11 = WAR_MISSING_VAL

ptest_players = unique(merge(ptest_players, tp_war_yrs[,c('player_id', 'debutage')]))

for(yearnum in year_range) {
  pprev_test = tp_war_yrs[tp_war_yrs$year_num == yearnum - 1, c('player_id', 'age', 'WAR')]
  pnext_test = tp_war_yrs[tp_war_yrs$year_num == yearnum, c('player_id', 'WAR')]
  
  if(yearnum == 7) {
    ptest_players[ptest_players$player_id %in% pnext_test$player_id,]$war7 = pnext_test$WAR
    ptest_players[ptest_players$player_id %in% pprev_test$player_id,]$war6 = pprev_test$WAR
  } else if(yearnum == 8) {
    ptest_players[ptest_players$player_id %in% pnext_test$player_id,]$war8 = pnext_test$WAR
  } else if(yearnum == 9) {
    ptest_players[ptest_players$player_id %in% pnext_test$player_id,]$war9 = pnext_test$WAR
  } else if(yearnum == 10) {
    ptest_players[ptest_players$player_id %in% pnext_test$player_id,]$war10 = pnext_test$WAR
  } else if(yearnum == 11) {
    ptest_players[ptest_players$player_id %in% pnext_test$player_id,]$war11 = pnext_test$WAR
  }
}

ptest_players$predwar7 = ptest_players$war6 + p_age_deltas$delta[ptest_players$debutage + 7 - min(p_age_deltas$age)]
ptest_players$predwar8 = ptest_players$war7 + p_age_deltas$delta[ptest_players$debutage + 8 - min(p_age_deltas$age)]
ptest_players$predwar9 = ptest_players$war8 + p_age_deltas$delta[ptest_players$debutage + 9 - min(p_age_deltas$age)]
ptest_players$predwar10 = ptest_players$war9 + p_age_deltas$delta[ptest_players$debutage + 10 - min(p_age_deltas$age)]
ptest_players$predwar11 = ptest_players$war10 + p_age_deltas$delta[ptest_players$debutage + 11 - min(p_age_deltas$age)]

ptest_players = ptest_players[,c(1,4:13)]

write.csv(ptest_players, 'pitching_pbp_delta1.csv')

ptest_r2s[1] = with(ptest_players, cor(war7, predwar7)^2)
ptest_r2s[2] = with(ptest_players, cor(war8, predwar8)^2)
ptest_r2s[3] = with(ptest_players, cor(war9, predwar9)^2)
ptest_r2s[4] = with(ptest_players, cor(war10, predwar10)^2)
ptest_r2s[5] = with(ptest_players, cor(war11, predwar11)^2)

presults = data.frame(year_range, ptrain_r2s, ptest_r2s)
colnames(presults) = c('year_num', 'train_r2', 'test_r2')
write.csv(presults, 'pitching_delta_results1.csv', row.names = FALSE)

#### Player by Player: Batters

test_players$war6 = WAR_MISSING_VAL
test_players$war7 = WAR_MISSING_VAL
test_players$war8 = WAR_MISSING_VAL
test_players$war9 = WAR_MISSING_VAL
test_players$war10 = WAR_MISSING_VAL
test_players$war11 = WAR_MISSING_VAL

test_players$predwar7 = WAR_MISSING_VAL
test_players$predwar8 = WAR_MISSING_VAL
test_players$predwar9 = WAR_MISSING_VAL
test_players$predwar10 = WAR_MISSING_VAL
test_players$predwar11 = WAR_MISSING_VAL

test_players = unique(merge(test_players, test_bat_war_yrs[,c('player_id', 'debutage')]))

for(yearnum in year_range) {
  prev_test = test_bat_war_yrs[test_bat_war_yrs$year_num == yearnum - 1, c('player_id', 'age', 'WAR')]
  next_test = test_bat_war_yrs[test_bat_war_yrs$year_num == yearnum, c('player_id', 'WAR')]
  
  if(yearnum == 7) {
    test_players[test_players$player_id %in% next_test$player_id,]$war7 = next_test$WAR
    test_players[test_players$player_id %in% prev_test$player_id,]$war6 = prev_test$WAR
  } else if(yearnum == 8) {
    test_players[test_players$player_id %in% next_test$player_id,]$war8 = next_test$WAR
  } else if(yearnum == 9) {
    test_players[test_players$player_id %in% next_test$player_id,]$war9 = next_test$WAR
  } else if(yearnum == 10) {
    test_players[test_players$player_id %in% next_test$player_id,]$war10 = next_test$WAR
  } else if(yearnum == 11) {
    test_players[test_players$player_id %in% next_test$player_id,]$war11 = next_test$WAR
  }
}

test_players$predwar7 = test_players$war6 + age_deltas$delta[test_players$debutage + 7 - min(age_deltas$age)]
test_players$predwar8 = test_players$war7 + age_deltas$delta[test_players$debutage + 8 - min(age_deltas$age)]
test_players$predwar9 = test_players$war8 + age_deltas$delta[test_players$debutage + 9 - min(age_deltas$age)]
test_players$predwar10 = test_players$war9 + age_deltas$delta[test_players$debutage + 10 - min(age_deltas$age)]
test_players$predwar11 = test_players$war10 + age_deltas$delta[test_players$debutage + 11 - min(age_deltas$age)]

test_players = test_players[,c(1,4:13)]

write.csv(test_players, 'batting_pbp_delta1.csv')

test_r2s[1] = with(test_players, cor(war7, predwar7)^2)
test_r2s[2] = with(test_players, cor(war8, predwar8)^2)
test_r2s[3] = with(test_players, cor(war9, predwar9)^2)
test_r2s[4] = with(test_players, cor(war10, predwar10)^2)
test_r2s[5] = with(test_players, cor(war11, predwar11)^2)

results = data.frame(year_range, train_r2s, test_r2s)
colnames(results) = c('year_num', 'train_r2', 'test_r2')
write.csv(results, 'batting_delta_results1.csv', row.names = FALSE)