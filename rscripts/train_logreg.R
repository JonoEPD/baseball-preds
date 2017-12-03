features <- read_csv('features.csv')
yvals <- read_csv('yvals_avg_rc.csv')

fnames <- colnames(features)[-1]
yidx <- match(features$player_id, yvals$player_id)
X <- features
y <- yvals[yidx,]

# simple plot comparing current to future performance
plot(X$rc_per_ab, y$rc_per_ab)
abline(0,1,col='red')

# simple logistic regression
Xnorm <- normalize_data(X)
Xnorm$y <- y$rc_per_ab
fmla <- as.formula(paste("y ~", paste(fnames, collapse= "+")))
m <- glm(fmla, data=Xnorm)
accuracy = sum(abs(m$residuals)) / sum(y$rc_per_ab)
print(paste("explanatory error of logistic regression: ",round(accuracy,3) * 100,'%'))


# min-max w/ mean normalization
normalize_data <- function(Xn) { 
  col_names <- setdiff(colnames(Xn), c("player_id"))
  norm_cache <<- sapply(col_names, function(name) {
    dat <- Xn[[name]]
    d_max <- max(dat)
    d_min <- min(dat)
    d_mean <- mean(dat)
    Xn[[name]] <<- (dat - d_mean) / max(abs(d_max - d_min),1) # don't div by 0
    data.frame(min=d_min, max=d_max, mean=d_mean)
  })
  norm_cache <<- t(norm_cache)
  Xn
}
