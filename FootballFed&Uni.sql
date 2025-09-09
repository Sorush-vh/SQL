DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

CREATE TYPE professionalism_level AS ENUM (
    'semi_pro',
    'professional',
    'elite'
);

CREATE TYPE staff_role AS ENUM (
    'Head Coach',
    'Assistant Coach',
    'Fitness Coach',
    'Goalkeeping Coach',
    'Team Doctor',
    'Physiotherapist',
    'Analyst'
);


create table federation(
    name TEXT primary key,
    foundation_date date
);

create table league(
    name TEXT primary key,
    level professionalism_level,
    federation_name TEXT references federation(name) on delete restrict
);

drop table  league_season;
create table league_season(
    starting_date date,
    ending_date date,
    league_name TEXT references league(name) on delete cascade,
    primary key (starting_date, ending_date, league_name)
);

drop table team;
create table team(
    name TEXT,
    team_id CHAR(6) CHECK (team_id ~ '^\d{6}$') primary key,
    foundation_date date,
    city TEXT,
    country TEXT,
    current_league TEXT references league(name) on delete set null,
    starting_date date,
    ending_date date,
    current_league_score int,
    foreign key (starting_date, ending_date, current_league) references league_season (starting_date, ending_date, league_name)
    on delete set null
);

drop table person;
create table person(
    id CHAR(10) CHECK (id ~ '^\d{10}$') primary key,
    full_name TEXT,
    address TEXT[],
    join_date date,
    date_of_birth date
);

drop table team_member;
create table team_member(
    personal_id CHAR(10) references person(id) on delete restrict primary key
);

create table team_member_transfers(
    seller_team_id char(6) references team(team_id) on delete restrict not null,
    destination_team_id char(6) references team(team_id) on delete restrict not null,

    member_id char(10) references team_member(personal_id) on delete  cascade not null, --CHECK IF SELLER HAS IT

    season_start date,
    season_end date,
    league_name text,
    foreign key (season_start, season_end, league_name) references league_season(starting_date, ending_date, league_name)
            on delete cascade,

    primary key (seller_team_id, destination_team_id, member_id, season_start, season_end)
);

create table technical_staff(
    staff_id CHAR(6) CHECK (staff_id ~ '^\d{6}$') primary key,
    job staff_role,
    personal_id CHAR(10) references team_member(personal_id) on delete restrict
);

create table player(
    player_id CHAR(6) CHECK (player_id ~ '^\d{6}$') primary key,
    nationality TEXT,
    personal_id CHAR(10) references team_member(personal_id) on delete restrict
);
ALTER TABLE player ADD COLUMN current_team_id CHAR(6) REFERENCES team(team_id);

create table contract(
    member_id CHAR(10) references team_member(personal_id),
    season_start date,
    season_end date,
    league_name TEXT references league(name) on delete restrict,
    team_id CHAR(6) references team(team_id),
    amount int check ( amount > 0 ),
    foreign key (season_start, season_end, league_name) references league_season(starting_date, ending_date, league_name) on delete restrict,
    primary key (member_id, season_start, season_end, league_name)
);

drop table  referee;
create table  referee(
    referee_id CHAR(10) CHECK (referee_id ~ '^\d{10}$') primary key,
    referee_level professionalism_level,
    overall_score int,
    personal_id CHAR(10) references person(id) on delete restrict
);

create table referee_team(
    team_id CHAR(6) CHECK (team_id ~ '^\d{6}$') primary key
);

drop table referee_team_members;
create table referee_team_members(
    referee_id CHAR(10) references referee(referee_id),
    team_id CHAR(6) references referee_team(team_id),
    primary key (referee_id, team_id)
);


drop table stadium;
create table stadium(
    stadium_id CHAR(6) primary key,
    name TEXT,
    city_name TEXT,
    price int check ( price>0  ),
    capacity int check ( capacity > 0 ),
    level professionalism_level
);

create table verified_stadiums(
    stadium_id char(6) references stadium(stadium_id) on delete cascade ,
    federation_name text references federation(name) on delete restrict ,
    primary key (stadium_id, federation_name)
);

drop table football_match;
create table football_match(
    season_start date,
    season_end date,
    league_name text,
    foreign key (season_start,season_end, league_name) references league_season(starting_date, ending_date, league_name)
        on delete cascade,


    match_id char(8) primary key,
    match_date date,

    stadium_id CHAR(6) references stadium(stadium_id),

    host_id CHAR(6) references team(team_id),
    guest_id char(6) references  team(team_id),

    host_score int check ( host_score >= 0 ) default (0),
    guest_score int check ( guest_score >= 0 ) default (0)
);

drop table  match_team_member_infos;
create table match_team_member_infos(
    match_id char(8) references football_match(match_id) on delete cascade ,
    member_id CHAR(10) references team_member(personal_id),
    primary key (match_id, member_id)
);

create table referee_committee(
    committee_id char(6) primary key,

    season_start date,
    season_end date,
    league_name text,
    foreign key (season_start, season_end, league_name) references league_season(starting_date, ending_date, league_name)
            on delete cascade
);

create table committee_members_table(
    comm_id char(6) references referee_committee on delete restrict,
    ref_id CHAR(10) references referee on delete cascade,
    primary key (comm_id, ref_id)
);

create table match_refereeing(
    match_id char(8) references football_match(match_id) on delete cascade primary key,
    ref_team_id CHAR(6) references referee_team(team_id) on delete restrict not null,
    ref_comm_id char(6) references referee_committee(committee_id) on delete restrict
);

CREATE TYPE football_event AS ENUM (
    'goal',
    'own_goal',
    'penalty_goal',
    'missed_penalty',
    'yellow_card',
    'red_card',
    'substitution',
    'offside',
    'corner',
    'foul',
    'free_kick',
    'throw_in',
    'injury'
);

create table event(
    event_id char(6) primary key,
    relating_match_id char(8) references football_match on delete cascade not null,
    relating_player_id char(6) references player(player_id) on delete cascade,
    event_type football_event not null,
    time_of_occurence timestamp,
    description text
);


CREATE TYPE match_stat_type AS ENUM (
    'possession',
    'shots_total',
    'shots_on_target',
    'shots_off_target',
    'goals',
    'fouls_committed',
    'yellow_cards',
    'red_cards',
    'offsides',
    'corners',
    'free_kicks',
    'goal_kicks',
    'saves',
    'passes',
    'pass_accuracy',
    'tackles',
    'interceptions',
    'clearances'
);

create table match_statistics(
    stat_type match_stat_type not null,
    relative_team_id CHAR(6) references team(team_id) on delete cascade not null,
    relative_match_id char(8) references football_match(match_id) on delete cascade not null,
    primary key (stat_type,  relative_team_id, relative_match_id)
);



-- Clear existing data
TRUNCATE TABLE event, match_statistics, match_refereeing, committee_members_table,
referee_committee, match_team_member_infos, football_match, verified_stadiums,
stadium, referee_team_members, referee_team, referee, contract, player,
technical_staff, team_member_transfers, team_member, person, team,
league_season, league, federation CASCADE;
-- Insert a single hardcoded federation
INSERT INTO federation (name, foundation_date)
VALUES ('Global Football Federation', '1950-01-01');

-- Insert 3 hardcoded leagues
INSERT INTO league (name, level, federation_name)
VALUES
    ('League A', 'elite', 'Global Football Federation'),
    ('League B', 'professional', 'Global Football Federation'),
    ('League C', 'semi_pro', 'Global Football Federation');

-- Insert 3 seasons per league
DO $$
DECLARE
    y INTEGER;
    l TEXT;
BEGIN
    FOR y IN 2020..2022 LOOP
        FOR l IN SELECT name FROM league LOOP
            INSERT INTO league_season (starting_date, ending_date, league_name)
            VALUES (
                TO_DATE(y || '-08-01', 'YYYY-MM-DD'),
                TO_DATE((y + 1) || '-05-15', 'YYYY-MM-DD'),
                l
            );
        END LOOP;
    END LOOP;
END $$;

-- Insert 5 teams per league
DO $$
DECLARE
    l TEXT;
    t INTEGER;
    id_seq INTEGER := 0;
BEGIN
    FOR l IN SELECT name FROM league LOOP
        FOR t IN 1..5 LOOP
            INSERT INTO team (
                name, team_id, foundation_date, city, country,
                current_league, starting_date, ending_date, current_league_score
            )
            VALUES (
                l || ' Team ' || t,
                LPAD(id_seq::TEXT, 6, '0'),
                '2000-01-01',
                'City' || id_seq,
                'CountryX',
                l,
                '2022-08-01',
                '2023-05-15',
                0
            );
            id_seq := id_seq + 1;
        END LOOP;
    END LOOP;
END $$;

-- Generate players (80% of total expected players)
-- 3 leagues * 5 teams * 10 players = 150 => 120 with teams, 30 without
DO $$
DECLARE
    player_idx INTEGER := 0;
    team RECORD;
    personal_id TEXT;
