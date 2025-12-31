BEGIN;
SELECT plan(13);

-- check if it exists
SELECT has_function('execute_attack');

-- add users to system
SET local role postgres;
INSERT INTO auth.users (id, role, email, created_at, raw_user_meta_data)
VALUES
  (
    '54a17113-6c72-454d-921e-3636ed7b7ac1',
    'authenticated',
    'attacker@example.com',
    CURRENT_TIMESTAMP,
    '{"username":"Attacker"}' -- Your custom metadata
  ),
  (
    'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2',
    'authenticated',
    'defender@example.com',
    CURRENT_TIMESTAMP,
    '{"username":"Defender"}' -- Your custom metadata
  );


-- test whether the users have logged in
SELECT set_has(
    'select id from auth.users',
    $$VALUES 
    ('54a17113-6c72-454d-921e-3636ed7b7ac1'::uuid),
    ('f0ddc881-d1b0-4e2b-a346-9a32fb6845b2'::uuid)$$,
    'Mock users should be logged in'
);

-- check if execute_attack attacker attacking themselves
SELECT results_eq(
    $$SELECT execute_attack('54a17113-6c72-454d-921e-3636ed7b7ac1', '54a17113-6c72-454d-921e-3636ed7b7ac1')::jsonb$$, 
    $$VALUES (json_build_object('message', 'attacker and defender are the same', 'success', false)::jsonb)$$, 
    'Attack cant attack themselves' 
);

-- does execute attack actually work (winner wins right amount and loser does reverse)
    -- set defender preroll to 0
    -- set defender points to 10 and attacker points to 1000000
    -- test for updates
    -- test when execute attack that attacker should win

    UPDATE public.game_state SET last_preroll_value = 0 WHERE id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2';
    UPDATE public.profiles SET points = 10 WHERE id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2';
    UPDATE public.profiles SET points = 1000000 WHERE id = '54a17113-6c72-454d-921e-3636ed7b7ac1';

    SELECT results_eq(
        $$
          WITH 
            attacker as (select * from public.profiles where id = '54a17113-6c72-454d-921e-3636ed7b7ac1'),
            defender as (select * from public.profiles where id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2')
          SELECT 
            attacker.points,
            defender.points
          FROM 
            attacker,
            defender
        $$,
        $$VALUES (1000000::numeric, 10::numeric)$$, 
        'Mock attacker & defender points should update to 10 and 1000000'
    );

    SELECT results_eq(
      $$select last_preroll_value from public.game_state where id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2'$$, 
      $$VALUES (0::int8)$$, 
      'Mock defenders preroll should be updated to 0'
    );

    SELECT results_eq(
      $$select execute_attack('54a17113-6c72-454d-921e-3636ed7b7ac1', 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2') ->> 'winner'$$,
      $$VALUES ('54a17113-6c72-454d-921e-3636ed7b7ac1')$$,
      'Mock attacker should win'
    );

    -- set defender preroll to 100
    -- set defender points to 1000000 and attacker points to 10 
    -- test for updates
    -- test when execute attack that defender should win

    UPDATE public.game_state SET last_preroll_value = 100 WHERE id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2';
    UPDATE public.profiles SET points = 1000000 WHERE id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2';
    UPDATE public.profiles SET points = 10 WHERE id = '54a17113-6c72-454d-921e-3636ed7b7ac1';

    SELECT results_eq(
        $$
          WITH 
            attacker as (select * from public.profiles where id = '54a17113-6c72-454d-921e-3636ed7b7ac1'),
            defender as (select * from public.profiles where id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2')
          SELECT 
            attacker.points,
            defender.points
          FROM 
            attacker,
            defender
        $$,
        $$VALUES (10::numeric, 1000000::numeric)$$, 
        'Mock attacker & defender should update to 10 and 1000000'
    );

    SELECT results_eq(
      $$select last_preroll_value from public.game_state where id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2'$$, 
      $$VALUES (100::int8)$$, 
      'Mock defenders preroll should be updated to 100'
    );

    SELECT results_eq(
      $$select execute_attack('54a17113-6c72-454d-921e-3636ed7b7ac1', 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2') ->> 'winner'$$,
      $$VALUES ('f0ddc881-d1b0-4e2b-a346-9a32fb6845b2')$$,
      'Mock defender should win'
    );

-- test for throwing error if the defender (or attacker) doesn't exist
SELECT results_eq(
  $$select execute_attack('54a17113-6c72-454d-921e-3636ed7b7ac1', '652440b2-de38-42ca-8f6b-6dcb5609fe60') ->> 'success'$$, 
  $$VALUES (FALSE::text)$$,
  'If mock defender doesnt exist, then fail execute attack'
);

SELECT results_eq(
  $$select execute_attack('652440b2-de38-42ca-8f6b-6dcb5609fe60', '54a17113-6c72-454d-921e-3636ed7b7ac1') ->> 'success'$$, 
  $$VALUES (FALSE::text)$$,
  'If mock attacker doesnt exist, then fail execute attack'
);
  
-- defender or attacker with 0 can't attack or be attacked
UPDATE public.profiles SET points = 0 WHERE id = '54a17113-6c72-454d-921e-3636ed7b7ac1';
UPDATE public.profiles SET points = 1000 WHERE id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2';

SELECT results_eq(
  $$SELECT execute_attack('54a17113-6c72-454d-921e-3636ed7b7ac1', 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2') ->> 'message'$$, 
  $$VALUES ('attacker has 0 points')$$, 
  'execute attack should fail because attacker has 0 points'
);

UPDATE public.profiles SET points = 1000 WHERE id = '54a17113-6c72-454d-921e-3636ed7b7ac1';
UPDATE public.profiles SET points = 0 WHERE id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2';

SELECT results_eq(
  $$SELECT execute_attack('54a17113-6c72-454d-921e-3636ed7b7ac1', 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2') ->> 'message'$$, 
  $$VALUES ('defender has 0 points')$$, 
  'execute attack should fail because defender has 0 points'
);

-- future: does loss appear on battle log.

SELECT * FROM finish();
ROLLBACK;
