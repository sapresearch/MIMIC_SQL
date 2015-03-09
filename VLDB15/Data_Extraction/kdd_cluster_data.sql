/*
  
  Created on   : Feb 2015 by Mornin Feng
  Last updated : 
 Extract data for paper for KDD with Ishrar

*/



--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-------------------------- Tier 1 Static Variables -----------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
drop table kdd_tier1_feb;
create table kdd_tier1_feb as
with population_1 as
(select distinct subject_id, hadm_id, icustay_id
from mimic2v26.icustay_detail
where icustay_seq=1 
and ICUSTAY_AGE_GROUP='adult'
and ICUSTAY_LOS>=48*60 -- at least 48 hour of icu stay
--and icustay_id<100
)

--select * from population; --15647

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-------------------------- Demographic and basic data  -----------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
, population_2 as
(select distinct
pop.*
, round(icud.icustay_los/60/24, 2) as icu_los_day
, round(icud.hospital_los/60/24,2) as hospital_los_day
, case when icud.icustay_admit_age>120 then 91.4 else  icud.icustay_admit_age end as age
--, icud.gender as gender
, case when icud.gender is null then null
  when icud.gender = 'M' then 1 else 0 end as gender_num
, icud.WEIGHT_FIRST
, bmi.bmi
, bmi.IMPUTED_INDICATOR
, icud.SAPSI_FIRST
, icud.SOFA_FIRST
, icud.ICUSTAY_FIRST_SERVICE as service_unit
, case when ICUSTAY_FIRST_SERVICE='SICU' then 1
      when ICUSTAY_FIRST_SERVICE='CCU' then 2
      when ICUSTAY_FIRST_SERVICE='CSRU' then 3
      else 0 --MICU & FICU
      end
  as service_num
, icud.icustay_intime 
, icud.icustay_outtime
, to_char(icud.ICUSTAY_INTIME, 'Day') as day_icu_intime
, to_number(to_char(icud.ICUSTAY_INTIME, 'D')) as day_icu_intime_num
, extract(hour from icud.ICUSTAY_INTIME) as hour_icu_intime
, case when icud.hospital_expire_flg='Y' then 1 else 0 end as hosp_exp_flg
, case when icud.icustay_expire_flg='Y' then 1 else 0 end as icu_exp_flg
, round((extract(day from d.dod-icud.icustay_intime)+extract(hour from d.dod-icud.icustay_intime)/24),2) as survival_day
from population_1 pop 
left join  mimic2v26.icustay_detail icud on pop.icustay_id = icud.icustay_id
left join mimic2devel.obesity_bmi bmi on bmi.icustay_id=pop.icustay_id
left join MIMIC2DEVEL.d_patients d on d.subject_id=pop.subject_id
)

--select * from population_2;

, population as
(select distinct pop.*
, elix.CONGESTIVE_HEART_FAILURE
, elix.CARDIAC_ARRHYTHMIAS
, elix.VALVULAR_DISEASE
, elix.PULMONARY_CIRCULATION
, elix.PERIPHERAL_VASCULAR
, elix.HYPERTENSION
, elix.PARALYSIS
, elix.OTHER_NEUROLOGICAL
, elix.CHRONIC_PULMONARY
, elix.DIABETES_UNCOMPLICATED
, elix.DIABETES_COMPLICATED
, elix.HYPOTHYROIDISM
, elix.RENAL_FAILURE
, elix.LIVER_DISEASE
, elix.PEPTIC_ULCER
, elix.AIDS
, elix.LYMPHOMA
, elix.METASTATIC_CANCER
, elix.SOLID_TUMOR
, elix.RHEUMATOID_ARTHRITIS
, elix.COAGULOPATHY
, elix.OBESITY
, elix.WEIGHT_LOSS
, elix.FLUID_ELECTROLYTE
, elix.BLOOD_LOSS_ANEMIA
, elix.DEFICIENCY_ANEMIAS
, elix.ALCOHOL_ABUSE
, elix.DRUG_ABUSE
, elix.PSYCHOSES
, elix.DEPRESSION
, pt.HOSPITAL_MORT_PT as elix_HOSPITAL_MORT_PT
, pt.TWENTY_EIGHT_DAY_MORT_PT as elix_TWENTY_EIGHT_DAY_MORT_PT
, pt.ONE_YR_MORT_PT as pt_ONE_YR_MORT_PT
, pt.TWO_YR_MORT_PT as pt_TWO_YR_MORT_PT
, pt.ONE_YEAR_SURVIVAL_PT as pt_ONE_YEAR_SURVIVAL_PT
, pt.TWO_YEAR_SURVIVAL_PT as pt_TWO_YEAR_SURVIVAL_PT
from population_2 pop
left join mimic2devel.elixhauser_revised elix on elix.hadm_id=pop.hadm_id
left join mimic2devel.ELIXHAUSER_POINTS pt on pt.hadm_id=pop.hadm_id
)

