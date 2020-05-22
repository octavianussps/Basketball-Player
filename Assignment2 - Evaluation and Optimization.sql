###################################################################################################################
# Optimization 1: Adding Integrity Constraint for each tables and columns used (accordingly) on this assignment----
# Unique Constraint------------------------------------------------------------------------------------------------
ALTER TABLE player
ADD UNIQUE(player);
# Not Null Constraints---------------------------------------------------------------------------------------------
ALTER TABLE player
MODIFY player VARCHAR(45) NOT NULL;
ALTER TABLE player
MODIFY height INT NOT NULL;
ALTER TABLE season
MODIFY player VARCHAR(45) NOT NULL;
ALTER TABLE season
MODIFY PER DECIMAL NOT NULL;
#------------------------------------------------------------------------------------------------------------------
###################################################################################################################
# Optimization 2: Adding Indices to every columns used on this particular assignment
# Unique Indexes--------------------------------------------------------------------------------------------------
CREATE UNIQUE INDEX player_idx
ON player(player);
# Regular Index---------------------------------------------------------------------------------------------------
CREATE INDEX player_h
ON player(height);
CREATE INDEX season_idx
ON season(player, PER, PTS, team, year_, FG, FGA, FTA, FT, ORB, DRB, STL, AST, BLK, PF, TOV);
#-------------------------------------------------------------------------------------------------------------------
####################################################################################################################
# Optimization 3: Rewriting SQL Queries without changing the meaning------------------------------------------------
# Query 1. Is being taller meaning you higher Efficeiency Rating (PER)
# Declare some useful variables----------------------------------------------------------------------------------
SELECT @ah := avg(p.height) as height_avg, 
       @ap := avg(s.PER) as PER_avg,  
       @dev := (stddev_samp(p.height) * stddev_samp(s.PER)) as dot_std
FROM player p, season s
WHERE  s.player IN (SELECT p.player FROM player p)
AND p.player = s.player
AND p.height IS NOT NULL and s.PER IS NOT NULL;

SELECT sum( ( p.height - @ah ) * (s.PER - @ap) ) / ((count(p.height) -1) * @dev) as corr_h_PER
FROM player p, season s
WHERE  s.player IN (SELECT p.player FROM player p)
AND p.player = s.player
AND p.height IS NOT NULL and s.PER IS NOT NULL;

##### Optimized Query -------------------------------------------------------------------------------------------------
SELECT sum( ( p.height - @ah ) * (s.PER - @ap) ) / ((count(p.height) -1) * @dev) as corr_h_PER
FROM player p JOIN season s ON p.player = s.player
WHERE p.height IS NOT NULL AND s.PER IS NOT NULL;
#-----------------------------------------------------------------------------------------------------------------------
# Query 2: Find players who had points above average for last 3 decades
SELECT p.player, round(AVG(s.PTS),1) AS avg_points
FROM player p , season s 
WHERE s.player  IN (SELECT p.player FROM player)
GROUP BY p.player
HAVING AVG(PTS) > ALL (SELECT AVG(PTS) FROM season 
						WHERE year_ >1990  AND year_ < 2020
						GROUP BY player)
ORDER BY avg_points DESC;

##### Optimized Query -------------------------------------------------------------------------------------------------
SELECT p.player, round(AVG(s.PTS),1) AS avg_points
FROM player p  JOIN season s ON p.player = s.player
GROUP BY p.player
HAVING AVG(PTS) > ALL (SELECT AVG(PTS) FROM season 
						WHERE year_ >1990  AND year_ < 2020
						GROUP BY player)
ORDER BY avg_points DESC;
#---------------------------------------------------------------------------------------------------------------------
# Query 3: Jordan's team mate of all time
SELECT DISTINCT(p.player), s.team
FROM player p, season s 
WHERE s.player  IN (SELECT p.player FROM player)
AND p.player NOT LIKE "Michael Jordan%"
AND s.team IN (SELECT s.team FROM player p, season s
				WHERE p.player = s.player AND p.player LIKE "Michael Jordan%")
