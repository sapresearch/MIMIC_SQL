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

DROP PROCEDURE view_average_num_sig;
CREATE PROCEDURE view_average_num_sig (IN SIG_NAME VARCHAR(10), IN NOISE_C VARCHAR(3)) 
	LANGUAGE SQLSCRIPT AS
	--DEFAULT SCHEMA "MIMIC2V26"
BEGIN
DECLARE view_exists INT := 0;
DECLARE query_string STRING;
SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "VIEW_NAME" = 'AVG_NUM_SIG_'  || :SIG_NAME;
IF :view_exists = 1 THEN
	EXEC 'DROP VIEW "AVG_NUM_SIG_' || :SIG_NAME || '"';
END IF;
query_string := 'CREATE VIEW "AVG_NUM_SIG_' || :SIG_NAME || '" AS 
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

CALL VIEW_AVERAGE_NUM_SIG('HR', 'on')