--select * from population;

, temp as
(select ICUSTAY_ID
,ICU_LOS_DAY
,HOSPITAL_LOS_DAY
,AGE
,GENDER_NUM as gender_male
--,WEIGHT_FIRST
--,BMI
--,case when IMPUTED_INDICATOR = 'FALSE' then 0 
--      when IMPUTED_INDICATOR = 'TRUE' then 1
--      else null end as IMPUTED_INDICATOR
,SAPSI_FIRST
,SOFA_FIRST
----,SERVICE_UNIT
, case when SERVICE_NUM = 0 then 1 else 0 end as micu_flg
, case when SERVICE_NUM = 1 then 1 else 0 end as sicu_flg
, case when SERVICE_NUM = 2 then 1 else 0 end as ccu_flg
, case when SERVICE_NUM = 3 then 1 else 0 end as csru_flg
--,ICUSTAY_INTIME
--,ICUSTAY_OUTTIME
--,DAY_ICU_INTIME
,DAY_ICU_INTIME_NUM
,HOUR_ICU_INTIME
,HOSP_EXP_FLG
,ICU_EXP_FLG
,SURVIVAL_DAY
,CONGESTIVE_HEART_FAILURE
,CARDIAC_ARRHYTHMIAS
,VALVULAR_DISEASE
,PULMONARY_CIRCULATION
,PERIPHERAL_VASCULAR
,HYPERTENSION
,PARALYSIS
,OTHER_NEUROLOGICAL
,CHRONIC_PULMONARY
,DIABETES_UNCOMPLICATED
,DIABETES_COMPLICATED
,HYPOTHYROIDISM
,RENAL_FAILURE
,LIVER_DISEASE
,PEPTIC_ULCER
,AIDS
,LYMPHOMA
,METASTATIC_CANCER
,SOLID_TUMOR
,RHEUMATOID_ARTHRITIS
,COAGULOPATHY
,OBESITY
,WEIGHT_LOSS
,FLUID_ELECTROLYTE
,BLOOD_LOSS_ANEMIA
,DEFICIENCY_ANEMIAS
,ALCOHOL_ABUSE
,DRUG_ABUSE
,PSYCHOSES
,DEPRESSION
,ELIX_HOSPITAL_MORT_PT
--,ELIX_TWENTY_EIGHT_DAY_MORT_PT
--,PT_ONE_YR_MORT_PT
--,PT_TWO_YR_MORT_PT
--,PT_ONE_YEAR_SURVIVAL_PT
--,PT_TWO_YEAR_SURVIVAL_PT
from population
)

--select * from temp;