AND s.year_ IN (SELECT s.year_ FROM player p, season s
				WHERE p.player LIKE "Michael Jordan%" AND p.player = s.player)
ORDER BY s.team;


# Optimized Query------------------------------------------------------------------
SELECT DISTINCT(p.player), s.team
FROM player p  JOIN season s ON p.player = s.player
AND p.player NOT LIKE "Michael Jordan%"
AND s.team IN (SELECT s.team FROM player p, season s
				WHERE p.player = s.player AND p.player LIKE "Michael Jordan%")
AND s.year_ IN (SELECT s.year_ FROM player p, season s
				WHERE p.player LIKE "Michael Jordan%" AND p.player = s.player)
ORDER BY s.team;

#Query 4. Top 20 scorer(accumulatively) in 00 (using John Hollinger's formula for Game Score)
SELECT p.player, 
round(sum(s.PTS + (0.4*s.FG) - (0.7*s.FGA) - (0.4*(s.FTA - s.FT)) + (0.7*s.ORB) + (0.3*s.DRB) + s.STL + (0.7*s.AST) + (0.7*s.BLK) - (0.4*s.PF) - s.TOV),1) AS GmScr
FROM player p, season s
WHERE s.player  IN (SELECT p.player FROM player)
AND s.year_ >= 2000 
GROUP BY p.player
ORDER BY GmScr DESC
LIMIT 20;
# Optimized Query------------------------------------------------------------------------------------------------
SELECT p.player, 
round(sum(s.PTS + (0.4*s.FG) - (0.7*s.FGA) - (0.4*(s.FTA - s.FT)) + (0.7*s.ORB) + (0.3*s.DRB) + s.STL + (0.7*s.AST) + (0.7*s.BLK) - (0.4*s.PF) - s.TOV),1) AS GmScr
FROM player p JOIN season s ON p.player = s.player
WHERE s.year_ >= 2000 
GROUP BY p.player
ORDER BY GmScr DESC
LIMIT 20;
####################################################################################################################
# Optimization 4: Adding Views--------------------------------------------------------------------------------------
# For Query 2-------------------------------------------------------------------------------------------------------
CREATE VIEW a_pts(ap) AS
SELECT AVG(PTS) FROM season 
WHERE year_ >1990  AND year_ < 2020
GROUP BY player;

SELECT p.player, round(AVG(s.PTS),1) AS avg_points
FROM player p  JOIN season s ON p.player = s.player
GROUP BY p.player
HAVING AVG(PTS) > ALL (SELECT * FROM a_pts)
ORDER BY avg_points DESC;
# For Query 3.------------------------------------------------------------------------------------------------------
CREATE VIEW team(team) AS
SELECT s.team 
FROM player p, season s
WHERE p.player = s.player AND p.player LIKE "Michael Jordan%";

CREATE VIEW years(years) AS
SELECT s.year_ 
FROM player p, season s
WHERE p.player LIKE "Michael Jordan%" AND p.player = s.player;

SELECT DISTINCT(p.player), s.team
FROM player p, season s 
WHERE s.player  IN (SELECT p.player FROM player)
AND p.player NOT LIKE "Michael Jordan%"
AND s.team IN (SELECT * FROM team)
AND s.year_ IN (SELECT * FROM years)
ORDER BY s.team;
# For Query 4.------------------------------------------------------------------------------------------------------
CREATE VIEW GameScores (player, score, year_) AS
SELECT player, cast((PTS + (0.4*FG) - (0.7*FGA) - (0.4*(FTA - FT)) + (0.7*ORB) + (0.3*DRB) + STL + (0.7*AST) + (0.7*BLK) - (0.4*PF) - TOV) AS FLOAT) AS score, year_
FROM season;

SELECT p.player, round(sum(g.score),1) AS score
FROM player p JOIN GameScores g ON p.player = g.player
WHERE g.year_ >= 2000 
GROUP BY p.player
ORDER BY score DESC
LIMIT 20;