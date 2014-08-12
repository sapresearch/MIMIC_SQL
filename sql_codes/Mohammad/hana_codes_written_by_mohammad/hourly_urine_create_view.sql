CREATE VIEW "MIMIC2V26"."hourly_urine_view" AS
( 

 SELECT "hum"."SUBJECT_ID",
    "hum"."ICUSTAY_ID",
    "miw"."max_weight",
    "hum"."day_hour",
    "hum"."volume"
      
  FROM
  (
  SELECT "icud"."SUBJECT_ID",
       "icud"."ICUSTAY_ID",
       "ie"."CHARTTIME" AS "day_hour",
       SUM("VOLUME")                AS "volume"      
		FROM "MIMIC2V26"."ioevents" "ie",
		     "MIMIC2V26"."icustay_detail" "icud"
		--THE URINARY ITEM IDS
		WHERE "ie"."ITEMID" IN ( 651, 715, 55, 56, 57, 61, 65, 69, 85, 94, 96, 288, 405, 428, 473, 2042, 2068, 2111, 2119, 2130, 1922, 2810, 2859, 3053, 3462, 3519, 3175, 2366, 2463, 2507, 2510, 2592, 2676, 3966, 3987, 4132, 4253, 5927 )
		  AND "icud"."ICUSTAY_AGE_GROUP" = 'adult'
		  AND "icud"."ICUSTAY_ID"        = "ie"."ICUSTAY_ID"
		  --AND icud.SUBJECT_ID < 100
		GROUP BY "icud"."SUBJECT_ID",
		         "icud"."ICUSTAY_ID",
		         "ie"."CHARTTIME"
		ORDER BY "icud"."SUBJECT_ID",
		         "icud"."ICUSTAY_ID",
		         "day_hour"
  
  	) "hum",
    (
     SELECT DISTINCT "icud"."SUBJECT_ID",
    "icud"."ICUSTAY_ID",
    MAX("ce"."VALUE1NUM") AS "max_weight"
  FROM "MIMIC2V26"."chartevents" "ce",
       "MIMIC2V26"."icustay_detail" "icud"
  WHERE "ITEMID"              IN ( 580, 1393, 762, 1395 )
 -- AND icud.SUBJECT_ID < 100
  AND "ce"."ICUSTAY_ID"          = "icud"."ICUSTAY_ID"
  AND "icud"."ICUSTAY_AGE_GROUP" = 'adult'
  AND "ce"."VALUE1NUM" IS NOT NULL
  AND "ce"."VALUE1NUM" >= 30 -- Arbitrary value to eliminate 0
  GROUP BY "icud"."SUBJECT_ID",
           "icud"."ICUSTAY_ID"
  ORDER BY "icud"."ICUSTAY_ID"
    ) "miw"
  WHERE "hum"."ICUSTAY_ID" = "miw"."ICUSTAY_ID"
  
  );