DROP TABLE IF EXISTS raw_batting;

CREATE TABLE raw_batting (
player_id VARCHAR(50),
year INTEGER,
stint INTEGER,
team_id VARCHAR(50),
league_id VARCHAR(50),
g INTEGER,
ab NUMERIC,
r NUMERIC,
h NUMERIC,
double NUMERIC,
triple NUMERIC,
hr NUMERIC,
rbi NUMERIC,
sb NUMERIC,
cs NUMERIC,
bb NUMERIC,
so NUMERIC,
ibb NUMERIC,
hbp NUMERIC,
sh NUMERIC,
sf NUMERIC,
g_idp NUMERIC
);

COPY raw_batting FROM '/Users/johollen/baseball-preds/raw_data/batting.csv' DELIMITER ',' CSV HEADER
;

-- figure out starting year / number of years / number of at bats for player
DROP TABLE IF EXISTS start_years;

SELECT player_id, MIN(year) AS start_year, COUNT(DISTINCT year) AS years, SUM(ab) AS at_bats
INTO start_years
FROM raw_batting
GROUP BY player_id
;

-- split atbats by before/after 6 year period
DROP TABLE IF EXISTS start_aug;

SELECT A.*, B.six_ab, B.rest_ab
INTO start_aug
FROM (
SELECT * FROM start_years
) AS A
LEFT JOIN
(
SELECT S.player_id,
SUM(ab) FILTER (WHERE R.year - 6 < S.start_year) AS six_ab,
SUM(ab) FILTER (WHERE R.year - 6 >= S.start_year AND R.year - 10 < S.start_year) AS rest_ab
FROM start_years S, raw_batting R
WHERE S.player_id = R.player_id
GROUP BY S.player_id
) AS B
ON A.player_id = B.player_id;

-- filter out players that started before 1970 or had less than 7 years in the league
-- eliminate anyone who didn't have any at bats (pitchers?)
DROP TABLE IF EXISTS batting;

SELECT R.*
INTO batting
FROM raw_batting R, start_aug S
WHERE R.player_id = S.player_id AND S.start_year >= 1970
AND S.six_ab > 1 AND S.rest_ab > 1
AND R.player_id NOT IN (SELECT DISTINCT player_id FROM pitching);

-- group records for first 6 years
DROP TABLE IF EXISTS batting_six;

SELECT R.*, R.year - S.start_year AS year_num, 
INTO batting_six
FROM batting R, start_aug S
WHERE R.player_id = S.player_id AND R.year - 6 < S.start_year;

-- group records for remaining years
DROP TABLE IF EXISTS batting_rest;

SELECT R.*
INTO batting_rest
FROM batting R, start_years S
WHERE R.player_id = S.player_id AND R.year - 6 >= S.start_year
AND R.year - 10 < S.start_year; -- only look at next 4 years

DROP TABLE IF EXISTS batting_agg;

SELECT player_id, MIN(year) AS start_year, SUM(g) AS g, SUM(ab) AS AB, SUM(r) AS r,
SUM(h) AS h, SUM(double) AS double,
SUM(triple) AS triple, SUM(hr) AS hr, SUM(rbi) AS rbi, SUM(sb) AS sb, SUM(cs) AS cs, SUM(bb) AS bb,
SUM(so) AS so, SUM(ibb) AS ibb, SUM(hbp) AS hbp, SUM(sh) AS sh, SUM(sf) AS sf, sum(g_idp) AS g_idp
INTO batting_agg
FROM batting_six
GROUP BY player_id
;

DROP TABLE IF EXISTS batting_features;

SELECT *,
-- simple per at bat averages
ab / g AS ab_per_g, r / ab AS r_per_ab, h / ab AS batting_avg, double / ab AS double_per_ab,
triple / ab AS triple_per_ab, hr / ab AS hr_per_ab, rbi / ab AS rbi_per_ab, sb / ab AS sb_per_ab,
cs / ab AS cs_per_ab, bb / ab AS bb_per_ab, so / ab AS so_per_ab, ibb / ab AS ibb_per_ab,
-- composite stats
(h + double + triple*2 + hr*3) / ab AS slg,
(h + bb + hbp) / (ab + bb + sf + hbp) AS obp,
(h + double + triple*2 + hr*3) * (h + bb) / (ab + bb) AS rc,
(h + double + triple*2 + hr*3) * (h + bb) / (ab + bb)^2 AS rc_per_ab,
(h - hr) / GREATEST(ab - so - hr + sf,1) AS babip,
(double + triple*2 + hr*3) / ab AS iso,
(ab + bb) / GREATEST(so,1) AS pa_per_so

INTO batting_features
FROM batting_agg
;

DROP TABLE IF EXISTS batting_rest_agg;

SELECT player_id, MAX(year) AS end_year, SUM(g) AS g, SUM(ab) AS AB, SUM(r) AS r,
SUM(h) AS h, SUM(double) AS double,
SUM(triple) AS triple, SUM(hr) AS hr, SUM(rbi) AS rbi, SUM(sb) AS sb, SUM(cs) AS cs, SUM(bb) AS bb,
SUM(so) AS so, SUM(ibb) AS ibb, SUM(hbp) AS hbp, SUM(sh) AS sh, SUM(sf) AS sf, sum(g_idp) AS g_idp
INTO batting_rest_agg
FROM batting_rest
GROUP BY player_id
;

COPY (

SELECT player_id,
(h + double + triple*2 + hr*3) * (h + bb) / (ab + bb)^2 AS rc_per_ab
FROM batting_rest_agg
)
TO '/Users/johollen/baseball-preds/yvals_avg_rc.csv' WITH CSV HEADER DELIMITER ',';

COPY batting_features TO '/Users/johollen/baseball-preds/features.csv' WITH CSV HEADER DELIMITER ',';
COPY batting_agg TO '/Users/johollen/baseball-preds/batting_6agg.csv' WITH CSV HEADER DELIMITER ',';
COPY batting TO '/Users/johollen/baseball-preds/batting.csv' WITH CSV HEADER DELIMITER ',';
COPY batting_rest_agg TO '/Users/johollen/baseball-preds/batting_rest_agg.csv' WITH CSV HEADER DELIMITER ',';
