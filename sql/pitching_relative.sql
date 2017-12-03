-- SQL to compute pitching metrics from players in our set

DROP TABLE IF EXISTS pitching_yba;

SELECT
SUM(g) AS g,
SUM(w) AS w,
SUM(l) AS l,
SUM(gs) AS gs,
SUM(cg) AS cg,
SUM(sho) AS sho,
SUM(sv) AS sv,
SUM(ipouts) AS ipouts,
SUM(h) AS h,
SUM(er) AS er,
SUM(hr) AS hr,
SUM(bb) AS bb,
SUM(so) AS so,
SUM(ibb) AS ibb,
SUM(wp) AS wp,
SUM(hbp) AS hbp,
SUM(bfp) AS bfp,
SUM(gf) AS gf,
SUM(r) AS r,
SUM(bfp - bb - COALESCE(sh,0) - COALESCE(sf,0) - hbp) AS tbf, -- true batters faced,
COUNT(DISTINCT ARRAY[player_id, year::text]) AS c -- unique player/years
INTO pitching_yba
FROM pitching_six;

DROP TABLE IF EXISTS pitching_yavg;
SELECT
g / c AS g,
w / c AS w,
l / c AS l,
gs / c AS gs,
cg / c AS cg,
sho / c AS sho,
sv / c AS sv,
ipouts / c AS ipouts,
h / c AS h,
er / c AS er,
hr / c AS hr,
bb / c AS bb,
so / c AS so,
ibb / c AS ibb,
wp / c AS wp,
hbp / c AS hbp,
bfp / c AS bfp,
gf / c AS gf,
r / c AS r,
tbf / c AS tbf,
0 AS war, -- for now just set average war = 0
safe_div(er * 9,(ipouts / 3)) AS era,
safe_div(h,tbf) AS baopp,
-- per game stats
safe_div(tbf,g) AS tbf_per_g,
safe_div(gs,g) AS starter_ratio,
safe_div(w,g) AS w_per_g,
safe_div(l,g) AS l_per_g,
safe_div(w,GREATEST((w+l),1)) AS p_win,
safe_div(gf,g) AS gf_per_g,
safe_div(cg,g) AS cg_per_g,
safe_div(sho,g) AS sho_per_g,
safe_div(sv,g) AS sv_per_g,
safe_div(ipouts,g) AS ipouts_per_g,
-- per at bat (or tbf) stats
safe_div(bb,bfp) AS bb_per_bfp,
safe_div(hbp,bfp) AS hbp_per_bfp,
safe_div(hr,tbf) AS hr_per_tbf,
safe_div(so,tbf) AS so_per_tbf,
safe_div(wp,bfp) AS wp_per_bfp,
safe_div(so,bb) AS so_per_bb
INTO pitching_yavg
FROM pitching_yba

;

\copy pitching_yavg TO '~/baseball-preds/pitching_means.csv' WITH CSV HEADER DELIMITER ',' ;
