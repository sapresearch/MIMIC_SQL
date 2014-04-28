/******************************************************************************/
/***************    Cohort Extraction for AKI project      ********************/
/***************    Created by Mornin Apr 2013              ********************/
/******************************************************************************/


with population as
(select ICUSTAY_ID,SUBJECT_ID,ICUSTAY_INTIME,ICUSTAY_OUTTIME from mimic2v26.ICUSTAY_DETAIL
where ICUSTAY_AGE_GROUP='adult'
and SUBJECT_ICUSTAY_SEQ=1 -- error corrected by mornin!
and WEIGHT_FIRST is not null
and weight_first >0
--and ICUSTAY_OUTTIME >= ICUSTAY_INTIME+interval '24' hour ---1st 15 (control+buffer) +3 (case) +6(aki) 
--and icustay_id<1000
)

--select * from population;

--gather uo data--table_temp is just all pts with certain itemid
, uo_table as
(
	select 
		io.ICUSTAY_ID,
		io.CHARTTIME 
		,max(VOLUME) max_vol
  from mimic2v26.IOEVENTS io, population pop
	where io.ICUSTAY_ID=pop.ICUSTAY_ID
	and io.ITEMID in(651, 715, 55, 56, 57, 61, 65, 69, 85, 94, 96, 288, 405,
                       428, 473, 2042, 2068, 2111, 2119, 2130, 1922, 2810, 2859,
                       3053, 3462, 3519, 3175, 2366, 2463, 2507, 2510, 2592,
                       2676, 3966, 3987, 4132, 4253, 5927 )                    
	group by io.ICUSTAY_ID , CHARTTIME 
)

--select * from uo_table;

--------------- calculating time span between uo readings ----------------
,uo_time_span as
(
	select 
		ICUSTAY_ID,
		CHARTTIME, 
    max_vol,    
   (case
				when (icustay_id=lag(icustay_id) over(order by icustay_id)) 
				then EXTRACT(day FROM (CHARTTIME-(lag(charttime) over(order by icustay_id))))*24 
        + EXTRACT(hour FROM (CHARTTIME-(lag(charttime) over(order by icustay_id))))
        +extract(minute from (CHARTTIME-(lag(charttime) over(order by icustay_id))))/60
			else NULL
		end) as time_span
	from uo_table
)
--select * from uo_time_span;

-------------------- calculate the normalized uo rate -------------------------
,normalized_uo as
(
	select uo.ICUSTAY_ID ,CHARTTIME,max_vol,time_span,icud.weight_first
  ,round(uo.max_vol/uo.time_span/icud.WEIGHT_first,3) as uo_rate
	from uo_time_span uo 
  left join mimic2v26.ICUSTAY_DETAIL icud on uo.ICUSTAY_ID=icud.ICUSTAY_ID 
	--left join population C on a.ICUSTAY_ID=c.ICUSTAY_ID 
	where uo.time_span is not null
)


, aki_onset_1 as
(select 
a.icustay_id
,a.charttime as onset_time
--, a.uo_rate as onset_uo
--, b.charttime
--, b.uo_rate
, round(avg(b.uo_rate),2) as uo_mean
from normalized_uo a --what to do here.
join normalized_uo b on a.icustay_id=b.icustay_id
where 
--a.uo_rate<0.5
--and 
b.charttime between a.charttime and a.charttime+6/24 --do i have to change this?
--and b.charttime>a.charttime
group by a.icustay_id, a.charttime
order by 1,2
)

--select * from aki_onset_1; --606sec



, aki_onset as
(
select distinct 
icustay_id
, onset_time
, uo_mean
, case when uo_mean<0.5 then 1 else 0end as aki_flg
from aki_onset_1
)

select * from aki_onset;