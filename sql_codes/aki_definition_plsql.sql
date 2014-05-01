/******************************************************************************/
/***************    Cohort Extraction for AKI project      ********************/
/***************    Created by Mornin Apr 2013              ********************/
/******************************************************************************/


with "population" as
(select "ICUSTAY_ID","SUBJECT_ID","ICUSTAY_INTIME","ICUSTAY_OUTTIME" from "MIMIC2V26"."icustay_detail" -- fixed capitalizations for the schema naming conventions used in SAP HANA (Ishrar)
where "ICUSTAY_AGE_GROUP"='adult'
and "SUBJECT_ICUSTAY_SEQ"=1 -- error corrected by mornin!
and "WEIGHT_FIRST" is not null
and "WEIGHT_FIRST" >0
--and ICUSTAY_OUTTIME >= ICUSTAY_INTIME+interval '24' hour ---1st 15 (control+buffer) +3 (case) +6(aki) 
--and icustay_id<1000
)

--select * from population;

--gather uo data--table_temp is just all pts with certain itemid
, "uo_table" as
(
	select 
		"io"."ICUSTAY_ID",
		"io"."CHARTTIME" 
		,max("VOLUME") "max_vol"
  from "MIMIC2V26"."ioevents" "io", "population" "pop" -- fixed capitalizations for the schema naming conventions used in SAP HANA (Ishrar)
	where "io"."ICUSTAY_ID"="pop"."ICUSTAY_ID"
	and "io"."ITEMID" in(651, 715, 55, 56, 57, 61, 65, 69, 85, 94, 96, 288, 405,
                       428, 473, 2042, 2068, 2111, 2119, 2130, 1922, 2810, 2859,
                       3053, 3462, 3519, 3175, 2366, 2463, 2507, 2510, 2592,
                       2676, 3966, 3987, 4132, 4253, 5927 )                    
	group by "io"."ICUSTAY_ID" , "CHARTTIME"
)


--select * from uo_table;

--------------- calculating time span between uo readings ----------------
,"uo_time_span" as
(
	select 
		"ICUSTAY_ID",
		"CHARTTIME", 
    "max_vol",    
   (case
				when ("ICUSTAY_ID"=lag("ICUSTAY_ID") over(order by "ICUSTAY_ID")) 
				then extract(day FROM "CHARTTIME")-extract(day FROM (lag("CHARTTIME") over(order by "ICUSTAY_ID")))*24 -- HANA does not support subtraction of TIMESTAMPS. Now, fixed! (Ishrar) 
        + extract(hour FROM "CHARTTIME")-extract(hour FROM (lag("CHARTTIME") over(order by "ICUSTAY_ID")))
        +extract(minute from "CHARTTIME")-extract(minute from (lag("CHARTTIME") over(order by "ICUSTAY_ID")))/60
			else NULL
		end) as "TIME_SPAN"
	from "uo_table"
)
--select * from uo_time_span;

-------------------- calculate the normalized uo rate -------------------------
,"normalized_uo" as
(
	select "uo"."ICUSTAY_ID" ,"CHARTTIME","max_vol","TIME_SPAN","icud"."WEIGHT_FIRST"
  ,round("uo"."max_vol"/"uo"."TIME_SPAN"/"icud"."WEIGHT_FIRST",3) as "uo_rate"
	from "uo_time_span" "uo" 
  left join "MIMIC2V26"."icustay_detail" "icud" on "uo"."ICUSTAY_ID"="icud"."ICUSTAY_ID" -- fixed capitalizations for the schema naming conventions used in SAP HANA (Ishrar)
	--left join population C on a.ICUSTAY_ID=c.ICUSTAY_ID 
	where "uo"."TIME_SPAN" is not null
)


, "aki_onset_1" as
(select 
"a"."ICUSTAY_ID"
,"a"."CHARTTIME" as "onset_time"
--, a.uo_rate as onset_uo
--, b.charttime
--, b.uo_rate
, round(avg("b"."uo_rate"),2) as "uo_mean"
from "normalized_uo" "a" --what to do here.
join "normalized_uo" "b" on "a"."ICUSTAY_ID"="b"."ICUSTAY_ID"
where 
--a.uo_rate<0.5
--and 
"b"."CHARTTIME" between "a"."CHARTTIME" and "a"."CHARTTIME"+6/24 --do i have to change this?
																	-- Yes, please change this. Hana does not support addition operation on TIMESTAMP. (Ishrar)
--and b.charttime>a.charttime
group by "a"."ICUSTAY_ID", "a"."CHARTTIME"
order by 1,2
)

--select * from aki_onset_1; --606sec



, "aki_onset" as
(
select distinct 
"ICUSTAY_ID"
, "onset_time"
, "uo_mean"
, case when "uo_mean"<0.5 then 1 else 0end as "aki_flg"
from "aki_onset_1"
)

select * from "aki_onset";