, final_table as
(select 
ICUSTAY_ID

-- basic info
,AGE
,GENDER_MALE
,SAPSI_FIRST
,SOFA_FIRST
,ELIX_HOSPITAL_MORT_PT
,MICU_FLG
,SICU_FLG
,CCU_FLG
,CSRU_FLG
,DAY_ICU_INTIME_NUM
,HOUR_ICU_INTIME

-- co-morbidities
,CONGESTIVE_HEART_FAILURE
,CARDIAC_ARRHYTHMIAS
,VALVULAR_DISEASE
,PULMONARY_CIRCULATION
,PERIPHERAL_VASCULAR
,HYPERTENSION
,PARALYSIS
,OTHER_NEUROLOGICAL
,CHRONIC_PULMONARY
,DIABETES_UNCOMPLICATED
,DIABETES_COMPLICATED
,HYPOTHYROIDISM
,RENAL_FAILURE
,LIVER_DISEASE
,PEPTIC_ULCER
,AIDS
,LYMPHOMA
,METASTATIC_CANCER
,SOLID_TUMOR
,RHEUMATOID_ARTHRITIS
,COAGULOPATHY
,OBESITY
,WEIGHT_LOSS
,FLUID_ELECTROLYTE
,BLOOD_LOSS_ANEMIA
,DEFICIENCY_ANEMIAS
,ALCOHOL_ABUSE
,DRUG_ABUSE
,PSYCHOSES
,DEPRESSION


-- outcomes
,HOSP_EXP_FLG
,ICU_EXP_FLG
,SURVIVAL_DAY
,ICU_LOS_DAY
,HOSPITAL_LOS_DAY
from temp
where
ICUSTAY_ID is not null
--and ICU_LOS_DAY is not null
--and HOSPITAL_LOS_DAY is not null
and AGE is not null
and GENDER_MALE is not null
and SAPSI_FIRST is not null
and SOFA_FIRST is not null
and MICU_FLG is not null
and SICU_FLG is not null
and CCU_FLG is not null
and CSRU_FLG is not null
and DAY_ICU_INTIME_NUM is not null
and HOUR_ICU_INTIME is not null
--and HOSP_EXP_FLG is not null
--and ICU_EXP_FLG is not null
--and SURVIVAL_DAY is not null
and CONGESTIVE_HEART_FAILURE is not null
and CARDIAC_ARRHYTHMIAS is not null
and VALVULAR_DISEASE is not null
and PULMONARY_CIRCULATION is not null
and PERIPHERAL_VASCULAR is not null
and HYPERTENSION is not null
and PARALYSIS is not null
and OTHER_NEUROLOGICAL is not null
and CHRONIC_PULMONARY is not null
and DIABETES_UNCOMPLICATED is not null
and DIABETES_COMPLICATED is not null
and HYPOTHYROIDISM is not null
and RENAL_FAILURE is not null
and LIVER_DISEASE is not null
and PEPTIC_ULCER is not null
and AIDS is not null
and LYMPHOMA is not null
and METASTATIC_CANCER is not null
and SOLID_TUMOR is not null
and RHEUMATOID_ARTHRITIS is not null
and COAGULOPATHY is not null
and OBESITY is not null
and WEIGHT_LOSS is not null
and FLUID_ELECTROLYTE is not null
and BLOOD_LOSS_ANEMIA is not null
and DEFICIENCY_ANEMIAS is not null
and ALCOHOL_ABUSE is not null
and DRUG_ABUSE is not null
and PSYCHOSES is not null
and DEPRESSION is not null
and ELIX_HOSPITAL_MORT_PT is not null

)
select * from final_table; --13912



--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-------------------------- Tier 2 Variables -------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------------------------
-------------------------- Vent & vasopressor patients  ------------------------------------------------
--------------------------------------------------------------------------------------------------------
create table kdd_tier2_feb as
with population as
(select kdd.icustay_id
, icu.intime as icustay_intime
, icu.outtime as icustay_outtime
from kdd_tier1_feb kdd
join mimic2v26.icustayevents icu on kdd.icustay_id= icu.icustay_id
--where kdd.icustay_id<10
)

--select * from population;

