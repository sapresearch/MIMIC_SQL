---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl F and replace 'uo_aki_column_t' with something unique.
-- 2. THE OUTPUTS HERE MUST MATCH THE OUTPUT OF YOUR FUNCTION
create or replace force type uo_aki_column_t as object 
(SUBJECT_ID	NUMBER(7,0),
 ICUSTAY_ID NUMBER(7,0),
 uo_aki NUMBER(7,0)
);

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl + F, and replace 'uo_aki_subs_t' with a unique name
create or replace type uo_aki_subs_t as table of uo_aki_column_t;

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl+F and replace 'uo_aki' with name of function 
-- 2. specify your inputs: q_lab_name in D_LABITEMS.TEST_NAME%type
create or replace function uo_aki(q_lab_item in LABEVENTS.ITEMID%type)
return uo_aki_subs_t as
  v_ret   uo_aki_subs_t;
begin
  select 
  cast(
  multiset(
  -- PUT YOUR QUERY FROM HERE...
WITH

hourly_urine_measurements AS
(
SELECT icud.subject_id,
       icud.icustay_id,
       TRUNC(ie.charttime,'HH24') AS day_hour,
       SUM(volume)                AS volume      
FROM MIMIC2V26.ioevents ie,
     MIMIC2V26.icustay_detail icud
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
  )
  
--select count(distinct icustay_id) from hourly_urine_measurements;--------------------------------------


--------------------------------------------------------------------------------
--      2.2 FIND THE MAXIMUM ICU WEIGHT FOR THE COHORT, TO NORMALIZE UO
--------------------------------------------------------------------------------  
,max_icustay_weight AS
  ( SELECT DISTINCT icud.subject_id,
    icud.icustay_id,
    MAX(ce.value1num) AS max_weight
  FROM MIMIC2V26.chartevents ce,
       MIMIC2V26.icustay_detail icud
  WHERE itemid              IN ( 580, 1393, 762, 1395 )
 -- AND icud.subject_id < 100
  AND ce.icustay_id          = icud.icustay_id
  AND icud.icustay_age_group = 'adult'
  AND ce.value1num IS NOT NULL
  AND ce.value1num >= 30 -- Arbitrary value to eliminate 0
  GROUP BY icud.subject_id,
           icud.icustay_id
  ORDER BY icud.icustay_id
  )
 --select * from max_icustay_weight;-------------------------------------------
  
--------------------------------------------------------------------------------
--      2.3 COMPUTE THE NORMALIZED URINARY OUTPUT
--------------------------------------------------------------------------------  
  , normalised_uo_measurements AS
  (SELECT hum.subject_id,
    hum.icustay_id,
    miw.max_weight,
    hum.day_hour,
    hum.volume,
    hum.volume / max_weight AS normalised_volume,
    
    -- FOR THE 6HR AKI VALUES------------------------------------------------------   
    /* Count the number of measurements in the next 6 hours (not including current) */
    COUNT ( hum.volume ) OVER ( partition BY hum.subject_id, hum.icustay_id order by hum.day_hour RANGE BETWEEN INTERVAL '1' HOUR FOLLOWING AND INTERVAL '6' HOUR FOLLOWING ) measurements_in_six_hr,
    
    /* Count the number of measurements in the next 6 hours which meet the defined threshold */
    SUM (
    CASE
      WHEN ( ( hum.volume / miw.max_weight ) <= 0.5 )
      THEN 1
      ELSE 0
    END ) OVER ( partition BY hum.subject_id, hum.icustay_id order by hum.day_hour RANGE BETWEEN INTERVAL '1' HOUR FOLLOWING AND INTERVAL '6' HOUR FOLLOWING ) aki1_uo_in_six_hr,
    
    /* Calculate the total volume of urine in the next 6 hours */
    SUM ( hum.volume / max_weight ) OVER ( partition BY hum.subject_id, hum.icustay_id order by hum.day_hour RANGE BETWEEN INTERVAL '1' HOUR FOLLOWING AND INTERVAL '6' HOUR FOLLOWING ) normalised_uo_in_six_hr,
    
    -- FOR THE 12HR AKI VALUES------------------------------------------------------     
    /* Count the number of measurements in the next 12 hours (not including current) */
    COUNT ( hum.volume ) OVER ( partition BY hum.subject_id, hum.icustay_id order by hum.day_hour RANGE BETWEEN INTERVAL '1' HOUR FOLLOWING AND INTERVAL '12' HOUR FOLLOWING ) measurements_in_twelve_hr,

    /* Count the number of measurements in the next 12 hours which meet the defined threshold */
    SUM (
    CASE
      WHEN ( ( hum.volume / miw.max_weight ) <= 0.5 )
      THEN 1
      ELSE 0
    END ) OVER ( partition BY hum.subject_id, hum.icustay_id order by hum.day_hour RANGE BETWEEN INTERVAL '1' HOUR FOLLOWING AND INTERVAL '12' HOUR FOLLOWING ) aki2_uo_in_twelve_hr,
    /* Calculate the total volume of urine in the next 12 hours */
    SUM ( hum.volume / max_weight ) OVER ( partition BY hum.subject_id, hum.icustay_id order by hum.day_hour RANGE BETWEEN INTERVAL '1' HOUR FOLLOWING AND INTERVAL '12' HOUR FOLLOWING ) normalised_uo_in_twelve_hr,
    
    -- FOR THE 24HR AKI VALUES------------------------------------------------------         
    COUNT ( hum.volume ) OVER ( partition BY hum.subject_id, hum.icustay_id order by hum.day_hour RANGE BETWEEN INTERVAL '1' HOUR FOLLOWING AND INTERVAL '24' HOUR FOLLOWING ) measurements_in_twentyfour_hr,
    /* Count the number of measurements in the next 24 hours which meet the defined threshold */
    SUM (
    CASE
      WHEN ( ( hum.volume / miw.max_weight ) <=0.3 )
      THEN 1
      ELSE 0
    END ) OVER ( partition BY hum.subject_id, hum.icustay_id order by hum.day_hour RANGE BETWEEN INTERVAL '1' HOUR FOLLOWING AND INTERVAL '24' HOUR FOLLOWING ) aki3_uo_in_twentyfour_hr,
    /* Calculate the total volume of urine in the next 24 hours */
    SUM ( hum.volume / max_weight ) OVER ( partition BY hum.subject_id, hum.icustay_id order by hum.day_hour RANGE BETWEEN INTERVAL '1' HOUR FOLLOWING AND INTERVAL '24' HOUR FOLLOWING ) normalised_uo_in_twentyfour_hr,
    /* Count the number of measurements in the next 12 hours which meet the defined threshold */
    SUM (
    CASE
      WHEN ( ( hum.volume / miw.max_weight ) = 0 )
      THEN 1
      ELSE 0
    END ) OVER ( partition BY hum.subject_id, hum.icustay_id order by hum.day_hour RANGE BETWEEN INTERVAL '1' HOUR FOLLOWING AND INTERVAL '12' HOUR FOLLOWING ) aki4_uo_in_twelve_hr
  
  FROM hourly_urine_measurements hum,
    max_icustay_weight miw
  WHERE hum.icustay_id = miw.icustay_id
  )
  --select count(distinct ICUSTAY_ID) from normalised_uo_measurements;------------------------------------
  
--------------------------------------------------------------------------------
--      2.4 AKI ACCORDING TO URINARY OUTPUT
--------------------------------------------------------------------------------  
  ,uo_aki_measurements AS
  (SELECT num.subject_id,
    num.icustay_id,
    num.max_weight,
    num.day_hour,
    num.volume,
    num.normalised_volume,
    num.measurements_in_six_hr,
    num.aki1_uo_in_six_hr,
    num.normalised_uo_in_six_hr,
    num.measurements_in_twelve_hr,
    num.aki2_uo_in_twelve_hr,
    num.normalised_uo_in_twelve_hr,
    num.measurements_in_twentyfour_hr,
    num.aki3_uo_in_twentyfour_hr,
    num.normalised_uo_in_twentyfour_hr,
    num.aki4_uo_in_twelve_hr,
    CASE
      WHEN ( num.measurements_in_six_hr >= 3
      AND num.aki1_uo_in_six_hr          > 5 )
      THEN 1
      ELSE 0
    END AS uo_aki1,
    CASE
      WHEN ( num.measurements_in_twelve_hr >= 6
      AND num.aki2_uo_in_twelve_hr          > 11 )
      THEN 1
      ELSE 0
    END AS uo_aki2,
    CASE
      WHEN ( num.measurements_in_twentyfour_hr >= 12
      AND num.aki3_uo_in_twentyfour_hr          > 23 )
      THEN 1
      ELSE 0
    END AS uo_aki3,
    CASE
      WHEN ( num.measurements_in_twelve_hr >= 6
      AND num.aki4_uo_in_twelve_hr          > 11 )
      THEN 1
      ELSE 0
    END AS uo_aki4
  FROM normalised_uo_measurements num
  ) 
--select count(distinct icustay_id) from uo_aki_measurements;-------------------------------------------
  
  
--------------------------------------------------------------------------------
--      2.5 COMPUTE AKI NUMERICAL VALUES
--------------------------------------------------------------------------------    
  ,uo_aki_flag AS
  (SELECT uam.subject_id,
    uam.icustay_id,
    uam.max_weight,
    uam.day_hour,
    uam.volume,
    uam.normalised_volume,
    uam.measurements_in_six_hr,
    uam.aki1_uo_in_six_hr,
    uam.normalised_uo_in_six_hr,
    uam.measurements_in_twelve_hr,
    uam.aki2_uo_in_twelve_hr,
    uam.normalised_uo_in_twelve_hr,
    uam.measurements_in_twentyfour_hr,
    uam.aki3_uo_in_twentyfour_hr,
    uam.normalised_uo_in_twentyfour_hr,
    uam.aki4_uo_in_twelve_hr,
    uam.uo_aki1,
    uam.uo_aki2,
    uam.uo_aki3,
    uam.uo_aki4,
    CASE
      WHEN ( uam.uo_aki3 = 1
      OR uam.uo_aki4     = 1 )
      THEN 3
      WHEN ( uam.uo_aki2 = 1 )
      THEN 2
      WHEN ( uam.uo_aki1 = 1 )
      THEN 1
      ELSE 0
    END AS uo_aki
  FROM uo_aki_measurements uam
  )
  
  SELECT DISTINCT SUBJECT_ID, ICUSTAY_ID, UO_AKI FROM uo_aki_flag
         

  -- TILL HERE  
    ) 
    as uo_aki_subs_t)
    into
      v_ret
    from 
      dual;

  return v_ret;
  
end uo_aki; -- CHANGE ME

-- THIS SHOWS HOW TO CALL THE FUNCTION
select * from table(uo_aki(''));