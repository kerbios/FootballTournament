use FootballTournament;

GO

-- "Жеребьевка команд" -- генерация таблицы игр комманд друг с другом во всех турнирах.
CREATE PROCEDURE CreateTournamentsGamesTable AS
DECLARE @TeamsCnt int, @TournamentsCnt int;
SET @TeamsCnt = (SELECT COUNT(*) FROM Teams);

IF (@TeamsCnt%2)=0
BEGIN
	SET @TournamentsCnt = (@TeamsCnt*(@TeamsCnt-1)*2)/@TeamsCnt;
	DECLARE @t1 table(ID1 int);
	DECLARE @t2 table(ID2 int);
	DECLARE @GTable table(ID int identity PRIMARY KEY, T1 int, T2 int);

	INSERT @t1
	SELECT ID
	FROM Teams;

	INSERT @t2
	SELECT ID
	FROM Teams;

	INSERT @Gtable
	SELECT ID2, ID1
	FROM @t1, @t2
	WHERE ID1 <> ID2

	DECLARE @i int, @ID_Game int;
	SET @i = 1;
	SET @ID_Game = 1;
	
	WHILE @i <= @TournamentsCnt
	BEGIN
		DECLARE @j int
		SET @j = 1;
		DECLARE @tmp table(ID int);
		WHILE @j <= (@TeamsCnt/2)
		BEGIN
			DECLARE @ID int, @Team1 int, @Team2 int;

			IF @j = 1
			BEGIN
				SELECT TOP(1) @ID = ID, @Team1 = T1, @Team2 = T2 FROM @GTable
				DELETE FROM @GTable WHERE ID = (SELECT Top(1) ID FROM @GTable)
				INSERT INTO @tmp VALUES(@Team1);
				INSERT INTO @tmp VALUES(@Team2);
			END	
			ELSE
			BEGIN
				DECLARE @ST table(T1 int, T2 int, ID int)
				INSERT @ST
				SELECT T1, T2, ID
				FROM @GTable
				WHERE T1 NOT IN (SELECT * FROM @tmp) AND T2 NOT IN (SELECT * FROM @tmp);
				SELECT TOP(1) @ID = ID, @Team1 = T1, @Team2 = T2 FROM @ST;
				DELETE FROM @ST;
				DELETE FROM @GTable WHERE ID = @ID;
				INSERT INTO @tmp VALUES(@Team1);
				INSERT INTO @tmp VALUES(@Team2);
			END

			INSERT INTO Games VALUES(@Team1, @Team2, @i);
			SET @ID_Game = @ID_Game + 1;
			SET @j = @j+1;
		END
	
		DELETE FROM @tmp;
		SET @i = @i+1;
	END
END
	ELSE
		Print 'Невозможно сгенерировать таблицу игр, посколько кол-во команд не чётное!';
		
GO

-- "Проведение чемпионата" -- генерация результатов всех игр чемпионата.
CREATE PROCEDURE FillTournamentsGameTable AS
DECLARE @GamesCnt int, @TournamentsCnt int;
SET @GamesCnt = (SELECT COUNT(*) FROM Games);
IF @GamesCnt>0
BEGIN
	DECLARE @i int;
	SET @i = 1;
	WHILE @i <= @GamesCnt
	BEGIN
		DECLARE @Team1 int, @Team2 int;
		SET @Team1 = (SELECT ID_HomeTeam FROM Games WHERE ID = @i);
		SET @Team2 = (SELECT ID_GuestTeam FROM Games WHERE ID = @i);
		DECLARE @r1 int, @r2 int;
		SET @r1 = -1;
		SET @r2 = -1;
		WHILE @r1 NOT BETWEEN 0 AND 6
		SET @r1 = CAST(RAND() * 100 AS int)
		WHILE @r2 NOT BETWEEN 0 AND 6
		SET @r2 = CAST(RAND() * 100 AS int)

		DECLARE @Score1 int, @Score2 int;
		SET @Score1 = 1;
		SET @Score2 = 1;

		WHILE @Score1 <= @r1
		BEGIN
			DECLARE @attackerCnt int
			SET @attackerCnt = (SELECT Count(*)
			FROM Players
			WHERE ID_Team = @Team1 AND PlayerType = 0);
			
			DECLARE @r3 int;
			SET @r3 = -1;
			
			WHILE @r3 NOT BETWEEN 1 AND @attackerCnt
			SET @r3 = CAST(RAND() * 100 AS int)

			DECLARE @attackerPlayers table(ID int PRIMARY KEY, ID_Player int);
			INSERT @attackerPlayers
			SELECT row_number() over (ORDER BY ID DESC), ID
			FROM Players
			WHERE PlayerType = 0 AND ID_Team = @Team1
			
			DECLARE @ID_attackerPlayer1 int, @ID_attackerTeam1 int;
			SET @ID_attackerPlayer1 = (SELECT ID_Player FROM @attackerPlayers WHERE ID = @r3);
			SET @ID_attackerTeam1 = (SELECT ID_Team FROM Players WHERE ID = @ID_attackerPlayer1);
			INSERT INTO Scores VALUES(@ID_attackerPlayer1, @ID_attackerTeam1, @i);

			DELETE FROM @attackerPlayers;
			SET @Score1 = @Score1 + 1;
		END
		
		WHILE @Score2 <= @r2
		BEGIN
			DECLARE @attackerCnt2 int
			SET @attackerCnt2 = (SELECT Count(*)
			FROM Players
			WHERE ID_Team = @Team2 AND PlayerType = 0);
			
			DECLARE @r4 int;
			SET @r4 = -1;
			
			WHILE @r4 NOT BETWEEN 1 AND @attackerCnt
			SET @r4 = CAST(RAND() * 100 AS int)

			DECLARE @attackerPlayers2 table(ID int PRIMARY KEY, ID_Player int);
			INSERT @attackerPlayers2
			SELECT row_number() over (ORDER BY ID DESC), ID
			FROM Players
			WHERE PlayerType = 0 AND ID_Team = @Team2
			
			DECLARE @ID_attackerPlayer2 int, @ID_attackerTeam2 int;
			SET @ID_attackerPlayer2 = (SELECT ID_Player FROM @attackerPlayers2 WHERE ID = @r4);
			SET @ID_attackerTeam2 = (SELECT ID_Team FROM Players WHERE ID = @ID_attackerPlayer2);
			INSERT INTO Scores VALUES(@ID_attackerPlayer2, @ID_attackerTeam2, @i);
			DELETE FROM @attackerPlayers2;
			SET @Score2 = @Score2 + 1;
		END
		
		SET @i = @i + 1;
	END
