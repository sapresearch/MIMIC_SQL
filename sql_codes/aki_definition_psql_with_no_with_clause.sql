-- Translated for PostgreSQL by Ishrar
-- Runtime Recorded on PostgreSQL @MIMIC VM: 241.875 seconds
select distinct 
	icustay_id
	, onset_time
	, uo_mean
	, case when uo_mean< 0.5 then 1 else 0 end as aki_flg
	from ( select 
		a.icustay_id
		,a.charttime as onset_time
		, round( avg(b.uo_rate), 2 ) as uo_mean
		from ( select
			uo.icustay_id ,charttime,max_vol,time_span,icud.weight_first
			,cast(round(cast(uo.max_vol/uo.time_span/icud.weight_first as numeric),3) as double precision) as uo_rate
			from ( select 
				icustay_id,
				charttime, 
				max_vol,
				( case
					when ( icustay_id = lag( icustay_id ) over( order by icustay_id ) ) 
					then extract( day from charttime ) - extract( day from ( lag( charttime ) over( order by icustay_id ) ) )*24
						+ extract( hour from charttime ) - extract( hour from ( lag( charttime ) over( order by icustay_id ) ) )
						+ extract( minute from charttime ) - extract( minute from ( lag( charttime ) over( order by icustay_id ) ) )/60
					else null
				end) as time_span
				from (	select
					io.icustay_id,
					io.charttime 
					,max(volume) max_vol
					from mimic2v26.ioevents io,
						( select icustay_id,subject_id,icustay_intime,icustay_outtime from mimic2v26.icustay_detail
							where icustay_age_group='adult'
								and subject_icustay_seq=1
								and weight_first is not null
								and weight_first > 0
						) pop
						where io.icustay_id=pop.icustay_id
						and io.itemid in(651, 715, 55, 56, 57, 61, 65, 69, 85, 94, 96, 288, 405,
							428, 473, 2042, 2068, 2111, 2119, 2130, 1922, 2810, 2859,
							3053, 3462, 3519, 3175, 2366, 2463, 2507, 2510, 2592,
							2676, 3966, 3987, 4132, 4253, 5927 )
						group by io.icustay_id , charttime
					) uo_table
			) uo 
			left join mimic2v26.icustay_detail icud on uo.icustay_id = icud.icustay_id
			where uo.time_span is not null
		) a
		join ( select uo.icustay_id ,charttime,max_vol,time_span,icud.weight_first
			, round( uo.max_vol / uo.time_span / icud.weight_first, 3 ) as uo_rate
			from ( select 
				icustay_id,
				charttime, 
				max_vol,
				( case
					when ( icustay_id = lag( icustay_id ) over( order by icustay_id ) ) 
					then extract( day from charttime ) - extract( day from ( lag( charttime ) over( order by icustay_id ) ) )*24
						+ extract( hour from charttime ) - extract( hour from ( lag( charttime ) over( order by icustay_id ) ) )
						+ extract( minute from charttime ) - extract( minute from ( lag( charttime ) over( order by icustay_id ) ) )/60
					else null
				end) as time_span
				from (	select
						io.icustay_id,
						io.charttime 
						,max(volume) max_vol
						from mimic2v26.ioevents io,
							( select icustay_id,subject_id,icustay_intime,icustay_outtime from mimic2v26.icustay_detail
								where icustay_age_group='adult'
									and subject_icustay_seq=1
									and weight_first is not null
									and weight_first > 0
							) pop
						where io.icustay_id=pop.icustay_id
						and io.itemid in(651, 715, 55, 56, 57, 61, 65, 69, 85, 94, 96, 288, 405,
							428, 473, 2042, 2068, 2111, 2119, 2130, 1922, 2810, 2859,
							3053, 3462, 3519, 3175, 2366, 2463, 2507, 2510, 2592,
							2676, 3966, 3987, 4132, 4253, 5927 )
						group by io.icustay_id , charttime
					) uo_table
				) uo 
				left join mimic2v26.icustay_detail icud on uo.icustay_id = icud.icustay_id
				where uo.time_span is not null
					and uo.time_span != 0
			) b on a.icustay_id = b.icustay_id
			where 
				b.charttime between a.charttime and a.charttime + interval '6 hours'
			group by a.icustay_id, a.charttime
			order by 1,2
	) aki_onset_1 ;
