/*
  
  Created on   : Feb 2015 by Mornin Feng
  Last updated : 
 Extract data for paper for KDD with Ishrar

*/


--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-------------------------- Tier 2 Variables -------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------Patients' vital sing and lab values over the 1st 12 hours------------------------------------------



--------------------------------------------------------------------------------------------------------
-------------------------- Vent & vasopressor patients  ------------------------------------------------
--------------------------------------------------------------------------------------------------------
--create table kdd_tier2_feb as
with population as
(select kdd.icustay_id
, icu.hadm_id
, icu.icustay_intime as icustay_intime
, icu.icustay_outtime as icustay_outtime
, kdd.gender_male as gender_num
from kdd_tier1_feb kdd
join mimic2v26.icustay_detail icu on kdd.icustay_id= icu.icustay_id
where kdd.icustay_id<100
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
, case when first_value(timestamp_hr) over (partition by icustay_id order by timestamp_hr asc) <=12 then 1 else 0 end as vent_1st_12hr
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
, case when first_value(timestamp_hr) over (partition by icustay_id order by timestamp_hr asc) <=12 then 1 else 0 end as vaso_1st_12hr
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
, case when first_value(timestamp_hr) over (partition by icustay_id order by timestamp_hr asc) <=12 then 1 else 0 end as sedative_1st_12hr
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
    and ch.charttime between pop.icustay_intime and pop.icustay_intime+12/24
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
--------------------------------------------------------------------------------------------------------
-------------------------- Lab results   ---------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--- WBC ---
, lab_wbc_1 as
(select pop.hadm_id
, pop.icustay_id
, pop.ICUSTAY_INTIME
, lab.charttime
--, lab.valuenum as wbc
, first_value(lab.valuenum) over (partition by pop.hadm_id order by lab.charttime asc) as wbc_first
--, case when lab.valuenum between 4.5 and 10 then 0 else 1 end as abnormal_flg
from population pop
--join mimic2v26.icustay_detail icud on pop.hadm_id=icud.hadm_id and ICUSTAY_SEQ =1
join mimic2v26.labevents lab 
  on pop.icustay_id=lab.icustay_id 
  and lab.itemid in (50316,50468)
  and lab.valuenum is not null
  --and lab.charttime<=pop.ICUSTAY_INTIME+3/24
order by 1
)

--select * from lab_wbc_1;

, lab_wbc as
(select distinct icustay_id
, wbc_first
, case when wbc_first between 4.5 and 10 then 0 else 1 end as wbc_abnormal_flg
from lab_wbc_1
order by 1
)

--select * from lab_wbc; --22364

--- hemoglobin ----

, lab_hgb_1 as
(select pop.hadm_id
, pop.icustay_id
, pop.ICUSTAY_INTIME
, pop.gender_num
, lab.charttime
--, lab.valuenum as hgb
, first_value(lab.valuenum) over (partition by pop.hadm_id order by charttime asc) as hgb_first
--, case when pop.gender_num=1 and lab.valuenum between 13.8 and 17.2 then 0 
--       when pop.gender_num=0 and lab.valuenum between 12.1 and 15.1 then 0 
--       --when pop.gender_num is null then null
--       else 1 end as abnormal_flg
from population pop
--join mimic2v26.icustay_detail icud on pop.hadm_id=icud.hadm_id and ICUSTAY_SEQ =1
join mimic2v26.labevents lab 
  on pop.icustay_id=lab.icustay_id 
  and lab.itemid in (50386,50007,50184)
  --(50377,50386,50388,50391,50411,50454,50054,50003,50007,50011,50184,50183,50387,50389,50390,50412)
  and lab.valuenum is not null
  --and lab.charttime<=pop.ICUSTAY_INTIME+3/24
  and pop.gender_num is not null
order by 1
)

--select * from lab_hgb_1;

, lab_hgb as
(select distinct icustay_id
--, first_value(hgb) over (partition by hadm_id order by charttime asc) as hgb_first
--, first_value(hgb) over (partition by hadm_id order by hgb asc) as hgb_lowest
--, first_value(hgb) over (partition by hadm_id order by hgb desc) as hgb_highest
--, first_value(abnormal_flg) over (partition by hadm_id order by abnormal_flg desc) hgb_abnormal_flg
, hgb_first
, case when gender_num=1 and hgb_first between 13.8 and 17.2 then 0 
       when gender_num=0 and hgb_first between 12.1 and 15.1 then 0 
       --when pop.gender_num is null then null
       else 1 end as hgb_abnormal_flg
from lab_hgb_1
order by 1
)

--select * from lab_hgb; 

---- platelets ---
, lab_platelet_1 as
(select pop.hadm_id
, pop.icustay_id
, pop.ICUSTAY_INTIME
, lab.charttime
, lab.itemid
--, lab.valueuom
--, lab.valuenum as platelet
, first_value(lab.valuenum) over (partition by pop.hadm_id order by charttime asc) as platelet_first
--, case when lab.valuenum between 150 and 400 then 0 
--       else 1 end as abnormal_flg
from population pop
--join mimic2v26.icustay_detail icud on pop.hadm_id=icud.hadm_id and ICUSTAY_SEQ =1
join mimic2v26.labevents lab 
  on pop.icustay_id=lab.icustay_id 
  and lab.itemid = 50428
  and lab.valuenum is not null
  --and lab.charttime<=pop.ICUSTAY_INTIME+3/24
  --and pop.gender_num is not null
order by 1
)
--select distinct itemid from lab_platelet_1;
--select * from lab_platelet_1;

, lab_platelet as
(select distinct icustay_id
--, first_value(platelet) over (partition by hadm_id order by charttime asc) as platelet_first
--, first_value(platelet) over (partition by hadm_id order by platelet asc) as platelet_lowest
--, first_value(platelet) over (partition by hadm_id order by platelet desc) as platelet_highest
--, first_value(abnormal_flg) over (partition by hadm_id order by abnormal_flg desc) platelet_abnormal_flg
, platelet_first
, case when platelet_first between 150 and 400 then 0 
      else 1 end as platelet_abnormal_flg
from lab_platelet_1
order by 1
)

--select * from lab_platelet;

--- sodium ---
, lab_sodium_1 as
(select pop.hadm_id
, pop.icustay_id
, pop.ICUSTAY_INTIME
, lab.charttime
, lab.itemid
, lab.valueuom
--, lab.valuenum as sodium
, first_value(lab.valuenum) over (partition by pop.hadm_id order by charttime asc) as sodium_first
--, case when lab.valuenum between 135 and 145 then 0 
--       else 1 end as abnormal_flg
from population pop
--join mimic2v26.icustay_detail icud on pop.hadm_id=icud.hadm_id and ICUSTAY_SEQ =1
join mimic2v26.labevents lab 
  on pop.icustay_id=lab.icustay_id 
  and lab.itemid in (50159, 50012) ---- 50012 is for blood gas
  and lab.valuenum is not null
  --and lab.charttime<=pop.ICUSTAY_INTIME+3/24
  --and pop.gender_num is not null
order by 1
)

--select distinct valueuom from lab_sodium_1;
--select * from lab_sodium_1 where valueuom is null;

, lab_sodium as
(select distinct icustay_id
--, first_value(sodium) over (partition by hadm_id order by charttime asc) as sodium_first
--, first_value(sodium) over (partition by hadm_id order by sodium asc) as sodium_lowest
--, first_value(sodium) over (partition by hadm_id order by sodium desc) as sodium_highest
--, first_value(abnormal_flg) over (partition by hadm_id order by abnormal_flg desc) sodium_abnormal_flg
, sodium_first
, case when sodium_first between 135 and 145 then 0 
       else 1 end as sodium_abnormal_flg
from lab_sodium_1
order by 1
)

--select * from lab_sodium; --17542

--- potassium ---
, lab_potassium_1 as
(select pop.hadm_id
, pop.icustay_id
, pop.ICUSTAY_INTIME
, lab.charttime
, lab.itemid
, lab.valueuom
--, lab.valuenum as potassium
, first_value(lab.valuenum) over (partition by pop.hadm_id order by charttime asc) as potassium_first
--, case when lab.valuenum between 3.7 and 5.2 then 0 
--       else 1 end as abnormal_flg
from population pop
--join mimic2v26.icustay_detail icud on pop.hadm_id=icud.hadm_id and ICUSTAY_SEQ =1
join mimic2v26.labevents lab 
  on pop.icustay_id=lab.icustay_id 
  and lab.itemid in (50149, 50009) ---- 50009 is from blood gas
  and lab.valuenum is not null
  --and lab.charttime<=pop.ICUSTAY_INTIME+3/24
  --and pop.gender_num is not null
order by 1
)

--select distinct valueuom from lab_potassium_1;
--select * from lab_potassium_1 where valueuom is null;

, lab_potassium as
(select distinct icustay_id
--, first_value(potassium) over (partition by hadm_id order by charttime asc) as potassium_first
--, first_value(potassium) over (partition by hadm_id order by potassium asc) as potassium_lowest
--, first_value(potassium) over (partition by hadm_id order by potassium desc) as potassium_highest
--, first_value(abnormal_flg) over (partition by hadm_id order by abnormal_flg desc) potassium_abnormal_flg
, potassium_first
, case when potassium_first between 3.7 and 5.2 then 0 
       else 1 end as potassium_abnormal_flg
from lab_potassium_1
order by 1
)

--select * from lab_potassium; --20665

--- bicarbonate ---
, lab_tco2_1 as
(select pop.hadm_id
, pop.icustay_id
, pop.ICUSTAY_INTIME
, lab.charttime
--, lab.itemid
, lab.valueuom
--, lab.valuenum as tco2
, first_value(lab.valuenum) over (partition by pop.hadm_id order by charttime asc) as tco2_first
--, case when lab.valuenum between 22 and 28 then 0 else 1 end as abnormal_flg
from population pop
--join mimic2v26.icustay_detail icud on pop.hadm_id=icud.hadm_id and ICUSTAY_SEQ =1
join mimic2v26.labevents lab 
  on pop.icustay_id=lab.icustay_id 
  and lab.itemid in (50172, 50025,50022) --- (50025,50022,50172) the rest are from blood gas
  and lab.valuenum is not null
  --and lab.charttime<=pop.ICUSTAY_INTIME+3/24
  --and pop.gender_num is not null
order by 1
)

--select distinct valueuom from lab_tco2_1;
--select * from lab_tco2_1 where valueuom is null;

, lab_tco2 as
(select distinct icustay_id
--, first_value(tco2) over (partition by hadm_id order by charttime asc) as tco2_first
--, first_value(tco2) over (partition by hadm_id order by tco2 asc) as tco2_lowest
--, first_value(tco2) over (partition by hadm_id order by tco2 desc) as tco2_highest
--, first_value(abnormal_flg) over (partition by hadm_id order by abnormal_flg desc) tco2_abnormal_flg
, tco2_first
, case when tco2_first between 22 and 28 then 0 else 1 end as tco2_abnormal_flg
from lab_tco2_1
order by 1
)

--select * from lab_tco2; --11367

--- chloride ---
, lab_chloride_1 as
(select pop.hadm_id
, pop.icustay_id
, pop.ICUSTAY_INTIME
, lab.charttime
, lab.itemid
, lab.valueuom
, lab.valuenum as chloride
, first_value(lab.valuenum) over (partition by pop.hadm_id order by charttime asc) as chloride_first
--, case when lab.valuenum between 96 and 106 then 0 else 1 end as abnormal_flg
from population pop
--join mimic2v26.icustay_detail icud on pop.hadm_id=icud.hadm_id and ICUSTAY_SEQ =1
join mimic2v26.labevents lab 
  on pop.icustay_id=lab.icustay_id 
  and lab.itemid in (50083,50004) --- 50004 is from blood gas
  and lab.valuenum is not null
  --and lab.charttime<=pop.ICUSTAY_INTIME+3/24
  --and pop.gender_num is not null
order by 1
)

--select distinct valueuom from lab_chloride_1;
--select * from lab_chloride_1 where valueuom is null;

, lab_chloride as
(select distinct icustay_id
--, first_value(chloride) over (partition by hadm_id order by charttime asc) as chloride_first
--, first_value(chloride) over (partition by hadm_id order by chloride asc) as chloride_lowest
--, first_value(chloride) over (partition by hadm_id order by chloride desc) as chloride_highest
--, first_value(abnormal_flg) over (partition by hadm_id order by abnormal_flg desc) chloride_abnormal_flg
, chloride_first
, case when chloride_first between 96 and 106 then 0 else 1 end as chloride_abnormal_flg
from lab_chloride_1
order by 1
)

--select * from lab_chloride; --19461

--- bun ---
, lab_bun_1 as
(select pop.hadm_id
, pop.icustay_id
, pop.ICUSTAY_INTIME
, lab.charttime
--, lab.itemid
, lab.valueuom
--, lab.valuenum as bun
, first_value(lab.valuenum) over (partition by pop.hadm_id order by charttime asc) as bun_first
--, case when lab.valuenum between 6 and 20 then 0 else 1 end as abnormal_flg
from population pop
--join mimic2v26.icustay_detail icud on pop.hadm_id=icud.hadm_id and ICUSTAY_SEQ =1
join mimic2v26.labevents lab 
  on pop.icustay_id=lab.icustay_id 
  and lab.itemid = 50177 
  and lab.valuenum is not null
  --and lab.charttime<=pop.ICUSTAY_INTIME+3/24
  --and pop.gender_num is not null
order by 1
)

--select * from lab_bun_1;

, lab_bun as
(select distinct icustay_id
--, first_value(bun) over (partition by hadm_id order by charttime asc) as bun_first
----, first_value(abnormal_flg) over (partition by hadm_id order by chartime asc) as wbs_first_abn_flg
--, first_value(bun) over (partition by hadm_id order by bun asc) as bun_lowest
--, first_value(bun) over (partition by hadm_id order by bun desc) as bun_highest
--, first_value(abnormal_flg) over (partition by hadm_id order by abnormal_flg desc) bun_abnormal_flg
, bun_first
, case when bun_first between 6 and 20 then 0 else 1 end as bun_abnormal_flg
from lab_bun_1
order by 1
)

--select * from lab_bun; --19027

--- creatinine ---
, lab_creatinine_1 as
(select pop.hadm_id
, pop.icustay_id
, pop.ICUSTAY_INTIME
, pop.gender_num
, lab.charttime
, lab.valueuom
--, lab.valuenum as creatinine
, first_value(lab.valuenum) over (partition by pop.hadm_id order by charttime asc) as creatinine_first
--, case when pop.gender_num=1 and lab.valuenum <= 1.3 then 0 
--       when pop.gender_num=0 and lab.valuenum <= 1.1 then 0 
--        else 1 end as abnormal_flg
from population pop
--join mimic2v26.icustay_detail icud on pop.hadm_id=icud.hadm_id and ICUSTAY_SEQ =1
join mimic2v26.labevents lab 
  on pop.icustay_id=lab.icustay_id 
  and lab.itemid = 50090 
  and lab.valuenum is not null
  --and lab.charttime<=pop.ICUSTAY_INTIME+3/24
  and pop.gender_num is not null
order by 1
)

--select * from lab_creatinine_1;

, lab_creatinine as
(select distinct icustay_id
--, first_value(creatinine) over (partition by hadm_id order by charttime asc) as creatinine_first
----, first_value(abnormal_flg) over (partition by hadm_id order by chartime asc) as wbs_first_abn_flg
--, first_value(creatinine) over (partition by hadm_id order by creatinine asc) as creatinine_lowest
--, first_value(creatinine) over (partition by hadm_id order by creatinine desc) as creatinine_highest
--, first_value(abnormal_flg) over (partition by hadm_id order by abnormal_flg desc) creatinine_abnormal_flg
, creatinine_first
, case when gender_num=1 and creatinine_first <= 1.3 then 0 
       when gender_num=0 and creatinine_first <= 1.1 then 0 
        else 1 end as creatinine_abnormal_flg
from lab_creatinine_1
order by 1
)

--select * from lab_creatinine; --19027


--- Lactate ---
, lab_lactate_1 as
(select pop.hadm_id
, pop.icustay_id
, pop.ICUSTAY_INTIME
, lab.charttime
, lab.valueuom
--, lab.valuenum as lactate
, first_value(lab.valuenum) over (partition by pop.hadm_id order by charttime asc) as lactate_first
--, case when lab.valuenum between 0.5 and 2.2 then 0 else 1 end as abnormal_flg
from population pop
--join mimic2v26.icustay_detail icud on pop.hadm_id=icud.hadm_id and ICUSTAY_SEQ =1
join mimic2v26.labevents lab 
  on pop.icustay_id=lab.icustay_id 
  and lab.itemid = 50010 
  and lab.valuenum is not null
  --and lab.charttime<=pop.ICUSTAY_INTIME+3/24
  --and pop.gender_num is not null
order by 1
)

--select * from lab_lactate_1;

, lab_lactate as
(select distinct icustay_id
--, first_value(lactate) over (partition by hadm_id order by charttime asc) as lactate_first
----, first_value(abnormal_flg) over (partition by hadm_id order by chartime asc) as wbs_first_abn_flg
--, first_value(lactate) over (partition by hadm_id order by lactate asc) as lactate_lowest
--, first_value(lactate) over (partition by hadm_id order by lactate desc) as lactate_highest
--, first_value(abnormal_flg) over (partition by hadm_id order by abnormal_flg desc) lactate_abnormal_flg
, lactate_first
, case when lactate_first between 0.5 and 2.2 then 0 else 1 end as lactate_abnormal_flg
from lab_lactate_1
order by 1
)

--select * from lab_lactate; --9747

--- PH ---
, lab_ph_1 as
(select pop.hadm_id
, pop.icustay_id
, pop.ICUSTAY_INTIME
, lab.charttime
, lab.valueuom
--, lab.valuenum as ph
, first_value(lab.valuenum) over (partition by pop.hadm_id order by charttime asc) as ph_first
--, case when lab.valuenum between 7.38 and 7.42 then 0 else 1 end as abnormal_flg
from population pop
--join mimic2v26.icustay_detail icud on pop.hadm_id=icud.hadm_id and ICUSTAY_SEQ =1
join mimic2v26.labevents lab 
  on pop.icustay_id=lab.icustay_id 
  and lab.itemid = 50018 
  and lab.valuenum is not null
  --and lab.charttime<=pop.ICUSTAY_INTIME+3/24
  --and pop.gender_num is not null
order by 1
)

--select * from lab_ph_1;

, lab_ph as
(select distinct icustay_id
--, first_value(ph) over (partition by hadm_id order by charttime asc) as ph_first
----, first_value(abnormal_flg) over (partition by hadm_id order by chartime asc) as wbs_first_abn_flg
--, first_value(ph) over (partition by hadm_id order by ph asc) as ph_lowest
--, first_value(ph) over (partition by hadm_id order by ph desc) as ph_highest
--, first_value(abnormal_flg) over (partition by hadm_id order by abnormal_flg desc) ph_abnormal_flg
, ph_first
, case when ph_first between 7.38 and 7.42 then 0 else 1 end as ph_abnormal_flg
from lab_ph_1
order by 1
)

--select * from lab_ph; --13266

--- po2 ---
, lab_po2_1 as
(select pop.hadm_id
, pop.icustay_id
, pop.ICUSTAY_INTIME
, lab.charttime
, lab.valueuom
--, lab.valuenum as po2
, first_value(lab.valuenum) over (partition by pop.hadm_id order by charttime asc) as po2_first
--, case when lab.valuenum between 75 and 100 then 0 else 1 end as abnormal_flg
from population pop
--join mimic2v26.icustay_detail icud on pop.hadm_id=icud.hadm_id and ICUSTAY_SEQ =1
join mimic2v26.labevents lab 
  on pop.icustay_id=lab.icustay_id 
  and lab.itemid = 50019 
  and lab.valuenum is not null
  --and lab.charttime<=pop.ICUSTAY_INTIME+3/24
  --and pop.gender_num is not null
order by 1
)

--select * from lab_po2_1;

, lab_po2 as
(select distinct icustay_id
--, first_value(po2) over (partition by hadm_id order by charttime asc) as po2_first
----, first_value(abnormal_flg) over (partition by hadm_id order by chartime asc) as wbs_first_abn_flg
--, first_value(po2) over (partition by hadm_id order by po2 asc) as po2_lowest
--, first_value(po2) over (partition by hadm_id order by po2 desc) as po2_highest
--, first_value(abnormal_flg) over (partition by hadm_id order by abnormal_flg desc) po2_abnormal_flg
, po2_first
, case when po2_first between 75 and 100 then 0 else 1 end as po2_abnormal_flg
from lab_po2_1
order by 1
)

--select * from lab_po2; --12784

--- paco2 ---
, lab_pco2_1 as
(select pop.hadm_id
, pop.icustay_id
, pop.ICUSTAY_INTIME
, lab.charttime
, lab.valueuom
--, lab.valuenum as pco2
, first_value(lab.valuenum) over (partition by pop.hadm_id order by charttime asc) as pco2_first
--, case when lab.valuenum between 35 and 45 then 0 else 1 end as abnormal_flg
from population pop
--join mimic2v26.icustay_detail icud on pop.hadm_id=icud.hadm_id and ICUSTAY_SEQ =1
join mimic2v26.labevents lab 
  on pop.icustay_id=lab.icustay_id 
  and lab.itemid = 50016 
  and lab.valuenum is not null
  --and lab.charttime<=pop.ICUSTAY_INTIME+3/24
  --and pop.gender_num is not null
order by 1
)

--select * from lab_pco2_1;

, lab_pco2 as
(select distinct icustay_id
--, first_value(pco2) over (partition by hadm_id order by charttime asc) as pco2_first
----, first_value(abnormal_flg) over (partition by hadm_id order by chartime asc) as wbs_first_abn_flg
--, first_value(pco2) over (partition by hadm_id order by pco2 asc) as pco2_lowest
--, first_value(pco2) over (partition by hadm_id order by pco2 desc) as pco2_highest
--, first_value(abnormal_flg) over (partition by hadm_id order by abnormal_flg desc) pco2_abnormal_flg
, pco2_first
, case when pco2_first between 35 and 45 then 0 else 1 end as pco2_abnormal_flg
from lab_pco2_1
order by 1
)

--select * from lab_pco2; --12782


, final_table as
(select pop.icustay_id
, coalesce(vent.vent_1st_12hr, 0) as vent_1st_12hr
, coalesce(vaso.vaso_1st_12hr, 0) as vaso_1st_12hr
, coalesce(se.sedative_1st_12hr, 0) as sedative_1st_12hr

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


, wbc.wbc_first
, coalesce(wbc.wbc_first,0) as wbc_first_coded
--, wbc.wbc_lowest
--, wbc.wbc_highest
, wbc.wbc_abnormal_flg
, hgb.hgb_first
, coalesce(hgb.hgb_first, 0) as hgb_first_coded
--, hgb.hgb_lowest
--, hgb.hgb_highest
, hgb.hgb_abnormal_flg
, platelet.platelet_first
, coalesce(platelet.platelet_first, 0) as platelet_first_coded
--, platelet.platelet_lowest
--, platelet.platelet_highest
, platelet.platelet_abnormal_flg
, sodium.sodium_first
, coalesce(sodium.sodium_first, 0) as sodium_first_coded
--, sodium.sodium_lowest
--, sodium.sodium_highest
, sodium.sodium_abnormal_flg
, potassium.potassium_first
, coalesce(potassium.potassium_first, 0) as potassium_first_coded
--, potassium.potassium_lowest
--, potassium.potassium_highest
, potassium.potassium_abnormal_flg
, tco2.tco2_first
, coalesce(tco2.tco2_first, 0) as tco2_first_coded
--, tco2.tco2_lowest
--, tco2.tco2_highest
, tco2.tco2_abnormal_flg
, chloride.chloride_first
, coalesce(chloride.chloride_first, 0) as chloride_first_coded
--, chloride.chloride_lowest
--, chloride.chloride_highest
, chloride.chloride_abnormal_flg
, bun.bun_first
, coalesce(bun.bun_first, 0) as bun_first_coded
--, bun.bun_lowest
--, bun.bun_highest
, bun.bun_abnormal_flg
, creatinine.creatinine_first
, coalesce(creatinine.creatinine_first, 0) as creatinine_first_coded
--, creatinine.creatinine_lowest
--, creatinine.creatinine_highest
, creatinine.creatinine_abnormal_flg
, po2.po2_first
, coalesce(po2.po2_first, 0) as po2_first_coded
--, po2.po2_lowest
--, po2.po2_highest
, po2.po2_abnormal_flg
, pco2.pco2_first
, coalesce(pco2.pco2_first, 0) as pco2_first_coded
--, pco2.pco2_lowest
--, pco2.pco2_highest
, pco2.pco2_abnormal_flg
, lactate.lactate_first
, coalesce(lactate.lactate_first, 0) as lactate_first_coded
, lactate.lactate_abnormal_flg
, ph.ph_first
, coalesce(ph.ph_first, 0) as ph_first_coded
, ph.ph_abnormal_flg

from population pop
left join vent_group vent on pop.icustay_id = vent.icustay_id
left join vaso_group vaso on pop.icustay_id = vaso.icustay_id
left join sedative_group se on pop.icustay_id = se.icustay_id
left join vital_sign_min mi on pop.icustay_id = mi.icustay_id
left join vital_sign_max ma on pop.icustay_id = ma.icustay_id
left join vital_sign_avg av on pop.icustay_id = av.icustay_id
left join care_protocol care on pop.icustay_id = care.icustay_id

left join lab_wbc wbc on wbc.icustay_id=pop.icustay_id
left join lab_hgb hgb on hgb.icustay_id=pop.icustay_id
left join lab_platelet platelet on platelet.icustay_id=pop.icustay_id
left join lab_sodium sodium on sodium.icustay_id=pop.icustay_id
left join lab_potassium potassium on potassium.icustay_id=pop.icustay_id
left join lab_tco2 tco2 on tco2.icustay_id=pop.icustay_id
left join lab_chloride chloride on chloride.icustay_id=pop.icustay_id
left join lab_bun bun on bun.icustay_id=pop.icustay_id
left join lab_creatinine creatinine on creatinine.icustay_id=pop.icustay_id
left join lab_po2 po2 on po2.icustay_id=pop.icustay_id
left join lab_pco2 pco2 on pco2.icustay_id=pop.icustay_id
left join lab_ph ph on ph.icustay_id=pop.icustay_id
left join lab_lactate lactate on lactate.icustay_id=pop.icustay_id
)

select * from final_table;
