BEGIN;
SELECT plan(1);

SELECT results_eq()

SELECT * FROM finish();
ROLLBACK;
