DROP PROCEDURE view_return_chart_ids;
CREATE PROCEDURE view_return_chart_ids (IN q_chart_name VARCHAR)
	LANGUAGE SQLSCRIPT AS

BEGIN
	DECLARE query_string STRING;
	DECLARE view_exists INT := 0;
	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = 'MIMIC2V26' AND "VIEW_NAME" = 'RETURN_CHART_IDS';
	IF :view_exists = 1 THEN
		EXEC 'DROP VIEW "MIMIC2V26"."RETURN_CHART_IDS"';
	END IF;
	query_string := 'CREATE VIEW "MIMIC2V26"."RETURN_CHART_IDS" AS (
			SELECT	"ev"."ITEMID" AS "ITEMID",
				"di"."LABEL" AS "LABEL",
				COUNT("ev"."ITEMID") AS "COUNT_ITEMID"
			FROM "MIMIC2V26"."chartevents"	"ev"
				JOIN "MIMIC2V26"."d_chartitems"	"di"
			ON "di"."ITEMID" = "ev"."ITEMID"
			WHERE LOWER("di"."LABEL") LIKE ''%'|| :q_chart_name || '%''
			GROUP BY "ev"."ITEMID", "di"."LABEL"
			ORDER BY "COUNT_ITEMID" DESC
		)';
	EXEC query_string;
END;

CALL "MIMIC2V26"."VIEW_RETURN_CHART_IDS"('po');
