use FootballTournament;

-- "Жеребьевка команд" -- генерация таблицы игр комманд друг с другом во всех турнирах.
exec CreateTournamentsGamesTable;

-- "Проведение чемпионата" -- генерация результатов всех игр чемпионата.
exec FillTournamentsGameTable;

-- Подсчёт количества забитых/пропущенных командой голов.
--exec TeamScore 'Арсенал К'

-- Лучший бомбардир чемпионата чемпионата.
--exec BestAttackerByChampionship

-- Лучший бомбардир команды.
--exec BestAttackerByTeam 'Шахтёр'

-- Лучший голкипер чемпионата.
--exec BestDefferByChampionship

-- Определение турнирного положения команды по заданному туру.
--exec TeamStatusByTournament 'Шахтёр', 30

-- Результаты команды по каждому туру.
--exec TeamStatusByChampionship 'Ильичёвец'

-- "Турнирный путь" чемпиона.
--exec ChampionWay

-- Команда ,которая забила наибольшее количество голов.
--exec TopAttackersTeams