END

GO

-- Подсчёт количества забитых/пропущенных командой голов.
CREATE PROCEDURE TeamScore @Team varchar(64) AS

DECLARE @ID_Team int;
SET @ID_Team = (SELECT ID FROM Teams Where Name = @Team);

IF @ID_Team IS NOT NULL
	BEGIN
		DECLARE @AScore int, @DScore int, @ID_GuestTeam int, @ID_HomeTeam int;
		SET @AScore = 0;
		SET @DScore = 0;

		DECLARE @RivalsTable table(ID int identity PRIMARY KEY, ID_RivalTeam int, ID_Game int);

		INSERT @RivalsTable
		SELECT ID_GuestTeam, ID
		FROM Games
		WHERE ID_HomeTeam = @ID_Team
		UNION ALL
		SELECT ID_HomeTeam, ID
		FROM Games
		WHERE ID_GuestTeam = @ID_Team

		SET @DScore = @DScore + (SELECT COUNT(*) FROM Scores s JOIN @RivalsTable r ON s.ID_Team = r.ID_RivalTeam AND s.ID_Game = r.ID_Game);
		SET @AScore = @AScore + (SELECT COUNT(*) FROM Scores WHERE ID_Team = @ID_Team);

		Print 'Команда ' + @Team + ' забила: ' + CAST(@AScore AS varchar(3)) + ' голов за чемпионат';
		Print 'Команда ' + @Team + ' пропустила: ' + CAST(@DScore AS varchar(3)) + ' голов за чемпионат';
	END
ELSE
	Print 'Команда ' + @Team + ' не участвовала в чемпионате!';

GO

-- Лучший бомбардир чемпионата чемпионата.
CREATE PROCEDURE BestAttackerByChampionship AS

with TopAttackers(Name, Age, TName, Score) AS
(
SELECT p.LastName + ' ' + p.FirstName, p.Age, t.Name, (SELECT COUNT(*) FROM Scores WHERE ID_Player = p.ID)
FROM Players p JOIN Teams t ON p.ID_Team = t.ID
WHERE p.PlayerType = 0
)

SELECT top(1) Name AS 'ФИО Футболиста', Age AS 'Возраст', TName AS 'Команда', Score AS 'Кол-во забитых мячей'
FROM TopAttackers
ORDER BY Score DESC

GO

-- Лучший бомбардир команды.
CREATE PROCEDURE BestAttackerByTeam @Team varchar(32) AS

DECLARE @ID_Team int;
SET @ID_Team = (SELECT ID FROM Teams WHERE Name = @Team);

IF @ID_Team IS NOT NULL
BEGIN
	with TopAttackersByTeam(Name, Age, TName, Score) AS
	(
	SELECT p.LastName + ' ' + p.FirstName, p.Age, t.Name, (SELECT COUNT(*) FROM Scores WHERE ID_Player = p.ID)
	FROM Players p JOIN Teams t ON p.ID_Team = t.ID
	WHERE p.PlayerType = 0 AND t.ID = @ID_Team
	)

	SELECT top(1) Name AS 'ФИО Футболиста', Age AS 'Возраст', TName AS 'Команда', Score AS 'Кол-во забитых мячей'
	FROM TopAttackersByTeam
	ORDER BY Score DESC
