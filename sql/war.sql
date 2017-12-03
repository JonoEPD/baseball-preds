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
