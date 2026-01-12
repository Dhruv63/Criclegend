/*
  CricLegend Prototype - Comprehensive Mock Data Seed
  ---------------------------------------------------
  Populates Supabase with realistic data for end-to-end testing.
  Includes:
  - 100 Users (Players, Sellers, Providers)
  - 40 Teams (Mumbai-based)
  - 15 Tournaments
  - 30 Matches (Live, Completed, Upcoming)
  - Marketplace (Products, Services, Business Listings)
  - Community (Posts, Reviews)
  
  Safety: Deletes existing 'is_mock=true' data before inserting.
*/

-- 1. CLEANUP PREVIOUS MOCK DATA
DELETE FROM public.reviews WHERE is_mock = true;
DELETE FROM public.posts WHERE is_mock = true;
DELETE FROM public.bookings WHERE is_mock = true;
DELETE FROM public.orders WHERE is_mock = true;
DELETE FROM public.products WHERE is_mock = true;
DELETE FROM public.services WHERE is_mock = true;
DELETE FROM public.innings WHERE is_mock = true; -- Cascades to balls normally, but explicit is safer if no cascade
DELETE FROM public.matches WHERE is_mock = true;
DELETE FROM public.tournaments WHERE is_mock = true;
DELETE FROM public.teams WHERE is_mock = true;
DELETE FROM public.users WHERE is_mock = true;

-- 2. CREATE HELPER FUNCTIONS (Temporary for this seed)

-- 3. SEED USERS (100)
INSERT INTO public.users (id, phone, profile_json, is_seller, seller_rating, is_mock, created_at)
SELECT 
  gen_random_uuid(),
  CASE WHEN seq = 1 THEN '8551069057' ELSE '98765' || LPAD(seq::text, 5, '0') END, 
  jsonb_build_object(
    'name', CASE 
      WHEN seq = 1 THEN 'Dudu Sharma'
      WHEN seq = 2 THEN 'Rohit Patil' 
      WHEN seq = 3 THEN 'Vikas Mehta'
      WHEN seq = 4 THEN 'Arjun Singh'
      WHEN seq = 5 THEN 'Priya Desai'
      ELSE 'Player ' || seq
    END,
    'location', (ARRAY['Andheri', 'Bandra', 'Powai', 'Vile Parle', 'Goregaon', 'Thane', 'Malad', 'Borivali'])[1 + (seq % 8)],
    'role', (ARRAY['Batsman', 'Bowler', 'All-rounder', 'Wicket-keeper'])[1 + (seq % 4)],
    'batting_style', (ARRAY['Right-hand Bat', 'Left-hand Bat'])[1 + (seq % 2)],
    'bowling_style', (ARRAY['Right-arm Fast', 'Right-arm Spin', 'Left-arm Fast', 'Left-arm Spin', 'None'])[1 + (seq % 5)],
    'total_runs', (random() * 2000)::int,
    'total_wickets', (random() * 50)::int,
    'matches_played', (10 + (random() * 50))::int
  ),
  (seq % 5 = 0), -- 20% users are sellers
  CASE WHEN (seq % 5 = 0) THEN (3 + (random() * 2)) ELSE 0 END, -- random rating 3-5
  true,
  NOW() - (random() * interval '180 days')
FROM generate_series(1, 100) AS seq;

-- 4. SEED TEAMS (40)
-- Link specific names, random captains
INSERT INTO public.teams (id, name, logo_url, captain_id, location, is_mock)
SELECT 
  gen_random_uuid(),
  t_name,
  'https://ui-avatars.com/api/?background=random&name=' || replace(t_name, ' ', '+'),
  (SELECT id FROM public.users WHERE is_mock = true ORDER BY random() LIMIT 1),
  (ARRAY['Mumbai', 'Thane', 'Navi Mumbai', 'Pune'])[1 + (floor(random() * 4))::int],
  true