END
ELSE
	Print 'Команда ' + @Team + ' не участвовала в чемпионате!';
	
GO

-- Лучший голкипер чемпионата.
CREATE PROCEDURE BestDefferByChampionship AS

with GRivalsTable(ID_RivalTeam, ID_Game) AS
(
SELECT ID_GuestTeam, ID
FROM Games
),
HRivalsTable(ID_RivalTeam, ID_Game) AS
(
SELECT ID_HomeTeam, ID
FROM Games
),
TopDeffers(Name, Age, TName, Score) AS
(
	SELECT Players.LastName + ' ' + Players.FirstName, Players.Age, Teams.Name, (SELECT COUNT(*)
	FROM Scores s JOIN(GRivalsTable gr JOIN Games g ON gr.ID_Game = g.ID)ON s.ID_Team = gr.ID_RivalTeam
	WHERE g.ID_GuestTeam = gr.ID_RivalTeam AND g.ID_HomeTeam = Teams.ID AND s.ID_Game = g.ID)
	+
	(SELECT COUNT(*)
	FROM Scores s JOIN(HRivalsTable hr JOIN Games g ON hr.ID_Game = g.ID)ON s.ID_Team = hr.ID_RivalTeam
	WHERE g.ID_HomeTeam = hr.ID_RivalTeam AND g.ID_GuestTeam = Teams.ID AND s.ID_Game = g.ID)
	FROM Teams JOIN Players ON Players.ID_Team = Teams.ID
	WHERE Players.PlayerType = 1
)

SELECT top(1) Name AS 'ФИО голкипера', Age AS 'Возраст', TName AS 'Название команды', Score AS 'Кол-во пропущеных голов'
FROM TopDeffers
ORDER BY Score

GO

-- Определение турнирного положения команды по заданному туру.
CREATE PROCEDURE TeamStatusByTournament @Team varchar(64), @Tournament int AS
IF @Team IN (SELECT Name FROM Teams) AND @Tournament > 0 AND @Tournament <= (((SELECT COUNT(*) FROM Teams)-1)*2)
BEGIN

with TournamentStat(Name, Games, Vins, DeadHeats, Loses, Score) AS
(
SELECT Name, @Tournament,
				(SELECT COUNT(*)
				 FROM Games
				 WHERE ID_HomeTeam = Teams.ID AND Tournament<=@Tournament AND
					(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)
					>
					(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam))
				+
				(SELECT COUNT(*)
				 FROM Games
				 WHERE ID_GuestTeam = Teams.ID AND Tournament<=@Tournament AND
					(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam)
					>
					(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)),
				(SELECT COUNT(*)
				 FROM Games
				 WHERE (ID_HomeTeam = Teams.ID OR ID_GuestTeam = Teams.ID) AND Tournament<=@Tournament AND
				(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)
				=
				(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam)),
				(SELECT COUNT(*)
				 FROM Games
				 WHERE ID_HomeTeam = Teams.ID AND Tournament<=@Tournament AND
					(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)
					<
					(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam))
				+
				(SELECT COUNT(*)
				 FROM Games
				 WHERE ID_GuestTeam = Teams.ID AND Tournament<=@Tournament AND
					(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam)
					<
					(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)),
				(((SELECT COUNT(*)
				   FROM Games
				   WHERE ID_HomeTeam = Teams.ID AND Tournament<=@Tournament AND
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)
						>
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam))
				+
				(SELECT COUNT(*)
				 FROM Games
				 WHERE ID_GuestTeam = Teams.ID AND Tournament<=@Tournament AND
					(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam)
					>
					(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)))*2)
				+
				(SELECT COUNT(*)
				 FROM Games
				 WHERE (ID_HomeTeam = Teams.ID OR ID_GuestTeam = Teams.ID) AND Tournament <= @Tournament AND
					(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)
					=
					(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam))
FROM Teams
)

	SELECT *
	FROM TournamentStat
	WHERE Name = @Team;
END
ELSE
	Print 'Переданые параметры не верны!'
	
GO

-- Результаты команды по каждому туру.
CREATE PROCEDURE TeamStatusByChampionship @Team varchar(64) AS

