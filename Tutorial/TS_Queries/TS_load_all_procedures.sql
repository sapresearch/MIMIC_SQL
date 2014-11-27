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

DROP PROCEDURE view_num_sig_to_noteevents;
CREATE PROCEDURE view_num_sig_to_noteevents (IN SIG_NAME VARCHAR(10), IN SUBJ_ID INTEGER, IN NOISE_C VARCHAR(3)) 
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
	
SELECT COUNT(*) INTO found_clinical FROM "MIMIC2V26"."noteevents"
	WHERE "SUBJECT_ID" = :SUBJ_ID;
	
IF :found_clinical = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found in NOTEEVENTS!');
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."noteevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSEIF :found_signal = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found for the numeric signal: ' || :SIG_NAME);
	SELECT "MIMIC2V26"."wav_num_signals"."RECORD_ID", "SUBJECT_ID", "SIGNAL_NAME"
		FROM "MIMIC2V26"."wav_num_signals", "MIMIC2V26"."wav_num_records"
		WHERE "MIMIC2V26"."wav_num_signals"."RECORD_ID" = "MIMIC2V26"."wav_num_records"."RECORD_ID"
			AND "MIMIC2V26"."wav_num_records"."SUBJECT_ID" = :SUBJ_ID
			ORDER BY "MIMIC2V26"."wav_num_signals"."RECORD_ID";
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."noteevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSE
	DECLARE view_exists INT := 0;
	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "VIEW_NAME" = 'JOIN_NUM_SIG_' || :SIG_NAME || '_TO_NOTEEVENTS_FOR_' || :SUBJ_ID;
	IF :view_exists = 1 THEN
		EXEC 'DROP VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_NOTEEVENTS_FOR_' || :SUBJ_ID || '"';
	END IF;
	query_string := 'CREATE VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_NOTEEVENTS_FOR_' || :SUBJ_ID || '" AS (
		( SELECT
			"t"."SUBJECT_ID",
			"t"."RECORD_ID" AS "SIG_RECORD_ID",
			ADD_SECONDS("t"."RECORD_TIME",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."SAMPLE_ID"/"t"."SAMPLE_FREQ") AS "TIME_SERIES",
			''[SIGNAL DATA]'' AS "CATEGORY",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE"/"t"."ADC_GAIN" AS "AMPLITUDE",
			null AS "CAREGIVER",
			null AS "TITLE",
			null AS "TEXT",
			null AS "EXAM_NAME",
			null AS "CORRECTION"
			
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
			"x"."CHARTTIME" AS "TIME_SERIES",
			"x"."CATEGORY" AS "CATEGORY",
			null AS "AMPLITUDE",
			"y"."LABEL" AS "CAREGIVER",
			"x"."TITLE",
			TO_VARCHAR("x"."TEXT"),
			"x"."EXAM_NAME",
			"x"."CORRECTION"
			
			FROM
				"MIMIC2V26"."noteevents" AS "x" ,
				"MIMIC2V26"."d_caregivers" AS "y"
				
				WHERE "x"."CGID" = "y"."CGID"
					AND "x"."SUBJECT_ID" = ' || :SUBJ_ID || '
		)
	)';
	EXEC query_string;
END IF;
END;

DROP PROCEDURE view_num_sig_to_procedureevents;
CREATE PROCEDURE view_num_sig_to_procedureevents (IN SIG_NAME VARCHAR(10), IN SUBJ_ID INTEGER, IN NOISE_C VARCHAR(3)) 
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
	
SELECT COUNT(*) INTO found_clinical FROM "MIMIC2V26"."procedureevents"
	WHERE "SUBJECT_ID" = :SUBJ_ID;
	