FROM UNNEST(ARRAY[
  'Mumbai Warriors', 'Andheri Strikers', 'Bandra Blasters', 'Powai Panthers', 'Vile Parle Veterans', 
  'Goregaon Gladiators', 'Thane Titans', 'Malad Mavericks', 'Borivali Bulldogs', 'Kurla Kings',
  'Vikhroli Vipers', 'Mulund Mustangs', 'Dadar Dragons', 'Ghatkopar Giants', 'Kandivali Knights',
  'Santacruz Spartans', 'Juhu Jaguars', 'Versova Victors', 'Jogeshwari Juggernauts', 'Khar Krakens',
  'Colaba Chargers', 'Worli Wolves', 'Sion Smashers', 'Mazgaon Meteors', 'Parel Pirates',
  'Mahim Marauders', 'Matunga Maulers', 'Wadala Warriors', 'Chembur Cheetahs', 'Deonar Destroyers',
  'Mankhurd Masters', 'Trombay Tigers', 'Bhandup Bears', 'Dombivli Daredevils', 'Kalyan Kings',
  'Ulhasnagar United', 'Ambernath Avengers', 'Badlapur Bashers', 'Virar Vikings', 'Vasai Victors'
]) AS t_name;

-- 5. SEED TOURNAMENTS (15)
INSERT INTO public.tournaments (id, name, start_date, end_date, format, status, organizer_id, is_mock)
SELECT
  gen_random_uuid(),
  t_name,
  NOW() + (t_offset * interval '1 day'),
  NOW() + ((t_offset + 30) * interval '1 day'),
  (ARRAY['T20', 'ODI', '10-Over'])[1 + (floor(random() * 3))::int],
  CASE 
    WHEN t_offset < -35 THEN 'Completed'
    WHEN t_offset BETWEEN -10 AND 10 THEN 'Ongoing'
    ELSE 'Upcoming'
  END,
  (SELECT id FROM public.users WHERE is_mock = true ORDER BY random() LIMIT 1),
  true
FROM UNNEST(ARRAY[
  'Mumbai Premier League 2026', 'Corporate Cricket Cup 2026', 'Andheri T20 Championship', 'Weekend Warriors League', 
  'Mumbai Box Cricket Masters', 'Suburban Premier League', 'Office Cricket Cup', 'Society Cup 2026', 
  'Mumbai Super Series', 'Night Cricket Tournament', 'Monsoon Cup 2026', 'Friendship Cup', 
  'College Cricket League', 'Veterans Trophy', 'Youth Cricket Championship'
]) WITH ORDINALITY AS t(t_name, idx),
LATERAL (SELECT (random() * 90 - 45)::int as t_offset) AS r_offset;

-- 6. SEED MATCHES (30)
-- 5 Live (Today), 15 Completed (Past), 10 Upcoming (Future)
WITH match_configs AS (
    SELECT 
        CASE 
            WHEN idx <= 5 THEN 'Live'
            WHEN idx <= 20 THEN 'Completed'
            ELSE 'Upcoming'
        END as status,
        CASE
            WHEN idx <= 5 THEN NOW() -- Today
            WHEN idx <= 20 THEN NOW() - (random() * interval '30 days') -- Past
            ELSE NOW() + (random() * interval '30 days') -- Future
        END as date
    FROM generate_series(1, 30) idx
)
INSERT INTO public.matches (id, team_a_id, team_b_id, tournament_id, date, status, ground, toss_winner_id, toss_decision, is_mock)
SELECT
    gen_random_uuid(),
    (SELECT id FROM public.teams WHERE is_mock = true ORDER BY random() LIMIT 1),
    (SELECT id FROM public.teams WHERE is_mock = true ORDER BY random() LIMIT 1),
    (SELECT id FROM public.tournaments WHERE is_mock = true ORDER BY random() LIMIT 1),
    date,
    status,
    (ARRAY['MCA Ground Bandra', 'Azad Maidan', 'Cross Maidan', 'Oval Maidan', 'Shivaji Park'])[1 + (floor(random() * 5))::int],
    NULL, -- Set randomly below via update or trigger, or keep null for now
    (ARRAY['Bat', 'Bowl'])[1 + (floor(random() * 2))::int],
    true
FROM match_configs;

-- Fix Toss & Ensure unique teams in match
UPDATE public.matches 
SET team_b_id = (SELECT id FROM public.teams WHERE id != matches.team_a_id AND is_mock = true ORDER BY random() LIMIT 1)
WHERE team_a_id = team_b_id;

UPDATE public.matches
SET toss_winner_id = CASE WHEN random() > 0.5 THEN team_a_id ELSE team_b_id END
WHERE is_mock = true;


