---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl F and replace 'lab_increase_column_t' with something unique.
-- 2. THE OUTPUTS HERE MUST MATCH THE OUTPUT OF YOUR FUNCTION
create or replace force type lab_increase_column_t as object 
(SUBJECT_ID	NUMBER(7,0),
 ICUSTAY_ID NUMBER(7,0),
 MAX_INCREASE NUMBER(7,0),
 MAX_PERCENT_INCREASE NUMBER(7,0),
 FIRST_VALUE NUMBER(7,0),
 MAX_PER_ICUSTAY NUMBER(7,0),
 MIN_PER_ICUSTAY NUMBER(7,0),
 max_per_hosp_adm number(7,0),
 min_per_hosp_adm number(7,0),
 max_icu_48hrs number(7,0),
 min_icu_48_hrs number(7,0),
  min_per_hosp_adm_48 number(7,0),
 max_per_hosp_adm_48 number(7,0),
 max_increase_icu_48 number(7,0),
 max_incr_icu_48_perc number(7,0),
 max_incr_icu_48_vs_hos number(7,0),
 max_incr_icu_48_vs_hos_perc number(7,0),
 max_incr_icu_vs_hos number(7,0),
 max_incr_icu_vs_hos_perc number(7,0)
);


 

      
---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl + F, and replace 'lab_increase_subs_t' with a unique name
create or replace type lab_increase_subs_t as table of lab_increase_column_t;

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl+F and replace 'lab_increase' with name of function 
-- 2. specify your inputs: q_lab_name in D_LABITEMS.TEST_NAME%type
create or replace function lab_increase(q_lab_item in LABEVENTS.ITEMID%type)
return lab_increase_subs_t as
  v_ret   lab_increase_subs_t;
