
DROP TABLE IF EXISTS bw_diag;

SELECT R.player_id, COUNT(DISTINCT R.year)
INTO bw_diag
FROM batting_sy R, batting_war W
WHERE R.player_id = W.player_id AND R.year = W.year
GROUP BY R.player_id;

DROP TABLE IF EXISTS bw_diff;

SELECT A.*, total_years - war_years AS diff
INTO bw_diff
FROM (
SELECT A.player_id, A.count AS total_years, COALESCE(D.count,0) AS war_years
FROM (
SELECT player_id, COUNT(*)
FROM batting_sy
GROUP BY player_id
) AS A
LEFT JOIN bw_diag D
ON A.player_id = D.player_id
) AS A
WHERE total_years != war_years;