IF :found_clinical = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found in PROCEDUREEVENTS!');
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."procedureevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSEIF :found_signal = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found for the numeric signal: ' || :SIG_NAME);
	SELECT "MIMIC2V26"."wav_num_signals"."RECORD_ID", "SUBJECT_ID", "SIGNAL_NAME"
		FROM "MIMIC2V26"."wav_num_signals", "MIMIC2V26"."wav_num_records"
		WHERE "MIMIC2V26"."wav_num_signals"."RECORD_ID" = "MIMIC2V26"."wav_num_records"."RECORD_ID"
			AND "MIMIC2V26"."wav_num_records"."SUBJECT_ID" = :SUBJ_ID
			ORDER BY "MIMIC2V26"."wav_num_signals"."RECORD_ID";
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."procedureevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSE
	DECLARE view_exists INT := 0;
	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "VIEW_NAME" = 'JOIN_NUM_SIG_' || :SIG_NAME || '_TO_PROCEDUREEVENTS_FOR_' || :SUBJ_ID;
	IF :view_exists = 1 THEN
		EXEC 'DROP VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_PROCEDUREEVENTS_FOR_' || :SUBJ_ID || '"';
	END IF;
	query_string := 'CREATE VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_PROCEDUREEVENTS_FOR_' || :SUBJ_ID || '" AS (
		( SELECT
			"t"."SUBJECT_ID",
			"t"."RECORD_ID" AS "SIG_RECORD_ID",
			ADD_SECONDS("t"."RECORD_TIME",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."SAMPLE_ID"/"t"."SAMPLE_FREQ") AS "TIME_SERIES",
			''[SIGNAL DATA]'' AS "CATEGORY",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE"/"t"."ADC_GAIN" AS "AMPLITUDE",
			null AS "DESCRIPTION"
			
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
			"x"."PROC_DT" AS "TIME_SERIES",
			"y"."TYPE" AS "CATEGORY",
			null AS "AMPLITUDE",
			"y"."DESCRIPTION" AS "DESCRIPTION"
			
			FROM
				"MIMIC2V26"."procedureevents" AS "x" ,
				"MIMIC2V26"."d_codeditems" AS "y"
				
				WHERE "x"."ITEMID" = "y"."ITEMID"
					AND "x"."SUBJECT_ID" = ' || :SUBJ_ID || '
		)
	)';
	EXEC query_string;
END IF;
END;

DROP PROCEDURE view_num_sig_to_labevents;
CREATE PROCEDURE view_num_sig_to_labevents (IN SIG_NAME VARCHAR(10), IN SUBJ_ID INTEGER, IN NOISE_C VARCHAR(3)) 
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
	
SELECT COUNT(*) INTO found_clinical FROM "MIMIC2V26"."labevents"
	WHERE "SUBJECT_ID" = :SUBJ_ID;
	
