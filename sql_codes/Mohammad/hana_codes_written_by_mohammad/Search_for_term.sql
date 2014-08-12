--THIS QUERY SEARCHES THE ENTIRE DATABASE FOR A TERM AND RETURNS 
--A DESCING LIST OF ITEMIDS, MATCHING LABELS, AND SOURCE TABLES WHERE THE TERM WAS FOUND.
DROP TYPE findchart_t;
CREATE TYPE findchart_t AS TABLE (
	"ITEMID" INTEGER CS_INT NOT NULL,
	"LABEL" VARCHAR(110),
	"COUNT_ITEMID" INTEGER CS_INT NOT NULL,
	"SOURCE" VARCHAR(110)
);

DROP PROCEDURE return_chart_ids_proc;
CREATE PROCEDURE return_chart_ids_proc (IN q_chart_name VARCHAR, OUT v_ret findchart_t)
	LANGUAGE SQLSCRIPT READS SQL DATA WITH RESULT VIEW return_chart_ids AS

BEGIN
    v_ret =	
	SELECT	"ITEMID" AS "ITEMID",
			"LABEL" AS "LABEL",
			COUNT("ITEMID") AS "COUNT_ITEMID",
			"SOURCE"	
	FROM
	(
		--FROM LABITEMS
	    SELECT	"ev"."ITEMID" AS "ITEMID",
			"di"."LABEL" AS "LABEL",
			'CHARTEVENTS' AS "SOURCE"
		FROM "MIMIC2V26"."chartevents"	"ev"
			JOIN "MIMIC2V26"."d_chartitems"	"di"
		ON "di"."ITEMID" = "ev"."ITEMID"
		WHERE LOWER("di"."LABEL") LIKE '%'|| :q_chart_name || '%'
		
		--FROM MEDITEMS
		UNION ALL
	    SELECT	"ev"."ITEMID" AS "ITEMID",
			"di"."LABEL" AS "LABEL",
			'MEDEVENTS' AS "SOURCE"
		FROM "MIMIC2V26"."medevents"	"ev"
			JOIN "MIMIC2V26"."d_meditems"	"di"
		ON "di"."ITEMID" = "ev"."ITEMID"
		WHERE LOWER("di"."LABEL") LIKE '%'|| :q_chart_name || '%'

		--FROM LABITEMS--
		UNION ALL
	    SELECT	"ev"."ITEMID" AS "ITEMID",
			"di"."TEST_NAME" AS "LABEL",
			'LABEVENTS' AS "SOURCE"
		FROM "MIMIC2V26"."labevents"	"ev"
			JOIN "MIMIC2V26"."d_labitems"	"di"
		ON "di"."ITEMID" = "ev"."ITEMID"
		WHERE LOWER("di"."TEST_NAME") LIKE '%'|| :q_chart_name || '%'
		
		--FROM IOITEMS--
		UNION ALL
	    SELECT	"ev"."ITEMID" AS "ITEMID",
			"di"."LABEL" AS "LABEL",
			'IOEVENTS' AS "SOURCE"
		FROM "MIMIC2V26"."ioevents"	"ev"
			JOIN "MIMIC2V26"."d_ioitems"	"di"
		ON "di"."ITEMID" = "ev"."ITEMID"
		WHERE LOWER("di"."LABEL") LIKE '%'|| :q_chart_name || '%'
		

		
	)
	GROUP BY "ITEMID", "LABEL","SOURCE"
	ORDER BY "COUNT_ITEMID" DESC ; 
		
END;


SELECT * 
FROM return_chart_ids 
WITH PARAMETERS('placeholder' = ('$$q_chart_name$$', ''));
