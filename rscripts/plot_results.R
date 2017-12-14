library(readr)
library(ggplot2)

# deltas

b_delta <- read_csv('batting_delta_results.csv')
p_delta <- read_csv('pitching_delta_results.csv')

# R2 score vs year

pt <- read_csv('Pitching_Test.csv')
bt <- read_csv('Batting_Results_test.csv')
names(pt) = names(bt) # different names for each of these

pt <- cbind(pt, Delta = p_delta$test_r2)
ptm = melt(pt, id=c("Year"), variable.name = 'Method', value.name = 'R2')

# plots for R2 vs year
ggplot(ptm, aes(x=Year,y=R2, group=Method, color=Method)) +
  geom_line() +
  labs(title="Year vs. Pitching R2 Score by Method") +
  theme(plot.title = element_text(hjust = 0.5))

bt <- cbind(bt, Delta = b_delta$test_r2)
btm = melt(bt, id=c("Year"), variable.name = 'Method', value.name = 'R2')

ggplot(btm, aes(x=Year,y=R2, group=Method, color=Method)) +
  geom_line() +
  labs(title="Year vs. Batting R2 Score by Method") +
  theme(plot.title = element_text(hjust = 0.5))

# combined batting/pitching R2 score vs. year
btm$type <- 'Batter'
ptm$type <- 'Pitcher'
ctm <- rbind(btm,ptm)

ggplot(ctm, aes(x=Year,y=R2, group=Method, color=Method)) +
  geom_point() + geom_line(linetype=2) +
  facet_wrap(~type) +
  theme_bw(base_size = 6) +
  theme(legend.position = 'bottom')

# player-by-player analysis
bat <- read_delim("~/baseball-preds/results/batting_pbp_results.csv", 
                                "\t", escape_double = FALSE, trim_ws = TRUE)
pitch <- read_delim("~/baseball-preds/results/pitching_test_pbp.csv", 
                                "\t", escape_double = FALSE, trim_ws = TRUE)

bat <- bat[order(bat$ID),]
bat_len <- dim(bat)[1]
bcd <- read_csv("comparison/batting_pbp_delta0.csv") # add in deltas
bat1 <- cbind(pred=bat$preds0, y=bat$'1',delta_pred=bcd$'predwar7',year=rep(7,bat_len))
bat2 <- cbind(pred=bat$preds0, y=bat$'2',delta_pred=bcd$'predwar8',year=rep(8,bat_len))
bat3 <- cbind(pred=bat$preds0, y=bat$'3',delta_pred=bcd$'predwar9',year=rep(9,bat_len))
bat4 <- cbind(pred=bat$preds0, y=bat$'4',delta_pred=bcd$'predwar10',year=rep(10,bat_len))
bat5 <- cbind(pred=bat$preds0, y=bat$'5',delta_pred=bcd$'predwar11',year=rep(11,bat_len))
bm = data.frame(rbind(bat1,bat2,bat3,bat4,bat5))

pitch <- pitch[order(pitch$player_id),]
pitch_len <- dim(pitch)[1]
pcd <- read_csv("comparison/pitching_pbp_delta0.csv") # add in deltas
pitch1 <- cbind(pred=pitch$pred0, y=pitch$'1',delta_pred=pcd$'predwar7',year=rep(7,pitch_len))
pitch2 <- cbind(pred=pitch$pred0, y=pitch$'2',delta_pred=pcd$'predwar8',year=rep(8,pitch_len))
pitch3 <- cbind(pred=pitch$pred0, y=pitch$'3',delta_pred=pcd$'predwar9',year=rep(9,pitch_len))
pitch4 <- cbind(pred=pitch$pred0, y=pitch$'4',delta_pred=pcd$'predwar10',year=rep(10,pitch_len))
pitch5 <- cbind(pred=pitch$pred0, y=pitch$'5',delta_pred=pcd$'predwar11',year=rep(11,pitch_len))
pm = data.frame(rbind(pitch1,pitch2,pitch3,pitch4,pitch5))

ggplot(pm, aes(x=pred, y=y)) + 
  geom_point() +
  geom_abline(intercept=0, slope=1, col='red')

# residual analysis -- batting

bm$'NN' = bm$y - bm$pred
bm$'Delta' = bm$y - bm$delta_pred
bmm <- melt(bm,id=c('y','year'),measure=c('Delta','NN'), variable.name = "Method", value.name = "Residual")
bmm$'Player WAR' = round(bmm$y)

ggplot(bmm, aes(x=round(y), y=Residual, group=interaction(round(y),Method), fill=Method)) +
  geom_boxplot(alpha=0.3) +
  labs(title="Batting Residual Comparison", 
       x = "Actual WAR (bin size = 1)",
       y = "Prediction Residual") +
  theme(plot.title = element_text(hjust = 0.5),
        legend.background = element_rect(fill="gray90", size=.5, linetype="dotted"))

