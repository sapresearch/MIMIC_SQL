DROP TYPE hourlyurine_t;
CREATE TYPE hourlyurine_t AS TABLE (
	"SUBJECT_ID" INTEGER CS_INT NOT NULL ,
	"ICUSTAY_ID" INTEGER CS_INT NOT NULL ,
	"DAY_HOUR" INTEGER CS_INT NOT NULL ,
	"VOLUME" DECIMAL CS_DECIMAL_FLOAT
);

DROP PROCEDURE hourly_urine_proc;
CREATE PROCEDURE hourly_urine_proc (IN q_item_id INTEGER, OUT v_ret hourlyurine_t)
	LANGUAGE SQLSCRIPT READS SQL DATA WITH RESULT VIEW hourly_urine AS

BEGIN
    v_ret =	
		SELECT "icud"."SUBJECT_ID",
		   "icud"."ICUSTAY_ID",
		   HOUR("ie"."CHARTTIME")	AS "DAY_HOUR",
		   SUM("ie"."VOLUME")			AS "VOLUME"
		FROM "MIMIC2V26"."ioevents"			"ie",
			 "MIMIC2V26"."icustay_detail"	"icud"
		WHERE "ie"."ITEMID" = :q_item_id
		  AND "icud"."ICUSTAY_AGE_GROUP"	= 'adult'
		  AND "icud"."ICUSTAY_ID"			= "ie"."ICUSTAY_ID"
		GROUP BY "icud"."SUBJECT_ID",
				 "icud"."ICUSTAY_ID",
				 HOUR("ie"."CHARTTIME")
		ORDER BY "icud"."SUBJECT_ID",
				 "icud"."ICUSTAY_ID",
				 "DAY_HOUR";
END;

SELECT * FROM hourly_urine WITH PARAMETERS('placeholder' = ('$$q_item_id$$', '651'));