BEGIN
    -- Assigned players
    FOR team IN SELECT team_id FROM team LOOP
        FOR i IN 1..10 LOOP
            personal_id := LPAD((player_idx + 1)::TEXT, 10, '0');
            INSERT INTO person (id, full_name, address, join_date, date_of_birth)
            VALUES (personal_id, 'Player ' || personal_id, ARRAY['Street ' || player_idx], '2022-07-01', '2000-01-01');

            INSERT INTO team_member (personal_id) VALUES (personal_id);

            INSERT INTO player (player_id, nationality, personal_id, current_team_id)
            VALUES (
                LPAD(player_idx::TEXT, 6, '0'),
                'CountryX',
                personal_id,
                team.team_id
            );

            player_idx := player_idx + 1;
        END LOOP;
    END LOOP;

    -- Unassigned players
    FOR i IN 1..30 LOOP
        personal_id := LPAD((player_idx + 1)::TEXT, 10, '0');
        INSERT INTO person (id, full_name, address, join_date, date_of_birth)
        VALUES (personal_id, 'Free Player ' || personal_id, ARRAY['Street ' || player_idx], '2022-07-01', '2000-01-01');

        INSERT INTO team_member (personal_id) VALUES (personal_id);

        INSERT INTO player (player_id, nationality, personal_id, current_team_id)
        VALUES (
            LPAD(player_idx::TEXT, 6, '0'),
            'CountryY',
            personal_id,
            NULL
        );

        player_idx := player_idx + 1;
    END LOOP;
END $$;

-- =========================================================
-- Utilities: normal random (Box–Muller) + helper generators
-- =========================================================

-- Normal random with mean/sd, truncated at 0 when converted to goals
-- Volatile because it calls random()
CREATE OR REPLACE FUNCTION normal_rand(mu DOUBLE PRECISION, sigma DOUBLE PRECISION)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql VOLATILE AS $$
DECLARE
    u1 DOUBLE PRECISION := GREATEST(random(), 1e-12);
    u2 DOUBLE PRECISION := random();
    z  DOUBLE PRECISION;
BEGIN
    z := sqrt(-2 * ln(u1)) * cos(2 * pi() * u2);
    RETURN mu + sigma * z;
END $$;

-- Helper to pad to fixed-length numeric CHAR
CREATE OR REPLACE FUNCTION pad6(i BIGINT) RETURNS CHAR(6)
LANGUAGE SQL IMMUTABLE AS $$ SELECT LPAD(i::TEXT, 6, '0')::CHAR(6) $$;

CREATE OR REPLACE FUNCTION pad8(i BIGINT) RETURNS CHAR(8)
LANGUAGE SQL IMMUTABLE AS $$ SELECT LPAD(i::TEXT, 8, '0')::CHAR(8) $$;

CREATE OR REPLACE FUNCTION pad10(i BIGINT) RETURNS CHAR(10)
LANGUAGE SQL IMMUTABLE AS $$ SELECT LPAD(i::TEXT, 10, '0')::CHAR(10) $$;

-- =========================================
-- Stadiums: one per team, verified by the federation
-- =========================================
-- Map each team to a stadium (same id as team_id for simplicity),
-- level based on the team's league level.
INSERT INTO stadium (stadium_id, name, city_name, price, capacity, level)
SELECT
    t.team_id,
    t.name || ' Stadium',
    t.city,
    (500000 + (random()*500000))::INT,       -- > 0
    (15000   + (random()*45000))::INT,       -- > 0
    l.level
FROM team t
JOIN league l ON l.name = t.current_league
ON CONFLICT (stadium_id) DO NOTHING;

-- Verify all stadiums with the (single) federation you inserted earlier
INSERT INTO verified_stadiums (stadium_id, federation_name)
SELECT s.stadium_id, 'Global Football Federation'
FROM stadium s
ON CONFLICT DO NOTHING;

-- =====================================================
-- Team goal-scoring profile: Normal(μ>1, σ≈0.9), stored per team
-- =====================================================
DROP TABLE IF EXISTS team_goal_profile;
CREATE TEMP TABLE team_goal_profile (
    team_id CHAR(6) PRIMARY KEY,
    mu DOUBLE PRECISION NOT NULL,
    sigma DOUBLE PRECISION NOT NULL
);

INSERT INTO team_goal_profile (team_id, mu, sigma)
SELECT t.team_id,
       1.1 + (random() * 1.7) AS mu,  -- μ in (1.1, 2.8) > 1
       0.9 AS sigma
FROM team t;

-- ============================================================
-- Matches for each league season: double round-robin, home & away
-- Scores drawn from truncated normal using team μ, σ
-- Stadium = host's stadium (already created)
-- ============================================================
DO $$
DECLARE
    s RECORD;
    t_host RECORD;
    t_guest RECORD;
    m_id BIGINT := COALESCE((SELECT MAX(match_id)::BIGINT FROM football_match), 0) + 1;
    host_mu DOUBLE PRECISION;
    guest_mu DOUBLE PRECISION;
    host_goals INT;
    guest_goals INT;
    d_offset INT := 0;
BEGIN
    FOR s IN SELECT * FROM league_season ORDER BY starting_date, league_name LOOP
        -- All teams in this league for this season (based on current_league = s.league_name)
        FOR t_host IN
            SELECT team_id FROM team WHERE current_league = s.league_name ORDER BY team_id
        LOOP
            FOR t_guest IN
                SELECT team_id FROM team
                WHERE current_league = s.league_name AND team_id > t_host.team_id
                ORDER BY team_id
            LOOP
                -- First leg: host = t_host
                SELECT mu INTO host_mu FROM team_goal_profile WHERE team_id = t_host.team_id;
                SELECT mu INTO guest_mu FROM team_goal_profile WHERE team_id = t_guest.team_id;

                host_goals := GREATEST(0, ROUND(normal_rand(host_mu, 0.9)))::INT;
                guest_goals := GREATEST(0, ROUND(normal_rand(guest_mu, 0.9)))::INT;

                INSERT INTO football_match (
                    season_start, season_end, league_name,
                    match_id, match_date, stadium_id,
                    host_id, guest_id, host_score, guest_score
                )
                VALUES (
                    s.starting_date, s.ending_date, s.league_name,
                    pad8(m_id),
                    s.starting_date + (d_offset % 90),  -- spread through season
                    t_host.team_id,                      -- host plays at own stadium
                    t_host.team_id, t_guest.team_id,
                    host_goals, guest_goals
                );
                m_id := m_id + 1;
                d_offset := d_offset + 1;

                -- Second leg: host = t_guest
                host_goals := GREATEST(0, ROUND(normal_rand(guest_mu, 0.9)))::INT;
                guest_goals := GREATEST(0, ROUND(normal_rand(host_mu, 0.9)))::INT;

                INSERT INTO football_match (
                    season_start, season_end, league_name,
                    match_id, match_date, stadium_id,
                    host_id, guest_id, host_score, guest_score
                )
                VALUES (
                    s.starting_date, s.ending_date, s.league_name,
                    pad8(m_id),
                    s.starting_date + (d_offset % 90),
                    t_guest.team_id,
                    t_guest.team_id, t_host.team_id,
                    host_goals, guest_goals
                );
                m_id := m_id + 1;
                d_offset := d_offset + 1;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- =======================================================
-- Non-goal match events (~8 per match on average), player
-- chosen from host/guest rosters only; exclude goal events.
-- =======================================================
DO $$
DECLARE
    m RECORD;
    e_id BIGINT := COALESCE((SELECT MAX(event_id)::BIGINT FROM event), 0) + 1;
    k INT;
    num_events INT;
    chosen_player CHAR(6);
    minute INT;
    et football_event;
BEGIN
    FOR m IN
        SELECT fm.match_id, fm.match_date, fm.host_id, fm.guest_id
        FROM football_match fm
        ORDER BY fm.match_id
    LOOP
        -- Around 8 events: Uniform 5..11 (mean ≈ 8)
        num_events := 5 + FLOOR(random() * 7)::INT;

        FOR k IN 1..num_events LOOP
            -- Random minute 0..90
            minute := FLOOR(random() * 91)::INT;

            -- Random event from the allowed set (exclude goal/own_goal/penalty_goal/missed_penalty)
            SELECT unnest(ARRAY[
                'yellow_card'::football_event,
                'red_card'::football_event,
                'substitution'::football_event,
                'offside'::football_event,
                'corner'::football_event,
                'foul'::football_event,
                'free_kick'::football_event,
                'throw_in'::football_event,
                'injury'::football_event
            ]) ORDER BY random() LIMIT 1 INTO et;

            -- Pick a random player from either host or guest (current_team_id must match one of them)
            SELECT p.player_id
            INTO chosen_player
            FROM player p
            WHERE p.current_team_id IN (m.host_id, m.guest_id)
            ORDER BY random()
            LIMIT 1;

            INSERT INTO event (
                event_id, relating_match_id, relating_player_id,
                event_type, time_of_occurence, description
            )
            VALUES (
                pad6(e_id),
                m.match_id,
                chosen_player,
                et,
                m.match_date + (minute || ' minutes')::interval,
                'Auto-generated non-goal event'
            );
            e_id := e_id + 1;
        END LOOP;
    END LOOP;
END $$;

-- =========================================================
-- Transfers: 20% chance per player per SEASON, within same
-- league; updates player.current_team_id; records transfer
-- in team_member_transfers (FK to league_season).
-- =========================================================
DO $$
DECLARE
    s RECORD;
    p RECORD;
    from_team CHAR(6);
    to_team CHAR(6);
