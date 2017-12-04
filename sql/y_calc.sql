-- calculate y values (from WAR)

DROP TABLE IF EXISTS batting_y;
SELECT *
INTO batting_y
FROM (
SELECT S.player_id, year - start_year + 1 AS year_num, war
FROM start_aug S, batting_war W
WHERE S.player_id = W.player_id AND S.player_id IN (SELECT DISTINCT player_id FROM batting)
) AS A
WHERE year_num > 6 AND year_num <= 16;

DROP TABLE IF EXISTS pitching_y;
SELECT *
INTO pitching_y
FROM (
SELECT S.player_id, year - start_year + 1 AS year_num, war
FROM start_aug S, pitching_war W
WHERE S.player_id = W.player_id AND S.player_id IN (SELECT DISTINCT player_id FROM pitching)
) AS A
WHERE year_num > 6 AND year_num <= 15;

\copy batting_y TO '~/baseball-preds/batting_y.csv' WITH CSV HEADER DELIMITER ',';
\copy pitching_y TO '~/baseball-preds/pitching_y.csv' WITH CSV HEADER DELIMITER ',';
