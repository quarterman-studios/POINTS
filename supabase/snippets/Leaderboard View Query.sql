-- Create an index to make sorting fast (Crucial for performance)
CREATE INDEX IF NOT EXISTS "profiles_points_idx" ON "public"."profiles" ("points" DESC);

-- Create the view
CREATE OR REPLACE VIEW "public"."leaderboard" AS
SELECT 
  id,
  username,
  points,
  -- Calculate rank dynamically
  RANK() OVER (ORDER BY points DESC) as rank,
  ROW_NUMBER() OVER (ORDER BY points DESC, created_at ASC) as row_number
FROM 
  "public"."profiles";

-- Grant access so your frontend can query it
GRANT SELECT ON "public"."leaderboard" TO "anon", "authenticated", "service_role";