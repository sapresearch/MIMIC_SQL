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

