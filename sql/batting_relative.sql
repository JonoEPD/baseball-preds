-- SQL to compute league average metrics for each year
-- collated from ALL data, not just the players in our set


-- batting year base aggregates
DROP TABLE IF EXISTS batting_yba;

SELECT year,
SUM(g) AS g,
SUM(ab) AS ab,
SUM(r) AS r,
SUM(h) AS h,
SUM(double) AS double,
SUM(triple) AS triple,
SUM(hr) AS hr,
SUM(rbi) AS rbi,
SUM(sb) AS sb,
SUM(cs) AS cs,
SUM(bb) AS bb,
SUM(so) AS so,
SUM(ibb) AS ibb,
SUM(hbp) AS hbp,
SUM(sh) AS sh,
SUM(sf) AS sf,
SUM(g_idp) AS g_idp,
SUM(h + bb + ibb + hbp) AS ob, -- times on base
SUM(ab + bb + ibb + hbp + sh + sf) AS pa, -- plate appearances
SUM(h + double + triple*2 + hr*3) AS tb, -- total bases
COUNT(DISTINCT player_id) AS c -- unique players
INTO batting_yba
FROM batting_six
GROUP BY year
;

-- batting year averages
DROP TABLE IF EXISTS batting_yavg;

SELECT year,
g / c AS g,
ab / c AS ab,
r / c AS r,
h / c AS h,
double / c AS double,
triple / c AS triple,
hr / c AS hr,
rbi / c AS rbi,
sb / c AS sb,
cs / c AS cs,
bb / c AS bb,
so / c AS so,
ibb / c AS ibb,
hbp / c AS hbp,
sh / c AS sh,
sf / c AS sf,
g_idp / c AS g_idp,
ob / c AS ob,
pa / c AS pa,
tb / c AS tb,
ab / g AS ab_per_g,
r / ab AS r_per_ab,
h / ab AS batting_avg,
double / ab AS double_per_ab,
triple / ab AS triple_per_ab,
hr / ab AS hr_per_ab,
rbi / ab AS rbi_per_ab,
sb / ob AS sb_per_ob,
cs / ob AS cs_per_ob,
sb / (sb+cs) AS sb_ratio,
bb / pa AS bb_per_pa,
so / ab AS so_per_ab,
tb / ab AS slg,
(h + bb + hbp) / (ab + bb + sf + hbp) AS obp,
tb * (h+bb) / (ab + bb) AS rc,
tb * (h+bb) / (ab + bb)^2 AS rc_per_ab,
(h - hr) / (ab - so - hr + sf) AS babip,
(tb - h) / ab AS iso,
(ab + bb) / so AS pa_per_so
INTO batting_yavg
FROM batting_yba

;

\copy batting_yavg TO '~/baseball-preds/batting_yearly_averages.csv' WITH CSV HEADER DELIMITER ','