-- 7. SEED PRODUCTS (50)
INSERT INTO public.products (id, seller_id, title, description, price, category, images, condition, is_mock)
SELECT
    gen_random_uuid(),
    (SELECT id FROM public.users WHERE is_mock = true AND is_seller = true ORDER BY random() LIMIT 1),
    p_name,
    'High quality cricket equipment. Well maintained and ready for match play.',
    (random() * 10000 + 500)::numeric(10,2),
    (ARRAY['Bat', 'Ball', 'Kit', 'Protection', 'Apparel'])[1 + (floor(random() * 5))::int],
    ARRAY['https://placehold.co/600x400/png?text=' || replace(p_name, ' ', '+')],
    (ARRAY['New', 'Used'])[1 + (floor(random() * 2))::int],
    true
FROM UNNEST(ARRAY[
    'SS Master 2000 English Willow', 'MRF Grand Edition', 'SG Sunny Tonny LE', 'Kookaburra Kahuna', 'Gray-Nicolls Powerbow',
    'Adidas Incurza', 'Spartan CGC', 'BAS Vampire', 'DSC Blak', 'CEAT Hitman Edition',
    'SG Test Red Ball', 'Kookaburra Turf White', 'MRF Pace Leather Ball', 'SG Club Ball', 'Tennis Ball Pack',
    'Spearhead Kit Bag', 'SG Complete Kit', 'Nike Elite Bag', 'Puma Duffle', 'SS Team Kit',
    'SG Optipro Pads', 'MRF Genius Gloves', 'SS Matrix Helmet', 'Kookaburra Pro Pads', 'Moonwalkr Thigh Pad',
    'Nike Dri-FIT Jersey', 'Adidas Training Tee', 'Puma Track Pants', 'Cricket Whites Set', 'Team India Replica',
    'Custom Team Jersey', 'Wide Brim Hat', 'Oakley Sunglasses', 'Spiked Shoes', 'Rubber Sole Shoes',
    'Grip Tape', 'Bat Mallet', 'Stumps Set', 'Bails Set', 'Scorebook',
    'Umpire Counter', 'Coaching Cone Set', 'Catching Mitt', 'Fielding Net', 'Bowling Machine Ball',
    'Wrist Band', 'Headband', 'Compression Sleeve', 'Elbow Guard', 'Chest Guard'
]) AS p_name;


-- 8. SEED SERVICES (25)
INSERT INTO public.services (id, provider_id, title, description, hourly_rate, location, is_mock)
SELECT
    gen_random_uuid(),
    (SELECT id FROM public.users WHERE is_mock = true ORDER BY random() LIMIT 1),
    s_type,
    'Experienced professional available for matches and tournaments in Mumbai.',
    (random() * 1000 + 200)::numeric(10,2),
    (ARRAY['Andheri', 'Bandra', 'Dadar', 'Thane'])[1 + (floor(random() * 4))::int],
    true
FROM UNNEST(ARRAY[
    'Scorer', 'Scorer', 'Scorer', 'Scorer', 'Scorer',
    'Umpire', 'Umpire', 'Umpire', 'Umpire', 'Umpire',
    'Commentator', 'Commentator', 'Commentator',
    'Coach', 'Coach', 'Coach', 'Coach', 'Coach',
    'Streamer', 'Streamer', 'Physio', 'Physio',
    'Groundsman', 'Organiser', 'Shop'
]) AS s_type;


-- 9. SEED COMMUNITY POSTS (40)
INSERT INTO public.posts (id, author_id, type, content, location, created_at, is_mock)
SELECT
    gen_random_uuid(),
    (SELECT id FROM public.users WHERE is_mock = true ORDER BY random() LIMIT 1),
    p_type,
    CASE 
        WHEN p_type = 'Opponent' THEN 'Looking for an opponent team for a T20 match this weekend. We have ground booked.'
        WHEN p_type = 'Player' THEN 'We need a wicket-keeper batsman for our team. Regular matches in Andheri.'
        ELSE 'I am a fast bowler looking for a team to join. Available on weekends.'
    END,
    (ARRAY['Andheri', 'Bandra', 'Borivali', 'Thane'])[1 + (floor(random() * 4))::int],
    NOW() - (random() * interval '5 days'),
    true
FROM UNNEST(ARRAY[
    'Opponent', 'Opponent', 'Opponent', 'Opponent', 'Opponent', 'Opponent', 'Opponent', 'Opponent', 'Opponent', 'Opponent',
    'Player', 'Player', 'Player', 'Player', 'Player', 'Player', 'Player', 'Player', 'Player', 'Player',
    'Team', 'Team', 'Team', 'Team', 'Team', 'Team', 'Team', 'Team', 'Team', 'Team'  
]) AS p_type;

