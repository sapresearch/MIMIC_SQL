DROP TYPE findmed_t;
CREATE TYPE findmed_t AS TABLE (
	"ITEMID" INTEGER CS_INT NOT NULL,
	"LABEL" VARCHAR(20),
	"COUNT_ITEMID" INTEGER CS_INT NOT NULL
);

DROP PROCEDURE return_meds_ids_proc;
CREATE PROCEDURE return_meds_proc (IN q_med_name VARCHAR, OUT v_ret findchart_t)
	LANGUAGE SQLSCRIPT READS SQL DATA WITH RESULT VIEW return_meds AS

BEGIN
    v_ret =	
	SELECT	"ev"."ITEMID" AS "ITEMID",
			"di"."LABEL" AS "LABEL",
			COUNT("ev"."ITEMID") AS "COUNT_ITEMID"
		FROM "MIMIC2V26"."medevents"	"ev"
			JOIN "MIMIC2V26"."d_meditems"	"di"
		ON "di"."ITEMID" = "ev"."ITEMID"
		WHERE LOWER("di"."LABEL") LIKE '%'|| :q_med_name || '%'
		
		GROUP BY "ev"."ITEMID", "di"."LABEL"
		ORDER BY "COUNT_ITEMID" DESC ;
END;

SELECT * FROM return_meds WITH PARAMETERS('placeholder' = ('$$q_med_name$$', 'po'));