BEGIN
    FOR s IN SELECT * FROM league_season ORDER BY starting_date, league_name LOOP
        -- Snapshot: players whose current team is in this league at season start
        FOR p IN
            SELECT pl.player_id, pl.personal_id, pl.current_team_id
            FROM player pl
            JOIN team tf ON tf.team_id = pl.current_team_id
            WHERE tf.current_league = s.league_name
        LOOP
            IF random() < 0.2 THEN
                -- Choose a different destination team in the same league
                SELECT t.team_id
                INTO to_team
                FROM team t
                WHERE t.current_league = s.league_name
                  AND t.team_id <> p.current_team_id
                ORDER BY random()
                LIMIT 1;

                from_team := p.current_team_id;

                -- Record the transfer in the season
                INSERT INTO team_member_transfers (
                    seller_team_id, destination_team_id, member_id,
                    season_start, season_end, league_name
                )
                VALUES (
                    from_team,
                    to_team,
                    p.personal_id,
                    s.starting_date,
                    s.ending_date,
                    s.league_name
                );

                -- Update player's current team
                UPDATE player
                SET current_team_id = to_team
                WHERE player_id = p.player_id;
            END IF;
        END LOOP;
    END LOOP;
END $$;

-- =========================================================
-- Referees, referee teams, committees, and assignments
-- =========================================================

-- Allocate new person ids after players from Part 1.
-- (Assumes person.id are numeric CHAR(10); cast safely to BIGINT)
DO $$
DECLARE
    max_person BIGINT := COALESCE((SELECT MAX(id)::BIGINT FROM person), 0);
    next_person BIGINT := max_person + 1;
    r_count INT := 0;
    ref_id CHAR(10);
    ref_level professionalism_level;
    ref_overall INT;
    leagues_cnt INT := (SELECT COUNT(*) FROM league);
    per_league_refs INT := 12;  -- create enough referees
    rt BIGINT := 1;             -- referee_team id counter (separate namespace)
    c_id BIGINT := 1;           -- committee id counter
    l RECORD;
    s RECORD;
    r RECORD;
    team_needed INT := 3;       -- number of referee teams per league
BEGIN
    -- Create referees (persons + referee rows)
    FOR l IN SELECT name, level FROM league ORDER BY name LOOP
        FOR r_count IN 1..per_league_refs LOOP
            ref_id := pad10(next_person);
            INSERT INTO person (id, full_name, address, join_date, date_of_birth)
            VALUES (ref_id, l.name || ' Referee ' || r_count, ARRAY['Ref Street '||r_count], CURRENT_DATE, DATE '1985-01-01' + (random()*5000)::INT);

            -- Randomize level around league's level (kept simple here: use league's level)
            ref_level := l.level;
            ref_overall := 60 + (random()*40)::INT;

            INSERT INTO referee (referee_id, referee_level, overall_score, personal_id)
            VALUES (ref_id, ref_level, ref_overall, ref_id);

            next_person := next_person + 1;
        END LOOP;
    END LOOP;

    -- Create referee teams per league and assign members
    -- (team_id here is for referee_team, independent of club team ids)
    FOR l IN SELECT name FROM league ORDER BY name LOOP
        FOR r_count IN 1..team_needed LOOP
            INSERT INTO referee_team (team_id) VALUES (pad6(rt));
            -- put 3 randomly chosen referees from this league into the team
            INSERT INTO referee_team_members (referee_id, team_id)
            SELECT rf.referee_id, pad6(rt)
            FROM referee rf
            JOIN person p ON p.id = rf.personal_id
            WHERE p.full_name LIKE l.name || ' Referee%'
            ORDER BY random()
            LIMIT 3;

            rt := rt + 1;
        END LOOP;
    END LOOP;

    -- Create one committee per league-season and assign 5 refs to each
    FOR s IN SELECT * FROM league_season ORDER BY starting_date, league_name LOOP
        INSERT INTO referee_committee (committee_id, season_start, season_end, league_name)
        VALUES (pad6(c_id), s.starting_date, s.ending_date, s.league_name);

        INSERT INTO committee_members_table (comm_id, ref_id)
        SELECT pad6(c_id), rf.referee_id
        FROM referee rf
        JOIN person p ON p.id = rf.personal_id
        WHERE p.full_name LIKE s.league_name || ' Referee%'
        ORDER BY random()
        LIMIT 5;

        c_id := c_id + 1;
    END LOOP;
END $$;

-- Assign refereeing for each match: pick a referee team from the same league,
-- and the committee created for that league-season
DO $$
DECLARE
    m RECORD;
    comm_id CHAR(6);
    refteam CHAR(6);
BEGIN
    FOR m IN
        SELECT fm.season_start, fm.season_end, fm.league_name, fm.match_id
        FROM football_match fm
        ORDER BY fm.match_id
    LOOP
        -- committee for this league-season
        SELECT rc.committee_id INTO comm_id
        FROM referee_committee rc
        WHERE rc.season_start = m.season_start
          AND rc.season_end   = m.season_end
          AND rc.league_name  = m.league_name;

        -- pick a referee team that was created for this league (by name pattern)
        -- We don't have league linkage on referee_team, so we infer via members' names
        SELECT rtm.team_id
        INTO refteam
        FROM referee_team_members rtm
        JOIN referee rf ON rf.referee_id = rtm.referee_id
        JOIN person  p  ON p.id = rf.personal_id
        WHERE p.full_name LIKE m.league_name || ' Referee%'
        ORDER BY random()
        LIMIT 1;

        INSERT INTO match_refereeing (match_id, ref_team_id, ref_comm_id)
        VALUES (m.match_id, refteam, comm_id)
        ON CONFLICT (match_id) DO NOTHING;
    END LOOP;
END $$;

-- =========================================================
-- Technical staff: create per team, 3 roles per team
-- (Head Coach, Assistant Coach, Analyst)
-- =========================================================
DO $$
DECLARE
    next_person BIGINT := COALESCE((SELECT MAX(id)::BIGINT FROM person), 0) + 1;
    next_staff  BIGINT := 1;
    t RECORD;
    role staff_role;
    roles staff_role[] := ARRAY['Head Coach'::staff_role, 'Assistant Coach'::staff_role, 'Analyst'::staff_role];
    r INT;
    personal CHAR(10);
