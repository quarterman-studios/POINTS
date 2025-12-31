BEGIN;
SELECT plan(3);

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
  ),
  (
    'f0ddc881-d1b0-4e2b-a346-9a32fb6845b2',
    'authenticated',
    'player2@example.com',
    CURRENT_TIMESTAMP,
    '{"username":"PlayerTwo"}' -- Your custom metadata
  );

-- test to see if you has logged in 
SELECT set_has(
    'select id from auth.users',
    $$VALUES 
    ('54a17113-6c72-454d-921e-3636ed7b7ac1'::uuid)$$,
    'Mock user should be logged in'
);

-- test whether user can see their game_state
SET local role authenticated;
SET local "request.jwt.claims" = '{"sub":"54a17113-6c72-454d-921e-3636ed7b7ac1", "role": "authenticated" }';

SELECT results_eq(
    'select * from game_state', 
    $$VALUES('54a17113-6c72-454d-921e-3636ed7b7ac1'::uuid, NULL::timestamptz, 0::int8, NULL::timestamptz, 0::numeric, FALSE)$$, 
    'Auth users should see only own game state'
);

-- sign out, and test to see whether anon can see user's game_state
SET local role anon;

SELECT is_empty(
    'select * from game_state', 
    $$Anon users shouldnt see any game state$$
);

SELECT * FROM finish();
ROLLBACK;