, vent_group1 as
(select distinct 
pop.icustay_id
, 'ventilation' as variable_name
--, ch.charttime-pop.icustay_intime
, round( (extract(day from ch.charttime-pop.icustay_intime) *24
    + extract(hour from ch.charttime-pop.icustay_intime)
    + extract(minute from ch.charttime-pop.icustay_intime)/60
  ), 2)as timestamp_hr
--, vent.end_time as timestamp_2
, 1 as value1
, 'flag' as value1uom
from population pop
join mimic2v26.chartevents ch 
  on ch.icustay_id=pop.icustay_id 
  and ch.itemid in (720,722)
)

, vent_group as
(select distinct icustay_id
--, first_value(timestamp_hr) over (partition by icustay_id order by timestamp_hr asc) as first_vent
, case when first_value(timestamp_hr) over (partition by icustay_id order by timestamp_hr asc) <=24 then 1 else 0 end as vent_1st_24hr
from vent_group1
)


--select * from vent_group;

--- unit unified based on percentage of recommended max dosage

, vaso_group1 as
(select 
distinct 
pop.icustay_id
, 'vasopressor' as variable_name
, round( (extract(day from med.charttime-pop.icustay_intime) *24
    + extract(hour from med.charttime-pop.icustay_intime)
    + extract(minute from med.charttime-pop.icustay_intime)/60
  ), 2)as timestamp_hr
--, null as timestamp_2
, case when med.itemid=51 then round(med.dose/0.03*100,3)
      when med.itemid=43 then round(med.dose/15*100,3)
      when med.itemid=119 then round(med.dose/0.125*100,3)
      when med.itemid=120 then round(med.dose/3*100,3)
      when med.itemid=128 then round(med.dose/9.1*100,3)
    end as value1
, '% of max dosage' as value1uom
--, med.itemid
from population pop
join mimic2v26.medevents med on med.icustay_id=pop.icustay_id 
  and med.itemid in (51,43,128,120, 119) --- a more concise list
  and med.dose>0
  --and med.itemid in (46,47,120,43,307,44,119,309,51,127,128)
where med.charttime is not null
)

--select distinct itemid, count(*) from vaso_group group by itemid;

, vaso_group as
(select distinct icustay_id
--, first_value(timestamp_hr) over (partition by icustay_id order by timestamp_hr asc) as first_vaso
, case when first_value(timestamp_hr) over (partition by icustay_id order by timestamp_hr asc) <=24 then 1 else 0 end as vaso_1st_24hr
from vaso_group1
)


--select * from vaso_group;


--------------------------------------------------------------------------------------------------------
-------------------------- Sedative Medication  ------------------------------------------------
--------------------------------------------------------------------------------------------------------
, sedative_group1 as
(select 
distinct 
pop.icustay_id
, 'sedative' as variable_name
, round( (extract(day from med.charttime-pop.icustay_intime) *24
    + extract(hour from med.charttime-pop.icustay_intime)
    + extract(minute from med.charttime-pop.icustay_intime)/60
  ), 2)as timestamp_hr
--, null as timestamp_2
, 1 as value1
, 'flg' as value1uom
--, med.itemid
from population pop
join mimic2v26.medevents med on med.icustay_id=pop.icustay_id 
  --and med.itemid in (124,118,149,150,308,163,131)
  and itemid in (149,163,131,124,118)
where med.charttime is not null
)

--select count(distinct icustay_id) from sedative_group;
--select distinct itemid, value1uom from sedative_group;

, sedative_group as
(select distinct icustay_id
--, first_value(timestamp_hr) over (partition by icustay_id order by timestamp_hr asc) as first_sedative
, case when first_value(timestamp_hr) over (partition by icustay_id order by timestamp_hr asc) <=24 then 1 else 0 end as sedative_1st_24hr
from sedative_group1
)

--select * from sedative_group;

