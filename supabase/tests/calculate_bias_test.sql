BEGIN;
SELECT plan(2);

-- check if function exists
SELECT has_function('calculate_bias');

-- get two values and check if the function has the correct output
WITH test_vars AS (
    SELECT 
        (floor(random() * 100000000000) + 1)::numeric AS r1,
        (floor(random() * 100000000000) + 1)::numeric AS r2
)
SELECT results_eq(
    format('SELECT round(public.calculate_bias(%L, %L)::numeric, 8)', r1, r2),
    format('VALUES (round((1/(1+exp(-3 * ((%L::double precision - %L::double precision) / %L::double precision))))::numeric, 8))', r1, r2, r2),
    'calculate bias matches at 8 decimal places'
) FROM test_vars;


SELECT * FROM finish();
ROLLBACK;