# residual analysis -- pitching

pm$'NN' = pm$y - pm$pred
pm$'Delta' = pm$y - pm$delta_pred
pmm <- melt(pm,id=c('y','year'),measure=c('Delta','NN'), variable.name = "Method", value.name = "Residual")
pmm$'Player WAR' = round(pmm$y)

ggplot(pmm, aes(x=round(y), y=Residual, group=interaction(round(y),Method), fill=Method)) +
  geom_boxplot(alpha=0.3) +
  labs(title="Pitching Residual Comparison", 
       x = "Actual WAR (bin size = 1)",
       y = "Prediction Residual") +
  theme(plot.title = element_text(hjust = 0.5),
        legend.background = element_rect(fill="gray90", size=.5, linetype="dotted"))

# combined graphs ?!?!?!?!?!

bmm$type = 'Batter'
pmm$type = 'Pitcher'
cmm = rbind(bmm,pmm)

ggplot(cmm, aes(x=round(y), y=Residual, group=interaction(round(y),Method), fill=Method)) +
  geom_boxplot(outlier.shape = NA) +
  geom_abline(intercept=0, slope=0, col='red') +
  facet_wrap(~type) +
  labs(title="Residual Comparison", 
       x = "Actual WAR (bin size = 1)",
       y = "Prediction Residual") +
  theme(plot.title = element_text(hjust = 0.5),
        legend.background = element_rect(fill="gray90", size=.5, linetype="dotted"),
        text = element_text(size=14))

# scatterplots

bms <- melt(bm,id=c('y','year'),measure=c('pred','delta_pred'), variable.name = "Method", value.name = "Prediction")
pms <- melt(pm,id=c('y','year'),measure=c('pred','delta_pred'), variable.name = "Method", value.name = "Prediction")

bms$Method <- gsub('delta_pred','Delta Method',bms$Method)
bms$Method <- gsub('pred','Neural Net',bms$Method)
pms$Method <- gsub('delta_pred','Delta Method',pms$Method)
pms$Method <- gsub('pred','Neural Net',pms$Method)


ggplot(bms, aes(x=y, y=Prediction)) + 
  geom_point() +
  geom_abline(intercept=0, slope=1, col='red') +
  facet_wrap(~Method) +
  labs(title="Batting Predictions", 
       x = "Actual WAR",
       y = "Prediction") +
  theme(plot.title = element_text(hjust = 0.5),
        legend.background = element_rect(fill="gray90", size=.5, linetype="dotted"),
        text = element_text(size=14))

ggplot(pms, aes(x=y, y=Prediction)) + 
  geom_point() +
  geom_abline(intercept=0, slope=1, col='red') +
  facet_wrap(~Method) +
  labs(title="Pitching Predictions", 
       x = "Actual WAR",
       y = "Prediction") +
  theme(plot.title = element_text(hjust = 0.5),
        legend.background = element_rect(fill="gray90", size=.5, linetype="dotted"),
        text = element_text(size=14))

#hexbin plots
ggplot(bms, aes(x=y, y=Prediction)) +
  geom_hex(aes(fill=log(..count..))) + 
  geom_abline(intercept=0, slope=1, col='red') +
  facet_wrap(~Method) +
  labs(title="Batting Predictions", 
       x = "Actual WAR",
       y = "Prediction") +
  theme_bw(base_size = 6) +
  labs(fill="log(examples)") +
  theme(legend.position = 'bottom') +
  theme(plot.title = element_text(hjust = 0.5),
        legend.background = element_rect(fill="gray90", size=.5, linetype="dotted"))

ggplot(pms, aes(x=y, y=Prediction)) +
  geom_hex(aes(fill=log(..count..))) + 
  geom_abline(intercept=0, slope=1, col='red') +
  facet_wrap(~Method) +
  labs(title="Pitching Predictions", 
       x = "Actual WAR",
       y = "Prediction") +
  theme_bw(base_size = 6) +
  labs(fill="log(examples)") +
  theme(legend.position = 'bottom') +
  theme(plot.title = element_text(hjust = 0.5),
  legend.background = element_rect(fill="gray90", size=.5, linetype="dotted")) 

bms$type = 'Batter'
pms$type = 'Pitcher'
cms = rbind(bms,pms)

ggplot(cms, aes(x=y, y=Prediction)) +
  geom_hex(aes(fill=log(..count..))) +
  geom_abline(intercept=0, slope=1, col='red') +
  facet_wrap(~type+Method) +
  labs(x = "Actual WAR",
    y = "Prediction") +
  theme_bw(base_size=8) +
  labs(fill="log(examples)") +
  theme(legend.position = 'bottom') +
  theme(plot.title = element_text(hjust = 0.5),
        legend.background = element_rect(fill="gray90", size=.5, linetype="dotted"))