begin
  select 
  cast(
  multiset(
  -- PUT YOUR QUERY FROM HERE...
WITH
  -- THE FIRST VALUE OF CREATININ PER ICUSTAY
  first_creatinine_per_icu_stay AS
  ( SELECT DISTINCT icud.icustay_id,
    FIRST_VALUE ( cr.valuenum ) over ( partition BY icud.icustay_id order by cr.charttime ) first_cr
  FROM MIMIC2V26.labevents cr,
       MIMIC2V26.ICUSTAY_DETAIL icud
  WHERE cr.itemid   = q_lab_item
  AND cr.icustay_id = icud.icustay_id
  )
  --select count(*) from first_creatinine_per_icu_stay; 
  --Those ICUSTAY  that had a creatinine measurement = 30378
    
  -- THE MAXIMUM VALUE OF CREATININE PER ICU STAY
  ,max_creatinine_per_icu_stay AS
  (SELECT icud.icustay_id,
    MAX(cr.valuenum) AS max_cr
  FROM MIMIC2V26.labevents cr,
       MIMIC2V26.ICUSTAY_DETAIL icud
  WHERE cr.itemid   = q_lab_item
  AND cr.icustay_id = icud.icustay_id
  GROUP BY icud.icustay_id
  )
  --select count(distinct *) from max_creatinine_per_icu_stay;
  
  
  -- THE MINIMUM VALUE OF CREATININE PER ICUSTAY
  ,min_creatinine_per_icu_stay AS
  (SELECT icud.icustay_id,
    MIN(cr.valuenum) AS min_cr
  FROM MIMIC2V26.labevents cr,
       MIMIC2V26.ICUSTAY_DETAIL icud
  WHERE cr.itemid   = q_lab_item
  AND cr.icustay_id = icud.icustay_id
  GROUP BY icud.icustay_id
  ) 

  -- THE MAXIMUM VALUE OF CREATININ BASED ON FIRST 48 HOURS IN THE ICU
  ,max_creat_in_icu_48_hours AS
  (SELECT icud.icustay_id,
    MAX(cr.valuenum) AS max_cr_48
  FROM MIMIC2V26.labevents cr,
       MIMIC2V26.ICUSTAY_DETAIL icud
  WHERE cr.itemid   = q_lab_item
  AND cr.icustay_id = icud.icustay_id
  AND icud.icustay_intime + interval '2' day >  cr.charttime 
  GROUP BY icud.icustay_id
  )
  --select * from max_creat_in_icu_48_hours;

  -- THE MINIMUM VALUE OF CREATININ BASED ON FIRST 48 HOURS IN THE ICU
  ,min_creat_in_icu_48_hours AS
  (SELECT icud.icustay_id,
    MIN(cr.valuenum) AS min_cr_48
  FROM MIMIC2V26.labevents cr,
       MIMIC2V26.ICUSTAY_DETAIL icud
  WHERE cr.itemid   = q_lab_item
  AND cr.icustay_id = icud.icustay_id
  AND icud.icustay_intime + interval '2' day >  cr.charttime 
  GROUP BY icud.icustay_id
  )
  --select * from min_creat_in_icu_48_hours;
  
  -- THE MINIMUM VALUE OF CREATININ BASED ON THE ENTIRE HOSPITAL STAY 
  ,min_cr_per_hospital_stay AS
  ( SELECT DISTINCT icud.subject_id,
    icud.icustay_id,
    MIN(le.valuenum) OVER ( PARTITION BY icud.subject_id, icud.icustay_id ) AS min_cr_per_hosp_adm
  FROM MIMIC2V26.labevents le
  JOIN MIMIC2V26.icustay_detail icud
  ON ( icud.icustay_id = le.icustay_id )
  WHERE le.itemid      = q_lab_item
  AND le.valuenum     <> 0
    /* Eliminate zero values to prevent divide by zero errors later */
    /* Eliminate patients who have acute renal failure with dialysis */
  )
  --select * from min_cr_per_hospital_stay;
  -- THE MAXIMUM CREATININ BASED ON THE ENTIRE HOSPITAL STAY
  ,max_cr_per_hospital_stay AS
  ( SELECT DISTINCT icud.subject_id,
    icud.icustay_id,
    MAX(le.valuenum) OVER ( PARTITION BY icud.subject_id, icud.icustay_id ) AS max_cr_per_hosp_adm
  FROM MIMIC2V26.labevents le
  JOIN MIMIC2V26.icustay_detail icud
  ON ( icud.icustay_id = le.icustay_id )
  WHERE le.itemid      = q_lab_item
  AND le.valuenum     <> 0
    /* Eliminate zero values to prevent divide by zero errors later */
    /* Eliminate patients who have acute renal failure with dialysis */
  )
  
  -- THE MINIUMUM CREATININ BASED ON FIRST 48 HOURS IN THE HOSPITAL
  -- WE USED THIS FOR OUR INTERVENTION GROUP...
  ,min_cr_per_hosp_stay_48 AS
  ( SELECT DISTINCT icud.subject_id,
    icud.icustay_id,
    MIN(le.valuenum) OVER ( PARTITION BY icud.subject_id, icud.icustay_id ) AS min_cr_per_hosp_adm_48
  FROM MIMIC2V26.labevents le
  JOIN MIMIC2V26.icustay_detail icud
  ON ( icud.icustay_id = le.icustay_id )
  WHERE le.itemid      = q_lab_item
  AND le.valuenum     <> 0
    /* Eliminate zero values to prevent divide by zero errors later */
  AND icud.icustay_intime + interval '2' day >  le.charttime     
    /* Eliminate patients who have acute renal failure with dialysis */
  )
  
 
  
  -- THE MAXIMUM VALUE OF CREATININ BASED ON THE FIRST 48 HOURS IN THE HOSPITAL
  ,max_cr_per_hosp_stay_48 AS
  ( SELECT DISTINCT icud.subject_id,
    icud.icustay_id,
    MAX(le.valuenum) OVER ( PARTITION BY icud.subject_id, icud.icustay_id ) AS max_cr_per_hosp_adm_48
  FROM MIMIC2V26.labevents le
  JOIN MIMIC2V26.icustay_detail icud
  ON ( icud.icustay_id = le.icustay_id )
  WHERE le.itemid      = q_lab_item
  AND le.valuenum     <> 0
    /* Eliminate zero values to prevent divide by zero errors later */
  AND icud.icustay_intime + interval '2' day >  le.charttime   
    
    /* Eliminate patients who have acute renal failure with dialysis */
  )
  --select * from max_cr_per_hosp_stay_48;
  

-- THIS SECTION IS TO FIND WHERE THE CREATININ IS DECREASING --
-- SO THAT WE CAN FIND THE THEREPUTIC RANGE.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
,test1 AS (
SELECT icud.icustay_id,
       cr.valuenum,
       cr.charttime
  FROM MIMIC2V26.labevents cr,
       MIMIC2V26.ICUSTAY_DETAIL icud
  WHERE cr.itemid   = q_lab_item
  AND cr.icustay_id = icud.icustay_id
  --AND ROWNUM < 100
  ORDER BY ICUSTAY_ID, CHARTTIME, VALUENUM
  )
--select * from test1;

, test2 AS(
select ICUSTAY_ID, 
       MAX(VALUENUM) as max_val 
  FROM test1
  GROUP BY ICUSTAY_ID
)

,test3 AS(
SELECT t1.ICUSTAY_ID,
       t1.CHARTTIME,
       t1.VALUENUM
FROM test1 t1
JOIN test2 t2
ON t1.icustay_id = t2.icustay_id
WHERE t2.max_val = t1.valuenum
ORDER BY ICUSTAY_ID,CHARTTIME
)
--select * from test3;

,cr_max_times AS(
SELECT ICUSTAY_ID,
       MAX(charttime) as cr_max_time
FROM test3
GROUP BY ICUSTAY_ID
)
--select * from cr_max_times;

-- THIS IS THE TIME POINT WHERE AFTER THEY WILL 
--BECOME BETTER ACCORDING TO THE MEASUREMENTS.
,CR_MAX_VAL_TIME AS(
SELECT DISTINCT  
    t3.icustay_id,
    t3.valuenum as MAX_CR_VALUE,
    cr.cr_max_time,
    ROUND(EXTRACT(DAY FROM cr.cr_max_time - icud.icustay_intime)* 24 + EXTRACT(HOUR FROM cr.cr_max_time - icud.icustay_intime) + EXTRACT(MINUTE FROM cr.cr_max_time - icud.icustay_intime)/60,2) AS hr_bet_icu_in_and_cr_max,
    ROUND(EXTRACT(DAY FROM cr.cr_max_time - icud.icustay_intime)* 24 + EXTRACT(HOUR FROM cr.cr_max_time - icud.icustay_intime) + EXTRACT(MINUTE FROM cr.cr_max_time - icud.icustay_intime)/60,2) / ROUND(EXTRACT(DAY FROM icud.icustay_outtime - icud.icustay_intime)* 24 + EXTRACT(HOUR FROM icud.icustay_outtime - icud.icustay_intime) + EXTRACT(MINUTE FROM icud.icustay_outtime - icud.icustay_intime)/60,2) AS perc_of_time_not_theraputic
FROM test3 t3
JOIN cr_max_times cr
ON cr.icustay_id = t3.icustay_id
JOIN mimic2v26.icustay_detail icud
ON t3.icustay_id = icud.icustay_id
WHERE cr_max_time = CHARTTIME
)
--SELECT * FROM CR_MAX_VAL_TIME;

,final_creat_times AS(
SELECT ICUSTAY_ID,
       MAX(charttime) as final_creat_time
FROM test1
GROUP BY ICUSTAY_ID
)
--select * from final_creat_times;


,CR_FINAL_VALUES AS(
SELECT DISTINCT  
    t1.icustay_id,
    t1.valuenum as FINAL_CR_VALUE,
    fct.final_creat_time
FROM test1 t1
JOIN final_creat_times fct
ON fct.icustay_id = t1.icustay_id
WHERE final_creat_time = CHARTTIME
)

--SELECT * FROM CR_FINAL_VALUES;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

,creat_values AS
  ( SELECT DISTINCT cr.subject_id,
    icud.icustay_id,
    icud.icustay_age_group AS hospital_age_group,
    icud.icustay_admit_age AS hospital_admit_age,
    icud.icustay_intime,
    icud.icustay_outtime,
    cr.charttime,
    TO_CHAR(cr.charttime, 'dd Mon, yyyy hh24:mi:ss')                                                                                                             AS long_charttime,
    cr.valuenum                                                                                                                                                  AS current_cr,
    MAX(cr.valuenum) over ( partition BY icud.icustay_id order by cr.charttime RANGE BETWEEN CURRENT ROW AND INTERVAL '2' DAY FOLLOWING )                        AS max_cr_next_two_day,
    MAX(cr.valuenum) over ( partition BY icud.icustay_id order by cr.charttime RANGE BETWEEN CURRENT ROW AND INTERVAL '2' DAY FOLLOWING )    - cr.valuenum       AS max_increase,
    (MAX(cr.valuenum) over ( partition BY icud.icustay_id order by cr.charttime RANGE BETWEEN CURRENT ROW AND INTERVAL '2' DAY FOLLOWING ) ) * 100 / cr.valuenum AS percentage_increase
  FROM MIMIC2V26.labevents cr,
    MIMIC2V26.icustay_detail icud
  WHERE icud.icustay_id = cr.icustay_id
  AND cr.itemid         = q_lab_item
  AND cr.valuenum      <> 0
    /* Eliminate '0's to prevent divide by zero error */
  AND cr.valuenum IS NOT NULL
  ORDER BY cr.subject_id,
    cr.charttime
  )
  --select * from creat_values;
  

  ,
  max_creat_increase AS
  ( SELECT DISTINCT cv.subject_id,
    cv.icustay_id,
    cv.hospital_age_group,
    cv.hospital_admit_age,
    MAX(cv.max_increase) OVER (PARTITION BY cv.subject_id, cv.icustay_id, cv.hospital_age_group, cv.hospital_admit_age, max_cr, first_cr)                                                 max_increase,
    FIRST_VALUE(cv.long_charttime) OVER (PARTITION BY cv.subject_id, cv.icustay_id, cv.hospital_age_group, cv.hospital_admit_age, max_cr, first_cr ORDER BY cv.max_increase DESC)         date_max_increase,
    MAX(cv.percentage_increase) OVER (PARTITION BY cv.subject_id, cv.icustay_id, cv.hospital_age_group, cv.hospital_admit_age, max_cr, first_cr)                                          max_percent_increase,
    FIRST_VALUE(cv.long_charttime) OVER (PARTITION BY cv.subject_id, cv.icustay_id, cv.hospital_age_group, cv.hospital_admit_age, max_cr, first_cr ORDER BY cv.percentage_increase DESC)  date_max_percent_increase,
    
    fcr.first_cr,
    
    cr.max_cr AS    max_cr_per_icustay,
    micr.min_cr AS  min_cr_per_icustay,

    mcphs.min_cr_per_hosp_adm,
    macphs.max_cr_per_hosp_adm,
    
    -- THe 48 HR VALUES
    mcihr.max_cr_48 AS        max_cr_icu_48hrs,
    mici48.min_cr_48 AS       min_cr_icu_48hrs,
    
    micrhs.min_cr_per_hosp_adm_48,
    macrhs.max_cr_per_hosp_adm_48,
    
    
    --MAX CREATININ INCREASE (AND %) PER ICUSTAY
    --(cr.max_cr - micr.min_cr)                                                               AS max_cr_increase_icustay,
    --(cr.max_cr - micr.min_cr)/micr.min_cr                                                   AS max_cr_increase_icu_perc,
    
    --MAX CREATININ INCREASE (AND %) PER HOSPITAL STAY
    --(macphs.max_cr_per_hosp_adm - mcphs.min_cr_per_hosp_adm)                                AS max_cr_increase_per_hosstay,
    --(macphs.max_cr_per_hosp_adm - mcphs.min_cr_per_hosp_adm) / mcphs.min_cr_per_hosp_adm    AS max_cr_increase_per_hos_perc,
    
    --MAX CREATININ INCREASE USING MAX ICU VERSUS MIN IN HOSPITAL
    --(cr.max_cr - mcphs.min_cr_per_hosp_adm)                                                 AS max_cr_incr_icu_max_hos_min,
    --(cr.max_cr - mcphs.min_cr_per_hosp_adm)/mcphs.min_cr_per_hosp_adm                       AS max_cr_incr_icu_max_hos_min_perc,
    
    
    --MAX CREATININ INCREASE IN ICU FOR ONLY FIRST 48 HOURS
    (mcihr.max_cr_48 - mici48.min_cr_48)                                                    AS max_cr_increase_icu_48,
    100*(mcihr.max_cr_48 - mici48.min_cr_48) / mici48.min_cr_48                                 AS max_cr_incr_icu_48_perc,
    
    --MAX CREATININ INCREASE IN FIRST 48 HOURS ICU VERSUS MIN OF HOSPITAL STAY
    (mcihr.max_cr_48 - mcphs.min_cr_per_hosp_adm)                                           AS max_cr_incr_icu_48_vs_hos,
    100*(mcihr.max_cr_48 - mcphs.min_cr_per_hosp_adm) / mcphs.min_cr_per_hosp_adm               AS max_cr_incr_icu_48_vs_hos_perc,
    
    -- MAX CREATININ INCREASE IN TOTAL ICU STAY VERSUS MIN IN THE HOSPITAL                  
    (cr.max_cr - mcphs.min_cr_per_hosp_adm)                                                 AS max_cr_incr_icu_vs_hos,          
    100*(cr.max_cr - mcphs.min_cr_per_hosp_adm) / mcphs.min_cr_per_hosp_adm                     AS max_cr_incr_icu_vs_hos_perc,      
    
    
    fcr.first_cr - mcphs.min_cr_per_hosp_adm AS       bl_cr_increase,           -- DIFFERENCE BETWEEN CR ADMISSION AND MINIMUM VALUE OVER HOSPITAL STAY 
    fcr.first_cr * 100 / mcphs.min_cr_per_hosp_adm AS bl_cr_percent_increase    -- % VALUE OF ABOVE
  FROM creat_values cv
  
  JOIN max_creatinine_per_icu_stay            cr
  ON ( cv.icustay_id = cr.icustay_id )
  JOIN min_creatinine_per_icu_stay            micr
  ON ( cv.icustay_id = micr.icustay_id)
  
  JOIN first_creatinine_per_icu_stay          fcr
  ON ( cv.icustay_id = fcr.icustay_id )
  
  
  LEFT JOIN min_cr_per_hospital_stay          mcphs
  ON ( cv.icustay_id = mcphs.icustay_id )
  
  --THE 48 HOUR PART
  LEFT JOIN max_cr_per_hospital_stay          macphs
  ON ( cv.icustay_id = macphs.icustay_id ) 
  
  JOIN max_creat_in_icu_48_hours              mcihr
  ON ( cv.icustay_id = mcihr.icustay_id) 
  JOIN min_creat_in_icu_48_hours              mici48
  ON ( cv.icustay_id = mici48.icustay_id ) 
  
  JOIN min_cr_per_hosp_stay_48                micrhs
  ON ( cv.icustay_id = micrhs.icustay_id ) 
  JOIN max_cr_per_hosp_stay_48                macrhs
  ON ( cv.icustay_id = macrhs.icustay_id ) 
  
  WHERE micr.min_cr > 0
  AND mcphs.min_cr_per_hosp_adm > 0
  AND mici48.min_cr_48 > 0
  AND micrhs.min_cr_per_hosp_adm_48 > 0
  
  )
  SELECT SUBJECT_ID, 
         ICUSTAY_ID,
         MAX_INCREASE, 
         MAX_PERCENT_INCREASE,
         FIRST_CR,
         MAX_CR_PER_ICUSTAY,
         MIN_CR_PER_ICUSTAY,
         max_cr_per_hosp_adm,
         min_cr_per_hosp_adm,
         max_cr_icu_48hrs,
         min_cr_icu_48hrs,
        min_cr_per_hosp_adm_48, 
         max_cr_per_hosp_adm_48,
         max_cr_increase_icu_48, 
         max_cr_incr_icu_48_perc, 
         max_cr_incr_icu_48_vs_hos, 
         max_cr_incr_icu_48_vs_hos_perc, 
         max_cr_incr_icu_vs_hos,
         max_cr_incr_icu_vs_hos_perc 
         FROM max_creat_increase 
         

  -- TILL HERE  
    ) 
    as lab_increase_subs_t)
    into
      v_ret
    from 
      dual;

  return v_ret;
  
end lab_increase; -- CHANGE ME

-- THIS SHOWS HOW TO CALL THE FUNCTION
select * from table(lab_increase('50090'));