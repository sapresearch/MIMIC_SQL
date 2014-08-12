DROP VIEW "MIMIC2V26"."MIMIC_TERMS";

CREATE VIEW "MIMIC2V26"."MIMIC_TERMS" AS 
(
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
		WHERE LOWER("di"."LABEL") LIKE '%%'
		
		--FROM MEDITEMS
		UNION ALL
	    SELECT	"ev"."ITEMID" AS "ITEMID",
			"di"."LABEL" AS "LABEL",
			'MEDEVENTS' AS "SOURCE"
		FROM "MIMIC2V26"."medevents"	"ev"
			JOIN "MIMIC2V26"."d_meditems"	"di"
		ON "di"."ITEMID" = "ev"."ITEMID"
		WHERE LOWER("di"."LABEL") LIKE '%%'

		--FROM LABITEMS--
		UNION ALL
	    SELECT	"ev"."ITEMID" AS "ITEMID",
			"di"."TEST_NAME" AS "LABEL",
			'LABEVENTS' AS "SOURCE"
		FROM "MIMIC2V26"."labevents"	"ev"
			JOIN "MIMIC2V26"."d_labitems"	"di"
		ON "di"."ITEMID" = "ev"."ITEMID"
		WHERE LOWER("di"."TEST_NAME") LIKE '%%'
		
		--FROM IOITEMS--
		UNION ALL
	    SELECT	"ev"."ITEMID" AS "ITEMID",
			"di"."LABEL" AS "LABEL",
			'IOEVENTS' AS "SOURCE"
		FROM "MIMIC2V26"."ioevents"	"ev"
			JOIN "MIMIC2V26"."d_ioitems"	"di"
		ON "di"."ITEMID" = "ev"."ITEMID"
		WHERE LOWER("di"."LABEL") LIKE '%%'
		

		
	)
	GROUP BY "ITEMID", "LABEL","SOURCE"
	ORDER BY "COUNT_ITEMID" DESC
);
