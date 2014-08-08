-- Translated for SAP HANA by Ishrar
-- Runtime Recorded on SAP HANA @Cambridge HF1 Server: 37.728 seconds

WITH "population" AS
	( SELECT "ICUSTAY_ID","SUBJECT_ID","ICUSTAY_INTIME","ICUSTAY_OUTTIME" FROM "MIMIC2V26"."icustay_detail"
		WHERE "ICUSTAY_AGE_GROUP"='adult'
			AND "SUBJECT_ICUSTAY_SEQ"=1
			AND "WEIGHT_FIRST" IS NOT NULL
			AND "WEIGHT_FIRST" > 0
	)

-- gather uo data--table_temp is just all pts with certain itemid
, "uo_table" AS
	(	SELECT
			"io"."ICUSTAY_ID",
			"io"."CHARTTIME" 
			,MAX("VOLUME") "max_vol"
		FROM "MIMIC2V26"."ioevents" "io", "population" "pop"
		WHERE "io"."ICUSTAY_ID"="pop"."ICUSTAY_ID"
		AND "io"."ITEMID" in(651, 715, 55, 56, 57, 61, 65, 69, 85, 94, 96, 288, 405,
			428, 473, 2042, 2068, 2111, 2119, 2130, 1922, 2810, 2859,
			3053, 3462, 3519, 3175, 2366, 2463, 2507, 2510, 2592,
			2676, 3966, 3987, 4132, 4253, 5927 )
		GROUP BY "io"."ICUSTAY_ID" , "CHARTTIME"
	)

-- calculating time span between uo readings
,"uo_time_span" AS
	( SELECT 
		"ICUSTAY_ID",
		"CHARTTIME", 
		"max_vol",
		( CASE
			WHEN ( "ICUSTAY_ID" = LAG( "ICUSTAY_ID" ) OVER( ORDER BY "ICUSTAY_ID" ) ) 
			THEN EXTRACT( DAY FROM "CHARTTIME" ) - EXTRACT( DAY FROM ( LAG( "CHARTTIME" ) OVER( ORDER BY "ICUSTAY_ID" ) ) )*24
			+ EXTRACT( HOUR FROM "CHARTTIME" ) - EXTRACT( HOUR FROM ( LAG( "CHARTTIME" ) OVER( ORDER BY "ICUSTAY_ID" ) ) )
			+ EXTRACT( MINUTE FROM "CHARTTIME" ) - EXTRACT( MINUTE FROM ( LAG( "CHARTTIME" ) OVER( ORDER BY "ICUSTAY_ID" ) ) )/60
		ELSE NULL
		END) AS "TIME_SPAN"
		FROM "uo_table"
	)

-- calculate the normalized uo rate
,"normalized_uo" AS
	( SELECT "uo"."ICUSTAY_ID" ,"CHARTTIME","max_vol","TIME_SPAN","icud"."WEIGHT_FIRST"
		, ROUND( "uo"."max_vol" / "uo"."TIME_SPAN" / "icud"."WEIGHT_FIRST", 3 ) as "uo_rate"
		FROM "uo_time_span" "uo" 
		LEFT JOIN "MIMIC2V26"."icustay_detail" "icud" ON "uo"."ICUSTAY_ID" = "icud"."ICUSTAY_ID"
		WHERE "uo"."TIME_SPAN" IS NOT NULL
			AND "uo"."TIME_SPAN" != 0
	)

, "aki_onset_1" AS
	( SELECT 
		"a"."ICUSTAY_ID"
		,"a"."CHARTTIME" AS "onset_time"
		, ROUND( AVG("b"."uo_rate"), 2 ) AS "uo_mean"
		FROM "normalized_uo" "a"
		JOIN "normalized_uo" "b" ON "a"."ICUSTAY_ID" = "b"."ICUSTAY_ID"
		WHERE 
		"b"."CHARTTIME" BETWEEN "a"."CHARTTIME" AND ADD_SECONDS("a"."CHARTTIME", 60*60*6)
		GROUP BY "a"."ICUSTAY_ID", "a"."CHARTTIME"
		ORDER BY 1,2
	)

, "aki_onset" as
	(
	SELECT DISTINCT 
		"ICUSTAY_ID"
		, "onset_time"
		, "uo_mean"
		, CASE WHEN "uo_mean"< 0.5 THEN 1 ELSE 0 END AS "aki_flg"
		FROM "aki_onset_1"
	)

SELECT * FROM "aki_onset";