--------------------------------------------------------------------------------------------------------
-------------------------- Chart events/ vital signs   ---------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
, vital_sign1 as
(select distinct
pop.icustay_id
, case when ch.itemid in (52,456) then 'MeanBP'
      when ch.itemid in (678,679) then 'Temperature F'
      when ch.itemid =211 then 'HR'
      when ch.itemid =113 then 'CVP'
      when ch.itemid =646 then 'SPO2'
      when ch.itemid in (190,3420) then 'FIO2'
      when  ch.itemid =198 then 'GCS'
      --when  ch.itemid =128 then 'Care_Protocol'
      when  ch.itemid =3580 then 'weight_kg'
      when ch.itemid =619 then 'ventilated_RR'
      when ch.itemid in (614,615,618) then 'spontaneous_RR'
    end as variable_name
, round( (extract(day from ch.charttime-pop.icustay_intime) *24
    + extract(hour from ch.charttime-pop.icustay_intime)
    + extract(minute from ch.charttime-pop.icustay_intime)/60
  ), 2)as timestamp_hr
--, null as timestamp_2
, round(ch.value1num, 3) as value1
, case when ch.itemid in (190,3420) then 'fraction'
    else ch.value1uom end as value1uom
from population pop
join mimic2v26.chartevents ch 
  on pop.icustay_id=ch.icustay_id 
    and ch.charttime <= pop.icustay_intime+1
where (ch.itemid in (52,456) -- mean bp
    or ch.itemid in (678,679)  -- temperature in F
    or ch.itemid =211 -- hr
    or ch.itemid =113 -- cvp
    or ch.itemid =646 -- spo2
    or ch.itemid in (190,3420) -- fio2
    or ch.itemid =198 -- GCS
    --or ch.itemid=128 -- care protocol
    or ch.itemid=3580 -- weight_kg
    or ch.itemid =619 -- ventilated_RR
    or ( ch.itemid in (614,615,618) and ch.value1num between 2 and 80))-- spontaneous_RR
    and ch.value1num is not null
)

--select * from vital_sign1 order by 1,2,3;

--select * from vital_sign1 where variable_name='HR' and icustay_id=4 order by 4;

, vital_sign2 as
(select distinct icustay_id
, variable_name
, first_value(value1) over (partition by icustay_id, variable_name order by value1 asc) as min 
, first_value(value1) over (partition by icustay_id, variable_name order by value1 desc) as max
, round(avg(value1) over (partition by icustay_id, variable_name),3) as avg
from vital_sign1
--where variable_name='HR'
)

--select * from vital_sign2 order by 1,2;
--select distinct variable_name from vital_sign2;
, vital_sign_min as
(
select * from
(select icustay_id, variable_name, min from vital_sign2
)
pivot
(min(min) for variable_name in ('Temperature F' as temp_min
,'MeanBP' as bp_min
, 'HR' as hr_min
, 'CVP' as cvp_min
, 'ventilated_RR' as ventilated_rr_min
, 'GCS' as gcs_min
, 'spontaneous_RR' as spontaneious_rr_min
, 'SPO2' as spo2_min
, 'FIO2' as fio2_min)
)
)

--select * from vital_sign_min;

, vital_sign_max as
(
select * from
(select icustay_id, variable_name, max from vital_sign2
)
pivot
(max(max) for variable_name in ('Temperature F' as temp_max
,'MeanBP' as bp_max
, 'HR' as hr_max
, 'CVP' as cvp_max
, 'ventilated_RR' as ventilated_rr_max
, 'GCS' as gcs_max
, 'spontaneous_RR' as spontaneious_rr_max
, 'SPO2' as spo2_max
, 'FIO2' as fio2_max)
)
)

--select * from vital_sign_max;

, vital_sign_avg as
(
select * from
(select icustay_id, variable_name, avg from vital_sign2
)
pivot
(avg(avg) for variable_name in ('Temperature F' as temp_avg
,'MeanBP' as bp_avg
, 'HR' as hr_avg
, 'CVP' as cvp_avg
, 'ventilated_RR' as ventilated_rr_avg
, 'GCS' as gcs_avg
, 'spontaneous_RR' as spontaneious_rr_avg
, 'SPO2' as spo2_avg
, 'FIO2' as fio2_avg)
)
)

