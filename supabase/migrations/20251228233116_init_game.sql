-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "pgtap" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

-- 2. TABLES (Create if not exist)
CREATE TABLE IF NOT EXISTS "public"."game_state" (
    "id" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "last_preroll_value" bigint DEFAULT '0'::bigint,
    "last_preroll_timestamp" timestamp with time zone,
    "hit_tolerance" smallint DEFAULT '3'::smallint,
    "streak" numeric DEFAULT '0'::numeric,
    "can_preroll" boolean DEFAULT false NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "points" numeric NOT NULL,
    "rank" numeric NOT NULL,
    "username" "text",
    CONSTRAINT "non_negative_check" CHECK (("points" >= (0)::numeric)),
    CONSTRAINT "profiles_username_check" CHECK (("length"("username") <= 50))
);

-- 3. CONSTRAINTS (The "Safe" Way: Drop then Add)

-- Game State Primary Key
ALTER TABLE "public"."game_state" DROP CONSTRAINT IF EXISTS "game_state_pkey";
ALTER TABLE "public"."game_state" ADD CONSTRAINT "game_state_pkey" PRIMARY KEY ("id");

-- Profiles Unique ID
ALTER TABLE "public"."profiles" DROP CONSTRAINT IF EXISTS "players_id_key";
ALTER TABLE "public"."profiles" ADD CONSTRAINT "players_id_key" UNIQUE ("id");

-- Profiles Primary Key
ALTER TABLE "public"."profiles" DROP CONSTRAINT IF EXISTS "players_pkey";
ALTER TABLE "public"."profiles" ADD CONSTRAINT "players_pkey" PRIMARY KEY ("id");

-- Game State Foreign Key
ALTER TABLE "public"."game_state" DROP CONSTRAINT IF EXISTS "game_state_id_fkey";
ALTER TABLE "public"."game_state" ADD CONSTRAINT "game_state_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;

-- Profiles Foreign Key
ALTER TABLE "public"."profiles" DROP CONSTRAINT IF EXISTS "profiles_id_fkey";
ALTER TABLE "public"."profiles" ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;

-- 4. FUNCTIONS (Using your LATEST logic from File 2)

-- Calculate Bias (Numeric Version)
CREATE OR REPLACE FUNCTION "public"."calculate_bias"("attacker_points" numeric, "defender_points" numeric) RETURNS double precision
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
  declare
    k double precision := 3.0;
    D double precision;
  begin
    D := (attacker_points::float - defender_points::float) / defender_points::float;

    if D > 5.0 then
      D := 5;
    end if;

    return 1.0 / (1.0 + exp(-1.0 * k * D));
  end;
$$;

