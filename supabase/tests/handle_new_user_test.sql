BEGIN;
SELECT plan(4);

-- create a user
SET local role postgres;
INSERT INTO auth.users (id, role, email, created_at, raw_user_meta_data)
VALUES
  (
    '54a17113-6c72-454d-921e-3636ed7b7ac1',
    'authenticated',
    'player1@example.com',
    CURRENT_TIMESTAMP,
    '{"username":"PlayerOne"}' -- Your custom metadata
  );

-- test to see if you has logged in 
SELECT set_has(
    'select id from auth.users',
    $$VALUES 
    ('54a17113-6c72-454d-921e-3636ed7b7ac1'::uuid)$$,
    'Mock user should be logged in'
);

-- test whether user can see their records are in profiles and game state
SET local role authenticated;
SET local "request.jwt.claims" = '{"sub":"54a17113-6c72-454d-921e-3636ed7b7ac1", "role": "authenticated" }';

SELECT set_has(
    'select id from profiles',
    $$VALUES ('54a17113-6c72-454d-921e-3636ed7b7ac1'::uuid)$$,
    'Created auth user should have a profiles record'
);

SELECT set_has(
    'select id from game_state',
    $$VALUES ('54a17113-6c72-454d-921e-3636ed7b7ac1'::uuid)$$,
    'Created auth user should have a game state record'
);

-- try and create another user with the same username, expect an error
SELECT throws_ok(
    $$
      SET local role postgres;
      INSERT INTO auth.users (id, role, email, created_at, raw_user_meta_data)
      VALUES
        (
          '57d05ecb-87d9-4138-b7f8-a61adb281460',
          'authenticated',
          'player2@example.com',
          CURRENT_TIMESTAMP,
          '{"username":"PlayerOne"}' -- Your custom metadata
        );
    $$,
    'P0001',
    'Username "PlayerOne" is already taken.',
    'Should get an error if a user logs in with the same username as someone else'

);

SELECT * FROM finish();
ROLLBACK;