IF @Team IN (SELECT Name FROM Teams)
BEGIN
	DECLARE @ResultT table(Name varchar(32), Games int, Vins int, DeadHeats int, Loses int, Score int, Tournament int)
	DECLARE @TCnt int, @i int;
	SET @TCnt = ((SELECT COUNT(*) FROM Teams)-1)*2;
	SET @i = 1;
	
	WHILE @i <= @TCnt
	BEGIN
		with TournamentStat(Name, Games, Vins, DeadHeats, Loses, Score) AS
		(
		SELECT Name, @i,
						(SELECT COUNT(*)
						FROM Games
						WHERE ID_HomeTeam = Teams.ID AND Tournament<=@i AND
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)
						>
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam))
						+
						(SELECT COUNT(*)
						FROM Games
						WHERE ID_GuestTeam = Teams.ID AND Tournament<=@i AND
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam)
						>
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)),
						(SELECT COUNT(*)
						FROM Games
						WHERE (ID_HomeTeam = Teams.ID OR ID_GuestTeam = Teams.ID) AND Tournament<=@i AND
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)
						=
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam)),
						(SELECT COUNT(*)
						FROM Games
						WHERE ID_HomeTeam = Teams.ID AND Tournament<=@i AND
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)
						<
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam))
						+
						(SELECT COUNT(*)
						FROM Games
						WHERE ID_GuestTeam = Teams.ID AND Tournament<=@i AND
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam)
						<
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)),
						(((SELECT COUNT(*)
						FROM Games
						WHERE ID_HomeTeam = Teams.ID AND Tournament<=@i AND
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)
						>
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam))
						+
						(SELECT COUNT(*)
						FROM Games
						WHERE ID_GuestTeam = Teams.ID AND Tournament<=@i AND
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam)
						>
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)))*2)
						+
						(SELECT COUNT(*)
						FROM Games
						WHERE (ID_HomeTeam = Teams.ID OR ID_GuestTeam = Teams.ID) AND Tournament <= @i AND
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)
						=
						(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam))

		FROM Teams
		)

		INSERT @ResultT
		SELECT Name, Games, Vins, DeadHeats, Loses, Score, @i
		FROM TournamentStat
		WHERE Name = @Team
		SET @i = @i + 1;
	END

	SELECT Name AS 'Название команды', Games AS 'Игр', Vins AS 'Побед', DeadHeats AS 'Ничьих', Loses AS 'Проигрышей', Score AS 'Очки', Tournament AS 'Тур'
	FROM @ResultT
END
ELSE
	Print 'Переданые параметры не верны!'
	
GO
	
-- "Турнирный путь" чемпиона.
CREATE PROCEDURE ChampionWay AS
DECLARE @TCnt int, @ID_CT int;
SET @TCnt = ((SELECT COUNT(*) FROM Teams)-1)*2;
DECLARE @TournamentStat table(ID int, Score int);
INSERT @TournamentStat
SELECT ID, (((SELECT COUNT(*) FROM Games
				WHERE ID_HomeTeam = Teams.ID AND Tournament<=@TCnt AND
				(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)
				> (SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam))
			+
			(SELECT COUNT(*) FROM Games
			 WHERE ID_GuestTeam = Teams.ID AND Tournament <= @TCnt AND
			 (SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam)
			 >(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)))*2)
			+
			(SELECT COUNT(*) FROM Games
			 WHERE (ID_HomeTeam = Teams.ID OR ID_GuestTeam = Teams.ID) AND Tournament <= @TCnt AND
			(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_HomeTeam)
			 =(SELECT COUNT(*) FROM Scores WHERE ID_Game = Games.ID AND ID_Team = ID_GuestTeam))
FROM Teams

SET @ID_CT = (SELECT top(1) ID FROM @TournamentStat ORDER BY Score DESC);

with TeamGoals(IDT, IDG, Cnt) AS
(
SELECT ID_Team, ID_Game, COUNT(*) AS GoalCount
FROM Scores
GROUP BY ID_Team, ID_Game
)
SELECT (SELECT Name FROM Teams WHERE ID = ID_HomeTeam) AS 'Домашняя команда', (SELECT Name FROM Teams WHERE ID = ID_GuestTeam)
		AS 'Гостевая команда', CAST(isnull((SELECT Cnt FROM TeamGoals WHERE IDG = Games.ID AND IDT = ID_HomeTeam),0) AS varchar(1)) + ':' + CAST(isnull((SELECT Cnt FROM TeamGoals WHERE IDG = Games.ID AND IDT = ID_GuestTeam),0) AS varchar(1))
		AS 'Счёт', Tournament AS 'Тур'
FROM Games
WHERE ID_HomeTeam = @ID_CT OR ID_GuestTeam = @ID_CT

GO

-- Команда ,которая забила наибольшее количество голов.
CREATE PROCEDURE TopAttackersTeams AS

with TopAttackersTeamsTable(Name, Score) AS
(
SELECT Name, (SELECT COUNT(*) FROM Scores WHERE ID_Team = Teams.ID)
FROM Teams
)

SELECT top(1) Name AS 'Название команды', Score AS 'Кол-во забитых голов'
FROM TopAttackersTeamsTable
ORDER BY Score DESC