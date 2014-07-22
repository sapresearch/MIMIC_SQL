DROP TYPE findlab_t;
CREATE TYPE findlab_t AS TABLE (
	"ITEMID" INTEGER CS_INT NOT NULL,
	"TEST_NAME" VARCHAR(50) NOT NULL,
	"COUNT_ITEMID" INTEGER CS_INT NOT NULL
);

DROP PROCEDURE return_labs_proc;
CREATE PROCEDURE return_labs_proc (IN q_lab_name VARCHAR, OUT v_ret findlab_t)
	LANGUAGE SQLSCRIPT READS SQL DATA WITH RESULT VIEW return_labs AS

BEGIN
    v_ret =	
	SELECT	"ev"."ITEMID" AS "ITEMID",
			"di"."TEST_NAME" AS "TEST_NAME",
			COUNT("ev"."ITEMID") AS "COUNT_ITEMID"
		FROM "MIMIC2V26"."labevents"	"ev"
			JOIN "MIMIC2V26"."d_labitems"	"di"
		ON "di"."ITEMID" = "ev"."ITEMID"
		WHERE LOWER("di"."TEST_NAME") LIKE '%'|| :q_lab_name || '%'
		
		GROUP BY "ev"."ITEMID", "di"."TEST_NAME"
		ORDER BY "COUNT_ITEMID" DESC ;
END;

SELECT * FROM return_labs WITH PARAMETERS('placeholder' = ('$$q_lab_name$$', 'po'));
