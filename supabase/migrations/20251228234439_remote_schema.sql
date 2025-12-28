drop policy "auth users can delete their own game state" on "public"."game_state";

drop policy "only auth users can delete themselves" on "public"."profiles";

drop function if exists "public"."calculate_bias"(attacker_points integer, defender_points integer);

set check_function_bodies = off;

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
$function$
;

CREATE OR REPLACE FUNCTION public.handle_delete_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$BEGIN
  delete from public.game_state where id = old.id;
  delete from public.profiles where id = old.id;
  return old;
END;$function$
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

  insert into public.game_state (id, streak, hit_tolerance)
  values (new.id, 0, 2);

  return new;
end;$function$
;


