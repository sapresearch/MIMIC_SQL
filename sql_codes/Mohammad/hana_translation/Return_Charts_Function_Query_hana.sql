DROP TYPE findchart_t;
CREATE TYPE findchart_t AS TABLE (
	"ITEMID" INTEGER CS_INT NOT NULL,
	"LABEL" VARCHAR(110),
	"COUNT_ITEMID" INTEGER CS_INT NOT NULL
);

DROP PROCEDURE return_chart_ids_proc;
CREATE PROCEDURE return_chart_ids_proc (IN q_chart_name VARCHAR, OUT v_ret findchart_t)
	LANGUAGE SQLSCRIPT READS SQL DATA WITH RESULT VIEW return_chart_ids AS

BEGIN
    v_ret =	
	SELECT	"ev"."ITEMID" AS "ITEMID",
			"di"."LABEL" AS "LABEL",
			COUNT("ev"."ITEMID") AS "COUNT_ITEMID"
		FROM "MIMIC2V26"."chartevents"	"ev"
			JOIN "MIMIC2V26"."d_chartitems"	"di"
		ON "di"."ITEMID" = "ev"."ITEMID"
		WHERE LOWER("di"."LABEL") LIKE '%'|| :q_chart_name || '%'
		
		GROUP BY "ev"."ITEMID", "di"."LABEL"
		ORDER BY "COUNT_ITEMID" DESC ;
END;

SELECT * FROM return_chart_ids WITH PARAMETERS('placeholder' = ('$$q_chart_name$$', 'po'));
