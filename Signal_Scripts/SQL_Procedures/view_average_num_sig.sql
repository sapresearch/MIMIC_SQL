-- author: Ishrar Hussain
-- email:  ishrar.hussain@sap.com
-- Copyright 2014 SAP Canada Inc.
-- ALL RIGHTS RESERVED

DROP PROCEDURE view_average_num_sig;
CREATE PROCEDURE view_average_num_sig (IN SIG_NAME VARCHAR(10)) 
	LANGUAGE SQLSCRIPT AS
	--DEFAULT SCHEMA "MIMIC2V26"
BEGIN
DECLARE view_exists INT := 0;
SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = 'MIMIC2V26' AND "VIEW_NAME" = 'AVG_NUM_SIG_'  || :SIG_NAME;
IF :view_exists = 1 THEN
	EXEC 'DROP VIEW "MIMIC2V26"."AVG_NUM_SIG_' || :SIG_NAME || '"';
END IF;
EXEC 'CREATE VIEW "MIMIC2V26"."AVG_NUM_SIG_' || :SIG_NAME || '" AS 
( SELECT
	"t"."SUBJECT_ID",
	"t"."RECORD_ID",
	"t"."AVG_AMP"/"MIMIC2V26"."wav_num_signals"."ADC_GAIN" AS "AVERAGE_' || :SIG_NAME || '"
	FROM
		( SELECT
			"MIMIC2V26"."wav_num_records"."SUBJECT_ID",
			"MIMIC2V26"."wav_num_records"."RECORD_ID",
			AVG("MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE") AS "AVG_AMP"
			FROM "MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '", "MIMIC2V26"."wav_num_records"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE" > 0
			GROUP BY "MIMIC2V26"."wav_num_records"."SUBJECT_ID", "MIMIC2V26"."wav_num_records"."RECORD_ID"
		) AS "t",
		"MIMIC2V26"."wav_num_signals"
	WHERE "t"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
		AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = ''' || :SIG_NAME || '''
)';
END;