-- 10. SEED BUSINESS LISTINGS (30)
INSERT INTO public.business_listings (id, owner_id, name, type, location, description, is_verified, rating, is_mock)
SELECT
    gen_random_uuid(),
    (SELECT id FROM public.users WHERE is_mock = true ORDER BY random() LIMIT 1),
    b_name,
    (ARRAY['Academy', 'Ground', 'Shop'])[1 + (floor(random() * 3))::int],
    (ARRAY['Andheri West', 'Bandra East', 'Powai', 'Malad', 'Borivali'])[1 + (floor(random() * 5))::int],
    'Premier facility for cricket enthusiasts. State of the art equipment and coaching.',
    (random() > 0.7), -- 30% verified
    (3.5 + (random() * 1.5))::numeric(2,1),
    true
FROM UNNEST(ARRAY[
    'Champion Cricket Academy', 'Mumbai Cricket School', 'Pro Skills Academy', 'Elite Cricket Training', 'Youth Cricket Academy',
    'MCA Recreation Ground', 'Azad Maidan', 'Shivaji Park Ground', 'Suburban Turf', 'Box Cricket Arena',
    'Cricket World Store', 'Sports Zone', 'Champion Sports', 'Pro Cricket Shop', 'Mumbai Sports Hub',
    'Future Stars Academy', 'Legends Cricket Ground', 'Victory Sports', 'Master Class Coaching', 'Green Pitch Turf',
    'The Cricket Shop', 'Bat & Ball Store', 'Gear Up Sports', 'Net Practice Arena', 'City Cricket Club',
    'Suburban Sports', 'Metro Cricket Ground', 'Star Cricket Academy', 'Prime Sports', 'Ultimate Turf'
]) AS b_name;

-- 11. SEED ORDERS (15)
INSERT INTO public.orders (id, user_id, total_amount, status, delivery_status, created_at, is_mock)
SELECT
    gen_random_uuid(),
    (SELECT id FROM public.users WHERE is_mock = true ORDER BY random() LIMIT 1),
    (random() * 25000 + 500)::numeric(10,2),
    (ARRAY['Completed', 'Pending', 'Failed'])[1 + (floor(random() * 3))::int],
    (ARRAY['Delivered', 'In Transit', 'Processing', 'Cancelled'])[1 + (floor(random() * 4))::int],
    NOW() - (random() * interval '60 days'),
    true
FROM generate_series(1, 15);

-- 12. SEED BOOKINGS (25)
INSERT INTO public.bookings (id, user_id, provider_id, service_type, booking_date, status, amount, created_at, is_mock)
SELECT
    gen_random_uuid(),
    (SELECT id FROM public.users WHERE is_mock = true ORDER BY random() LIMIT 1),
    (SELECT id FROM public.users WHERE is_mock = true ORDER BY random() LIMIT 1),
    (ARRAY['Scorer', 'Umpire', 'Coach', 'Ground'])[1 + (floor(random() * 4))::int],
    NOW() + (random() * interval '30 days'),
    (ARRAY['Confirmed', 'Pending', 'Completed', 'Cancelled'])[1 + (floor(random() * 4))::int],
    (random() * 5000 + 500)::numeric(10,2),
    NOW() - (random() * interval '10 days'),
    true
FROM generate_series(1, 25);

-- 13. SEED REVIEWS (60)
INSERT INTO public.reviews (id, author_id, target_id, target_type, rating, comment, is_mock)
SELECT
    gen_random_uuid(),
    (SELECT id FROM public.users WHERE is_mock = true ORDER BY random() LIMIT 1),
    -- We can't easily perform polymorphic joins in random selection here without CTEs effectively,
    -- so we will just pick random product IDs for now as they are the most common targets.
    -- In a real scenario we'd mix products, services etc.
    (SELECT id FROM public.products WHERE is_mock = true ORDER BY random() LIMIT 1),
    'Product',
    (floor(random() * 5) + 1)::int,
    (ARRAY['Great product!', 'Value for money.', 'Decent quality.', 'Highly recommended.', 'Not as described.'])[1 + (floor(random() * 5))::int],
    true
FROM generate_series(1, 60);


/* 
  NOTE: Innings and Balls generation is complex and will be handled in a separate step 
  or via a PL/pgSQL block if this script is executed in a context that supports it.
  For simplicity in this dump, we will skip complex ball-by-ball generation here 
  and handle it via specific logic updates if needed, or a second script.
*/
