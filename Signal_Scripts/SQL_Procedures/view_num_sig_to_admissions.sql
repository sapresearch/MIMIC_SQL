-- author: Ishrar Hussain
-- email:  ishrar.hussain@sap.com
-- Copyright 2014 SAP Canada Inc.
-- ALL RIGHTS RESERVED

DROP PROCEDURE view_num_sig_to_admissions;
CREATE PROCEDURE view_num_sig_to_admissions (IN SIG_NAME VARCHAR(10), IN SUBJ_ID INTEGER) 
	LANGUAGE SQLSCRIPT AS
	--DEFAULT SCHEMA "MIMIC2V26"
BEGIN

DECLARE found_signal INT := 0;
DECLARE found_clinical INT := 0;
	
SELECT COUNT(*) INTO found_signal FROM "MIMIC2V26"."wav_num_records","MIMIC2V26"."wav_num_signals"
	WHERE "SUBJECT_ID" = :SUBJ_ID
		AND "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
		AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME;
	
SELECT COUNT(*) INTO found_clinical FROM "MIMIC2V26"."admissions"
	WHERE "SUBJECT_ID" = :SUBJ_ID;
	
IF :found_clinical = 0 THEN
	CALL "SYSTEM"."INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found in ADMISSIONS!');
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."admissions" WHERE "SUBJECT_ID" IN
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
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."admissions" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "SYSTEM"."MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSE
	DECLARE view_exists INT := 0;
	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = 'MIMIC2V26' AND "VIEW_NAME" = 'JOIN_NUM_SIG_' || :SIG_NAME || '_TO_ADMISSIONS_FOR_' || :SUBJ_ID;
	IF :view_exists = 1 THEN
		EXEC 'DROP VIEW "MIMIC2V26"."JOIN_NUM_SIG_' || :SIG_NAME || '_TO_ADMISSIONS_FOR_' || :SUBJ_ID || '"';
	END IF;
	EXEC 'CREATE VIEW "MIMIC2V26"."JOIN_NUM_SIG_' || :SIG_NAME || '_TO_ADMISSIONS_FOR_' || :SUBJ_ID || '" AS (
		( SELECT
			"t"."SUBJECT_ID",
			"t"."RECORD_ID" AS "SIG_RECORD_ID",
			ADD_SECONDS("t"."RECORD_TIME",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."SAMPLE_ID"/"t"."SAMPLE_FREQ") AS "TIME_SERIES",
			''[SIGNAL DATA]'' AS "CATEGORY",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE"/"t"."ADC_GAIN" AS "AMPLITUDE"
			
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
		
				WHERE "t"."RECORD_ID" = "MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."RECORD_ID" 
					AND "AMPLITUDE" > 0
		)
		UNION
		( SELECT
			"x"."SUBJECT_ID",
			null AS "SIG_RECORD_ID",
			"x"."ADMIT_DT" AS "TIME_SERIES",
			''[ADMITTED]'' AS "CATEGORY",
			null AS "AMPLITUDE"
			
			FROM
				"MIMIC2V26"."admissions" AS "x"
				
				WHERE "x"."SUBJECT_ID" = ' || :SUBJ_ID || '
		)
		UNION
		( SELECT
			"x"."SUBJECT_ID",
			null AS "SIG_RECORD_ID",
			"x"."DISCH_DT" AS "TIME_SERIES",
			''[DISCHARGED]'' AS "CATEGORY",
			null AS "AMPLITUDE"
			
			FROM
				"MIMIC2V26"."admissions" AS "x"
				
				WHERE "x"."SUBJECT_ID" = ' || :SUBJ_ID || '
		)
	)';
END IF;
END