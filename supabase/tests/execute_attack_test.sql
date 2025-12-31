BEGIN;
SELECT plan(21);

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
SELECT throws_ok(
    $$SELECT execute_attack('54a17113-6c72-454d-921e-3636ed7b7ac1', '54a17113-6c72-454d-921e-3636ed7b7ac1')::jsonb$$, 
    'attacker and defender are the same', 
    'Shouldnt be able to attack yourself' 
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

    -- make sure heat value is 0 AND last_attacked_timestamp is null
    SELECT results_eq(
      $$select last_heat_value, last_attacked_timestamp from public.game_state where id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2'$$, 
      $$VALUES (0::real, null::timestamptz)$$,
      'Heat value should be 0 and attack timestamp should be null'
    );

    SELECT results_eq(
      $$select execute_attack('54a17113-6c72-454d-921e-3636ed7b7ac1', 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2') ->> 'winner'$$,
      $$VALUES ('54a17113-6c72-454d-921e-3636ed7b7ac1')$$,
      'Mock attacker should win'
    );

    -- check that a for defender random preroll has been created after an attack
    SELECT ok(
        (SELECT last_preroll_value FROM public.game_state WHERE id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2') BETWEEN 0 AND 100,
        'Mock defenders preroll should be a whole number between 0 and 100'
    );

    -- make sure defender heat value is 1 AND last_attacked_timestamp is now
    SELECT results_eq(
      $$select last_heat_value, last_attacked_timestamp from public.game_state where id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2'$$, 
      $$VALUES (1::real, now()::timestamptz)$$,
      'After first attack, defender Heat value should be 1 and attack timestamp should be now'
    );

    -- make sure the attacker attack streak increments if attacker wins
    SELECT results_eq(
      $$select attack_streak from public.game_state where id = '54a17113-6c72-454d-921e-3636ed7b7ac1'$$,
      $$VALUES (1::smallint)$$, 
      'Attack streak should increment if attacker won'
    );

  -- when the attacker wins a second time, see if heat value and attack streak has been applied to attacker point winnings
    UPDATE public.game_state SET last_preroll_value = 0 WHERE id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2';
    UPDATE public.profiles SET points = 10000 WHERE id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2';
    UPDATE public.profiles SET points = 1000000 WHERE id = '54a17113-6c72-454d-921e-3636ed7b7ac1';

    WITH result AS (
        SELECT execute_attack('54a17113-6c72-454d-921e-3636ed7b7ac1', 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2') AS payload
    )
    SELECT is(
            (payload->>'winner')::uuid, 
            '54a17113-6c72-454d-921e-3636ed7b7ac1'::uuid, 
            'The attacker should be the winner a second time'
        ) FROM result 

        UNION ALL 

        SELECT is(
            -- ACTUAL: Extract the transfer from payload and apply your local streak check
            round((payload->>'points transfer')::numeric * (1 + 0.01 * ((payload->>'new attack streak')::numeric - 1)))::numeric, 

            -- EXPECTED: The manual calculation
            (
                round(
                    10000::float * -- Defender Points
                    (
                        abs(
                            (payload->>'attacker roll')::float - 
                            (payload->>'defender preroll')::float
                        ) / 100.0
                    ) * 0.6::float * -- Heat
                    1.01         -- Streak Multiplier
                )
            )::numeric,

            'Heat & attack streak > 0, attacker point transfer should apply'
        )
    FROM result;    

  -- set defender preroll to 100
  -- set defender points to 1000000 and attacker points to 10 
  -- test for updates
  -- test when execute attack that defender should win

    UPDATE public.game_state SET last_preroll_value = 100 WHERE id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2';
    UPDATE public.profiles SET points = 10000 WHERE id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2';
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
        $$VALUES (1000000::numeric, 10000::numeric)$$, 
        'Mock attacker & defender should update to 10000 and 1000000'
    );

    SELECT results_eq(
      $$select last_preroll_value from public.game_state where id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2'$$, 
      $$VALUES (100::int8)$$, 
      'Mock defenders preroll should be updated to 100'
    );

    -- if attacker wins, then defender wins heat values should apply
    WITH result AS (
        SELECT execute_attack('54a17113-6c72-454d-921e-3636ed7b7ac1', 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2') AS payload
    )
    SELECT is(
            (payload->>'winner')::uuid, 
            'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2'::uuid, 
            'The defender should win after attack won'
        ) FROM result 

    UNION ALL 

        SELECT is(
            -- ACTUAL: Extract the transfer from payload and apply your local streak check
            (payload->>'points transfer')::numeric, 

            -- EXPECTED: The manual calculation
            round(
                  1000000::float * -- Attacker Points
                  (
                      abs(
                          (payload->>'attacker roll')::float - 
                          (payload->>'defender preroll')::float
                      ) / 100.0
                  ) * POWER(0.6, 2)::float -- Heat
            )::numeric,

            'Heat > 0, defender point transfer should apply'
        ) FROM result;  

    -- make sure the attacker attack streak goes 0 if attacker loses
    SELECT results_eq(
      $$select attack_streak from public.game_state where id = '54a17113-6c72-454d-921e-3636ed7b7ac1'$$,
      $$VALUES (0::smallint)$$, 
      'Attack streak should be 0 if attacker loses'
    );

-- test for throwing error if the defender (or attacker) doesn't exist
SELECT throws_ok(
  $$select execute_attack('54a17113-6c72-454d-921e-3636ed7b7ac1', '652440b2-de38-42ca-8f6b-6dcb5609fe60')$$, 
  'P0001',
  'defender doesnt exist',
  'If mock defender doesnt exist, then fail execute attack'
);

SELECT throws_ok(
  $$select execute_attack('652440b2-de38-42ca-8f6b-6dcb5609fe60', '54a17113-6c72-454d-921e-3636ed7b7ac1')$$, 
  'P0001',
  'attacker doesnt exist',
  'If mock attacker doesnt exist, then fail execute attack'
);
  
-- defender or attacker with 0 can't attack or be attacked
UPDATE public.profiles SET points = 0 WHERE id = '54a17113-6c72-454d-921e-3636ed7b7ac1';
UPDATE public.profiles SET points = 1000 WHERE id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2';

SELECT throws_ok(
  $$SELECT execute_attack('54a17113-6c72-454d-921e-3636ed7b7ac1', 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2')$$, 
  'attacker has 0 points', 
  'execute attack should fail because attacker has 0 points'
);

UPDATE public.profiles SET points = 1000 WHERE id = '54a17113-6c72-454d-921e-3636ed7b7ac1';
UPDATE public.profiles SET points = 0 WHERE id = 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2';

SELECT throws_ok(
  $$SELECT execute_attack('54a17113-6c72-454d-921e-3636ed7b7ac1', 'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2')$$, 
  'defender has 0 points', 
  'execute attack should fail because defender has 0 points'
);

-- future: does attack appear on battle log.

SELECT * FROM finish();
ROLLBACK;
