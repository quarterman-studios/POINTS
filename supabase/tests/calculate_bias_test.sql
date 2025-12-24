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
        -- We use format() to inject the random numbers into the query string
        format('SELECT public.calculate_bias(%L, %L)', r1, r2),
        -- We calculate the expected result using the same variables
        format('VALUES (1/(1+exp(-3 * ((%L::double precision - %L::double precision) / %L::double precision))))', r1, r2, r2),
        'calculate bias should produce the correct bias'
) FROM test_vars;

SELECT * FROM finish();
ROLLBACK;
