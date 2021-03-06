drop table "MIMIC2V26"."MIMIC.PREDICTION::DEATH_FEATURES";
create column table "MIMIC2V26"."MIMIC.PREDICTION::DEATH_FEATURES" as (
   	select  "icud"."ICUSTAY_ID" ,
          	"icud"."ICUSTAY_ADMIT_AGE" "AGE",
          	"icud"."WEIGHT_FIRST" ,
          	"icud"."WEIGHT_MIN" ,
          	"icud"."WEIGHT_MAX" ,
          	"icud"."SAPSI_FIRST",
          	"icud"."SOFA_FIRST",
   	map("icud"."GENDER",'F',0,'M',1) "GENDER",
   	map("icud"."EXPIRE_FLG",'N',0,'Y',1) "DEAD",
   	1-floor(rand()/0.75) "training"
   	from "MIMIC2V26"."icustay_detail" "icud"
   	where "icud"."WEIGHT_FIRST" is not null and
          	"icud"."WEIGHT_MIN" is not null and
          	"icud"."WEIGHT_MAX" is not null and
          	"icud"."SAPSI_FIRST" is not null and
          	"icud"."SOFA_FIRST" is not null and
          	"icud"."GENDER" is not null
);


SET SCHEMA _SYS_AFL;
--prepare input training data table type--DROP TYPE INPUT_DATA_T;
DROP TYPE INPUT_DATA_T;
CREATE TYPE INPUT_DATA_T AS TABLE (
ICUSTAY_ID integer,
DEAD double,
AGE double,
WEIGHT_FIRST double,
WEIGHT_MIN double,
WEIGHT_MAX double,
SAPSI_FIRST double,
SOFA_FIRST double,
GENDER integer
);

DROP TYPE ARGS_T;
CREATE TYPE ARGS_T AS TABLE(
NAME varchar(50),
INTARGS integer,
DOUBLEARGS double,
STRINGARGS varchar(100)
);



DROP TYPE RESULTS_MODELPART1_T;
CREATE TYPE RESULTS_MODELPART1_T AS TABLE(
ID varchar(50),
VALUEE double
);

DROP TYPE RESULTS_MODELPART2_T;
CREATE TYPE RESULTS_MODELPART2_T AS TABLE(
ICUSTAY_ID integer,
ALPHA double,
AGE double,
WEIGHT_FIRST double,
WEIGHT_MIN double,
WEIGHT_MAX double,
SAPSI_FIRST double,
SOFA_FIRST double,
GENDER integer
);

DROP TABLE TRAINPDATA;
CREATE TABLE TRAINPDATA(
"ID" INT,
"TYPENAME" VARCHAR(100),
"DIRECTION" VARCHAR(100) );

INSERT INTO TRAINPDATA VALUES (1,'_SYS_AFL.INPUT_DATA_T','in');
INSERT INTO TRAINPDATA VALUES (2,'_SYS_AFL.ARGS_T','in');
INSERT INTO TRAINPDATA VALUES (3,'_SYS_AFL.RESULTS_MODELPART1_T','out');
INSERT INTO TRAINPDATA VALUES (4,'_SYS_AFL.RESULTS_MODELPART2_T','out');

call SYSTEM.afl_wrapper_eraser('PAL_SVM_TRAIN');
call SYSTEM.afl_wrapper_generator('PAL_SVM_TRAIN','AFLPAL','SVMTRAIN',TRAINPDATA);




DROP TYPE INPUT_DATA_P_T;
CREATE TYPE INPUT_DATA_P_T AS TABLE (
ICUSTAY_ID integer,
AGE double,
WEIGHT_FIRST double,
WEIGHT_MIN double,
WEIGHT_MAX double,
SAPSI_FIRST double,
SOFA_FIRST double,
GENDER integer
);

DROP TYPE PREDICT_RESULT_T;
CREATE TYPE PREDICT_RESULT_T AS TABLE(
ID integer,
PREDICT double
);

DROP TABLE PREDICTPDATA;
CREATE TABLE PREDICTPDATA(
"ID" INT,
"TYPENAME" VARCHAR(100),
"DIRECTION" VARCHAR(100));

INSERT INTO PREDICTPDATA VALUES (1,'_SYS_AFL.INPUT_DATA_P_T','in');
INSERT INTO PREDICTPDATA VALUES (2,'_SYS_AFL.ARGS_T','in');
INSERT INTO PREDICTPDATA VALUES (3,'_SYS_AFL.RESULTS_MODELPART1_T','in');
INSERT INTO PREDICTPDATA VALUES (4,'_SYS_AFL.RESULTS_MODELPART2_T','in');
INSERT INTO PREDICTPDATA VALUES (5,'_SYS_AFL.PREDICT_RESULT_T','out');


