use FootballTournament;

GO

CREATE TABLE Trainers (
ID int identity PRIMARY KEY,
FirstName varchar(32),
LastName varchar(32)
);

CREATE TABLE Stadions (
ID int identity PRIMARY KEY,
Name varchar(64)
);

CREATE TABLE Teams (
ID int identity PRIMARY KEY,
Name varchar(64),
ID_Trainer int FOREIGN KEY REFERENCES Trainers,
ID_Stadion int FOREIGN KEY REFERENCES Stadions
);

CREATE TABLE Players (
ID int identity PRIMARY KEY,
FirstName varchar(32),
LastName varchar(32),
Age int,
PlayerType bit,
ID_Team int
);

CREATE TABLE Games (
ID int identity PRIMARY KEY,
ID_HomeTeam int FOREIGN KEY REFERENCES Teams,
ID_GuestTeam int FOREIGN KEY REFERENCES Teams,
Tournament int
);

CREATE TABLE Scores (
ID int identity PRIMARY KEY,
ID_Player int FOREIGN KEY REFERENCES Players,
ID_Team int FOREIGN KEY REFERENCES Teams,
ID_Game int FOREIGN KEY REFERENCES Games
);