BEGIN
    FOR t IN SELECT team_id, name FROM team ORDER BY team_id LOOP
        FOR r IN 1..array_length(roles,1) LOOP
            personal := pad10(next_person);

            INSERT INTO person (id, full_name, address, join_date, date_of_birth)
            VALUES (personal, t.name || ' ' || roles[r] || ' ' || pad6(next_staff), ARRAY['Staff Street'], CURRENT_DATE, DATE '1975-01-01' + (random()*8000)::INT);

            INSERT INTO team_member (personal_id) VALUES (personal);

            INSERT INTO technical_staff (staff_id, job, personal_id)
            VALUES (pad6(next_staff), roles[r], personal);

            -- Optionally, create a contract tying staff to the team's current league-season
            -- (Comment out if you don't want contracts)
            INSERT INTO contract (member_id, season_start, season_end, league_name, team_id, amount)
            SELECT personal, ls.starting_date, ls.ending_date, ls.league_name, t.team_id, (50000 + (random()*50000))::INT
            FROM league_season ls
            WHERE ls.league_name = (SELECT current_league FROM team WHERE team_id = t.team_id)
              AND ls.starting_date = DATE '2022-08-01'   -- matches team.starting_date from Part 1
              AND ls.ending_date   = DATE '2023-05-15'   -- matches team.ending_date from Part 1
            ON CONFLICT DO NOTHING;

            next_person := next_person + 1;
            next_staff  := next_staff  + 1;
        END LOOP;
    END LOOP;
END $$;

-- =========================================================
-- Optional: record participating players per match (7 per team)
-- =========================================================
DO $$
DECLARE
    m RECORD;
BEGIN
    FOR m IN
        SELECT match_id, host_id, guest_id FROM football_match ORDER BY match_id
    LOOP
        -- Host participants
        INSERT INTO match_team_member_infos (match_id, member_id)
        SELECT m.match_id, tm.personal_id
        FROM team_member tm
        JOIN player pl ON pl.personal_id = tm.personal_id
        WHERE pl.current_team_id = m.host_id
        ORDER BY random() LIMIT 7
        ON CONFLICT DO NOTHING;

        -- Guest participants
        INSERT INTO match_team_member_infos (match_id, member_id)
        SELECT m.match_id, tm.personal_id
        FROM team_member tm
        JOIN player pl ON pl.personal_id = tm.personal_id
        WHERE pl.current_team_id = m.guest_id
        ORDER BY random() LIMIT 7
        ON CONFLICT DO NOTHING;
    END LOOP;
END $$;

-- =========================================================
-- (Optional) Contracts for players in the 2022-23 season only
-- =========================================================
-- Comment out if you prefer not to create contracts for players.
DO $$
DECLARE
    ls RECORD;
    p RECORD;
BEGIN
    -- Use the same league-season your team rows reference via (2022-08-01 .. 2023-05-15)
    FOR ls IN
        SELECT * FROM league_season
        WHERE starting_date = DATE '2022-08-01' AND ending_date = DATE '2023-05-15'
    LOOP
        FOR p IN
            SELECT pl.personal_id, pl.current_team_id
            FROM player pl
            JOIN team t ON t.team_id = pl.current_team_id
            WHERE t.current_league = ls.league_name
        LOOP
            INSERT INTO contract (member_id, season_start, season_end, league_name, team_id, amount)
            VALUES (p.personal_id, ls.starting_date, ls.ending_date, ls.league_name, p.current_team_id, (80000 + (random()*40000))::INT)
            ON CONFLICT DO NOTHING;
        END LOOP;
    END LOOP;
END $$;

DO $$
DECLARE
    m RECORD;
    team CHAR(6);
    opp CHAR(6);
    goals INT;
    stat_types match_stat_type[] := ARRAY[
        'possession', 'shots_total', 'shots_on_target', 'shots_off_target', 'goals',
        'fouls_committed', 'yellow_cards', 'red_cards', 'offsides', 'corners',
        'free_kicks', 'goal_kicks', 'saves', 'passes', 'pass_accuracy',
        'tackles', 'interceptions', 'clearances'
    ];
    stat match_stat_type;
    value INT;
    accuracy INT;
    possession1 INT;
    possession2 INT;
BEGIN
    FOR m IN SELECT * FROM football_match LOOP
        -- Randomize possession split (e.g., 52% vs 48%)
        possession1 := 45 + FLOOR(random() * 11);
        possession2 := 100 - possession1;

        FOR team, opp, goals IN
            SELECT m.host_id, m.guest_id, m.host_score
            UNION ALL
            SELECT m.guest_id, m.host_id, m.guest_score
        LOOP
            FOREACH stat IN ARRAY stat_types LOOP
                -- Randomized logic per stat type
                CASE stat
                    WHEN 'possession' THEN
                        value := CASE team WHEN m.host_id THEN possession1 ELSE possession2 END;
                    WHEN 'goals' THEN
                        value := goals;
                    WHEN 'shots_total' THEN
                        value := goals + FLOOR(random() * 10 + 3)::INT;
                    WHEN 'shots_on_target' THEN
                        value := GREATEST(goals, FLOOR(value * 0.6));
                    WHEN 'shots_off_target' THEN
                        value := GREATEST(0, FLOOR(value * 0.4));
                    WHEN 'fouls_committed' THEN
                        value := FLOOR(random() * 10 + 5);
                    WHEN 'yellow_cards' THEN
                        value := FLOOR(random() * 4);
                    WHEN 'red_cards' THEN
                        value := FLOOR(random() * 2);
                    WHEN 'offsides' THEN
                        value := FLOOR(random() * 5);
                    WHEN 'corners' THEN
                        value := FLOOR(random() * 8);
                    WHEN 'free_kicks' THEN
                        value := FLOOR(random() * 10);
                    WHEN 'goal_kicks' THEN
                        value := FLOOR(random() * 8);
                    WHEN 'saves' THEN
                        value := FLOOR(random() * 5);
                    WHEN 'passes' THEN
                        value := 300 + FLOOR(random() * 300);
                    WHEN 'pass_accuracy' THEN
                        value := 70 + FLOOR(random() * 20);
                    WHEN 'tackles' THEN
                        value := FLOOR(random() * 10);
                    WHEN 'interceptions' THEN
                        value := FLOOR(random() * 10);
                    WHEN 'clearances' THEN
                        value := FLOOR(random() * 10);
                    ELSE
                        value := 0;
                END CASE;

                -- Insert
                INSERT INTO match_statistics (stat_type, relative_team_id, relative_match_id)
                VALUES (stat, team, m.match_id)
                ON CONFLICT DO NOTHING;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- Add 2023–24 season for League A
INSERT INTO league_season (starting_date, ending_date, league_name)
VALUES ('2023-08-01', '2024-05-15', 'League A');


-- Add person
INSERT INTO person (id, full_name, address, join_date, date_of_birth)
VALUES ('9999999999', 'Test Player', ARRAY['Goal St'], '2022-01-01', '2000-01-01');

-- Add to team_member
INSERT INTO team_member (personal_id) VALUES ('9999999999');

-- Add player assigned to Team A originally
INSERT INTO player (player_id, nationality, personal_id, current_team_id)
VALUES ('999999', 'CountryX', '9999999999', '000001');

-- Add contract with Team A
INSERT INTO contract (member_id, season_start, season_end, league_name, team_id, amount)
VALUES ('9999999999', '2022-08-01', '2023-05-15', 'League A', '000001', 100000);

-- Add a match where Team A hosted Team B
INSERT INTO football_match (
    season_start, season_end, league_name, match_id,
    match_date, stadium_id, host_id, guest_id, host_score, guest_score
) VALUES (
    '2022-08-01', '2023-05-15', 'League A', '88888888',
    '2023-01-01', '000001', '000001', '000002', 2, 1
);

-- Insert a goal by the player
INSERT INTO event (
    event_id, relating_match_id, relating_player_id, event_type, time_of_occurence, description
) VALUES (
    'g99999', '88888888', '999999', 'goal', '2023-01-01 00:20:00', 'Test goal'
);

-- Now safe to insert the transfer
INSERT INTO team_member_transfers (
    seller_team_id, destination_team_id, member_id,
    season_start, season_end, league_name
) VALUES (
    '000001', '000002', '9999999999',
    '2023-08-01', '2024-05-15', 'League A'
);


-- Update player’s current team to Team B
UPDATE player SET current_team_id = '000002' WHERE player_id = '999999';

-- Optional: Add contract with Team B
INSERT INTO contract (member_id, season_start, season_end, league_name, team_id, amount)
VALUES ('9999999999', '2023-08-01', '2024-05-15', 'League A', '000002', 120000);

--truncating events:
TRUNCATE TABLE event RESTART IDENTITY CASCADE;
DO $$
DECLARE
    m RECORD;
    i INT;
    scorer CHAR(6);
    minute INT;
    next_event_id INT := 1;
    non_goal_event football_event;
    card_yellow_count INT;
    card_red_count INT;
    r FLOAT;
BEGIN
    FOR m IN SELECT * FROM football_match LOOP

        -- Generate goal events for host team
        FOR i IN 1..m.host_score LOOP
            SELECT player_id INTO scorer
            FROM player WHERE current_team_id = m.host_id
            ORDER BY random() LIMIT 1;

            INSERT INTO event (
                event_id, relating_match_id, relating_player_id, event_type, time_of_occurence, description
            )
            VALUES (
                LPAD(next_event_id::text, 6, '0'),
                m.match_id,
                scorer,
                'goal',
                m.match_date + (i * INTERVAL '3 minutes'),
                'Auto-generated goal (host)'
            );
            next_event_id := next_event_id + 1;
        END LOOP;

        -- Generate goal events for guest team
        FOR i IN 1..m.guest_score LOOP
            SELECT player_id INTO scorer
            FROM player WHERE current_team_id = m.guest_id
            ORDER BY random() LIMIT 1;

            INSERT INTO event (
                event_id, relating_match_id, relating_player_id, event_type, time_of_occurence, description
            )
            VALUES (
                LPAD(next_event_id::text, 6, '0'),
                m.match_id,
                scorer,
                'goal',
                m.match_date + (i * INTERVAL '4 minutes'),
                'Auto-generated goal (guest)'
            );
            next_event_id := next_event_id + 1;
        END LOOP;

        -- Reset per-match card counters
        card_yellow_count := 0;
        card_red_count := 0;

        -- Generate ~8 random non-goal events
        FOR i IN 1..(5 + floor(random()*7)::int) LOOP
            SELECT player_id INTO scorer
            FROM player
            WHERE current_team_id IN (m.host_id, m.guest_id)
            ORDER BY random() LIMIT 1;

            minute := floor(random() * 91)::int;
            r := random();

            -- Weighted random selection
            IF r < 0.25 THEN non_goal_event := 'foul';
            ELSIF r < 0.40 THEN non_goal_event := 'free_kick';
            ELSIF r < 0.55 THEN non_goal_event := 'throw_in';
            ELSIF r < 0.65 THEN non_goal_event := 'corner';
            ELSIF r < 0.75 THEN non_goal_event := 'substitution';
            ELSIF r < 0.83 THEN non_goal_event := 'offside';
            ELSIF r < 0.90 THEN non_goal_event := 'injury';
            ELSIF r < 0.97 AND card_yellow_count < 6 THEN
                non_goal_event := 'yellow_card';
                card_yellow_count := card_yellow_count + 1;
            ELSIF r < 1.00 AND card_red_count < 2 THEN
                non_goal_event := 'red_card';
                card_red_count := card_red_count + 1;
            ELSE
                CONTINUE; -- skip if too many cards
            END IF;

            INSERT INTO event (
                event_id, relating_match_id, relating_player_id, event_type, time_of_occurence, description
            )
            VALUES (
                LPAD(next_event_id::text, 6, '0'),
                m.match_id,
                scorer,
                non_goal_event,
                m.match_date + (minute || ' minutes')::interval,
                'Auto-generated ' || non_goal_event
            );
            next_event_id := next_event_id + 1;
        END LOOP;

    END LOOP;
END $$;


TRUNCATE TABLE event CASCADE;



DROP INDEX IF EXISTS idx_event_match_type;
DROP INDEX IF EXISTS idx_player_current_team;
DROP INDEX IF EXISTS idx_fm_host;
DROP INDEX IF EXISTS idx_fm_guest;
DROP INDEX IF EXISTS idx_tmt_member_dest_season;
DROP INDEX IF EXISTS idx_tmt_dest_seller_season;



--QUERIES:
-- recommended before/after each big change
VACUUM ANALYZE;

-- show execution time in psql
\timing on


--1: Players who scored a goal to their current team, before joining
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT DISTINCT p.player_id, p.personal_id, p.current_team_id,
       tm.name AS current_team, e.relating_match_id, fm.match_date
FROM player p
JOIN team tm ON p.current_team_id = tm.team_id
JOIN event e ON p.player_id = e.relating_player_id AND e.event_type = 'goal'
JOIN football_match fm ON e.relating_match_id = fm.match_id
JOIN team_member_transfers tmt ON tmt.member_id = p.personal_id
    AND tmt.destination_team_id = p.current_team_id
WHERE
    fm.match_date < tmt.season_start -- goal was scored before joining current team
    AND (
        (fm.host_id = p.current_team_id AND fm.guest_id != p.current_team_id) OR
        (fm.guest_id = p.current_team_id AND fm.host_id != p.current_team_id)
    )
ORDER BY p.player_id;
--execution time: 2.233ms
--new time: 3.564
--new time: 2.178 ms

SELECT event_type, COUNT(*) FROM event GROUP BY event_type;

--2: number of goals and yellow cards in each game:
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    fm.match_id,
    fm.host_id,
    fm.guest_id,
    fm.host_score,
    fm.guest_score,
    COUNT(CASE WHEN e.event_type = 'goal' THEN 1 END) AS total_goals,
    COUNT(CASE WHEN e.event_type = 'yellow_card' THEN 1 END) AS yellow_cards
FROM football_match fm
LEFT JOIN event e ON fm.match_id = e.relating_match_id
GROUP BY fm.match_id, fm.host_id, fm.guest_id, fm.host_score, fm.guest_score
ORDER BY fm.match_id;
--execution time: 2.850ms
--new time: 1.771ms


--3: Teams most wins at home:
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    t.team_id,
    t.name AS team_name,
    fm.season_start,
    COUNT(*) AS home_wins
FROM team t
JOIN football_match fm ON fm.host_id = t.team_id
WHERE fm.host_score > fm.guest_score
GROUP BY t.team_id, t.name, fm.season_start
ORDER BY home_wins DESC;
--time: 0.175 ms
--new time: 0.241


--4: players who have both scored and got a yellow card at a same match
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT DISTINCT ON (p.player_id, goal_events.relating_match_id)
    p.player_id,
    p.personal_id,
    per.full_name,
    goal_events.relating_match_id AS match_id
FROM player p
JOIN person per ON p.personal_id = per.id
JOIN event goal_events ON p.player_id = goal_events.relating_player_id
    AND goal_events.event_type = 'goal'
JOIN event card_events ON p.player_id = card_events.relating_player_id
    AND card_events.event_type IN ('yellow_card', 'red_card')
    AND goal_events.relating_match_id = card_events.relating_match_id
JOIN football_match fm ON goal_events.relating_match_id = fm.match_id
ORDER BY p.player_id, goal_events.relating_match_id;
--time: 0.741
--new time: 0.824 ms

--5: players sorted based on number of cards
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    p.player_id,
    per.full_name,
    t.name AS current_team,
    COUNT(CASE WHEN e.event_type = 'yellow_card' THEN 1 END) AS yellow_cards,
    COUNT(CASE WHEN e.event_type = 'red_card' THEN 1 END) AS red_cards,
    COUNT(e.event_id) AS total_cards
FROM player p
JOIN person per ON p.personal_id = per.id
JOIN event e ON p.player_id = e.relating_player_id
    AND e.event_type IN ('yellow_card', 'red_card')
LEFT JOIN team t ON p.current_team_id = t.team_id
GROUP BY p.player_id, per.full_name, t.name
HAVING COUNT(e.event_id) > 0
ORDER BY total_cards DESC, red_cards DESC, yellow_cards DESC;
--time: 0.681ms
--new time: 0.755ms

--6 most active referees in season:
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    r.referee_id,
    p.full_name,
    COUNT(mr.match_id) AS matches_refereed,
    r.overall_score
FROM referee r
JOIN person p ON r.personal_id = p.id
JOIN referee_team_members rtm ON r.referee_id = rtm.referee_id
JOIN match_refereeing mr ON rtm.team_id = mr.ref_team_id
GROUP BY r.referee_id, p.full_name, r.overall_score
ORDER BY matches_refereed DESC
LIMIT 10;
--time: 0.726ms
--new time: 0.583 ms

--7:number of players and staff for each team:
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    t.team_id,
    t.name,
    COUNT(DISTINCT p.player_id) AS player_count,
    COUNT(DISTINCT ts.staff_id) AS staff_count,
    COUNT(DISTINCT p.player_id) + COUNT(DISTINCT ts.staff_id) AS total_members
FROM team t
LEFT JOIN player p ON t.team_id = p.current_team_id
LEFT JOIN technical_staff ts ON ts.personal_id IN (
    SELECT tm.personal_id
    FROM team_member tm
    JOIN team_member_transfers tf ON tf.member_id = tm.personal_id
    WHERE tf.destination_team_id = t.team_id
)
WHERE t.starting_date = '2022-08-01'
GROUP BY t.team_id, t.name
ORDER BY t.name;
--time: 29.049 ms
--new time: 30.330 ms



--8: ordered intervals of time based on number of goals scored:
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
WITH match_periods AS (
    SELECT generate_series(0, 80, 10) AS period_start
),
match_goals AS (
    SELECT
        e.relating_match_id,
        EXTRACT(MINUTE FROM (e.time_of_occurence - fm.match_date)) AS minute_scored
    FROM event e
    JOIN football_match fm ON e.relating_match_id = fm.match_id
    WHERE e.event_type = 'goal'
)
SELECT
    mp.period_start,
    mp.period_start + 9 AS period_end,
    COUNT(mg.minute_scored) AS goals_scored
FROM match_periods mp
LEFT JOIN match_goals mg ON
    mg.minute_scored BETWEEN mp.period_start AND mp.period_start + 9
GROUP BY mp.period_start, mp.period_start + 9
ORDER BY mp.period_start;
--time: 3.323ms
--new time: 3.024

--9: players who have scored to their old team after changing clubs
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT DISTINCT
  pl.player_id,
  per.full_name,
  tmt.seller_team_id   AS old_team_id,
  t_old.name           AS old_team_name,
  tmt.destination_team_id AS new_team_id,
  t_new.name              AS new_team_name,
  fm.match_id,
  fm.match_date,
  fm.season_start,
  fm.league_name
FROM team_member_transfers tmt
JOIN player pl           ON pl.personal_id = tmt.member_id
JOIN person per          ON per.id = pl.personal_id
JOIN football_match fm   ON fm.league_name = tmt.league_name
                         AND fm.match_date >= tmt.season_start
                         AND (
                              (fm.host_id = tmt.destination_team_id AND fm.guest_id = tmt.seller_team_id) OR
                              (fm.guest_id = tmt.destination_team_id AND fm.host_id = tmt.seller_team_id)
                         )
JOIN event e             ON e.relating_match_id = fm.match_id
                         AND e.relating_player_id = pl.player_id
                         AND e.event_type = 'goal'
JOIN team t_old          ON t_old.team_id = tmt.seller_team_id
JOIN team t_new          ON t_new.team_id = tmt.destination_team_id
ORDER BY fm.match_date, per.full_name;
--time: 1.203ms
--new time: 1.390ms

--10: cards given by referees
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
    WITH ref_matches AS (
  SELECT
    r.referee_id,
    p.full_name,
    fm.season_start,
    mr.match_id
  FROM match_refereeing mr
  JOIN football_match fm       ON fm.match_id = mr.match_id
  JOIN referee_team_members rtm ON rtm.team_id = mr.ref_team_id
  JOIN referee r               ON r.referee_id = rtm.referee_id
  JOIN person p                ON p.id = r.personal_id
),
cards_in_match AS (
  SELECT
    e.relating_match_id AS match_id,
    COUNT(*) FILTER (WHERE e.event_type IN ('yellow_card','red_card')) AS cards_in_this_match
  FROM event e
  GROUP BY e.relating_match_id
)
SELECT
  rm.referee_id,
  rm.full_name,
  rm.season_start,
  COUNT(DISTINCT rm.match_id)                           AS matches_refereed,
  COALESCE(SUM(cim.cards_in_this_match), 0)             AS total_cards_in_those_matches,
  ROUND( COALESCE(SUM(cim.cards_in_this_match)::numeric, 0) / NULLIF(COUNT(DISTINCT rm.match_id),0), 2)
                                                        AS cards_per_match
FROM ref_matches rm
LEFT JOIN cards_in_match cim ON cim.match_id = rm.match_id
GROUP BY rm.referee_id, rm.full_name, rm.season_start
HAVING COUNT(DISTINCT rm.match_id) > 0
ORDER BY rm.season_start, cards_per_match DESC, matches_refereed DESC, rm.full_name;
--time: 3.018ms
--new time: 2.917 ms


--ADDING INDEXES TO SEE IMPROVEMENT IN TIME:

-- 1) Events by match + type  → speeds #2, #4, #5, #8, #9, #10
CREATE INDEX IF NOT EXISTS idx_event_match_type
  ON event (relating_match_id, event_type);

