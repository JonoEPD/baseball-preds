-- SQL to stack up batting features for a player's individual years

-- group stints for players' first 6 years
-- mostly copied from batting_relative
DROP TABLE IF EXISTS batting_sy;
SELECT player_id, MAX(year_num) AS year_num,
year,
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
INTO batting_sy
FROM batting_six
GROUP BY player_id, year;

-- join WAR data
DROP TABLE IF EXISTS batting_sw;
SELECT R.*, COALESCE(W.war, 0) AS war
INTO batting_sw
FROM batting_sy R
LEFT JOIN batting_war W
ON R.player_id = W.player_id AND R.year = W.year;


-- "safe" numeric div function -- outputs -1 to flag "divide by 0". optional arg 'p' is 'precision'

CREATE OR REPLACE FUNCTION safe_div(num numeric, denom numeric, p integer default 8) RETURNS numeric AS $$
SELECT CASE WHEN denom = 0 THEN -1 ELSE ROUND(num/denom,p) END
$$ LANGUAGE SQL
;

-- compute features from the year data
DROP TABLE IF EXISTS batting_sf;
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
INTO batting_sf
FROM batting_sw
;

\copy batting_sf TO 'batting.csv' WITH CSV HEADER DELIMITER ',';
