-- author: Ishrar Hussain
-- email:  ishrar.hussain@sap.com
-- Copyright 2014 SAP Canada Inc.
-- ALL RIGHTS RESERVED

DROP PROCEDURE build_num_sig_to_medevents;
CREATE PROCEDURE build_num_sig_to_medevents (IN SIG_NAME VARCHAR(10)) 
	LANGUAGE SQLSCRIPT AS
	--DEFAULT SCHEMA "MIMIC2V26"
BEGIN
--EXEC 'DROP PROCEDURE join_num_sig_' || :SIG_NAME || '_to_medevents';
EXEC 'CREATE PROCEDURE join_num_sig_' || :SIG_NAME || '_to_medevents (IN SUBJ_ID INTEGER) 
	LANGUAGE SQLSCRIPT AS
	--DEFAULT SCHEMA "MIMIC2V26"
	BEGIN
	
	DECLARE found_signal INT := 0;
	DECLARE found_clinical INT := 0;
	DECLARE SIG_NAME VARCHAR(10) := ''' || :SIG_NAME || ''';
	
	SELECT COUNT(*) INTO found_signal FROM "MIMIC2V26"."wav_num_records","MIMIC2V26"."wav_num_signals"
		WHERE "SUBJECT_ID" = :SUBJ_ID
			AND "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
			AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME;
	
	SELECT COUNT(*) INTO found_clinical FROM "MIMIC2V26"."medevents"
		WHERE "SUBJECT_ID" = :SUBJ_ID;
	
	IF :found_clinical = 0 THEN
		CALL "SYSTEM"."INS_MSG_PROC"(''SUBJECT_ID: '' || :SUBJ_ID || '' is not found in MEDEVENTS!'');
		SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."medevents" ORDER BY "SUBJECT_ID";
		SELECT TOP 1 "P_MSG" AS "ERROR" FROM "SYSTEM"."MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
	ELSEIF :found_signal = 0 THEN
		CALL "SYSTEM"."INS_MSG_PROC"(''SUBJECT_ID: '' || :SUBJ_ID || '' is not found for the numeric signal: '' || :SIG_NAME);
		SELECT "MIMIC2V26"."wav_num_signals"."RECORD_ID", "SUBJECT_ID", "SIGNAL_NAME"
			FROM "MIMIC2V26"."wav_num_signals", "MIMIC2V26"."wav_num_records"
			WHERE "MIMIC2V26"."wav_num_signals"."RECORD_ID" = "MIMIC2V26"."wav_num_records"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_records"."SUBJECT_ID" = :SUBJ_ID
				ORDER BY "MIMIC2V26"."wav_num_signals"."RECORD_ID";
		SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
				ORDER BY "SUBJECT_ID";
		SELECT TOP 1 "P_MSG" AS "ERROR" FROM "SYSTEM"."MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
	ELSE
		SELECT * FROM (
	
			( SELECT
				"t"."SUBJECT_ID",
				"t"."RECORD_ID" as "SIG_RECORD_ID",
				ADD_SECONDS("t"."RECORD_TIME",
				"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."SAMPLE_ID"/"t"."SAMPLE_FREQ") as "TIME_SERIES",
				''[SIGNAL DATA]'' as "LABEL",
				"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE"/"t"."ADC_GAIN",
				null as "VOLUME",
				null as "DOSE",
				null as "DOSEUOM",
				null as "SOLUTIONID",
				null as "SOLVOLUME",
				null as "SOLUNITS",
				null as "ROUTE",
				null as "STOPPED"
			
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
							AND "MIMIC2V26"."wav_num_records"."SUBJECT_ID" = :SUBJ_ID
									
					) AS "t" 
			
					WHERE "t"."RECORD_ID" = "MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."RECORD_ID" 
					AND "AMPLITUDE" > 0
			)
			UNION
			( SELECT
				"x"."SUBJECT_ID",
				null AS "SIG_RECORD_ID",
				"x"."REALTIME" AS "TIME_SERIES",
				"y"."LABEL" AS "LABEL",
				null AS "AMPLITUDE",
				"x"."VOLUME",
				"x"."DOSE",
				"x"."DOSEUOM",
				"x"."SOLUTIONID",
				"x"."SOLVOLUME",
				"x"."SOLUNITS",
				"x"."ROUTE",
				"x"."STOPPED"
				
				FROM
					"MIMIC2V26"."medevents" as "x" ,
					"MIMIC2V26"."d_meditems" as "y"
					
				WHERE
					"x"."ITEMID" = "y"."ITEMID"
					AND "x"."SUBJECT_ID" = :SUBJ_ID
			)
				
		) ORDER BY "TIME_SERIES";
	END IF;
	END';
END;