IF :found_clinical = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found in LABEVENTS!');
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."labevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSEIF :found_signal = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found for the numeric signal: ' || :SIG_NAME);
	SELECT "MIMIC2V26"."wav_num_signals"."RECORD_ID", "SUBJECT_ID", "SIGNAL_NAME"
		FROM "MIMIC2V26"."wav_num_signals", "MIMIC2V26"."wav_num_records"
		WHERE "MIMIC2V26"."wav_num_signals"."RECORD_ID" = "MIMIC2V26"."wav_num_records"."RECORD_ID"
			AND "MIMIC2V26"."wav_num_records"."SUBJECT_ID" = :SUBJ_ID
			ORDER BY "MIMIC2V26"."wav_num_signals"."RECORD_ID";
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."labevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSE
	DECLARE view_exists INT := 0;
	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "VIEW_NAME" = 'JOIN_NUM_SIG_' || :SIG_NAME || '_TO_LABEVENTS_FOR_' || :SUBJ_ID;
	IF :view_exists = 1 THEN
		EXEC 'DROP VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_LABEVENTS_FOR_' || :SUBJ_ID || '"';
	END IF;
	query_string := 'CREATE VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_LABEVENTS_FOR_' || :SUBJ_ID || '" AS (
		( SELECT
			"t"."SUBJECT_ID",
			"t"."RECORD_ID" as "SIG_RECORD_ID",
			ADD_SECONDS("t"."RECORD_TIME",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."SAMPLE_ID"/"t"."SAMPLE_FREQ") AS "TIME_SERIES",
			''[SIGNAL DATA]'' as "CATEGORY",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE"/"t"."ADC_GAIN" AS "AMPLITUDE",
			null as "TEST_NAME",
			null as "FLUID",
			null as "LOINC_CODE",
			null as "LOINC_DESCRIPTION",
			null as "VALUE",
			null as "VALUENUM",
			null as "VALUEUOM",
			null as "FLAG"
			
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
			"x"."CHARTTIME" AS "TIME_SERIES",
			"y"."CATEGORY" AS "CATEGORY",
			null AS "AMPLITUDE",
			"y"."TEST_NAME",
			"y"."FLUID",
			"y"."LOINC_CODE",
			"y"."LOINC_DESCRIPTION",
			"x"."VALUE",
			"x"."VALUENUM",
			"x"."VALUEUOM",
			"x"."FLAG"
				
			FROM
				"MIMIC2V26"."labevents" as "x" ,
				"MIMIC2V26"."d_labitems" as "y"
				
			WHERE
				"x"."ITEMID" = "y"."ITEMID"
				AND "x"."SUBJECT_ID" = ' || :SUBJ_ID || '
		)
	)';
	EXEC query_string;
END IF;
END;

DROP PROCEDURE view_num_sig_to_microbiologyevents;
CREATE PROCEDURE view_num_sig_to_microbiologyevents (IN SIG_NAME VARCHAR(10), IN SUBJ_ID INTEGER, IN NOISE_C VARCHAR(3)) 
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
	
SELECT COUNT(*) INTO found_clinical FROM "MIMIC2V26"."microbiologyevents"
	WHERE "SUBJECT_ID" = :SUBJ_ID;
	