-- 2) Player lookup by current team → speeds #2, #7 (and many joins from team → players)
CREATE INDEX IF NOT EXISTS idx_player_current_team
  ON player (current_team_id);

-- 3) Matches by host team → speeds #3; also used in #9 OR-condition
CREATE INDEX IF NOT EXISTS idx_fm_host
  ON football_match (host_id);

-- 4) Matches by guest team → complements #3 for the #9 OR-condition path
CREATE INDEX IF NOT EXISTS idx_fm_guest
  ON football_match (guest_id);

-- 5) Transfers by (member → destination) with season → critical for #1
CREATE INDEX IF NOT EXISTS idx_tmt_member_dest_season
  ON team_member_transfers (member_id, destination_team_id, season_start);

-- 6) Transfers by (destination → seller) with season → critical for #9
CREATE INDEX IF NOT EXISTS idx_tmt_dest_seller_season
  ON team_member_transfers (destination_team_id, seller_team_id, season_start);

ANALYZE;















































-- PRACTICE FOR EXAM






-- ============================
-- University Practice Database
-- ============================

-- Start fresh
DROP SCHEMA IF EXISTS uni CASCADE;
CREATE SCHEMA uni;
SET search_path TO uni;

-- ---------- Types ----------
-- (Optional) you can switch to ENUMs; using CHECK for portability/readability.
-- CREATE TYPE uni.grade AS ENUM ('A','B','C','D','F','I','W');

