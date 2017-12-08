-- same as batting_stacked but doesn't group by year.

DROP TABLE IF EXISTS batting_sya;
SELECT player_id, COUNT(DISTINCT year_num) AS active_years,
COUNT(*) - COUNT(DISTINCT year_num) AS extra_stints,
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
SUM(h + double + triple*2 + hr*3) AS tb -- total bases
INTO batting_sya
FROM batting_six
GROUP BY player_id;

-- join WAR data
DROP TABLE IF EXISTS batting_swa;
SELECT R.*, W.war
INTO batting_swa
FROM batting_sya R
LEFT JOIN (
SELECT player_id, SUM(COALESCE(war, 0)) AS war
FROM batting_war
GROUP BY player_id
) AS W
ON R.player_id = W.player_id;


-- compute features from the year data
DROP TABLE IF EXISTS batting_sfa;
SELECT *,
safe_div(ab,g) AS ab_per_g,
safe_div(r,ab) AS r_per_ab,
safe_div(h,ab) AS batting_avg,
safe_div(double,ab) AS double_per_ab,
safe_div(triple,ab) AS triple_per_ab,
safe_div(hr,ab) AS hr_per_ab,
safe_div(rbi,ab) AS rbi_per_ab,
safe_div(sb,ob) AS sb_per_ob,
safe_div(cs,ob) AS cs_per_ob,
safe_div(sb,(sb+cs)) AS sb_ratio,
safe_div(bb,pa) AS bb_per_pa,
safe_div(so,ab) AS so_per_ab,
safe_div(tb,ab) AS slg,
safe_div((h + bb + hbp),(ab + bb + sf + hbp)) AS obp,
safe_div(tb * (h+bb),(ab + bb)) AS rc,
safe_div(tb * (h+bb),(ab + bb)^2) AS rc_per_ab,
safe_div((h - hr),(ab - so - hr + sf)) AS babip,
safe_div((tb - h),ab) AS iso,
safe_div((ab + bb),so) AS pa_per_so
INTO batting_sfa
FROM batting_swa
;

\copy batting_sfa TO 'batting_agg.csv' WITH CSV HEADER DELIMITER ',';