call SYSTEM.afl_wrapper_eraser('PAL_SVM_PREDICT');
call SYSTEM.afl_wrapper_generator('PAL_SVM_PREDICT','AFLPAL','SVMPREDICT',PREDICTPDATA);


SET SCHEMA MIMIC2V26;
DROP TABLE INPUT_DATA_TABLE;
CREATE TABLE INPUT_DATA_TABLE AS(
SELECT ICUSTAY_ID, DEAD, AGE, WEIGHT_FIRST, WEIGHT_MIN,WEIGHT_MAX,SAPSI_FIRST,SOFA_FIRST,GENDER
FROM "MIMIC2V26"."MIMIC.PREDICTION::DEATH_FEATURES" 
WHERE "training" = 1);

DROP TABLE ARGS;
CREATE TABLE ARGS(
NAME varchar(50),
INTARGS integer,
DOUBLEARGS double,
STRINGARGS varchar(100)
);

INSERT INTO ARGS VALUES('KERNEL_TYPE',2,null,null);
INSERT INTO ARGS VALUES('TYPE',1,null,null);
INSERT INTO ARGS VALUES('CROSS_VALIDATION',0,null,null);
INSERT INTO ARGS VALUES('NR_FOLD',5,null,null);
--INSERT INTO ARGS VALUES('RBF_GAMMA',0.1,null,null);

DROP TABLE RESULTS_MODELPART1;
CREATE TABLE RESULTS_MODELPART1(
ID varchar(50),
VALUEE double
);
--prepare result table type-- 

--create result table--DROP TABLE RESULTS_MODELPART2;
DROP TABLE RESULTS_MODELPART2;
CREATE TABLE RESULTS_MODELPART2(
ICUSTAY_ID integer,
ALPHA double,
AGE double,
WEIGHT_FIRST double,
WEIGHT_MIN double,
WEIGHT_MAX double,
SAPSI_FIRST double,
SOFA_FIRST double,
GENDER integer
);

CALL 
_SYS_AFL.PAL_SVM_TRAIN(INPUT_DATA_TABLE,ARGS,RESULTS_MODELPART1,RESULTS_MODELPART2) WITH OVERVIEW;
--check the result--SELECT * FROM INPUT_DATA_TABLE;
SELECT * FROM ARGS;
SELECT * FROM RESULTS_MODELPART1;
SELECT * FROM RESULTS_MODELPART2;





DROP TABLE INPUT_DATA_P_TABLE;
CREATE TABLE INPUT_DATA_P_TABLE as (
SELECT ICUSTAY_ID, AGE, WEIGHT_FIRST, WEIGHT_MIN,WEIGHT_MAX,SAPSI_FIRST,SOFA_FIRST,GENDER
FROM "MIMIC2V26"."MIMIC.PREDICTION::DEATH_FEATURES" 
WHERE "training" = 0);

DROP TABLE ARGS_P;
CREATE TABLE ARGS_P(
NAME varchar(50),
INTARGS integer,
DOUBLEARGS double,
STRINGARGS varchar(100)
);
INSERT INTO ARGS_P VALUES('THREAD_NUMBER',8,null,null);


DROP TABLE PREDICT_RESULT;
CREATE TABLE PREDICT_RESULT(
ICUSTAY_ID integer,
PREDICT double
);


CALL 
_SYS_AFL.PAL_SVM_PREDICT(INPUT_DATA_P_TABLE,ARGS_P,RESULTS_MODELPART1,RESULTS_MODELPART2,PREDICT_RESULT) WITH OVERVIEW;

drop view VALIDATION_RESULT;
create view VALIDATION_RESULT as (SELECT "MIMIC2V26"."PREDICT_RESULT"."ICUSTAY_ID",
"MIMIC2V26"."MIMIC.PREDICTION::DEATH_FEATURES"."DEAD",
"MIMIC2V26"."PREDICT_RESULT"."PREDICT"
FROM  "MIMIC2V26"."PREDICT_RESULT","MIMIC2V26"."MIMIC.PREDICTION::DEATH_FEATURES"
WHERE "MIMIC2V26"."PREDICT_RESULT"."ICUSTAY_ID" = "MIMIC2V26"."MIMIC.PREDICTION::DEATH_FEATURES"."ICUSTAY_ID"
AND "MIMIC2V26"."MIMIC.PREDICTION::DEATH_FEATURES"."training" = 0);

select * from VALIDATION_RESULT;
select 1 - sum(abs(DEAD-PREDICT))/COUNT(*) FROM VALIDATION_RESULT;
