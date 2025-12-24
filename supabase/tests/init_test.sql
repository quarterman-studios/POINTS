BEGIN;
SELECT plan(2);

SELECT has_table( 'game_state' );
SELECT has_table( 'profiles' );

SELECT * FROM finish();
ROLLBACK;



