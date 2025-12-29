BEGIN;
SELECT plan(3);

-- add users to system (should all two profiles to profiles table)
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


-- test whether the users have logged in
SELECT set_has(
    'select id from auth.users',
    $$VALUES 
    ('54a17113-6c72-454d-921e-3636ed7b7ac1'::uuid),
    ('f0ddc881-d1b0-4e2b-a346-9a32fb6845b2'::uuid)$$,
    'Mock users should be logged in'
);

-- as a non loggin user, check if you can see data
SET local role anon;
SELECT set_has(
    'select id, points, rank, username from profiles',
    $$VALUES 
    ('54a17113-6c72-454d-921e-3636ed7b7ac1'::uuid, 1000::numeric, 1::numeric, 'PlayerOne'),
    ('f0ddc881-d1b0-4e2b-a346-9a32fb6845b2'::uuid, 1000::numeric, 1::numeric, 'PlayerTwo')$$,
    'Non loggin in users should see any part of the profiles table'
);

-- as a logged in user, can you see the data
SET local role authenticated;
SELECT set_has(
    'select id, points, rank, username from profiles',
    $$VALUES 
    ('54a17113-6c72-454d-921e-3636ed7b7ac1'::uuid, 1000::numeric, 1::numeric, 'PlayerOne'),
    ('f0ddc881-d1b0-4e2b-a346-9a32fb6845b2'::uuid, 1000::numeric, 1::numeric, 'PlayerTwo')$$,
    'Logged in users should see any part of the profiles table'
);


SELECT * FROM finish();
ROLLBACK;