IF :found_clinical = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found in MICROBIOLOGYEVENTS!');
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."microbiologyevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSEIF :found_signal = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found for the numeric signal: ' || :SIG_NAME);
	SELECT "MIMIC2V26"."wav_num_signals"."RECORD_ID", "SUBJECT_ID", "SIGNAL_NAME"
		FROM "MIMIC2V26"."wav_num_signals", "MIMIC2V26"."wav_num_records"
		WHERE "MIMIC2V26"."wav_num_signals"."RECORD_ID" = "MIMIC2V26"."wav_num_records"."RECORD_ID"
			AND "MIMIC2V26"."wav_num_records"."SUBJECT_ID" = :SUBJ_ID
		ORDER BY "MIMIC2V26"."wav_num_signals"."RECORD_ID";
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."microbiologyevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSE
	DECLARE view_exists INT := 0;
	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "VIEW_NAME" = 'JOIN_NUM_SIG_' || :SIG_NAME || '_TO_MICROBIOLOGYEVENTS_FOR_' || :SUBJ_ID;
	IF :view_exists = 1 THEN
		EXEC 'DROP VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_MICROBIOLOGYEVENTS_FOR_' || :SUBJ_ID || '"';
	END IF;
	query_string := 'CREATE VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_MICROBIOLOGYEVENTS_FOR_' || :SUBJ_ID || '" AS (
		( SELECT
			"t"."SUBJECT_ID",
			"t"."RECORD_ID" AS "SIG_RECORD_ID",
			ADD_SECONDS("t"."RECORD_TIME",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."SAMPLE_ID"/"t"."SAMPLE_FREQ") AS "TIME_SERIES",
			''[SIGNAL DATA]'' AS "CATEGORY",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE"/"t"."ADC_GAIN" AS "AMPLITUDE",
			null AS "ANTIBACTERIUM",
			null AS "SPECIMEN",
			null AS "ORGANISM",
			null AS "DILUTION_AMOUNT",
			null AS "DILUTION_COMPARISON",
			null AS "INTERPRETATION",
			null AS "ISOLATE_NUM"
			
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
			"SUBJECT_ID",
			null AS "SIG_RECORD_ID",
			"CHARTTIME" AS "TIME_SERIES",
			"MIMIC2V26"."d_codeditems"."TYPE" AS "CATEGORY",
			null AS "AMPLITUDE",
			"q"."ANTIBACTERIUM",
			"q"."SPECIMEN",
			"MIMIC2V26"."d_codeditems"."LABEL" AS "ORGANISM",
			"q"."DILUTION_AMOUNT",
			"q"."DILUTION_COMPARISON",
			"q"."INTERPRETATION",
			"q"."ISOLATE_NUM"
			FROM
				( SELECT 
					"p"."ANTIBACTERIUM",
					"MIMIC2V26"."d_codeditems"."LABEL" AS "SPECIMEN",
					"p"."DILUTION_AMOUNT",
					"p"."DILUTION_COMPARISON",
					"p"."INTERPRETATION",
					"p"."SUBJECT_ID",
					"p"."HADM_ID",
					"p"."CHARTTIME",
					"p"."SPEC_ITEMID",
					"p"."ORG_ITEMID",
					"p"."ISOLATE_NUM"
					FROM
						( SELECT 
							"MIMIC2V26"."d_codeditems"."LABEL" AS "ANTIBACTERIUM",
							"DILUTION_AMOUNT",
							"DILUTION_COMPARISON",
							"INTERPRETATION",
							"SUBJECT_ID",
							"HADM_ID",
							"CHARTTIME",
							"SPEC_ITEMID",
							"ORG_ITEMID",
							"ISOLATE_NUM"
							FROM "MIMIC2V26"."microbiologyevents", "MIMIC2V26"."d_codeditems"
							WHERE "AB_ITEMID" = "ITEMID" ) AS "p",
						"MIMIC2V26"."d_codeditems"
					WHERE "p"."SPEC_ITEMID" = "ITEMID" ) AS "q",
				"MIMIC2V26"."d_codeditems"
				WHERE "q"."ORG_ITEMID" = "ITEMID"
					AND "SUBJECT_ID" = ' || :SUBJ_ID || '
					AND "CHARTTIME" is not null
		)
	)';
	EXEC query_string;
END IF;
END;

DROP PROCEDURE view_num_sig_to_medevents;
CREATE PROCEDURE view_num_sig_to_medevents (IN SIG_NAME VARCHAR(10), IN SUBJ_ID INTEGER, IN NOISE_C VARCHAR(3)) 
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
	
SELECT COUNT(*) INTO found_clinical FROM "MIMIC2V26"."medevents"
	WHERE "SUBJECT_ID" = :SUBJ_ID;
	
IF :found_clinical = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found in MEDEVENTS!');
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."medevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSEIF :found_signal = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found for the numeric signal: ' || :SIG_NAME);
	SELECT "MIMIC2V26"."wav_num_signals"."RECORD_ID", "SUBJECT_ID", "SIGNAL_NAME"
		FROM "MIMIC2V26"."wav_num_signals", "MIMIC2V26"."wav_num_records"
		WHERE "MIMIC2V26"."wav_num_signals"."RECORD_ID" = "MIMIC2V26"."wav_num_records"."RECORD_ID"
			AND "MIMIC2V26"."wav_num_records"."SUBJECT_ID" = :SUBJ_ID
			ORDER BY "MIMIC2V26"."wav_num_signals"."RECORD_ID";
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."medevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSE
	DECLARE view_exists INT := 0;
	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "VIEW_NAME" = 'JOIN_NUM_SIG_' || :SIG_NAME || '_TO_MEDEVENTS_FOR_' || :SUBJ_ID;
	IF :view_exists = 1 THEN
		EXEC 'DROP VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_MEDEVENTS_FOR_' || :SUBJ_ID || '"';
	END IF;
	query_string := 'CREATE VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_MEDEVENTS_FOR_' || :SUBJ_ID || '" AS (
		( SELECT
			"t"."SUBJECT_ID",
			"t"."RECORD_ID" as "SIG_RECORD_ID",
			ADD_SECONDS("t"."RECORD_TIME",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."SAMPLE_ID"/"t"."SAMPLE_FREQ") AS "TIME_SERIES",
			''[SIGNAL DATA]'' as "LABEL",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE"/"t"."ADC_GAIN" AS "AMPLITUDE",
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
				AND "x"."SUBJECT_ID" = ' || :SUBJ_ID || '
		)
				
	)';
	EXEC query_string;
