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
SUM(g) FILTER (WHERE R.year - 6 >= S.start_year AND R.year - 10 < S.start_year) AS rest_g,
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

SELECT R.*, R.year - S.start_year AS year_num
INTO pitching_six
FROM pitching R, start_pitch_aug S
WHERE R.player_id = S.player_id AND R.year - 6 < S.start_year;
