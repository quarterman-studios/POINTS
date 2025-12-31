create extension if not exists "pg_cron" with schema "pg_catalog";

alter table "public"."game_state" drop column "hit_tolerance";

alter table "public"."game_state" add column "attack_streak" smallint not null default '0'::smallint;

alter table "public"."game_state" add column "last_attacked_timestamp" timestamp with time zone;

alter table "public"."game_state" add column "last_heat_value" real not null default '0'::real;

alter table "public"."game_state" alter column "last_preroll_timestamp" set default (now() AT TIME ZONE 'utc'::text);

alter table "public"."game_state" alter column "last_preroll_value" set default round((random() * (100)::double precision));

alter table "public"."game_state" alter column "updated_at" set default (now() AT TIME ZONE 'utc'::text);

alter table "public"."game_state" add constraint "game_state_last_preroll_value_check" CHECK (((last_preroll_value >= 0) AND (last_preroll_value <= 100))) not valid;

alter table "public"."game_state" validate constraint "game_state_last_preroll_value_check";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.calculate_current_heat_value(last_heat_value double precision, last_attacked_timestamp timestamp with time zone)
 RETURNS double precision
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$BEGIN
  return GREATEST(0, last_heat_value - (0.5 * (EXTRACT(EPOCH FROM (now() - COALESCE(last_attacked_timestamp, now()))) / 3600)));
END;$function$
;

CREATE OR REPLACE FUNCTION public.execute_attack(attacker_id uuid, defender_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$declare
    attacker_points numeric := null;
    defender_points numeric := null;
    
    defender_yield_percent float;
    defender_lhv int; 
    defender_lat timestamptz;

    attacker_win_streak int;

    defender_preroll_value int;
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
    
    if attacker_points is null then 
      raise exception 'attacker doesnt exist';
    elsif defender_points is null then 
      raise exception 'defender doesnt exist';    
    elsif attacker_points <= 0 then
      raise exception 'attacker has 0 points'; 
    elsif defender_points <= 0 then 
      raise exception 'defender has 0 points';
    elsif attacker_id = defender_id then 
      raise exception 'attacker and defender are the same';
    else

      bias_val := calculate_bias(attacker_points, defender_points);
      
      r1 := round(random() * 100);
      r2 := round(random() * 100);

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

      select last_heat_value into defender_lhv from public.game_state where id = defender_id for update;

      select last_attacked_timestamp into defender_lat from public.game_state where id = defender_id for update;

      select attack_streak into attacker_win_streak from public.game_state where id = attacker_id for update;

      defender_yield_percent := POWER(0.6,calculate_current_heat_value(defender_lhv, defender_lat));

      if final_roll > defender_preroll_value then
        winner_id = attacker_id;

        point_transfer = round(defender_yield_percent * ((abs(final_roll::float - defender_preroll_value::float) / 100) * defender_points::float)); 

        update public.profiles set points = round(points + (point_transfer * (1+(attacker_win_streak * 0.01)))) where id = attacker_id;
        update public.profiles set points = greatest(0, points - point_transfer) where id = defender_id;

        update public.game_state set attack_streak = attack_streak + 1 where id = attacker_id;
        attacker_win_streak := attacker_win_streak + 1;
      end if;
      
      if final_roll < defender_preroll_value then
        winner_id = defender_id;

        point_transfer = round(defender_yield_percent * ((abs(final_roll::float - defender_preroll_value::float) / 100) * attacker_points::float)); 

        update public.profiles set points = points + point_transfer where id = defender_id;
        update public.profiles set points = greatest(0, points - point_transfer) where id = attacker_id;

        update public.game_state set attack_streak = 0 where id = attacker_id;
        attacker_win_streak := 0;
      end if;

      update public.game_state set last_preroll_value = round(random() * 100) where id = defender_id;
      update public.game_state set last_preroll_timestamp = current_timestamp where id = defender_id;
      update public.game_state set can_preroll = TRUE where id = defender_id;
      update public.game_state set updated_at = current_timestamp where id = defender_id;
      
      update public.game_state set last_heat_value = calculate_current_heat_value(defender_lhv, defender_lat) + 1 where id = defender_id;
      update public.game_state set last_attacked_timestamp = now() where id = defender_id;

      update public.game_state set updated_at = current_timestamp where id = attacker_id;

      return json_build_object('attacker roll', final_roll, 'defender preroll', defender_preroll_value ,'winner', winner_id, 'attacker points', attacker_points, 'defender points', defender_points, 'points transfer', point_transfer, 'defender yield percent', defender_yield_percent, 'old last heat value', calculate_current_heat_value(defender_lhv, defender_lat), 'new attack streak', attacker_win_streak);
    end if;
  end;$function$
;

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

  insert into public.game_state (id, streak)
  values (new.id, 0);

  return new;
end;$function$
;


