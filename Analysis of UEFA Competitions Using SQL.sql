CREATE TABLE Goals (
    GOAL_ID VARCHAR PRIMARY KEY,
    MATCH_ID VARCHAR,
    PID VARCHAR,
    DURATION INTEGER,
    ASSIST VARCHAR,
    GOAL_DESC VARCHAR
);
COPY Goals FROM 'A:\Cuvette\SQL_resource\UEFA\goals.csv' CSV HEADER;
select * from goals;


CREATE TABLE Matches (
    MATCH_ID VARCHAR PRIMARY KEY,
    SEASON VARCHAR,
    DATE DATE,
    HOME_TEAM VARCHAR,
    AWAY_TEAM VARCHAR,
    STADIUM VARCHAR,
    HOME_TEAM_SCORE INTEGER,
    AWAY_TEAM_SCORE INTEGER,
    PENALTY_SHOOT_OUT INTEGER,
    ATTENDANCE INTEGER
);
COPY Matches FROM 'A:\Cuvette\SQL_resource\UEFA\Matches.csv' CSV HEADER;
select * from Matches;


CREATE TABLE Players (
    PLAYER_ID VARCHAR PRIMARY KEY,
    FIRST_NAME VARCHAR,
    LAST_NAME VARCHAR,
    NATIONALITY VARCHAR,
    DOB DATE,
    TEAM VARCHAR,
    JERSEY_NUMBER FLOAT,
    POSITION VARCHAR,
    HEIGHT FLOAT,
    WEIGHT FLOAT,
    FOOT VARCHAR
);
COPY Players FROM 'A:\Cuvette\SQL_resource\UEFA\Players.csv' CSV HEADER;
select * from Players;


CREATE TABLE Teams (
    TEAM_NAME VARCHAR PRIMARY KEY,
    COUNTRY VARCHAR,
    HOME_STADIUM VARCHAR
);
COPY Teams FROM 'A:\Cuvette\SQL_resource\UEFA\Teams.csv' CSV HEADER;
select * from Teams;


CREATE TABLE Stadiums (
    NAME VARCHAR ,
    CITY VARCHAR,
    COUNTRY VARCHAR,
    CAPACITY INTEGER
);

COPY Stadiums FROM 'A:\Cuvette\SQL_resource\UEFA\Stadiums.csv' CSV HEADER;
select * from Stadiums;

--1)Count the Total Number of Teams
select count(distinct(team_name)) as total_number_of_team from teams ; 
 
--2)Find the Number of Teams per Country
select country, count(distinct(team_name)) as number_of_teams_per_country
from Teams group by country;

--3)Calculate the Average Team Name Length
select avg(length(team_name)) as Avg_team_name_lenght from teams ;

--4)Calculate the Average Stadium Capacity in Each Country round it off and sort by the total stadiums in the country.
select round(avg(capacity)) as avg_capacity , country , count(*) as total_stadium from stadiums 
group by country order by total_stadium desc ;

--5)Calculate the Total Goals Scored.
select count(*) as total_goals_scored from goals;

--6)Find the total teams that have city in their names
select count(*) as total_teams_with_city_name from teams 
	where team_name ilike '%city%';

--7) Use Text Functions to Concatenate the Team's Name and Country
select concat(team_name,' - ',country) as team_name_and_country from teams ;

--8) What is the highest attendance recorded in the dataset, and which match (including home and away teams, and date) 
-- does it correspond to?
select * from matches ;
select attendance ,home_team ,away_team ,date from matches order by attendance desc limit 1;

--9)What is the lowest attendance recorded in the dataset, and which match (including home and away teams, and date) 
-- does it correspond to set the criteria as greater than 1 as some matches had 0 attendance because of covid.
select match_id ,attendance ,home_team ,away_team ,date from matches 
	where attendance > 1
	order by attendance desc limit 1;

--10) Identify the match with the highest total score (sum of home and away team scores) in the dataset.
-- Include the match ID, home and away teams, and the total score.
select match_id , (home_team_score + away_team_score) as total_score , home_team , away_team from matches 
	order by total_score desc limit 1 ;