--select * from vital_sign_avg;


, care_protocol1 as
(select distinct
pop.icustay_id
--,  'Care_Protocol' as variable_name
, round( (extract(day from ch.charttime-pop.icustay_intime) *24
    + extract(hour from ch.charttime-pop.icustay_intime)
    + extract(minute from ch.charttime-pop.icustay_intime)/60
  ), 2)as timestamp_hr
, case when value1 = 'Full Code' then 1 else 0 end as fullcode_flg
, case when value1 = 'Comfort Measures' then 1 else 0 end as comfort_flg
, case when value1 = 'Do Not Intubate' then 1 else 0 end as dni_flg
, case when value1 = 'Do Not Resuscita' then 1 else 0 end as dnr_flg
, case when value1 = 'CPR Not Indicate' then 1 else 0 end as cpr_flg
, case when value1 = 'Other/Remarks' then 1 else 0 end as other_flg
from population pop
join mimic2v26.chartevents ch 
  on pop.icustay_id=ch.icustay_id 
  and ch.itemid=128 -- care protocol
  and ch.value1 is not null
  and ch.charttime <= pop.icustay_intime+1
)

--select * from care_protocol1;

, care_protocol as
(select distinct icustay_id
--, first_value(timestamp_hr) over (partition by icustay_id order by timestamp_hr desc) as timestamp_hr
, first_value(fullcode_flg) over (partition by icustay_id order by timestamp_hr desc) as fullcode_flg
, first_value(comfort_flg) over (partition by icustay_id order by timestamp_hr desc) as comfort_flg
, first_value(dni_flg) over (partition by icustay_id order by timestamp_hr desc) as dni_flg
, first_value(dnr_flg) over (partition by icustay_id order by timestamp_hr desc) as dnr_flg
, first_value(cpr_flg) over (partition by icustay_id order by timestamp_hr desc) as cpr_flg
, first_value(other_flg) over (partition by icustay_id order by timestamp_hr desc) as other_flg
from care_protocol1
)


--select * from care_protocol;

, final_table as
(select pop.icustay_id
, coalesce(vent.vent_1st_24hr, 0) as vent_1st_24hr
, coalesce(vaso.vaso_1st_24hr, 0) as vaso_1st_24hr
, coalesce(se.sedative_1st_24hr, 0) as sedative_1st_24hr

, mi.temp_min
, ma.temp_max
, av.temp_avg
, mi.bp_min
, ma.bp_max
, av.bp_avg
, mi.hr_min
, ma.hr_max
, av.hr_avg
, mi.cvp_min
, ma.cvp_max
, av.cvp_avg
, mi.ventilated_rr_min
, ma.ventilated_rr_max
, av.ventilated_rr_avg
, mi.gcs_min
, ma.gcs_max
, av.gcs_avg
, mi.spontaneious_rr_min
, ma.spontaneious_rr_max
, av.spontaneious_rr_avg
, mi.spo2_min
, ma.spo2_max
, av.spo2_avg
, mi.fio2_min
, ma.fio2_max
, av.fio2_avg

, care.fullcode_flg
, care.comfort_flg
, care.dni_flg
, care.dnr_flg
, care.cpr_flg
, care.other_flg

from population pop
left join vent_group vent on pop.icustay_id = vent.icustay_id
left join vaso_group vaso on pop.icustay_id = vaso.icustay_id
left join sedative_group se on pop.icustay_id = se.icustay_id
left join vital_sign_min mi on pop.icustay_id = mi.icustay_id
left join vital_sign_max ma on pop.icustay_id = ma.icustay_id
left join vital_sign_avg av on pop.icustay_id = av.icustay_id
left join care_protocol care on pop.icustay_id = care.icustay_id
)

select * from final_table;