END IF;
END;

DROP PROCEDURE view_num_sig_to_icustayevents;
CREATE PROCEDURE view_num_sig_to_icustayevents (IN SIG_NAME VARCHAR(10), IN SUBJ_ID INTEGER, IN NOISE_C VARCHAR(3)) 
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
	
SELECT COUNT(*) INTO found_clinical FROM "MIMIC2V26"."icustayevents"
	WHERE "SUBJECT_ID" = :SUBJ_ID;
	
IF :found_clinical = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found in ICUSTAYEVENTS!');
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."icustayevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSEIF :found_signal = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found for the numeric signal: ' || :SIG_NAME);
	SELECT "MIMIC2V26"."wav_num_signals"."RECORD_ID", "SUBJECT_ID", "SIGNAL_NAME"
		FROM "MIMIC2V26"."wav_num_signals", "MIMIC2V26"."wav_num_records"
		WHERE "MIMIC2V26"."wav_num_signals"."RECORD_ID" = "MIMIC2V26"."wav_num_records"."RECORD_ID"
			AND "MIMIC2V26"."wav_num_records"."SUBJECT_ID" = :SUBJ_ID
			ORDER BY "MIMIC2V26"."wav_num_signals"."RECORD_ID";
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."icustayevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSE
	DECLARE view_exists INT := 0;
	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "VIEW_NAME" = 'JOIN_NUM_SIG_' || :SIG_NAME || '_TO_ICUSTAYEVENTS_FOR_' || :SUBJ_ID;
	IF :view_exists = 1 THEN
		EXEC 'DROP VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_ICUSTAYEVENTS_FOR_' || :SUBJ_ID || '"';
	END IF;
	query_string := 'CREATE VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_ICUSTAYEVENTS_FOR_' || :SUBJ_ID || '" AS (
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
			"x"."INTIME" AS "TIME_SERIES",
			''[ENTERED ICU]'' AS "CATEGORY",
			null AS "AMPLITUDE"
			
			FROM
				"MIMIC2V26"."icustayevents" AS "x"
				
				WHERE "x"."SUBJECT_ID" = ' || :SUBJ_ID || '
		)
		UNION
		( SELECT
			"x"."SUBJECT_ID",
			null AS "SIG_RECORD_ID",
			"x"."OUTTIME" AS "TIME_SERIES",
			''[EXITED ICU]'' AS "CATEGORY",
			null AS "AMPLITUDE"
			
			FROM
				"MIMIC2V26"."icustayevents" AS "x"
				
				WHERE "x"."SUBJECT_ID" = ' || :SUBJ_ID || '
		)
	)';
	EXEC query_string;
END IF;
END;

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
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found in IOEVENTS!');
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."ioevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSEIF :found_signal = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found for the numeric signal: ' || :SIG_NAME);
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
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSE
	DECLARE view_exists INT := 0;
	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "VIEW_NAME" = 'JOIN_NUM_SIG_' || :SIG_NAME || '_TO_IOEVENTS_FOR_' || :SUBJ_ID;
	IF :view_exists = 1 THEN
		EXEC 'DROP VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_IOEVENTS_FOR_' || :SUBJ_ID || '"';
	END IF;
	query_string := 'CREATE VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_IOEVENTS_FOR_' || :SUBJ_ID || '" AS (
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
END;