--11)Find the total goals scored by each team, distinguishing between home and away goals. 
-- Use a CASE WHEN statement to differentiate home and away goals within the subquery
select * from matches ;
select * from teams ;

select  t.team_name as team_name ,
	sum(case when m.home_team = t.team_name 
			then home_team_score else 0 end) as home_goals , 
	sum(case when m.away_team = t.team_name 
			then away_team_score else 0 end) as home_goals 
from teams as t 
left join matches as m  on  t.team_name = m.home_team or t.team_name = m.away_team 
group by t.team_name ;
	
--12) windows function - Rank teams based on their total scored goals (home and away combined) using a window function.
-- In the stadium Old Trafford.
select team_name, 
       rank() over (order by total_goals desc) as rank
	from (
    	select team_name, 
           	sum(case when matches.home_team = team_name 
						then home_team_score else 0 end + 
               	case when matches.away_team = team_name 
						then away_team_score else 0 end) as total_goals
    from teams
    	left join matches 
		on teams.team_name = matches.home_team or teams.team_name = matches.away_team
    where stadium = 'Old Trafford'
    group by team_name
) as ranked_teams;


--13) TOP 5 l players who scored the most goals in Old Trafford, ensuring null values are not included in the result 
-- (especially pertinent for cases where a player might not have scored any goals).
select p.player_id, p.first_name, p.last_name, count(g.goal_id) as total_goals
	from players p
	join goals g on p.player_id = g.pid
	join matches m on g.match_id = m.match_id
	where m.stadium = 'Old Trafford'
	group by p.player_id, p.first_name, p.last_name
		order by total_goals desc
		limit 5;


--14)Write a query to list all players along with the total number of goals they have scored. 
-- Order the results by the number of goals scored in descending order to easily identify the top 6 scorers.
select p.player_id, p.first_name, p.last_name, count(g.goal_id) as total_goals
	from players p
	left join goals g on p.player_id = g.pid
	group by p.player_id, p.first_name, p.last_name
	order by total_goals desc
		limit 6;

--15)Identify the Top Scorer for Each Team - Find the player from each team who has scored 
-- the most goals in all matches combined. This question requires joining the Players, Goals, and 
-- possibly the Matches tables, and then using a subquery to aggregate goals by players and teams.
select t.team_name, p.player_id, p.first_name, p.last_name, max(p.goals) as goals
	from (
    	select player_id, first_name, last_name, team, count(goal_id) as goals
    	from players
    	left join goals on players.player_id = goals.pid
    	group by player_id, first_name, last_name, team
	) as p
		join teams t on p.team = t.team_name
		group by t.team_name, p.player_id, p.first_name, p.last_name
		order by t.team_name, goals desc;


--16)Find the Total Number of Goals Scored in the Latest Season - Calculate the total number of goals scored in 
-- the latest season available in the dataset. This question involves using a subquery to first identify 
-- the latest season from the Matches table, then summing the goals from the Goals table that occurred in matches 
-- from that season.
select sum(goal_count) as total_goals 
	from (
		select g.goal_id , m.season , count(g.goal_id) as goal_count from goals g
		join matches m on g.match_id = m.match_id
		where m.season = (select max(season) from matches)
		group by g.goal_id , m.season
	) as season_goals ;


--17)Find Matches with Above Average Attendance - Retrieve a list of matches that had an attendance higher than 
-- the average attendance across all matches. This question requires a subquery to calculate the average attendance first, 
-- then use it to filter matches.

-- select avg(attendance) from matches ; 

select * from matches where attendance > (select avg(attendance) from matches) ;

--18)Find the Number of Matches Played Each Month - Count how many matches were played in each month across all seasons. 
-- This question requires extracting the month from the match dates and grouping the results by this value. 
-- as January Feb march
select * from matches order  by extract(month from date);

select extract(month from date) as month , count(*) as matches_played_each_month 
	from matches 
	group by month 
	order by month ;





