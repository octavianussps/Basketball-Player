# Query 1: Find the player who played second highest games and in which season (over 67 seasons (1950-2017))
SELECT player, games AS numGames, year_  FROM season s 
WHERE s.games < (SELECT max(s.games) FROM season s) 
ORDER BY s.games DESC LIMIT 1;

# Query 2: Find dominantly played as centre and rank them based on their points
SELECT  p.player_names, p.position, s.PTS AS points
FROM player_data p, season s
WHERE p.position LIKE 'c%' AND p.player_names = s.player
ORDER BY points DESC;


# Query 3: Find the players who attended Ivy League
SELECT DISTINCT(p.player), p.collage
FROM player p JOIN season s ON p.player=s.player
WHERE p.collage IN ("Brown University", "Columbia University", "Cornell University", "Dartmouth College", "Harvard University", 
					"University of Pennsylvania", "Princeton University", "Yale University")
ORDER BY p.collage;

# Query 4: Find the players who played on NBA season 1960 who were not from STL
SELECT p.player, s.team AS team, s.PTS AS points
FROM season s INNER JOIN player p ON s.player = p.player
WHERE s.pts BETWEEN 600 AND 820 AND s.year_ = 1960
AND s.team NOT IN("STL")
ORDER BY points DESC;

#Query 5: Top 5 rule breaker in NBA 2017 (Personal Fouls)
SELECT p.player, s.PF AS fouls
FROM player p JOIN season s ON p.player = s.player
WHERE s.year_ = 2017
ORDER BY fouls DESC
LIMIT 5;

# Query 6. Is being taller meaning you higher Efficeiency Rating (PER)
SELECT @h := avg(p.height) as height_avg, 
       @p := avg(s.PER) as PER_avg,  
       @dev := (stddev_samp(p.height) * stddev_samp(s.PER)) as dot_std
FROM player p, season s
WHERE  s.player IN (SELECT p.player FROM player p)
AND p.player = s.player
AND p.height IS NOT NULL and s.PER IS NOT NULL;

SELECT sum( ( p.height - @h ) * (s.PER - @p) ) / ((count(p.height) -1) * @dev) as corr
FROM player p, season s
WHERE  s.player IN (SELECT p.player FROM player p)
AND p.player = s.player
AND p.height IS NOT NULL and s.PER IS NOT NULL;


# Query 7: Find players who had points above average for last 3 decades
SELECT p.player, round(AVG(s.PTS),1) AS avg_points
FROM player p , season s 
WHERE s.player  IN (SELECT p.player FROM player)
GROUP BY p.player
HAVING AVG(PTS) > ALL (SELECT AVG(PTS) FROM season 
						WHERE year_ >1990  AND year_ < 2017
						GROUP BY player)
ORDER BY avg_points DESC;

# Query 8: Jordan's team mate of all time
SELECT DISTINCT(p.player), s.team
FROM player p, season s 
WHERE s.player  IN (SELECT p.player FROM player)
AND p.player NOT LIKE "Michael Jordan%"
AND s.team IN (SELECT s.team FROM player p, season s
				WHERE p.player = s.player AND p.player LIKE "Michael Jordan%")
AND s.year_ IN (SELECT s.year_ FROM player p, season s
				WHERE p.player LIKE "Michael Jordan%" AND p.player = s.player)
ORDER BY s.team;

# Query 9: Average BMI for Point Guard
SELECT s.position AS pos, round(AVG((p.weight)/((p.height/100)*(p.height/100))),1) avg_bmi
FROM season s JOIN player p ON p.player = s.player
WHERE s.position LIKE "%PG%"
GROUP BY pos
ORDER BY avg_bmi DESC;

#Query 10. Top 20 scorer(accumulatively) in 00 (using John Hollinger's formula for Game Score)
SELECT p.player, 
round(sum(s.PTS + (0.4*s.FG) - (0.7*s.FGA) - (0.4*(s.FTA - s.FT)) + (0.7*s.ORB) + (0.3*s.DRB) + s.STL + (0.7*s.AST) + (0.7*s.BLK) - (0.4*s.PF) - s.TOV),1) AS GmScr
FROM player p, season s
WHERE s.player  IN (SELECT p.player FROM player)
AND s.year_ >= 2000 
GROUP BY p.player
ORDER BY GmScr DESC
LIMIT 20;

# Query 11. Correlation between height and Efficiency Rate for each row in whole table (Calculated related from N= 1 until N-1 for each Cor on N)
SET @SumX = 0;
SET @SumY = 0;
SET @Count = 0;
SET @SumX2 = 0;
SET @SumY2 = 0;
SET @SumXY = 0;

SELECT p.height, s.PER,
       @SumX := @SumX + p.height AS SumX,
       @SumY := @SumY + s.PER AS SumY,
       @Count := @Count + 1 AS ct,
       @SumX2 := @SumX2 + p.height*p.height AS SumX2,
       @SumY2 := @SumY2 + s.PER*s.PER AS SumY2,
       @SumXY := @SumXY + p.height*s.PER AS SumXY,
       (@Count*@SumXY-@SumX*@SumY)/(sqrt(@Count*@SumX2-@SumX*@SumX)*sqrt(@Count*@SumY2-@SumY*@SumY)) AS Correlation
FROM player p JOIN season s ON p.player = s.player
WHERE p.height IS NOT NULL AND s.PER IS NOT NULL;