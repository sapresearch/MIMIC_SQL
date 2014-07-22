---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl F and replace 'hourlyurine_column_t' with something unique.
-- 2. THE OUTPUTS HERE MUST MATCH THE OUTPUT OF YOUR FUNCTION
create or replace force type hourlyurine_column_t as object 
(SUBJECT_ID	NUMBER(7,0),
 ICUSTAY_ID	NUMBER(7,0),
 DAY_HOUR	TIMESTAMP,
 VOLUME  NUMBER(7,0),
);

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl + F, and replace 'hourlyurine_t' with a unique name
create or replace type hourlyurine_t as table of hourlyurine_column_t;

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl+F and replace 'find_max_labs_for_id' with name of function 
-- 2. specify your inputs: q_lab_name in D_LABITEMS.TEST_NAME%type
create or replace function hourly_urine()
return hourlyurine_t as
  v_ret   hourlyurine_t;
begin
  select 
  cast(
  multiset(
  -- PUT YOUR QUERY FROM HERE...
SELECT icud.subject_id,
       icud.icustay_id,
       TRUNC(ie.charttime,'HH24') AS day_hour,
       SUM(volume)                AS volume      
FROM ioevents ie,
     icustay_detail icud
--THE URINARY ITEM IDS
WHERE ie.itemid IN ( 651, 715, 55, 56, 57, 61, 65, 69, 85, 94, 96, 288, 405, 428, 473, 2042, 2068, 2111, 2119, 2130, 1922, 2810, 2859, 3053, 3462, 3519, 3175, 2366, 2463, 2507, 2510, 2592, 2676, 3966, 3987, 4132, 4253, 5927 )
  AND icud.icustay_age_group = 'adult'
  AND icud.icustay_id        = ie.icustay_id
  --AND icud.subject_id < 100
GROUP BY icud.subject_id,
         icud.icustay_id,
         TRUNC(ie.charttime,'HH24')
ORDER BY icud.subject_id,
         icud.icustay_id,
         day_hour
  -- TILL HERE  
    ) 
    as hourlyurine_t)
    into
      v_ret
    from 
      dual;

  return v_ret;
  
end hourly_urine; -- CHANGE ME

-- THIS SHOWS HOW TO CALL THE FUNCTION
select * from table(hourly_urine('5901'));