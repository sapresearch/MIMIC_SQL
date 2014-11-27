-- author: Ishrar Hussain
-- email:  ishrar.hussain@sap.com
-- Copyright 2014 SAP Canada Inc.
-- ALL RIGHTS RESERVED

CREATE ROW TABLE "MESSAGE_BOX" ( "P_MSG" VARCHAR(200) CS_STRING,
	 "TSTAMP" LONGDATE CS_LONGDATE ) ;

CREATE PROCEDURE "INS_MSG_PROC" (p_msg VARCHAR(200)) LANGUAGE SQLSCRIPT AS
BEGIN
	INSERT INTO message_box VALUES (:p_msg, CURRENT_TIMESTAMP);
END;

DROP PROCEDURE build_hist_average_num_sig;
CREATE PROCEDURE build_hist_average_num_sig (IN SIG_NAME VARCHAR(10), IN NOISE_C VARCHAR(3)) 
	LANGUAGE SQLSCRIPT AS
	--DEFAULT SCHEMA "MIMIC2V26"
BEGIN
	DECLARE view_exists INT := 0;
	DECLARE query_string STRING;

	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "VIEW_NAME" = 'TEMP_VIEW_FOR_HISTOGRAM';
	IF :view_exists = 1 THEN
		EXEC 'DROP VIEW "TEMP_VIEW_FOR_HISTOGRAM"';
	END IF;
	query_string := 'CREATE VIEW "TEMP_VIEW_FOR_HISTOGRAM" AS 
	( SELECT
		"t"."SUBJECT_ID",
		"t"."RECORD_ID",
		"t"."AVG_AMP"/"MIMIC2V26"."wav_num_signals"."ADC_GAIN" AS "HIST_VALUE"
		FROM
			( SELECT
				"MIMIC2V26"."wav_num_records"."SUBJECT_ID",
				"MIMIC2V26"."wav_num_records"."RECORD_ID",
				AVG("MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE") AS "AVG_AMP"
				FROM "MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '", "MIMIC2V26"."wav_num_records"
				WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."RECORD_ID" ';
		IF LOWER(:NOISE_C) = 'on' THEN
			query_string := query_string || ' AND "MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE" > 0';
		ELSE
			query_string := query_string || ' AND "MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE" > -32768';
		END IF;
		query_string := query_string || '
				GROUP BY "MIMIC2V26"."wav_num_records"."SUBJECT_ID", "MIMIC2V26"."wav_num_records"."RECORD_ID"
			) AS "t",
			"MIMIC2V26"."wav_num_signals"
		WHERE "t"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
			AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = ''' || :SIG_NAME || '''
	)';
	EXEC query_string;
END;

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

	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "VIEW_NAME" = 'TEMP_VIEW_FOR_HISTOGRAM';
	IF :view_exists = 0 THEN
		CALL "INS_MSG_PROC"('"TEMP_VIEW_FOR_HISTOGRAM" does not exist in SYSTEM schema!');
		SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
	ELSE
		SELECT TO_INTEGER(MAX("SYSTEM"."TEMP_VIEW_FOR_HISTOGRAM"."HIST_VALUE")) INTO max_val FROM "SYSTEM"."TEMP_VIEW_FOR_HISTOGRAM";
		SELECT TO_INTEGER(MIN("SYSTEM"."TEMP_VIEW_FOR_HISTOGRAM"."HIST_VALUE")) INTO min_val FROM "SYSTEM"."TEMP_VIEW_FOR_HISTOGRAM";
	
		bucket_size := TO_INTEGER( (:max_val - :min_val) / :NUM_OF_BUCKETS );
		
		IF MOD((:max_val - :min_val), :NUM_OF_BUCKETS) != 0 THEN
			bucket_size := :bucket_size + 1;
		END IF;
		
		SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "VIEW_NAME" = 'HISTOGRAM_OF_AVG_NUM_SIG';
		IF :view_exists = 1 THEN
			EXEC 'DROP VIEW "HISTOGRAM_OF_AVG_NUM_SIG"';
		END IF;
		
		query_string := 'CREATE VIEW "HISTOGRAM_OF_AVG_NUM_SIG" AS (';
		
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

CALL BUILD_HIST_AVERAGE_NUM_SIG('HR', 'on');
CALL VIEW_HIST_AVERAGE_NUM_SIG(20)
