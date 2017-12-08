---Pitcher aggregates

DROP TABLE IF EXISTS pitching_sya;
SELECT player_id,
COUNT(DISTINCT year_num) AS active_years,
COUNT(*) - COUNT(DISTINCT year_num) AS extra_stints,
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
SUM(bfp - bb - COALESCE(sh,0) - COALESCE(sf,0) - hbp) AS tbf -- true batters faced

INTO pitching_sya
FROM pitching_six
GROUP BY player_id;

-- join WAR data
DROP TABLE IF EXISTS pitching_swa;
SELECT R.*, W.war
INTO pitching_swa
FROM pitching_sya R
LEFT JOIN (
SELECT player_id, SUM(COALESCE(war, 0)) AS war
FROM pitching_war
GROUP BY player_id
) AS W
ON R.player_id = W.player_id;

-- select into feature table

DROP TABLE IF EXISTS pitching_sfa;

SELECT *,
safe_div(er * 9,(ipouts / 3)) AS era,
safe_div(h,tbf) AS baopp,
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
safe_div(bb,bfp) AS bb_per_bfp,
safe_div(hbp,bfp) AS hbp_per_bfp,
safe_div(hr,tbf) AS hr_per_tbf,
safe_div(so,tbf) AS so_per_tbf,
safe_div(wp,bfp) AS wp_per_bfp,
safe_div(so,bb) AS so_per_bb
INTO pitching_sfa
FROM pitching_swa;

\copy pitching_sfa TO '~/baseball-preds/pitching_agg.csv' WITH CSV HEADER DELIMITER ',';
