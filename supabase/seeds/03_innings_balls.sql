/*
  CricLegend Prototype - Step 2: Ball-by-Ball Data Generation
  -------------------------------------------------------------
  This script generates:
  - Innings for all mock matches
  - Ball-by-ball data matching result status (Live/Completed)
  - Realistic score distribution
*/

DO $$
DECLARE
    m RECORD;
    inn_id UUID;
    batting_team UUID;
    bowling_team UUID;
    striker UUID;
    non_striker UUID;
    bowler UUID;
    
    over_num INT;
    ball_num INT;
    total_overs INT;
    
    run_scored INT;
    is_wkt BOOLEAN;
    wkt_type TEXT;
    
    curr_runs INT;
    curr_wkts INT;
    curr_balls INT;
    
    p_row RECORD;
    
    players_pool UUID[];
BEGIN
    -- Get some random users to act as players
    SELECT array_agg(id) INTO players_pool FROM public.users WHERE is_mock = true;

    FOR m IN SELECT * FROM public.matches WHERE is_mock = true LOOP
        
        -- --------------------------
        -- INNINGS 1
        -- --------------------------
        batting_team := m.team_a_id;
        bowling_team := m.team_b_id;
        
        inn_id := gen_random_uuid();
        
        INSERT INTO public.innings (id, match_id, batting_team_id, inning_number, is_mock) 
        VALUES (inn_id, m.id, batting_team, 1, true);
        
        -- Pick initial players
        striker := players_pool[1 + (floor(random() * array_length(players_pool, 1)))::int];
        non_striker := players_pool[1 + (floor(random() * array_length(players_pool, 1)))::int];
        bowler := players_pool[1 + (floor(random() * array_length(players_pool, 1)))::int];
        
        curr_runs := 0;
        curr_wkts := 0;
        curr_balls := 0;
        
        -- Decide overs based on match status
        IF m.status = 'Live' THEN
            total_overs := 5 + (random() * 10)::int; -- Live is mid-way
        ELSE
            total_overs := 20; -- Completed is full (mostly)
        END IF;

        -- Loop Overs
        <<over_loop>>
        FOR over_num IN 1..total_overs LOOP
             -- Change bowler every over
             bowler := players_pool[1 + (floor(random() * array_length(players_pool, 1)))::int];
             
             FOR ball_num IN 1..6 LOOP
                -- Simulate outcome
                -- 5% wicket, 30% dot, 65% runs
                IF random() < 0.05 THEN
                    is_wkt := true;
                    run_scored := 0;
                    wkt_type := 'Caught'; -- simplify
                ELSE
                    is_wkt := false;
                    run_scored := (ARRAY[0,0,1,1,1,2,3,4,4,6])[1 + (floor(random() * 10))::int];
                    wkt_type := NULL;
                END IF;
                
                -- Insert Ball
                INSERT INTO public.balls (
                    id, inning_id, match_id, over_number, ball_number, 
                    bowler_id, striker_id, non_striker_id, 
                    runs_scored, is_wicket, wicket_type, is_mock
                ) VALUES (
                    gen_random_uuid(), inn_id, m.id, over_num, ball_num,
                    bowler, striker, non_striker,
                    run_scored, is_wkt, wkt_type, true
                );
                
                curr_runs := curr_runs + run_scored;
                IF is_wkt THEN
                    curr_wkts := curr_wkts + 1;
                    -- New striker
                    striker := players_pool[1 + (floor(random() * array_length(players_pool, 1)))::int];
                END IF;
                
                curr_balls := curr_balls + 1;
                
                -- Allout?
                IF curr_wkts >= 10 THEN
                    EXIT over_loop;
                END IF;
                
             END LOOP; -- Ball Loop
        END LOOP; -- Over Loop
        
        -- Update Innings Summary
        UPDATE public.innings 
        SET total_runs = curr_runs, wickets = curr_wkts, overs_played = cast(curr_balls/6 as numeric), is_completed = (curr_wkts >= 10 OR total_overs=20)
        WHERE id = inn_id;

        -- --------------------------
        -- INNINGS 2 (Only if Completed or if Live & Inn 1 done)
        -- --------------------------
        IF m.status = 'Completed' OR (m.status = 'Live' AND random() > 0.5) THEN
            -- ... Similar logic for Innings 2 ...
            -- Simplified for brevity in this first pass, duplicating logic to ensure we get data
            
            batting_team := m.team_b_id;
            bowling_team := m.team_a_id;
            inn_id := gen_random_uuid();
            
             INSERT INTO public.innings (id, match_id, batting_team_id, inning_number, is_mock)
             VALUES (inn_id, m.id, batting_team, 2, true);
             
             -- Reset stats
            curr_runs := 0;
            curr_wkts := 0;
            curr_balls := 0;
            
            -- If Completed, chase target or random. If Live, few overs.
            IF m.status = 'Live' THEN
                 total_overs := 2 + (random() * 5)::int; 
            ELSE
                 total_overs := 18 + (random() * 2)::int; -- Chasing
            END IF;
            
             -- Loop Overs (Copy Paste Logic)
            <<over_loop_2>>
            FOR over_num IN 1..total_overs LOOP
                 bowler := players_pool[1 + (floor(random() * array_length(players_pool, 1)))::int];
                 FOR ball_num IN 1..6 LOOP
                    IF random() < 0.05 THEN
                        is_wkt := true;
                        run_scored := 0;
                        wkt_type := 'Bowled';
                    ELSE
                        is_wkt := false;
                        run_scored := (ARRAY[0,1,1,2,4,4,6])[1 + (floor(random() * 7))::int];
                         wkt_type := NULL;
                    END IF;
                    
                    INSERT INTO public.balls (
                        id, inning_id, match_id, over_number, ball_number, 
                        bowler_id, striker_id, non_striker_id, 
                        runs_scored, is_wicket, wicket_type, is_mock
                    ) VALUES (
                        gen_random_uuid(), inn_id, m.id, over_num, ball_num,
                        bowler, striker, non_striker,
                        run_scored, is_wkt, wkt_type, true
                    );
                    
                    curr_runs := curr_runs + run_scored;
                    IF is_wkt THEN
                        curr_wkts := curr_wkts + 1;
                        striker := players_pool[1 + (floor(random() * array_length(players_pool, 1)))::int];
                    END IF;
                    curr_balls := curr_balls + 1;
                    IF curr_wkts >= 10 THEN EXIT over_loop_2; END IF;
                 END LOOP;
            END LOOP;
            
            UPDATE public.innings 
            SET total_runs = curr_runs, wickets = curr_wkts, overs_played = cast(curr_balls/6 as numeric), is_completed = (curr_wkts >= 10 OR total_overs=20)
            WHERE id = inn_id;
            
        END IF; -- End Innings 2

    END LOOP; -- End Match Loop
END $$;
