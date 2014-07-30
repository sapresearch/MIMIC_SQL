/******************************************************************************/
/***************    Cohort Extraction for AKI project      ********************/
/***************    Created by Mornin Apr 2013              ********************/
/******************************************************************************/
-- Translated for PostgreSQL by Ishrar
-- Runtime Recorded on PostgreSQL @MIMIC-VM: 159.561 seconds

with population as
(select icustay_id
,subject_id
,icustay_intime
,icustay_outtime
from mimic2v26.icustay_detail
where icustay_age_group='adult'
and subject_icustay_seq = 1 -- error corrected by mornin!
and weight_first is not null
and weight_first > 0
--and icustay_outtime >= icustay_intime+interval '24' hour ---1st 15 (control+buffer) +3 (case) +6(aki)
--and icustay_id<1000
)

--select * from population;
--, temp as
--(
--select io.icustay_id
--from population pop
--join "mimic2v26"."ioevents" io
--on io.icustay_id=pop.icustay_id
--)

--select * from temp;


--gather uo data--table_temp is just all pts with certain itemid
, uo_table as
(
select
io.icustay_id,
io.charttime
,max(volume) max_vol
  from mimic2v26.ioevents io, population pop
where io.icustay_id=pop.icustay_id
and io.itemid in(651, 715, 55, 56, 57, 61, 65, 69, 85, 94, 96, 288, 405,
                       428, 473, 2042, 2068, 2111, 2119, 2130, 1922, 2810, 2859,
                       3053, 3462, 3519, 3175, 2366, 2463, 2507, 2510, 2592,
                       2676, 3966, 3987, 4132, 4253, 5927 )
group by io.icustay_id , charttime
)

--select * from uo_table;
--select (charttime)-1 as temp from uo_table;

--------------- calculating time span between uo readings ----------------
,uo_time_span as
(
select
icustay_id,
charttime,
    max_vol,
   (case
when (icustay_id=lag(icustay_id) over(order by icustay_id))
then extract(day from (charttime-(lag(charttime) over(order by icustay_id))))*24
        + extract(hour from (charttime-(lag(charttime) over(order by icustay_id))))
        +extract(minute from (charttime-(lag(charttime) over(order by icustay_id))))/60
else null
end) as time_span
from uo_table
)
--select * from uo_time_span;

-------------------- calculate the normalized uo rate -------------------------
,normalized_uo as
(
select uo.icustay_id ,charttime,max_vol,time_span,icud.weight_first
  ,cast(round(cast(uo.max_vol/uo.time_span/icud.weight_first as numeric),3) as double precision) as uo_rate
from uo_time_span uo
  left join mimic2v26.icustay_detail icud on uo.icustay_id=icud.icustay_id
--left join population c on a.icustay_id=c.icustay_id
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
b.charttime between a.charttime and a.charttime + interval '6 hours'  --do i have to change this?
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
, case when uo_mean<0.5 then 1 else 0 end as aki_flg
from aki_onset_1
)

select * from aki_onset;