-- Execute Attack (Your updated version with NULL checks)
CREATE OR REPLACE FUNCTION public.execute_attack(attacker_id uuid, defender_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
    attacker_points numeric := null;
    defender_points numeric := null;
    defender_preroll_value int;
    defender_hit_tolerance int;
    low_roll int;
    high_roll int; 
    r1 int;
    r2 int;
    final_roll int; 
    bias_val float;
    point_transfer numeric;     
    winner_id uuid;
  begin
    select points into attacker_points from public.profiles where id = attacker_id for update;
    select points into defender_points from public.profiles where id = defender_id for update;

    select hit_tolerance into defender_hit_tolerance from public.game_state where id = defender_id;
    
    if attacker_points is null then 
      return json_build_object('success', false, 'message', 'attacker doesnt exist');
    elsif defender_points is null then 
      return json_build_object('success', false, 'message', 'defender doesnt exist');      
    elsif attacker_points <= 0 then
      return json_build_object('success', false, 'message', 'attacker has 0 points'); 
    elsif defender_points <= 0 then 
      return json_build_object('success', false, 'message', 'defender has 0 points');
    elsif attacker_id = defender_id then 
      return json_build_object('success', false, 'message', 'attacker and defender are the same');
    elsif defender_hit_tolerance = 0 then
      return json_build_object('success', false, 'message', 'defender hit tolerance is 0');
    else

      bias_val := calculate_bias(attacker_points, defender_points);
      
      r1 := floor(random() * 100 + 1);
      r2 := floor(random() * 100 + 1);

      if r1 >= r2 then
        high_roll := r1;
        low_roll := r2;
      else
        high_roll := r2;
        low_roll := r1;
      end if;

      if (not (low_roll <= (high_roll - 50))) then
        low_roll := greatest(0, high_roll - 50);
      end if;

      final_roll := round((high_roll::float * bias_val) + (low_roll::float * (1 - bias_val)));

      select last_preroll_value into defender_preroll_value from public.game_state where id = defender_id for update;

      if final_roll > defender_preroll_value then
        winner_id = attacker_id;
        point_transfer = round((abs(final_roll::float - defender_preroll_value::float) / 100) * defender_points::float); 
        update public.profiles set points = points + point_transfer where id = attacker_id;
        update public.profiles set points = greatest(0, points - point_transfer) where id = defender_id;
      end if;
      
      if final_roll < defender_preroll_value then
        winner_id = defender_id;
        point_transfer = round((abs(final_roll::float - defender_preroll_value::float) / 100) * attacker_points::float); 
        update public.profiles set points = points + point_transfer where id = defender_id;
        update public.profiles set points = greatest(0, points - point_transfer) where id = attacker_id;
      end if;

      update public.game_state set last_preroll_value = 0 where id = defender_id;
      update public.game_state set last_preroll_timestamp = current_timestamp where id = defender_id;
      update public.game_state set can_preroll = TRUE where id = defender_id;
      update public.game_state set updated_at = current_timestamp where id = defender_id;
      update public.game_state set updated_at = current_timestamp where id = attacker_id;

      return json_build_object('success', true, 'attacker roll', final_roll, 'defender preroll', defender_preroll_value ,'winner', winner_id, 'attacker points', attacker_points, 'defender points', defender_points, 'points transfer', point_transfer);
    end if;
  end;
$function$;

-- Handle New User (Your updated version with username check)
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$begin
  if exists (select 1 from public.profiles where username = new.raw_user_meta_data ->> 'username') then
    raise exception 'Username "%" is already taken.', (new.raw_user_meta_data ->> 'username');
  end if;

  insert into public.profiles (id, username, points, rank)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'username', new.email),
    1000, 
    1
  );

  insert into public.game_state (id, streak, hit_tolerance)
  values (new.id, 0, 2);

  return new;
end;$function$;

-- Handle Delete User
CREATE OR REPLACE FUNCTION public.handle_delete_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$BEGIN
  delete from public.game_state where id = old.id;
  delete from public.profiles where id = old.id;
  return old;
END;$function$;

-- 5. TRIGGERS (Drop first to avoid duplication)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

DROP TRIGGER IF EXISTS on_auth_user_deleted ON auth.users;
CREATE TRIGGER on_auth_user_deleted BEFORE DELETE ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_delete_user();

-- 6. POLICIES (Drop first to avoid errors)
DROP POLICY IF EXISTS "anyone can see everyone " ON "public"."profiles";
CREATE POLICY "anyone can see everyone " ON "public"."profiles" FOR SELECT TO "authenticated", "anon" USING (true);

DROP POLICY IF EXISTS "auth users can only access their game state info" ON "public"."game_state";
CREATE POLICY "auth users can only access their game state info" ON "public"."game_state" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));

-- Enable RLS
ALTER TABLE "public"."game_state" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;

-- 7. GRANTS
GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON TABLE "public"."game_state" TO "anon", "authenticated", "service_role";
GRANT ALL ON TABLE "public"."profiles" TO "anon", "authenticated", "service_role";
GRANT ALL ON FUNCTION "public"."execute_attack" TO "anon", "authenticated", "service_role";