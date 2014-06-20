-- author: Ishrar Hussain
-- email:  ishrar.hussain@sap.com
-- Copyright 2014 SAP Canada Inc.
-- ALL RIGHTS RESERVED

DROP PROCEDURE view_hist_average_num_sig;
CREATE PROCEDURE view_hist_average_num_sig (IN NUM_OF_BUCKETS INTEGER) 
	LANGUAGE SQLSCRIPT AS
	--DEFAULT SCHEMA "MIMIC2V26"
BEGIN
IF :NUM_OF_BUCKETS > 0 THEN
	DECLARE view_exists INT := 0;
	DECLARE min_val INT := 0;
	DECLARE max_val INT := 0;
	DECLARE next_min_val INT := 0;
	DECLARE loop_idx INT := 0;
	DECLARE bucket_size INT := 0;
	DECLARE query_string CLOB;

	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = 'SYSTEM' AND "VIEW_NAME" = 'TEMP_VIEW_FOR_HISTOGRAM';
	IF :view_exists = 0 THEN
		CALL "SYSTEM"."INS_MSG_PROC"('"TEMP_VIEW_FOR_HISTOGRAM" does not exist in SYSTEM schema!');
		SELECT TOP 1 "P_MSG" AS "ERROR" FROM "SYSTEM"."MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
	ELSE
		SELECT TO_INTEGER(MAX("SYSTEM"."TEMP_VIEW_FOR_HISTOGRAM"."HIST_VALUE")) INTO max_val FROM "SYSTEM"."TEMP_VIEW_FOR_HISTOGRAM";
		SELECT TO_INTEGER(MIN("SYSTEM"."TEMP_VIEW_FOR_HISTOGRAM"."HIST_VALUE")) INTO min_val FROM "SYSTEM"."TEMP_VIEW_FOR_HISTOGRAM";
	
		bucket_size := TO_INTEGER( (:max_val - :min_val) / :NUM_OF_BUCKETS );
		
		IF MOD((:max_val - :min_val), :NUM_OF_BUCKETS) != 0 THEN
			bucket_size := :bucket_size + 1;
		END IF;
		
		SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = 'MIMIC2V26' AND "VIEW_NAME" = 'HISTOGRAM_OF_AVG_NUM_SIG';
		IF :view_exists = 1 THEN
			EXEC 'DROP VIEW "MIMIC2V26"."HISTOGRAM_OF_AVG_NUM_SIG"';
		END IF;
		
		query_string := 'CREATE VIEW "MIMIC2V26"."HISTOGRAM_OF_AVG_NUM_SIG" AS (';
		
		next_min_val := :min_val + :bucket_size;
		
		WHILE :next_min_val < :max_val DO
			query_string := query_string || '
				( SELECT
					'|| :min_val ||' AS "CLASS_MIN",
					'|| :next_min_val ||' AS "CLASS_MAX",
					COUNT(*) AS "FREQUENCY"
					FROM "SYSTEM"."TEMP_VIEW_FOR_HISTOGRAM"
					WHERE "SYSTEM"."TEMP_VIEW_FOR_HISTOGRAM"."HIST_VALUE" >= '|| :min_val ||'
						AND "SYSTEM"."TEMP_VIEW_FOR_HISTOGRAM"."HIST_VALUE" < '|| :next_min_val ||'
				)
				UNION';
			min_val := :next_min_val;
			next_min_val := :min_val + :bucket_size;
			IF :next_min_val >= :max_val THEN
				query_string := query_string || '
				( SELECT
				'|| :min_val ||' AS "CLASS_MIN",
				NULL AS "CLASS_MAX",
					COUNT(*) AS "FREQUENCY"
					FROM "SYSTEM"."TEMP_VIEW_FOR_HISTOGRAM"
					WHERE "SYSTEM"."TEMP_VIEW_FOR_HISTOGRAM"."HIST_VALUE" >= '|| :min_val ||'
				) )';
			END IF;
		END WHILE;
		EXEC query_string;
	END IF;
END IF;
END;