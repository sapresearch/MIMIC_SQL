-- 1. CTRL+F and replace 'myproc' with the name of your function.
-- 2. ADD Outputs below
-- 3. ADD code
-- If you make a mistake, or want to make a change - then drop.
--   DROP TYPE myproc_t;
--   DROP PROCEDURE myproc_table;

CREATE TYPE myproc_t AS TABLE (
  --"<MY_OUT_VAR>" DATA_TYPE -------------
	"SUBJECT_ID" INTEGER CS_INT NOT NULL ,
	"HADM_ID" INTEGER CS_INT NOT NULL ,
	"SEQUENCE" INTEGER CS_INT NOT NULL ,
	"CODE" VARCHAR(100) NOT NULL ,
	"DESCRIPTION" VARCHAR(255)
);

CREATE PROCEDURE 
myproc_table (IN q_subject_id INTEGER, OUT v_ret myproc_t)
LANGUAGE SQLSCRIPT READS SQL DATA WITH RESULT VIEW myproc_view AS
BEGIN 
	v_ret =
	-- INSERT YOUR CODE HERE -- 
    SELECT * FROM "MIMIC2V26"."icd9" WHERE "MIMIC2V26"."icd9"."SUBJECT_ID"=:q_subject_id;
END;

SELECT * FROM myproc_view WITH PARAMETERS('placeholder' = ('$$q_subject_id$$', '44'));