-- ---------- Core Tables ----------

CREATE TABLE department (
  dept_id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name             TEXT UNIQUE NOT NULL,
  faculty          TEXT NOT NULL,               -- e.g., "Engineering", "Arts & Sciences"
  office_phone     TEXT,
  chair_prof_id    INT                          -- set after professors are inserted
);

CREATE TABLE professor (
  prof_id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  full_name        TEXT NOT NULL,
  email            TEXT UNIQUE NOT NULL,
  hire_date        DATE NOT NULL,
  rank             TEXT NOT NULL CHECK (rank IN ('Assistant','Associate','Full','Lecturer')),
  dept_id          INT NOT NULL REFERENCES department(dept_id) ON DELETE RESTRICT
);

ALTER TABLE department
  ADD CONSTRAINT department_chair_fk
  FOREIGN KEY (chair_prof_id) REFERENCES professor(prof_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE term (
  term_id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  term_name        TEXT NOT NULL CHECK (term_name IN ('Fall','Spring','Summer')),
  term_year        INT  NOT NULL CHECK (term_year BETWEEN 2000 AND 2100),
  start_date       DATE NOT NULL,
  end_date         DATE NOT NULL,
  UNIQUE (term_name, term_year),
  CHECK (start_date < end_date)
);

CREATE TABLE building (
  building_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code             TEXT NOT NULL UNIQUE,        -- e.g., "ENG", "SCI"
  name             TEXT NOT NULL
);

CREATE TABLE classroom (
  room_id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  building_id      INT NOT NULL REFERENCES building(building_id) ON DELETE CASCADE,
  room_number      TEXT NOT NULL,
  capacity         INT  NOT NULL CHECK (capacity > 0),
  features         TEXT[] DEFAULT '{}',         -- e.g., {'Projector','Lab','WheelchairAccess'}
  UNIQUE (building_id, room_number)
);

CREATE TABLE course (
  course_id        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  dept_id          INT NOT NULL REFERENCES department(dept_id) ON DELETE RESTRICT,
  code             TEXT NOT NULL,               -- e.g., "CS101"
  title            TEXT NOT NULL,
  credits          NUMERIC(2,1) NOT NULL CHECK (credits IN (1.0, 1.5, 2.0, 3.0, 4.0, 5.0)),
  level            TEXT NOT NULL CHECK (level IN ('Undergrad','Graduate')),
  UNIQUE (dept_id, code)
);

CREATE TABLE course_prereq (
  course_id        INT NOT NULL REFERENCES course(course_id) ON DELETE CASCADE,
  prereq_course_id INT NOT NULL REFERENCES course(course_id) ON DELETE RESTRICT,
  PRIMARY KEY (course_id, prereq_course_id),
  CHECK (course_id <> prereq_course_id)
);

CREATE TABLE student (
  student_id       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  full_name        TEXT NOT NULL,
  email            TEXT UNIQUE NOT NULL,
  birthdate        DATE NOT NULL,
  gender           TEXT CHECK (gender IN ('F','M','X')),
  major_dept_id    INT REFERENCES department(dept_id) ON DELETE SET NULL,
  start_term_id    INT REFERENCES term(term_id) ON DELETE SET NULL
);

CREATE TABLE section (
  section_id       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  course_id        INT NOT NULL REFERENCES course(course_id) ON DELETE CASCADE,
  term_id          INT NOT NULL REFERENCES term(term_id) ON DELETE CASCADE,
  section_no       TEXT NOT NULL,               -- e.g., 'A', 'B1'
  professor_id     INT NOT NULL REFERENCES professor(prof_id) ON DELETE SET NULL,
  classroom_id     INT REFERENCES classroom(room_id) ON DELETE SET NULL,
  days             TEXT[] NOT NULL,             -- e.g., {'Mon','Wed'}
  start_time       TIME NOT NULL,
  end_time         TIME NOT NULL,
  UNIQUE (course_id, term_id, section_no),
  CHECK (start_time < end_time)
);

CREATE TABLE enrollment (
  student_id       INT NOT NULL REFERENCES student(student_id) ON DELETE CASCADE,
  section_id       INT NOT NULL REFERENCES section(section_id) ON DELETE CASCADE,
  enrolled_on      DATE NOT NULL DEFAULT CURRENT_DATE,
  grade            TEXT CHECK (grade IN ('A','B','C','D','F','I','W')),
  PRIMARY KEY (student_id, section_id)
);

CREATE TABLE assignment (
  assignment_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  section_id       INT NOT NULL REFERENCES section(section_id) ON DELETE CASCADE,
  title            TEXT NOT NULL,
  due_date         DATE NOT NULL,
  points           NUMERIC(5,2) NOT NULL CHECK (points > 0)
);

CREATE TABLE submission (
  student_id       INT NOT NULL REFERENCES student(student_id) ON DELETE CASCADE,
  assignment_id    INT NOT NULL REFERENCES assignment(assignment_id) ON DELETE CASCADE,
  submitted_at     TIMESTAMP NOT NULL,
  score            NUMERIC(5,2) CHECK (score >= 0),
  PRIMARY KEY (student_id, assignment_id)
);

-- ---------- Helpful Indexes ----------
CREATE INDEX idx_prof_dept    ON professor(dept_id);
CREATE INDEX idx_course_dept  ON course(dept_id);
CREATE INDEX idx_section_term ON section(term_id);
CREATE INDEX idx_enroll_sec   ON enrollment(section_id);
CREATE INDEX idx_student_major ON student(major_dept_id);

-- ======================
-- Seed Data (Instances)
-- ======================

-- Departments
INSERT INTO department (name, faculty, office_phone) VALUES
  ('Computer Science', 'Engineering', '+49-30-5555-100'),
  ('Mathematics',      'Science',     '+49-30-5555-200'),
  ('History',          'Arts & Sciences', '+49-30-5555-300'),
  ('Physics',          'Science',     '+49-30-5555-400');

-- Professors
INSERT INTO professor (full_name, email, hire_date, rank, dept_id) VALUES
  ('Dr. Anna Keller',      'anna.keller@uni.example',      '2016-09-01', 'Associate', (SELECT dept_id FROM department WHERE name='Computer Science')),
  ('Dr. Tobias Brand',     'tobias.brand@uni.example',     '2019-03-15', 'Assistant', (SELECT dept_id FROM department WHERE name='Computer Science')),
  ('Prof. Markus Engel',   'markus.engel@uni.example',     '2010-04-01', 'Full',      (SELECT dept_id FROM department WHERE name='Mathematics')),
  ('Dr. Sofia Romero',     'sofia.romero@uni.example',     '2021-10-01', 'Assistant', (SELECT dept_id FROM department WHERE name='Mathematics')),
  ('Prof. Helene Schäfer', 'helene.schaefer@uni.example',  '2008-01-10', 'Full',      (SELECT dept_id FROM department WHERE name='History')),
  ('Dr. Lars Neumann',     'lars.neumann@uni.example',     '2018-08-20', 'Associate', (SELECT dept_id FROM department WHERE name='Physics')),
  ('Dr. Li Wei',           'li.wei@uni.example',           '2020-02-01', 'Lecturer',  (SELECT dept_id FROM department WHERE name='Computer Science')),
  ('Dr. Petra Novak',      'petra.novak@uni.example',      '2015-07-01', 'Associate', (SELECT dept_id FROM department WHERE name='Physics'));

-- Set department chairs (deferred FK)
UPDATE department SET chair_prof_id = (SELECT prof_id FROM professor WHERE email='anna.keller@uni.example')
 WHERE name='Computer Science';
UPDATE department SET chair_prof_id = (SELECT prof_id FROM professor WHERE email='markus.engel@uni.example')
 WHERE name='Mathematics';
UPDATE department SET chair_prof_id = (SELECT prof_id FROM professor WHERE email='helene.schaefer@uni.example')
 WHERE name='History';
UPDATE department SET chair_prof_id = (SELECT prof_id FROM professor WHERE email='petra.novak@uni.example')
 WHERE name='Physics';

-- Terms (Year + dates)
INSERT INTO term (term_name, term_year, start_date, end_date) VALUES
  ('Fall',   2024, '2024-09-02', '2024-12-20'),
  ('Spring', 2025, '2025-02-17', '2025-06-06'),
  ('Summer', 2025, '2025-07-01', '2025-08-15');

-- Buildings
INSERT INTO building (code, name) VALUES
  ('ENG', 'Engineering Center'),
  ('SCI', 'Science Hall'),
  ('ART', 'Arts Building');

-- Classrooms
INSERT INTO classroom (building_id, room_number, capacity, features) VALUES
  ((SELECT building_id FROM building WHERE code='ENG'), '101', 80,  ARRAY['Projector','WheelchairAccess']),
  ((SELECT building_id FROM building WHERE code='ENG'), '201', 40,  ARRAY['Projector']),
  ((SELECT building_id FROM building WHERE code='SCI'), '12',  30,  ARRAY['Lab','Projector']),
  ((SELECT building_id FROM building WHERE code='SCI'), '220', 120, ARRAY['Projector','Audio']),
  ((SELECT building_id FROM building WHERE code='ART'), 'A1',  60,  ARRAY['Projector']),
  ((SELECT building_id FROM building WHERE code='ART'), 'B2',  25,  ARRAY['Studio']);

-- Courses
INSERT INTO course (dept_id, code, title, credits, level) VALUES
  ((SELECT dept_id FROM department WHERE name='Computer Science'),'CS101','Intro to Programming',3.0,'Undergrad'),
  ((SELECT dept_id FROM department WHERE name='Computer Science'),'CS201','Data Structures',4.0,'Undergrad'),
  ((SELECT dept_id FROM department WHERE name='Computer Science'),'CS301','Databases',3.0,'Undergrad'),
  ((SELECT dept_id FROM department WHERE name='Computer Science'),'CS501','Advanced Algorithms',4.0,'Graduate'),
  ((SELECT dept_id FROM department WHERE name='Mathematics'),    'MATH101','Calculus I',4.0,'Undergrad'),
  ((SELECT dept_id FROM department WHERE name='Mathematics'),    'MATH201','Linear Algebra',3.0,'Undergrad'),
  ((SELECT dept_id FROM department WHERE name='Mathematics'),    'MATH550','Probability Theory',4.0,'Graduate'),
  ((SELECT dept_id FROM department WHERE name='History'),        'HIST110','Modern Europe',3.0,'Undergrad'),
  ((SELECT dept_id FROM department WHERE name='History'),        'HIST320','History of Science',3.0,'Undergrad'),
  ((SELECT dept_id FROM department WHERE name='Physics'),        'PHYS101','General Physics I',4.0,'Undergrad'),
  ((SELECT dept_id FROM department WHERE name='Physics'),        'PHYS210','Quantum Mechanics',4.0,'Undergrad'),
  ((SELECT dept_id FROM department WHERE name='Physics'),        'PHYS530','Statistical Mechanics',4.0,'Graduate');

-- Prerequisites
INSERT INTO course_prereq (course_id, prereq_course_id) VALUES
  ((SELECT course_id FROM course WHERE code='CS201'),
   (SELECT course_id FROM course WHERE code='CS101')),
  ((SELECT course_id FROM course WHERE code='CS301'),
   (SELECT course_id FROM course WHERE code='CS201')),
  ((SELECT course_id FROM course WHERE code='CS501'),
   (SELECT course_id FROM course WHERE code='CS201')),
  ((SELECT course_id FROM course WHERE code='MATH201'),
   (SELECT course_id FROM course WHERE code='MATH101')),
  ((SELECT course_id FROM course WHERE code='PHYS210'),
   (SELECT course_id FROM course WHERE code='PHYS101'));

-- Students
INSERT INTO student (full_name, email, birthdate, gender, major_dept_id, start_term_id) VALUES
  ('Eva Müller',        'eva.mueller@student.example',   '2004-01-15','F',(SELECT dept_id FROM department WHERE name='Computer Science'),(SELECT term_id FROM term WHERE term_name='Fall' AND term_year=2024)),
  ('Jonas Fischer',     'jonas.fischer@student.example', '2003-05-02','M',(SELECT dept_id FROM department WHERE name='Mathematics'),     (SELECT term_id FROM term WHERE term_name='Fall' AND term_year=2024)),
  ('Marta Nowak',       'marta.nowak@student.example',   '2002-11-20','F',(SELECT dept_id FROM department WHERE name='History'),         (SELECT term_id FROM term WHERE term_name='Fall' AND term_year=2024)),
  ('Ali Hassan',        'ali.hassan@student.example',    '2005-03-11','M',(SELECT dept_id FROM department WHERE name='Physics'),         (SELECT term_id FROM term WHERE term_name='Fall' AND term_year=2024)),
  ('Luca Rossi',        'luca.rossi@student.example',    '2004-07-09','M',(SELECT dept_id FROM department WHERE name='Computer Science'),(SELECT term_id FROM term WHERE term_name='Fall' AND term_year=2024)),
  ('Sofia Schmidt',     'sofia.schmidt@student.example', '2003-09-30','F',(SELECT dept_id FROM department WHERE name='Mathematics'),     (SELECT term_id FROM term WHERE term_name='Fall' AND term_year=2024)),
  ('Tariq Aziz',        'tariq.aziz@student.example',    '2001-12-01','M',(SELECT dept_id FROM department WHERE name='Physics'),         (SELECT term_id FROM term WHERE term_name='Spring' AND term_year=2025)),
  ('Hannah Becker',     'hannah.becker@student.example', '2004-04-05','F',(SELECT dept_id FROM department WHERE name='History'),         (SELECT term_id FROM term WHERE term_name='Spring' AND term_year=2025)),
  ('Noah Wagner',       'noah.wagner@student.example',   '2003-06-21','M',(SELECT dept_id FROM department WHERE name='Computer Science'),(SELECT term_id FROM term WHERE term_name='Spring' AND term_year=2025)),
  ('Isabel García',     'isabel.garcia@student.example', '2002-10-14','F',(SELECT dept_id FROM department WHERE name='Physics'),         (SELECT term_id FROM term WHERE term_name='Spring' AND term_year=2025));

-- Sections (Fall 2024)
INSERT INTO section (course_id, term_id, section_no, professor_id, classroom_id, days, start_time, end_time) VALUES
  ((SELECT course_id FROM course WHERE code='CS101'),  (SELECT term_id FROM term WHERE term_name='Fall'   AND term_year=2024), 'A',
   (SELECT prof_id FROM professor WHERE email='anna.keller@uni.example'),
   (SELECT room_id FROM classroom JOIN building USING(building_id) WHERE code='ENG' AND room_number='101'),
   ARRAY['Mon','Wed'], '09:00','10:30'),
  ((SELECT course_id FROM course WHERE code='MATH101'),(SELECT term_id FROM term WHERE term_name='Fall'   AND term_year=2024), 'A',
   (SELECT prof_id FROM professor WHERE email='markus.engel@uni.example'),
   (SELECT room_id FROM classroom JOIN building USING(building_id) WHERE code='SCI' AND room_number='220'),
   ARRAY['Tue','Thu'], '11:00','12:30'),
  ((SELECT course_id FROM course WHERE code='HIST110'),(SELECT term_id FROM term WHERE term_name='Fall'   AND term_year=2024), 'A',
   (SELECT prof_id FROM professor WHERE email='helene.schaefer@uni.example'),
   (SELECT room_id FROM classroom JOIN building USING(building_id) WHERE code='ART' AND room_number='A1'),
   ARRAY['Mon'], '14:00','17:00'),
  ((SELECT course_id FROM course WHERE code='PHYS101'),(SELECT term_id FROM term WHERE term_name='Fall'   AND term_year=2024), 'A',
   (SELECT prof_id FROM professor WHERE email='lars.neumann@uni.example'),
   (SELECT room_id FROM classroom JOIN building USING(building_id) WHERE code='SCI' AND room_number='12'),
   ARRAY['Wed','Fri'], '10:00','11:30');

-- Sections (Spring 2025)
INSERT INTO section (course_id, term_id, section_no, professor_id, classroom_id, days, start_time, end_time) VALUES
  ((SELECT course_id FROM course WHERE code='CS201'),  (SELECT term_id FROM term WHERE term_name='Spring' AND term_year=2025), 'A',
   (SELECT prof_id FROM professor WHERE email='tobias.brand@uni.example'),
   (SELECT room_id FROM classroom JOIN building USING(building_id) WHERE code='ENG' AND room_number='201'),
   ARRAY['Mon','Wed'], '09:00','10:30'),
  ((SELECT course_id FROM course WHERE code='CS301'),  (SELECT term_id FROM term WHERE term_name='Spring' AND term_year=2025), 'A',
   (SELECT prof_id FROM professor WHERE email='li.wei@uni.example'),
   (SELECT room_id FROM classroom JOIN building USING(building_id) WHERE code='ENG' AND room_number='101'),
   ARRAY['Tue'], '13:00','16:00'),
  ((SELECT course_id FROM course WHERE code='MATH201'),(SELECT term_id FROM term WHERE term_name='Spring' AND term_year=2025), 'A',
   (SELECT prof_id FROM professor WHERE email='sofia.romero@uni.example'),
   (SELECT room_id FROM classroom JOIN building USING(building_id) WHERE code='SCI' AND room_number='12'),
   ARRAY['Tue','Thu'], '11:00','12:30'),
  ((SELECT course_id FROM course WHERE code='PHYS210'),(SELECT term_id FROM term WHERE term_name='Spring' AND term_year=2025), 'A',
   (SELECT prof_id FROM professor WHERE email='petra.novak@uni.example'),
   (SELECT room_id FROM classroom JOIN building USING(building_id) WHERE code='SCI' AND room_number='220'),
   ARRAY['Wed','Fri'], '10:00','11:30');

-- Enrollments (Fall 2024)
INSERT INTO enrollment (student_id, section_id, enrolled_on, grade)
SELECT s.student_id, sec.section_id, DATE '2024-09-05', NULL
FROM student s
JOIN section sec ON sec.term_id = (SELECT term_id FROM term WHERE term_name='Fall' AND term_year=2024)
WHERE (s.email IN ('eva.mueller@student.example','jonas.fischer@student.example','marta.nowak@student.example','ali.hassan@student.example','luca.rossi@student.example','sofia.schmidt@student.example'))
  AND (
        (sec.section_id IN (SELECT section_id FROM section JOIN course USING(course_id) WHERE code='CS101'))
     OR (sec.section_id IN (SELECT section_id FROM section JOIN course USING(course_id) WHERE code='MATH101'))
     OR (sec.section_id IN (SELECT section_id FROM section JOIN course USING(course_id) WHERE code='HIST110'))
     OR (sec.section_id IN (SELECT section_id FROM section JOIN course USING(course_id) WHERE code='PHYS101'))
  );

-- Assign some grades at end of Fall 2024
UPDATE enrollment e
SET grade = g.grade_val
FROM (
  VALUES
    ('eva.mueller@student.example','CS101','A'),
    ('luca.rossi@student.example','CS101','B'),
    ('jonas.fischer@student.example','MATH101','A'),
    ('sofia.schmidt@student.example','MATH101','B'),
    ('marta.nowak@student.example','HIST110','A'),
    ('ali.hassan@student.example','PHYS101','B')
) AS g(student_email, course_code, grade_val)
WHERE e.student_id = (SELECT student_id FROM student WHERE email=g.student_email)
  AND e.section_id IN (
    SELECT sec.section_id
    FROM section sec
    JOIN course c ON c.course_id = sec.course_id
    JOIN term t ON t.term_id = sec.term_id
    WHERE t.term_name='Fall' AND t.term_year=2024 AND c.code = g.course_code
  );

-- Enrollments (Spring 2025)
INSERT INTO enrollment (student_id, section_id, enrolled_on, grade)
SELECT s.student_id, sec.section_id, DATE '2025-02-20', NULL
FROM student s
JOIN section sec ON sec.term_id = (SELECT term_id FROM term WHERE term_name='Spring' AND term_year=2025)
WHERE s.email IN ('eva.mueller@student.example','luca.rossi@student.example','noah.wagner@student.example','isabel.garcia@student.example','tariq.aziz@student.example','hannah.becker@student.example','jonas.fischer@student.example','sofia.schmidt@student.example');

-- Assignments
INSERT INTO assignment (section_id, title, due_date, points)
SELECT section_id, 'HW1', (SELECT start_date FROM term WHERE term_name='Spring' AND term_year=2025) + 14, 100 FROM section
 WHERE term_id = (SELECT term_id FROM term WHERE term_name='Spring' AND term_year=2025);
INSERT INTO assignment (section_id, title, due_date, points)
SELECT section_id, 'Project', (SELECT start_date FROM term WHERE term_name='Spring' AND term_year=2025) + 56, 200 FROM section
 WHERE term_id = (SELECT term_id FROM term WHERE term_name='Spring' AND term_year=2025);

-- Submissions
INSERT INTO submission (student_id, assignment_id, submitted_at, score)
SELECT e.student_id, a.assignment_id, (a.due_date - INTERVAL '1 day')::timestamp + TIME '18:00', a.points * 0.9
FROM enrollment e
JOIN assignment a ON a.section_id = e.section_id
JOIN term t ON t.term_id = (SELECT term_id FROM term WHERE term_name='Spring' AND term_year=2025)
WHERE e.section_id IN (SELECT section_id FROM section WHERE term_id = t.term_id);

-- ======================
-- Handy Views (Optional)
-- ======================

-- GPA by simple 4.0 scale (A=4,B=3,C=2,D=1,F=0; I/W ignored)
CREATE OR REPLACE VIEW v_student_term_gpa AS
SELECT
  s.student_id,
  s.full_name,
  t.term_name,
  t.term_year,
  ROUND(AVG(
    CASE e.grade
      WHEN 'A' THEN 4.0
      WHEN 'B' THEN 3.0
      WHEN 'C' THEN 2.0
      WHEN 'D' THEN 1.0
      WHEN 'F' THEN 0.0
      ELSE NULL
    END
  )::numeric, 2) AS gpa
FROM student s
JOIN enrollment e ON e.student_id = s.student_id
JOIN section sec ON sec.section_id = e.section_id
JOIN term t ON t.term_id = sec.term_id
GROUP BY s.student_id, s.full_name, t.term_name, t.term_year
ORDER BY s.student_id, t.term_year, t.term_name;

-- Teaching load per professor per term
CREATE OR REPLACE VIEW v_prof_teaching_load AS
SELECT
  p.prof_id,
  p.full_name,
  t.term_name, t.term_year,
  COUNT(sec.section_id) AS sections_taught
FROM professor p
LEFT JOIN section sec ON sec.professor_id = p.prof_id
LEFT JOIN term t ON t.term_id = sec.term_id
GROUP BY p.prof_id, p.full_name, t.term_name, t.term_year
ORDER BY p.prof_id, t.term_year, t.term_name;

-- Quick checks
-- SELECT * FROM v_student_term_gpa;
-- SELECT * FROM v_prof_teaching_load;


Select * from course c join department d on c.dept_id=d.dept_id
where d.name='Computer Science';

Select avg(c.capacity) as avg_capacity from building b join classroom c on b.building_id = c.building_id
where b.name='Science Hall';


select count(c.course_id) as num_courses, d.name from department d left join course c on d.dept_id = c.dept_id
group by d.name;


--using join
select distinct s.full_name, s.email from student s
    join submission s2 on s.student_id = s2.student_id
    join assignment a on s2.assignment_id = a.assignment_id;

--using exists:
select distinct s.full_name, s.email from student s
where exists(
    select * from assignment a join submission s2 on a.assignment_id = s2.assignment_id
               and s2.student_id=s.student_id
);

select p.full_name, p.email from professor p
where not exists(
    select 1 from section s where s.professor_id = p.prof_id
);

--departments with more than 3 students
select d.name, count(s.student_id)  from department d join student s on d.dept_id = s.major_dept_id
group by d.name
having count(s.student_id) >= 2 order by count(*) desc, d.name asc;


WITH graded AS (
  SELECT
    s.student_id,
    s.full_name,
    t.term_name,
    t.term_year,
    CASE e.grade
      WHEN 'A' THEN 4.0
      WHEN 'B' THEN 3.0
      WHEN 'C' THEN 2.0
      WHEN 'D' THEN 1.0
      WHEN 'F' THEN 0.0
      ELSE NULL          -- I/W or NULL are ignored
    END AS points
  FROM uni.student s
  JOIN uni.enrollment e ON e.student_id = s.student_id
  JOIN uni.section sec   ON sec.section_id = e.section_id
  JOIN uni.term t        ON t.term_id = sec.term_id
),
gpa AS (
  SELECT
    student_id,
    full_name,
    term_name,
    term_year,
    ROUND(AVG(points)::numeric, 2) AS gpa
  FROM graded
  WHERE points IS NOT NULL
  GROUP BY student_id, full_name, term_name, term_year
)
SELECT
  full_name,
  term_name,
  term_year,
  gpa,
  RANK() OVER (PARTITION BY term_name, term_year ORDER BY gpa DESC) AS term_rank
FROM gpa
ORDER BY term_year, term_name, term_rank, full_name;


SELECT
  full_name,
  term_name,
  term_year,
  gpa,
  RANK() OVER (PARTITION BY term_name, term_year ORDER BY gpa DESC) AS term_rank
FROM uni.v_student_term_gpa
ORDER BY term_year, term_name, term_rank, full_name;

select c.code, c.title, d.name from course c join department d on c.dept_id = d.dept_id
    where not exists(
        select 1 from course_prereq cp where c.course_id = cp.course_id
    ) order by d.name, c.code;

select distinct c.code , c.title, d.name from course c
    join course_prereq cp on c.course_id = cp.course_id
    join department d on c.dept_id = d.dept_id;


WITH assign_avg AS (
  SELECT
    a.section_id,
    a.assignment_id,
    AVG(sub.score) AS avg_score_per_assignment
  FROM uni.assignment a
  JOIN uni.submission sub ON sub.assignment_id = a.assignment_id
  GROUP BY a.section_id, a.assignment_id
),
section_avg AS (
  SELECT
    section_id,
    ROUND(AVG(avg_score_per_assignment)::numeric, 2) AS avg_score
  FROM assign_avg
  GROUP BY section_id
)
SELECT
  c.code AS course_code,
  sec.section_no,
  t.term_name || ' ' || t.term_year AS term,
  sa.avg_score
FROM section_avg sa
JOIN uni.section sec ON sec.section_id = sa.section_id
JOIN uni.course  c   ON c.course_id  = sec.course_id
JOIN uni.term    t   ON t.term_id    = sec.term_id
WHERE t.term_name = 'Spring' AND t.term_year = 2025
  AND sa.avg_score >= 85
ORDER BY sa.avg_score DESC, c.code, sec.section_no;


WITH section_sizes AS (
  SELECT
    sec.section_id,
    c.code AS course_code,
    sec.section_no,
    t.term_name,
    t.term_year,
    COUNT(e.student_id) AS class_size
  FROM uni.section sec
  JOIN uni.course c ON c.course_id = sec.course_id
  JOIN uni.term   t ON t.term_id   = sec.term_id
  LEFT JOIN uni.enrollment e ON e.section_id = sec.section_id
  GROUP BY sec.section_id, c.code, sec.section_no, t.term_name, t.term_year
)
SELECT course_code,
       section_no,
       term_name || ' ' || term_year AS term,
       class_size,
       RANK() OVER (
    PARTITION BY term_name, term_year
    ORDER BY class_size DESC
  ) AS size_rank_in_term
FROM section_sizes
ORDER BY term_year, term_name, size_rank_in_term, course_code, section_no;