DROP PROCEDURE view_num_sig_to_chartevents;
CREATE PROCEDURE view_num_sig_to_chartevents (IN SIG_NAME VARCHAR(10), IN SUBJ_ID INTEGER, IN NOISE_C VARCHAR(3)) 
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
	
SELECT COUNT(*) INTO found_clinical FROM "MIMIC2V26"."chartevents"
	WHERE "SUBJECT_ID" = :SUBJ_ID;
	
IF :found_clinical = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found in CHARTEVENTS!');
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."chartevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSEIF :found_signal = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found for the numeric signal: ' || :SIG_NAME);
	SELECT "MIMIC2V26"."wav_num_signals"."RECORD_ID", "SUBJECT_ID", "SIGNAL_NAME"
		FROM "MIMIC2V26"."wav_num_signals", "MIMIC2V26"."wav_num_records"
		WHERE "MIMIC2V26"."wav_num_signals"."RECORD_ID" = "MIMIC2V26"."wav_num_records"."RECORD_ID"
			AND "MIMIC2V26"."wav_num_records"."SUBJECT_ID" = :SUBJ_ID
			ORDER BY "MIMIC2V26"."wav_num_signals"."RECORD_ID";
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."chartevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSE
	DECLARE view_exists INT := 0;
	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "VIEW_NAME" = 'JOIN_NUM_SIG_' || :SIG_NAME || '_TO_CHARTEVENTS_FOR_' || :SUBJ_ID;
	IF :view_exists = 1 THEN
		EXEC 'DROP VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_CHARTEVENTS_FOR_' || :SUBJ_ID || '"';
	END IF;
	query_string := 'CREATE VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_CHARTEVENTS_FOR_' || :SUBJ_ID || '" AS (
		( SELECT
			"t"."SUBJECT_ID",
			"t"."RECORD_ID" AS "SIG_RECORD_ID",
			ADD_SECONDS("t"."RECORD_TIME",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."SAMPLE_ID"/"t"."SAMPLE_FREQ") AS "TIME_SERIES",
			''[SIGNAL DATA]'' AS "CATEGORY",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE"/"t"."ADC_GAIN" AS "AMPLITUDE",
			null AS "LABEL",
			null AS "VALUE1",
			null AS "VALUE1NUM",
			null AS "VALUE1UOM",
			null AS "VALUE2",
			null AS "VALUE2NUM",
			null AS "VALUE2UOM",
			null AS "STOPPED"
			
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
			"y"."LABEL",
			"x"."VALUE1",
			"x"."VALUE1NUM",
			"x"."VALUE1UOM",
			"x"."VALUE2",
			"x"."VALUE2NUM",
			"x"."VALUE2UOM",
			"x"."STOPPED"
				
			FROM
				"MIMIC2V26"."chartevents" AS "x" ,
				"MIMIC2V26"."d_chartitems" AS "y"
				
			WHERE
				"x"."ITEMID" = "y"."ITEMID"
				AND "x"."SUBJECT_ID" = ' || :SUBJ_ID || '
		)
	)';
	EXEC query_string;
END IF;
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

DROP PROCEDURE view_num_sig_to_admissions;
CREATE PROCEDURE view_num_sig_to_admissions (IN SIG_NAME VARCHAR(10), IN SUBJ_ID INTEGER, IN NOISE_C VARCHAR(3)) 
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
	
SELECT COUNT(*) INTO found_clinical FROM "MIMIC2V26"."admissions"
	WHERE "SUBJECT_ID" = :SUBJ_ID;
	
IF :found_clinical = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found in ADMISSIONS!');
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."admissions" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSEIF :found_signal = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found for the numeric signal: ' || :SIG_NAME);
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
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSE
	DECLARE view_exists INT := 0;
	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "VIEW_NAME" = 'JOIN_NUM_SIG_' || :SIG_NAME || '_TO_ADMISSIONS_FOR_' || :SUBJ_ID;
	IF :view_exists = 1 THEN
		EXEC 'DROP VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_ADMISSIONS_FOR_' || :SUBJ_ID || '"';
	END IF;
	query_string := 'CREATE VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_ADMISSIONS_FOR_' || :SUBJ_ID || '" AS (
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
	EXEC query_string;
