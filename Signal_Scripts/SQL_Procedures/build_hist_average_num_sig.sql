-- author: Ishrar Hussain
-- email:  ishrar.hussain@sap.com
-- Copyright 2014 SAP Canada Inc.
-- ALL RIGHTS RESERVED

DROP PROCEDURE build_hist_average_num_sig;
CREATE PROCEDURE build_hist_average_num_sig (IN SIG_NAME VARCHAR(10), IN NOISE_C VARCHAR(3)) 
	LANGUAGE SQLSCRIPT AS
	--DEFAULT SCHEMA "MIMIC2V26"
BEGIN
	DECLARE view_exists INT := 0;
	DECLARE query_string STRING;

	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = 'SYSTEM' AND "VIEW_NAME" = 'TEMP_VIEW_FOR_HISTOGRAM';
	IF :view_exists = 1 THEN
		EXEC 'DROP VIEW "SYSTEM"."TEMP_VIEW_FOR_HISTOGRAM"';
	END IF;
	query_string := 'CREATE VIEW "SYSTEM"."TEMP_VIEW_FOR_HISTOGRAM" AS 
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