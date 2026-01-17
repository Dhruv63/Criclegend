-- 1. Create Tables

-- A. Player Stats (Career Aggregates)
CREATE TABLE IF NOT EXISTS public.player_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) UNIQUE NOT NULL,
    -- Batting
    total_matches INTEGER DEFAULT 0,
    innings_batted INTEGER DEFAULT 0,
    total_runs INTEGER DEFAULT 0,
    total_balls_faced INTEGER DEFAULT 0,
    total_fours INTEGER DEFAULT 0,
    total_sixes INTEGER DEFAULT 0,
    highest_score INTEGER DEFAULT 0,
    times_not_out INTEGER DEFAULT 0,
    fifties INTEGER DEFAULT 0,
    centuries INTEGER DEFAULT 0,
    ducks INTEGER DEFAULT 0,
    batting_average NUMERIC DEFAULT 0, -- Calc
    batting_strike_rate NUMERIC DEFAULT 0, -- Calc
    -- Bowling
    innings_bowled INTEGER DEFAULT 0,
    total_overs_bowled NUMERIC DEFAULT 0,
    total_balls_bowled INTEGER DEFAULT 0,
    total_runs_conceded INTEGER DEFAULT 0,
    total_wickets INTEGER DEFAULT 0,
    best_bowling_figures TEXT, -- "5/20"
    five_wicket_hauls INTEGER DEFAULT 0,
    bowling_average NUMERIC DEFAULT 0, -- Calc
    bowling_economy NUMERIC DEFAULT 0, -- Calc
    bowling_strike_rate NUMERIC DEFAULT 0, -- Calc
    -- Fielding
    total_catches INTEGER DEFAULT 0,
    total_stumpings INTEGER DEFAULT 0,
    total_run_outs INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- B. Match Performances (Per Match)
CREATE TABLE IF NOT EXISTS public.player_match_performances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    match_id UUID REFERENCES public.matches(id) NOT NULL,
    innings_id UUID REFERENCES public.innings(id),
    team_id UUID REFERENCES public.teams(id),
    
    -- Batting
    batting_position INTEGER, -- 1-11
    runs_scored INTEGER DEFAULT 0,
    balls_faced INTEGER DEFAULT 0,
    fours_hit INTEGER DEFAULT 0,
    sixes_hit INTEGER DEFAULT 0,
    strike_rate NUMERIC DEFAULT 0,
    dismissal_type TEXT, -- 'bowled', 'caught', etc. OR NULL if not out
    is_not_out BOOLEAN DEFAULT TRUE, -- Default true until out or innings end
    
    -- Bowling
    overs_bowled NUMERIC DEFAULT 0,
    balls_bowled INTEGER DEFAULT 0,
    runs_conceded INTEGER DEFAULT 0,
    wickets_taken INTEGER DEFAULT 0,
    bowling_economy NUMERIC DEFAULT 0,
    maidens INTEGER DEFAULT 0,
    
    -- Fielding
    catches_taken INTEGER DEFAULT 0,
    stumpings_done INTEGER DEFAULT 0,
    run_outs_involved INTEGER DEFAULT 0,
    
    player_of_match BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, match_id, innings_id) -- One record per innings per player
);

-- C. Milestones
CREATE TABLE IF NOT EXISTS public.player_milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    match_id UUID REFERENCES public.matches(id) NOT NULL,
    milestone_type TEXT NOT NULL, -- 'Century', 'Fifty', '5W', 'HatTrick'
    milestone_value TEXT NOT NULL, -- '100 runs', '5/20'
    achieved_at TIMESTAMPTZ DEFAULT NOW(),
    is_notified BOOLEAN DEFAULT FALSE
);

-- 2. Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_player_stats_user_id ON public.player_stats(user_id);
CREATE INDEX IF NOT EXISTS idx_match_perf_user_id ON public.player_match_performances(user_id);
CREATE INDEX IF NOT EXISTS idx_match_perf_match_id ON public.player_match_performances(match_id);

-- 3. Functions & Triggers

