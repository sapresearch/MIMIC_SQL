-- author: Ishrar Hussain
-- email:  ishrar.hussain@sap.com
-- Copyright 2014 SAP Canada Inc.
-- ALL RIGHTS RESERVED

DROP PROCEDURE view_num_sig_to_ioevents;
CREATE PROCEDURE view_num_sig_to_ioevents (IN SIG_NAME VARCHAR(10), IN SUBJ_ID INTEGER, IN NOISE_C VARCHAR(3)) 
	LANGUAGE SQLSCRIPT AS
	--DEFAULT SCHEMA "MIMIC2V26"
BEGIN

DECLARE found_signal INT := 0;
DECLARE found_clinical INT := 0;
DECLARE query_string STRING;
	
SELECT COUNT(*) INTO found_signal FROM "MIMIC2V26"."wav_num_records","MIMIC2V26"."wav_num_signals"
	WHERE "SUBJECT_ID" = :SUBJ_ID
		AND "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
		AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME;
	
SELECT COUNT(*) INTO found_clinical FROM "MIMIC2V26"."ioevents"
	WHERE "SUBJECT_ID" = :SUBJ_ID;
	
IF :found_clinical = 0 THEN
	CALL "SYSTEM"."INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found in IOEVENTS!');
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."ioevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "SYSTEM"."MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSEIF :found_signal = 0 THEN
	CALL "SYSTEM"."INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found for the numeric signal: ' || :SIG_NAME);
	SELECT "MIMIC2V26"."wav_num_signals"."RECORD_ID", "SUBJECT_ID", "SIGNAL_NAME"
		FROM "MIMIC2V26"."wav_num_signals", "MIMIC2V26"."wav_num_records"
		WHERE "MIMIC2V26"."wav_num_signals"."RECORD_ID" = "MIMIC2V26"."wav_num_records"."RECORD_ID"
			AND "MIMIC2V26"."wav_num_records"."SUBJECT_ID" = :SUBJ_ID
			ORDER BY "MIMIC2V26"."wav_num_signals"."RECORD_ID";
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."ioevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "SYSTEM"."MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSE
	DECLARE view_exists INT := 0;
	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = 'MIMIC2V26' AND "VIEW_NAME" = 'JOIN_NUM_SIG_' || :SIG_NAME || '_TO_IOEVENTS_FOR_' || :SUBJ_ID;
	IF :view_exists = 1 THEN
		EXEC 'DROP VIEW "MIMIC2V26"."JOIN_NUM_SIG_' || :SIG_NAME || '_TO_IOEVENTS_FOR_' || :SUBJ_ID || '"';
	END IF;
	query_string := 'CREATE VIEW "MIMIC2V26"."JOIN_NUM_SIG_' || :SIG_NAME || '_TO_IOEVENTS_FOR_' || :SUBJ_ID || '" AS (
		( SELECT
			"t"."SUBJECT_ID",
			"t"."RECORD_ID" as "SIG_RECORD_ID",
			ADD_SECONDS("t"."RECORD_TIME",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."SAMPLE_ID"/"t"."SAMPLE_FREQ") as "TIME_SERIES",
			''[SIGNAL DATA]'' as "CATEGORY",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE"/"t"."ADC_GAIN" AS "AMPLITUDE",
			null as "LABEL",
			null as "VOLUME",
			null as "VOLUMEUOM",
			null as "UNITSHUNG",
			null as "UNITSHUNGUOM",
			null as "NEWBOTTLE",
			null as "STOPPED",
			null as "ESTIMATE"
			
			FROM
				
				"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '" ,
					
				( SELECT
					"MIMIC2V26"."wav_num_records"."SUBJECT_ID",
					"MIMIC2V26"."wav_num_records"."RECORD_TIME",
					"MIMIC2V26"."wav_num_records"."RECORD_ID",
					"MIMIC2V26"."wav_num_records"."SAMPLE_FREQ",
					"MIMIC2V26"."wav_num_signals"."ADC_GAIN"
					 
					FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
										
					WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID" 
						AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = ''' || :SIG_NAME || '''
						AND "MIMIC2V26"."wav_num_records"."SUBJECT_ID" = ' || :SUBJ_ID || '
								
				) AS "t" 
		
				WHERE "t"."RECORD_ID" = "MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."RECORD_ID" ';
	IF LOWER(:NOISE_C) = 'on' THEN
		query_string := query_string || ' AND "AMPLITUDE" > 0';
	END IF;
	query_string := query_string || '
		)
		UNION
		( SELECT
			"x"."SUBJECT_ID",
			null AS "SIG_RECORD_ID",
			"x"."REALTIME" AS "TIME_SERIES",
			"y"."CATEGORY" AS "CATEGORY",
			null AS "AMPLITUDE",
			"y"."LABEL" AS "LABEL",
			"x"."VOLUME",
			"x"."VOLUMEUOM",
			"x"."UNITSHUNG",
			"x"."UNITSHUNGUOM",
			"x"."NEWBOTTLE",
			"x"."STOPPED",
			"x"."ESTIMATE"
				
			FROM
				"MIMIC2V26"."ioevents" as "x" ,
				"MIMIC2V26"."d_ioitems" as "y"
				
			WHERE
				"x"."ITEMID" = "y"."ITEMID"
				AND "x"."SUBJECT_ID" = ' || :SUBJ_ID || '
		)
	)';
	EXEC query_string;
END IF;
END