END IF;
END;

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
		CALL "INS_MSG_PROC"(''SUBJECT_ID: '' || :SUBJ_ID || '' is not found in MEDEVENTS!'');
		SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."medevents" ORDER BY "SUBJECT_ID";
		SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
	ELSEIF :found_signal = 0 THEN
		CALL "INS_MSG_PROC"(''SUBJECT_ID: '' || :SUBJ_ID || '' is not found for the numeric signal: '' || :SIG_NAME);
		SELECT "MIMIC2V26"."wav_num_signals"."RECORD_ID", "SUBJECT_ID", "SIGNAL_NAME"
			FROM "MIMIC2V26"."wav_num_signals", "MIMIC2V26"."wav_num_records"
			WHERE "MIMIC2V26"."wav_num_signals"."RECORD_ID" = "MIMIC2V26"."wav_num_records"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_records"."SUBJECT_ID" = :SUBJ_ID
				ORDER BY "MIMIC2V26"."wav_num_signals"."RECORD_ID";
		SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
				ORDER BY "SUBJECT_ID";
		SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
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

DROP PROCEDURE build_num_sig_to_ioevents;
CREATE PROCEDURE build_num_sig_to_ioevents (IN SIG_NAME VARCHAR(10)) 
	LANGUAGE SQLSCRIPT AS
	--DEFAULT SCHEMA "MIMIC2V26"