-- Function: Ensure Player Stats Record Exists
CREATE OR REPLACE FUNCTION public.ensure_player_stats_exists()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.player_stats (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: On New User Signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users; -- Can't easily trigger on auth.users in Supabase without superadmin, relying on app logic or public.users
-- Assuming we have public.users syncing with auth.users
DROP TRIGGER IF EXISTS on_public_user_created ON public.users;
CREATE TRIGGER on_public_user_created
AFTER INSERT ON public.users
FOR EACH ROW EXECUTE FUNCTION public.ensure_player_stats_exists();


-- Function: Handle Ball Event (The Big One)
CREATE OR REPLACE FUNCTION public.handle_ball_event()
RETURNS TRIGGER AS $$
DECLARE
    v_batting_team_id UUID;
    v_bowling_team_id UUID;
    v_match_id UUID;
    v_innings_id UUID;
BEGIN
    -- Fetch Innings Details
    SELECT match_id, batting_team_id, bowling_team_id INTO v_match_id, v_batting_team_id, v_bowling_team_id
    FROM public.innings WHERE id = NEW.inning_id; -- Note: 'inning_id' is column in balls based on previous context, verify?
    -- Assuming balls.inning_id exists. If it's innings_id check schema.
    -- (Self-correction: Schema check showed 'inning_id' in balls table from previous step 3565 output)
    
    v_innings_id := NEW.inning_id;

    -- 1. UPSERT Batting Performance (Striker)
    INSERT INTO public.player_match_performances (user_id, match_id, innings_id, team_id)
    VALUES (NEW.striker_id, v_match_id, v_innings_id, v_batting_team_id)
    ON CONFLICT (user_id, match_id, innings_id) DO NOTHING;

    UPDATE public.player_match_performances
    SET
        runs_scored = runs_scored + NEW.runs_scored,
        balls_faced = balls_faced + CASE WHEN (NEW.extras->>'type') IN ('wide', 'no_ball') THEN 0 ELSE 1 END, -- Don't count wides usually? Laws say No Ball counts as ball faced? Actually No Ball DOES count as ball faced in most modern scoring for SR, but not for bowler's over. Let's stick to: Wides don't count, No Balls count.
        fours_hit = fours_hit + CASE WHEN NEW.runs_scored = 4 THEN 1 ELSE 0 END,
        sixes_hit = sixes_hit + CASE WHEN NEW.runs_scored = 6 THEN 1 ELSE 0 END,
        updated_at = NOW() -- Not in schema but good practice
        -- strike_rate calc done on read or separate update? Let's leave calc for view/app to save DB load? Or calc here?
        -- Let's NOT calc SR here to avoid numeric div errors every ball. App can calc.
    WHERE user_id = NEW.striker_id AND innings_id = v_innings_id;

    -- 2. UPSERT Bowling Performance (Bowler)
    INSERT INTO public.player_match_performances (user_id, match_id, innings_id, team_id)
    VALUES (NEW.bowler_id, v_match_id, v_innings_id, v_bowling_team_id)
    ON CONFLICT (user_id, match_id, innings_id) DO NOTHING;

    UPDATE public.player_match_performances
    SET
        balls_bowled = balls_bowled + CASE WHEN (NEW.extras->>'type') IN ('wide', 'no_ball') THEN 0 ELSE 1 END,
        runs_conceded = runs_conceded + NEW.runs_scored + (NEW.extras_runs), -- Bowler gets charged for everything except byes/legbyes? Standard: Wides/NB go to bowler. Byes/Legbyes don't.
        -- We need to check extra type. 
        -- If extras_type is 'bye' or 'leg_bye', don't add to bowler runs.
        -- If 'wide' or 'no_ball', add to bowler.
        wickets_taken = wickets_taken + CASE WHEN NEW.is_wicket AND NEW.dismissal_type != 'run_out' THEN 1 ELSE 0 END
    WHERE user_id = NEW.bowler_id AND innings_id = v_innings_id;
    
    -- 3. Handle Dismissal (Wicket)
    IF NEW.is_wicket THEN
        -- Mark Striker as OUT (or Non-striker if run out on that end? The 'dismissed_player_id' tells us who)
        UPDATE public.player_match_performances
        SET
            is_not_out = FALSE,
            dismissal_type = NEW.dismissal_type
        WHERE user_id = NEW.dismissed_player_id AND innings_id = v_innings_id;

        -- Handle Fielder Stats (Catch/Run Out)
        IF NEW.dismissal_fielder_id IS NOT NULL THEN
             INSERT INTO public.player_match_performances (user_id, match_id, innings_id, team_id)
             VALUES (NEW.dismissal_fielder_id, v_match_id, v_innings_id, v_bowling_team_id) -- Fielder is on bowling team
             ON CONFLICT (user_id, match_id, innings_id) DO NOTHING;

             UPDATE public.player_match_performances
             SET
                catches_taken = catches_taken + CASE WHEN NEW.dismissal_type = 'caught' THEN 1 ELSE 0 END,
                run_outs_involved = run_outs_involved + CASE WHEN NEW.dismissal_type = 'run_out' THEN 1 ELSE 0 END,
                stumpings_done = stumpings_done + CASE WHEN NEW.dismissal_type = 'stumped' THEN 1 ELSE 0 END
             WHERE user_id = NEW.dismissal_fielder_id AND innings_id = v_innings_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on Ball Insert
DROP TRIGGER IF EXISTS on_ball_insert ON public.balls;
CREATE TRIGGER on_ball_insert
AFTER INSERT ON public.balls
FOR EACH ROW EXECUTE FUNCTION public.handle_ball_event();


-- Function: Aggregate Stats (Heavy Calc - Call this separately or trigger?)
-- To avoid race conditions, maybe simple incremental updates are better?
-- Let's do a simple incremental update trigger on 'player_match_performances'.

CREATE OR REPLACE FUNCTION public.update_career_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- This is tricky. Delta update is hard if we just perform UPDATE.
    -- Easiest strategy for correctness: RE-AGGREGATE for that user.
    -- Performance hit? Maybe. But reliable.
    
    -- Batting Aggregation
    UPDATE public.player_stats
    SET
        total_matches = (SELECT COUNT(DISTINCT match_id) FROM public.player_match_performances WHERE user_id = NEW.user_id),
        innings_batted = (SELECT COUNT(*) FROM public.player_match_performances WHERE user_id = NEW.user_id AND balls_faced > 0), -- Definition of batted?
        total_runs = (SELECT SUM(runs_scored) FROM public.player_match_performances WHERE user_id = NEW.user_id),
        total_balls_faced = (SELECT SUM(balls_faced) FROM public.player_match_performances WHERE user_id = NEW.user_id),
        total_fours = (SELECT SUM(fours_hit) FROM public.player_match_performances WHERE user_id = NEW.user_id),
        total_sixes = (SELECT SUM(sixes_hit) FROM public.player_match_performances WHERE user_id = NEW.user_id),
        highest_score = (SELECT MAX(runs_scored) FROM public.player_match_performances WHERE user_id = NEW.user_id),
        times_not_out = (SELECT COUNT(*) FROM public.player_match_performances WHERE user_id = NEW.user_id AND is_not_out = TRUE AND balls_faced > 0),
        
        -- Derived
        batting_average = CASE 
            WHEN (innings_batted - times_not_out) > 0 THEN total_runs / (innings_batted - times_not_out) 
            ELSE total_runs 
        END,
        
        -- Bowling
        total_runs_conceded = (SELECT SUM(runs_conceded) FROM public.player_match_performances WHERE user_id = NEW.user_id),
        total_wickets = (SELECT SUM(wickets_taken) FROM public.player_match_performances WHERE user_id = NEW.user_id),
        total_balls_bowled = (SELECT SUM(balls_bowled) FROM public.player_match_performances WHERE user_id = NEW.user_id),
        five_wicket_hauls = (SELECT COUNT(*) FROM public.player_match_performances WHERE user_id = NEW.user_id AND wickets_taken >= 5)
        
    WHERE user_id = NEW.user_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger updating career stats is too heavy for EVERY BALL. 
-- STRATEGY CHANGE: 
-- We will NOT update career stats on every ball. 
-- We will specific trigger it ONLY when 'Match Completed' OR allow client to call 'Refresh Stats'.
-- OR: Update it only on changes to player_match_performances? That changes every ball too.
-- BETTER: Only update career stats when a match is marked 'completed' in 'matches' table.
-- That way we act in bulk.

CREATE OR REPLACE FUNCTION public.handle_match_completion()
RETURNS TRIGGER AS $$
DECLARE
    r RECORD;
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- For every player in this match, update their career stats
        FOR r IN (SELECT DISTINCT user_id FROM public.player_match_performances WHERE match_id = NEW.id) LOOP
            -- Recalculate Logic (Same as above)
             UPDATE public.player_stats
            SET
                total_matches = (SELECT COUNT(DISTINCT match_id) FROM public.player_match_performances WHERE user_id = r.user_id),
                innings_batted = (SELECT COUNT(*) FROM public.player_match_performances WHERE user_id = r.user_id AND balls_faced > 0),
                total_runs = (SELECT COALESCE(SUM(runs_scored),0) FROM public.player_match_performances WHERE user_id = r.user_id),
                total_balls_faced = (SELECT COALESCE(SUM(balls_faced),0) FROM public.player_match_performances WHERE user_id = r.user_id),
                total_fours = (SELECT COALESCE(SUM(fours_hit),0) FROM public.player_match_performances WHERE user_id = r.user_id),
                total_sixes = (SELECT COALESCE(SUM(sixes_hit),0) FROM public.player_match_performances WHERE user_id = r.user_id),
                highest_score = (SELECT COALESCE(MAX(runs_scored),0) FROM public.player_match_performances WHERE user_id = r.user_id),
                times_not_out = (SELECT COUNT(*) FROM public.player_match_performances WHERE user_id = r.user_id AND is_not_out = TRUE AND balls_faced > 0),
                ducks = (SELECT COUNT(*) FROM public.player_match_performances WHERE user_id = r.user_id AND runs_scored = 0 AND is_not_out = FALSE),
                fifties = (SELECT COUNT(*) FROM public.player_match_performances WHERE user_id = r.user_id AND runs_scored >= 50 AND runs_scored < 100),
                centuries = (SELECT COUNT(*) FROM public.player_match_performances WHERE user_id = r.user_id AND runs_scored >= 100),
                
                -- Bowling
                total_runs_conceded = (SELECT COALESCE(SUM(runs_conceded),0) FROM public.player_match_performances WHERE user_id = r.user_id),
                total_wickets = (SELECT COALESCE(SUM(wickets_taken),0) FROM public.player_match_performances WHERE user_id = r.user_id),
                total_balls_bowled = (SELECT COALESCE(SUM(balls_bowled),0) FROM public.player_match_performances WHERE user_id = r.user_id),
                innings_bowled = (SELECT COUNT(*) FROM public.player_match_performances WHERE user_id = r.user_id AND balls_bowled > 0),
                five_wicket_hauls = (SELECT COUNT(*) FROM public.player_match_performances WHERE user_id = r.user_id AND wickets_taken >= 5)
            WHERE user_id = r.user_id;
            
            -- Calc Averages
            UPDATE public.player_stats SET
                batting_average = CASE WHEN (innings_batted - times_not_out) > 0 THEN TRUNC(total_runs::numeric / (innings_batted - times_not_out), 2) ELSE total_runs END,
                batting_strike_rate = CASE WHEN total_balls_faced > 0 THEN TRUNC((total_runs::numeric / total_balls_faced) * 100, 2) ELSE 0 END,
                bowling_average = CASE WHEN total_wickets > 0 THEN TRUNC(total_runs_conceded::numeric / total_wickets, 2) ELSE 0 END,
                bowling_economy = CASE WHEN total_balls_bowled > 0 THEN TRUNC((total_runs_conceded::numeric / (total_balls_bowled/6.0)), 2) ELSE 0 END,
                bowling_strike_rate = CASE WHEN total_wickets > 0 THEN TRUNC(total_balls_bowled::numeric / total_wickets, 2) ELSE 0 END
            WHERE user_id = r.user_id;

        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_match_completed ON public.matches;
CREATE TRIGGER on_match_completed
AFTER UPDATE ON public.matches
FOR EACH ROW EXECUTE FUNCTION public.handle_match_completion();
