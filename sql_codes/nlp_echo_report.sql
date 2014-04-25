drop materialized view mimic2v26_echo_groups;
--create materialized view mimic2v26_echo_groups as

with adults as (

  select distinct id.subject_id, id.icustay_id, 
      id.icustay_intime,
      id.icustay_outtime,
      id.gender
    from mimic2v25.icustay_detail id 
    where 
    --id.icustay_admit_age < 90
        id.icustay_id is not null
        and id.gender is not null
        and id.icustay_age_group = 'adult'
        
)
--select * from adults;
--select count(distinct icustay_id) from adults; -- 23,630 subject_id, 31,133 icustay_id

, echo_reports as (
  select ne.subject_id, ne.icustay_id, 
    case when ne.charttime > fc.icustay_intime and ne.charttime < fc.icustay_outtime 
      then 1 else 0
    end as echo_during_icustay,
    fc.icustay_intime,
    fc.icustay_outtime,
    ne.charttime echo_time,
    substr(ne.text,regexp_instr(ne.text,'[[:digit:]]{2}\%')-1,4) lvef_range,
    replace(replace(ne.text, chr(13), ''), chr(10), '') text
    from adults fc
    join  mimic2v25.noteevents ne on fc.icustay_id = ne.icustay_id
      where ne.category like 'ECHO_REPORT'
)
--select * from echo_reports where echo_during_icustay = 0;
--select count(distinct icustay_id) from echo_reports; -- 4655 subject_id, 5063 icustay_id

, lvef_group as (
  select er.subject_id, er.icustay_id,
    er.icustay_intime,
    er.icustay_outtime,
    er.echo_time,
    er.echo_during_icustay,
   case when er.lvef_range like '%10%'
          or er.lvef_range like '%15%'
          or er.lvef_range like '%20%'
          or er.lvef_range like '%25%'
          or er.lvef_range like '%30%'
          or er.lvef_range like '-35%'
          or er.lvef_range like '35%'
          or lower(er.text) like '%systolic function is severely depressed%'
          or lower(er.text) like '%systolic function appears severely depressed%'
          or lower(er.text) like '%severe%systolic dysfunction%'
          or lower(er.text) like '%severe%left ventricular hypokinesis%'
          or lower(er.text) like '%severe%LV hypokinesis%'
    then 1 
    when er.lvef_range like '>35'
          or er.lvef_range like '?35'
          or er.lvef_range like '%39%'
          or er.lvef_range like '%40%'
          or er.lvef_range like '%45%'
          or er.lvef_range like '%50%'
          or er.lvef_range like '-55%'
          or lower(er.text) like '%systolic function is midly depressed%'
          or lower(er.text) like '%systolic function appears midly depressed%'
          or lower(er.text) like '%systolic function is moderately depressed%'
          or lower(er.text) like '%systolic function appears moderately depressed%'
          or lower(er.text) like '%systolic function appears broadly depressed%'
          or lower(er.text) like '%mild%systolic dysfunction%'
          or lower(er.text) like '%moderate%systolic dysfunction%'
    then 2 
    when er.lvef_range like '%55%'
          or er.lvef_range like '50%'
          or er.lvef_range like '%60%'
          or er.lvef_range like '%65%'
          or er.lvef_range like '%-70'
          or lower(er.text) like '%systolic function is normal%'
          or lower(er.text) like '%systolic function appears normal%'
    then 3 
    when er.lvef_range like '>70%'
          or er.lvef_range like '%75%'
          or er.lvef_range like '%80%'
          or er.lvef_range like '%85%'
          or lower(er.text) like '%%hyperdynamic%'
          or lower(er.text) like '%%hypercontractile%'
          or lower(er.text) like '%hyperkinetic%'
    then 4 else 0 end as lvef_group,
    er.text
  from echo_reports er 
  order by icustay_id
)
--select * from lvef_group where lvef_group = 3 and rownum < 50;
--select count(distinct icustay_id) from lvef_group where lvef_group = 1 or lvef_group = 2; -- 1,793 subject_id, 1,890 icustay_id
--select count(distinct icustay_id) from lvef_group where lvef_group = 3 or lvef_group = 4; --2,431 subject_id, 2,570 icustay_id

, lvef as (
  select distinct subject_id, icustay_id, echo_time, echo_during_icustay,
    max(lvef_group) over (partition by icustay_id, echo_time) lvef
    from lvef_group
)
select * from lvef; --140secs