BEGIN
--EXEC 'DROP PROCEDURE join_num_sig_' || :SIG_NAME || '_to_ioevents';
EXEC 'CREATE PROCEDURE join_num_sig_' || :SIG_NAME || '_to_ioevents (IN SUBJ_ID INTEGER) 
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
	
	SELECT COUNT(*) INTO found_clinical FROM "MIMIC2V26"."ioevents"
		WHERE "SUBJECT_ID" = :SUBJ_ID;
	
	IF :found_clinical = 0 THEN
		CALL "INS_MSG_PROC"(''SUBJECT_ID: '' || :SUBJ_ID || '' is not found in IOEVENTS!'');
		SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."ioevents" ORDER BY "SUBJECT_ID";
		SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
	ELSEIF :found_signal = 0 THEN
		CALL "INS_MSG_PROC"(''SUBJECT_ID: '' || :SUBJ_ID || '' is not found for the numeric signal: '' || :SIG_NAME);
		SELECT "MIMIC2V26"."wav_num_signals"."RECORD_ID", "SUBJECT_ID", "SIGNAL_NAME"
			FROM "MIMIC2V26"."wav_num_signals", "MIMIC2V26"."wav_num_records"
			WHERE "MIMIC2V26"."wav_num_signals"."RECORD_ID" = "MIMIC2V26"."wav_num_records"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_records"."SUBJECT_ID" = :SUBJ_ID
				ORDER BY "MIMIC2V26"."wav_num_signals"."RECORD_ID";
		SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
				ORDER BY "SUBJECT_ID";
		SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
	ELSE
		SELECT * FROM (
	
			( SELECT
				"t"."SUBJECT_ID",
				"t"."RECORD_ID" as "SIG_RECORD_ID",
				ADD_SECONDS("t"."RECORD_TIME",
				"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."SAMPLE_ID"/"t"."SAMPLE_FREQ") as "TIME_SERIES",
				''[SIGNAL DATA]'' as "CATEGORY",
				"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE"/"t"."ADC_GAIN",
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
					AND "x"."SUBJECT_ID" = :SUBJ_ID
			)
				
		) ORDER BY "TIME_SERIES";
	END IF;
	END';
END;

DROP PROCEDURE view_num_sig_to_totalbalevents;
CREATE PROCEDURE view_num_sig_to_totalbalevents (IN SIG_NAME VARCHAR(10), IN SUBJ_ID INTEGER, IN NOISE_C VARCHAR(3)) 
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
	
SELECT COUNT(*) INTO found_clinical FROM "MIMIC2V26"."totalbalevents"
	WHERE "SUBJECT_ID" = :SUBJ_ID;
	
IF :found_clinical = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found in totalbalevents!');
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."totalbalevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSEIF :found_signal = 0 THEN
	CALL "INS_MSG_PROC"('SUBJECT_ID: ' || :SUBJ_ID || ' is not found for the numeric signal: ' || :SIG_NAME);
	SELECT "MIMIC2V26"."wav_num_signals"."RECORD_ID", "SUBJECT_ID", "SIGNAL_NAME"
		FROM "MIMIC2V26"."wav_num_signals", "MIMIC2V26"."wav_num_records"
		WHERE "MIMIC2V26"."wav_num_signals"."RECORD_ID" = "MIMIC2V26"."wav_num_records"."RECORD_ID"
			AND "MIMIC2V26"."wav_num_records"."SUBJECT_ID" = :SUBJ_ID
			ORDER BY "MIMIC2V26"."wav_num_signals"."RECORD_ID";
	SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."totalbalevents" WHERE "SUBJECT_ID" IN
		( SELECT DISTINCT "SUBJECT_ID" FROM "MIMIC2V26"."wav_num_records", "MIMIC2V26"."wav_num_signals"
			WHERE "MIMIC2V26"."wav_num_records"."RECORD_ID" = "MIMIC2V26"."wav_num_signals"."RECORD_ID"
				AND "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = :SIG_NAME
		)
		ORDER BY "SUBJECT_ID";
	SELECT TOP 1 "P_MSG" AS "ERROR" FROM "MESSAGE_BOX" ORDER BY "TSTAMP" DESC;
ELSE
	DECLARE view_exists INT := 0;
	SELECT COUNT(*) INTO view_exists FROM "VIEWS" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "VIEW_NAME" = 'JOIN_NUM_SIG_' || :SIG_NAME || '_TO_TOTALBALEVENTS_FOR_' || :SUBJ_ID;
	IF :view_exists = 1 THEN
		EXEC 'DROP VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_TOTALBALEVENTS_FOR_' || :SUBJ_ID || '"';
	END IF;
	query_string := 'CREATE VIEW "JOIN_NUM_SIG_' || :SIG_NAME || '_TO_TOTALBALEVENTS_FOR_' || :SUBJ_ID || '" AS (
		( SELECT
			"t"."SUBJECT_ID",
			"t"."RECORD_ID" as "SIG_RECORD_ID",
			ADD_SECONDS("t"."RECORD_TIME",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."SAMPLE_ID"/"t"."SAMPLE_FREQ") as "TIME_SERIES",
			''[SIGNAL DATA]'' as "CATEGORY",
			"MIMIC2V26"."wav_num_sig_' || :SIG_NAME || '"."AMPLITUDE"/"t"."ADC_GAIN" AS "AMPLITUDE",
			null AS "LABEL",
			null AS "PERVOLUME",
			null AS "CUMVOLUME",
			null AS "ACCUMPERIOD",
			null AS "APPROX",
			null AS "RESET",
			null AS "STOPPED"
			
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
			"x"."PERVOLUME",
			"x"."CUMVOLUME",
			"x"."ACCUMPERIOD",
			"x"."APPROX",
			"x"."RESET",
			"x"."STOPPED"
				
			FROM
				"MIMIC2V26"."totalbalevents" as "x" ,
				"MIMIC2V26"."d_ioitems" as "y"
				
			WHERE
				"x"."ITEMID" = "y"."ITEMID"
				AND "x"."SUBJECT_ID" = ' || :SUBJ_ID || '
		)
	)';
	EXEC query_string;
END IF;
END;

