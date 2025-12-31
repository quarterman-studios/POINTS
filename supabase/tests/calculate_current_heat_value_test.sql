BEGIN;
SELECT plan(2);

-- test where heat val is 5 and time is 8 hours ago (should be 1)
SELECT results_eq(
    $$select calculate_current_heat_value(5, current_timestamp - (8 * interval '1 hour'))$$, 
    $$VALUES (1::double precision)$$,
    'Heat value of 5 when 8 hours have past should be 1'
);

-- test when time is null
SELECT results_eq(
    $$select calculate_current_heat_value(5, null)$$, 
    $$VALUES (5::double precision)$$,
    'Heat value of 5 when timestamp is null should be 5'
);

SELECT * FROM finish();
ROLLBACK;
