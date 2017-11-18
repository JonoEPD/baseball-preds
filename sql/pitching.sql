DROP TABLE IF EXISTS raw_pitching;

CREATE TABLE raw_pitching (
player_id VARCHAR(50),
year INTEGER,
stint INTEGER,
team_id VARCHAR(50),
league_id VARCHAR(50),
w NUMERIC,
l NUMERIC,
g NUMERIC,
gs NUMERIC,
cg NUMERIC,
sho NUMERIC,
sv NUMERIC,
ipouts NUMERIC,
h NUMERIC,
er NUMERIC,
hr NUMERIC,
bb NUMERIC,
so NUMERIC,
baopp NUMERIC,
era NUMERIC,
ibb NUMERIC,
wp NUMERIC,
hbp NUMERIC,
bk NUMERIC,
bfp NUMERIC,
gf NUMERIC,
r NUMERIC,
sh NUMERIC,
sf NUMERIC,
g_idp NUMERIC
);

COPY raw_pitching FROM '/Users/johollen/baseball-preds/raw_data/pitching.csv'
WITH DELIMITER ',' CSV HEADER;

DROP TABLE IF EXISTS start_pitch;

SELECT player_id, MIN(year) AS start_year, COUNT(DISTINCT year) AS years, SUM(g) AS total_games
INTO start_pitch
FROM raw_pitching
GROUP BY player_id;

-- split atbats by before/after 6 year period
DROP TABLE IF EXISTS start_pitch_aug;

SELECT A.*, B.six_g, B.rest_g
INTO start_pitch_aug
FROM (
SELECT * FROM start_pitch
) AS A
LEFT JOIN
(
SELECT S.player_id,
SUM(g) FILTER (WHERE R.year - 6 < S.start_year) AS six_g,
SUM(g) FILTER (WHERE R.year - 6 >= S.start_year) AS rest_g,
SUM(g) AS total_g
FROM start_pitch S, raw_pitching R
WHERE S.player_id = R.player_id
GROUP BY S.player_id
) AS B
ON A.player_id = B.player_id;

-- filter out players that started before 1970 or had less than 7 years in the league
-- eliminate anyone who didn't have any at bats (pitchers?)
DROP TABLE IF EXISTS pitching;

SELECT R.*
INTO pitching
FROM raw_pitching R, start_pitch_aug S
WHERE R.player_id = S.player_id AND S.start_year >= 1970
AND S.six_g > 1 AND S.rest_g > 1;

-- group records for first 6 years
DROP TABLE IF EXISTS pitching_six;

SELECT R.*
INTO pitching_six
FROM pitching R, start_pitch_aug S
WHERE R.player_id = S.player_id AND R.year - 6 < S.start_year;

-- group records for remaining years
DROP TABLE IF EXISTS pitching_rest;

SELECT R.*
INTO pitching_rest
FROM pitching R, start_pitch S
WHERE R.player_id = S.player_id AND R.year - 6 >= S.start_year;

DROP TABLE IF EXISTS pitching_agg;

SELECT player_id, MIN(year) AS start_year, SUM(g) AS g, SUM(w) AS w, SUM(l) AS l, SUM(gs) AS gs,
SUM(cg) AS cg, SUM(sho) AS sho, SUM(sv) AS sv, SUM(ipouts) AS ipouts, SUM(h) AS h,
SUM(er) AS er, SUM(hr) AS hr, SUM(bb) AS bb, SUM(so) AS so, SUM(ibb) AS ibb, SUM(wp) AS wp,
SUM(hbp) AS hbp, SUM(bk) AS bk, SUM(bfp) AS bfp, SUM(gf) AS gf, SUM(r) AS r, SUM(sh) AS sh,
SUM(sf) AS sf, SUM(bfp - bb - COALESCE(sh,0) - COALESCE(sf,0) - hbp) AS tbf
INTO pitching_agg
FROM pitching_six
GROUP BY player_id
;

DROP TABLE IF EXISTS pitching_features;

SELECT *,
er * 9 / (ipouts / 3) AS era,
h / tbf AS baopp,
-- per game stats
tbf/ g AS tbf_per_g,
gs / g AS starter_ratio,
w / g AS w_per_g,
l / g AS l_per_g,
w / GREATEST((w+l),1) AS p_win,
gf / g AS gf_per_g,
cg / g AS cg_per_g,
sho / g AS sho_per_g,
sv / g AS sv_per_g,
ipouts / g AS ipouts_per_g,
-- per at bat (or tbf) stats
bb / bfp AS bb_per_bfp,
bk / bfp AS bk_per_bfp,
hbp / bfp AS hbp_per_bfp,
hr / tbf AS hr_per_tbf,
so / tbf AS so_per_tbf,
wp / bfp AS wp_per_bfp,
so / bb AS so_per_bb
INTO pitching_features
FROM pitching_agg
;

DROP TABLE IF EXISTS pitching_rest_agg;

SELECT player_id, MAX(year) AS end_year, SUM(g) AS g, SUM(w) AS w, SUM(l) AS l, SUM(gs) AS gs,
SUM(cg) AS cg, SUM(sho) AS sho, SUM(sv) AS sv, SUM(ipouts) AS ipouts, SUM(h) AS h,
SUM(er) AS er, SUM(hr) AS hr, SUM(bb) AS bb, SUM(so) AS so, SUM(ibb) AS ibb, SUM(wp) AS wp,
SUM(hbp) AS hbp, SUM(bk) AS bk, SUM(bfp) AS bfp, SUM(gf) AS gf, SUM(r) AS r, SUM(sh) AS sh,
SUM(sf) AS sf, SUM(bfp - bb - COALESCE(sh,0) - COALESCE(sf,0) - hbp) AS tbf
INTO pitching_rest_agg
FROM pitching_rest
GROUP BY player_id
;

COPY pitching_features TO '/Users/johollen/baseball-preds/pitching_features.csv' WITH CSV HEADER DELIMITER ',';
COPY pitching_agg TO '/Users/johollen/baseball-preds/pitching_6agg.csv' WITH CSV HEADER DELIMITER ',';
COPY pitching TO '/Users/johollen/baseball-preds/pitching.csv' WITH CSV HEADER DELIMITER ',';
COPY pitching_rest_agg TO '/Users/johollen/baseball-preds/pitching_rest_agg.csv' WITH CSV HEADER DELIMITER ',';

