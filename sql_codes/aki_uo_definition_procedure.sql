DROP TYPE aki_uo_def_t;
CREATE TYPE aki_uo_def_t AS TABLE (
	"ICUSTAY_ID" INTEGER CS_INT NOT NULL,
	"ONSET_TIME" TIMESTAMP,
	"AKI_FLG" INTEGER CS_INT
);

DROP PROCEDURE aki_uo_def_proc;
CREATE PROCEDURE aki_uo_def_proc (IN q_threshold DOUBLE, OUT v_ret aki_uo_def_t)
	LANGUAGE SQLSCRIPT READS SQL DATA WITH RESULT VIEW aki_uo_def AS

BEGIN
    v_ret =	
SELECT DISTINCT 
	"ICUSTAY_ID"
	, "onset_time" as "ONSET_TIME"
	--, "uo_mean"
	, CASE WHEN "uo_mean"< :q_threshold THEN 1 ELSE 0 END AS "AKI_FLG"
	FROM ( SELECT 
		"a"."ICUSTAY_ID"
		,"a"."CHARTTIME" AS "onset_time"
		, ROUND( AVG("b"."uo_rate"), 2 ) AS "uo_mean"
		FROM ( SELECT
			"uo"."ICUSTAY_ID" ,"CHARTTIME","max_vol", "MAX_CHARTTIME", "TIME_SPAN","icud"."WEIGHT_FIRST"
			, cast("uo"."max_vol" / "uo"."TIME_SPAN" / "icud"."WEIGHT_FIRST" as double) as "uo_rate"
			FROM ( SELECT 
					"ICUSTAY_ID",
					"CHARTTIME", 
					"max_vol",
					( CASE
						WHEN ( "ICUSTAY_ID" = LAG( "ICUSTAY_ID" ) OVER( ORDER BY "ICUSTAY_ID" ) ) 
						THEN EXTRACT( DAY FROM "CHARTTIME" ) - EXTRACT( DAY FROM ( LAG( "CHARTTIME" ) OVER( ORDER BY "ICUSTAY_ID", "CHARTTIME" ) ) )*24
							+ EXTRACT( HOUR FROM "CHARTTIME" ) - EXTRACT( HOUR FROM ( LAG( "CHARTTIME" ) OVER( ORDER BY "ICUSTAY_ID" , "CHARTTIME") ) )
							+ EXTRACT( MINUTE FROM "CHARTTIME" ) - EXTRACT( MINUTE FROM ( LAG( "CHARTTIME" ) OVER( ORDER BY "ICUSTAY_ID" , "CHARTTIME") ) )/60
						ELSE NULL
					END) AS "TIME_SPAN",
					first_value("CHARTTIME") over (partition by "ICUSTAY_ID" order by "CHARTTIME" desc) as "MAX_CHARTTIME"
					FROM (	SELECT
						"io"."ICUSTAY_ID",
						"io"."CHARTTIME" 
						,MAX("VOLUME") "max_vol"
						FROM "MIMIC2V26"."ioevents" "io", ( SELECT "ICUSTAY_ID","SUBJECT_ID","ICUSTAY_INTIME","ICUSTAY_OUTTIME" FROM "MIMIC2V26"."icustay_detail"
							WHERE "ICUSTAY_AGE_GROUP"='adult'
								AND "SUBJECT_ICUSTAY_SEQ"=1
								AND "WEIGHT_FIRST" IS NOT NULL
								AND "WEIGHT_FIRST" > 0
						) "pop"
					WHERE "io"."ICUSTAY_ID"="pop"."ICUSTAY_ID"
						AND "io"."ITEMID" in(651, 715, 55, 56, 57, 61, 65, 69, 85, 94, 96, 288, 405,
							428, 473, 2042, 2068, 2111, 2119, 2130, 1922, 2810, 2859,
							3053, 3462, 3519, 3175, 2366, 2463, 2507, 2510, 2592,
							2676, 3966, 3987, 4132, 4253, 5927 )
						And "VOLUME" is not null
					GROUP BY "io"."ICUSTAY_ID" , "CHARTTIME"
				)
			) "uo" 
			LEFT JOIN "MIMIC2V26"."icustay_detail" "icud" ON "uo"."ICUSTAY_ID" = "icud"."ICUSTAY_ID"
			WHERE "uo"."TIME_SPAN" IS NOT NULL and "uo"."TIME_SPAN">0
		) "a"
		JOIN ( SELECT "uo"."ICUSTAY_ID" ,"CHARTTIME","max_vol","TIME_SPAN","icud"."WEIGHT_FIRST"
				,  cast("uo"."max_vol" / "uo"."TIME_SPAN" / "icud"."WEIGHT_FIRST" as double) as "uo_rate"
				FROM ( SELECT 
					"ICUSTAY_ID",
					"CHARTTIME", 
					"max_vol",
					( CASE
						WHEN ( "ICUSTAY_ID" = LAG( "ICUSTAY_ID" ) OVER( ORDER BY "ICUSTAY_ID" ) ) 
						THEN EXTRACT( DAY FROM "CHARTTIME" ) - EXTRACT( DAY FROM ( LAG( "CHARTTIME" ) OVER( ORDER BY "ICUSTAY_ID", "CHARTTIME" ) ) )*24
						+ EXTRACT( HOUR FROM "CHARTTIME" ) - EXTRACT( HOUR FROM ( LAG( "CHARTTIME" ) OVER( ORDER BY "ICUSTAY_ID", "CHARTTIME" ) ) )
						+ EXTRACT( MINUTE FROM "CHARTTIME" ) - EXTRACT( MINUTE FROM ( LAG( "CHARTTIME" ) OVER( ORDER BY "ICUSTAY_ID", "CHARTTIME" ) ) )/60
						ELSE NULL
					END) AS "TIME_SPAN",
					first_value("CHARTTIME") over (partition by "ICUSTAY_ID" order by "CHARTTIME" desc) as "MAX_CHARTTIME"
					FROM (	SELECT
							"io"."ICUSTAY_ID",
							"io"."CHARTTIME" 
							,MAX("VOLUME") "max_vol"
							FROM "MIMIC2V26"."ioevents" "io", ( SELECT "ICUSTAY_ID","SUBJECT_ID","ICUSTAY_INTIME","ICUSTAY_OUTTIME" FROM "MIMIC2V26"."icustay_detail"
								WHERE "ICUSTAY_AGE_GROUP"='adult'
									AND "SUBJECT_ICUSTAY_SEQ"=1
									AND "WEIGHT_FIRST" IS NOT NULL
									AND "WEIGHT_FIRST" > 0
						) "pop"
						WHERE "io"."ICUSTAY_ID"="pop"."ICUSTAY_ID"
							AND "io"."ITEMID" in(651, 715, 55, 56, 57, 61, 65, 69, 85, 94, 96, 288, 405,
								428, 473, 2042, 2068, 2111, 2119, 2130, 1922, 2810, 2859,
								3053, 3462, 3519, 3175, 2366, 2463, 2507, 2510, 2592,
								2676, 3966, 3987, 4132, 4253, 5927 )
							And "VOLUME" is not null
						GROUP BY "io"."ICUSTAY_ID" , "CHARTTIME"
					)
				) "uo" 
				LEFT JOIN "MIMIC2V26"."icustay_detail" "icud" ON "uo"."ICUSTAY_ID" = "icud"."ICUSTAY_ID"
				WHERE "uo"."TIME_SPAN" IS NOT NULL
					AND "uo"."TIME_SPAN" > 0
			) "b" ON "a"."ICUSTAY_ID" = "b"."ICUSTAY_ID" AND "a"."CHARTTIME"<=ADD_SECONDS("a"."MAX_CHARTTIME", -60*60*6)
			WHERE 
				"b"."CHARTTIME" BETWEEN "a"."CHARTTIME" AND ADD_SECONDS("a"."CHARTTIME", 60*60*6)
			GROUP BY "a"."ICUSTAY_ID", "a"."CHARTTIME"
			--ORDER BY 3 desc
	);
END;

select * from aki_uo_def WITH PARAMETERS('placeholder' = ('$$q_threshold$$', '0.5'));
