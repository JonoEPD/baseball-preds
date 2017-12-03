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

SELECT R.*, R.year - S.start_year AS year_num
INTO batting_six
FROM batting R, start_aug S
WHERE R.player_id = S.player_id AND R.year - 6 < S.start_year;
