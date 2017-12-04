-- scripts to load and merge in WAR y values and
-- handling NA values in WAR by making it text

DROP TABLE IF EXISTS pitching_w;

CREATE TABLE pitching_w (
player_id VARCHAR(50),
year INTEGER,
age INTEGER,
war VARCHAR(50)
);

DROP TABLE IF EXISTS batting_w;

CREATE TABLE batting_w (
player_id VARCHAR(50),
year INTEGER,
age INTEGER,
position VARCHAR(50),
war VARCHAR(50)
);

\copy pitching_w FROM '~/baseball-preds/pitching_war.csv' WITH DELIMITER ',' CSV HEADER;
\copy batting_w FROM '~/baseball-preds/batting_war.csv' WITH DELIMITER ',' CSV HEADER;

-- cast N/A to 0
UPDATE pitching_w SET war = '0' WHERE war = 'NA';
UPDATE batting_w SET war = '0' WHERE war = 'NA';

DROP TABLE IF EXISTS batting_war;
SELECT player_id, year, SUM(war::numeric) AS war
INTO batting_war
FROM batting_w
GROUP BY player_id, year;

DROP TABLE IF EXISTS pitching_war;
SELECT player_id, year, SUM(war::numeric) AS war
INTO pitching_war
FROM pitching_w
GROUP BY player_id, year;

-- compute y values for WAR (7-15th year)
SELECT *, SUM(num_exact) OVER (ORDER BY years ROWS UNBOUNDED PRECEDING) AS num_cum,
ROUND(SUM(num_exact) OVER (ORDER BY years ROWS UNBOUNDED PRECEDING) / 1388,2) AS p_cum
FROM (
SELECT years, COUNT(*) AS num_exact
FROM (
SELECT player_id, COUNT(*) AS years
FROM (
SELECT S.player_id, year - start_year + 1 AS year_num
FROM start_aug S, pitching_war W
WHERE S.player_id = W.player_id AND S.player_id IN (SELECT DISTINCT player_id FROM pitching)
) AS A
WHERE year_num > 6 -- AND year_num < 15
GROUP BY player_id
) AS A
GROUP BY years
) AS A
ORDER BY years
;

