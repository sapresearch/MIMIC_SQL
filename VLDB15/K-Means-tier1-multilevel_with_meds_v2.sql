-- Multi-Level Tier 1 Clustering by Incremental K-Means
-- Finds the best k for each level, using HANA's built-in optimum K finder

-- Used six additional variables, representing Admission Medications
-- (as extracted from the notes of Discharge Summaries)

-- Dynamically builds hierarchical (or nested) clusters
-- Where Tier-1-Level-1 uses the Patient-Demographics & Comorbidity Variables 
--   and Tier-1-Level-2 uses the Six types of Admission Medications

-- Created by: ISHRAR HUSSAIN
-- Date: March 9, 2015

DROP TABLE PAL_CLSTR_T1_DATA_TBL;
CREATE COLUMN TABLE PAL_CLSTR_T1_DATA_TBL AS (
	SELECT 
		"TIER1_VARIABLES".*,
		CASE WHEN "MEDICATION/DiabeticMedication" IS NOT NULL THEN TO_DOUBLE("MEDICATION/DiabeticMedication") ELSE TO_DOUBLE(0) END AS "NOTES_DIABETICMEDICATION",
		CASE WHEN "MEDICATION/BetaBlocker" IS NOT NULL THEN TO_DOUBLE("MEDICATION/BetaBlocker") ELSE TO_DOUBLE(0) END AS "NOTES_BETABLOCKER",
		CASE WHEN "MEDICATION/Diuretics" IS NOT NULL THEN TO_DOUBLE("MEDICATION/Diuretics") ELSE TO_DOUBLE(0) END AS "NOTES_DIURECTICS",
		CASE WHEN "MEDICATION/ACEInhibitor" IS NOT NULL THEN TO_DOUBLE("MEDICATION/ACEInhibitor") ELSE TO_DOUBLE(0) END AS "NOTES_ACEINHIBITOR",
		CASE WHEN "MEDICATION/CalciumChannelBlocker" IS NOT NULL THEN TO_DOUBLE("MEDICATION/CalciumChannelBlocker") ELSE TO_DOUBLE(0) END AS "NOTES_CALCIUMCHANNELBLOCKER",
		CASE WHEN "MEDICATION/ARB" IS NOT NULL THEN TO_DOUBLE("MEDICATION/ARB") ELSE TO_DOUBLE(0) END AS "NOTES_ARB"
	FROM (
		SELECT 
			TO_INTEGER(ICUSTAY_ID) AS ID
			
		-- BASIC INFO
			,CASE WHEN AGE IS NOT NULL THEN TO_DOUBLE(AGE) ELSE TO_DOUBLE(-32768) END AS AGE
			,CASE WHEN GENDER_MALE IS NOT NULL THEN TO_DOUBLE(GENDER_MALE) ELSE TO_DOUBLE(-32768) END AS GENDER_MALE
			,CASE WHEN SAPSI_FIRST IS NOT NULL THEN TO_DOUBLE(SAPSI_FIRST) ELSE TO_DOUBLE(-32768) END AS SAPSI_FIRST
			,CASE WHEN SOFA_FIRST IS NOT NULL THEN TO_DOUBLE(SOFA_FIRST) ELSE TO_DOUBLE(-32768) END AS SOFA_FIRST
			,CASE WHEN ELIX_HOSPITAL_MORT_PT IS NOT NULL THEN TO_DOUBLE(ELIX_HOSPITAL_MORT_PT) ELSE TO_DOUBLE(-32768) END AS ELIX_HOSPITAL_MORT_PT
			,CASE WHEN MICU_FLG IS NOT NULL THEN TO_DOUBLE(MICU_FLG) ELSE TO_DOUBLE(-32768) END AS MICU_FLG
			,CASE WHEN SICU_FLG IS NOT NULL THEN TO_DOUBLE(SICU_FLG) ELSE TO_DOUBLE(-32768) END AS SICU_FLG
			,CASE WHEN CCU_FLG IS NOT NULL THEN TO_DOUBLE(CCU_FLG) ELSE TO_DOUBLE(-32768) END AS CCU_FLG
			,CASE WHEN CSRU_FLG IS NOT NULL THEN TO_DOUBLE(CSRU_FLG) ELSE TO_DOUBLE(-32768) END AS CSRU_FLG
			,CASE WHEN DAY_ICU_INTIME_NUM IS NOT NULL THEN TO_DOUBLE(DAY_ICU_INTIME_NUM) ELSE TO_DOUBLE(-32768) END AS DAY_ICU_INTIME_NUM
			,CASE WHEN HOUR_ICU_INTIME IS NOT NULL THEN TO_DOUBLE(HOUR_ICU_INTIME) ELSE TO_DOUBLE(-32768) END AS HOUR_ICU_INTIME
			
		-- CO-MORBIDITIES
			,CASE WHEN CONGESTIVE_HEART_FAILURE IS NOT NULL THEN TO_DOUBLE(CONGESTIVE_HEART_FAILURE) ELSE TO_DOUBLE(-32768) END AS CONGESTIVE_HEART_FAILURE
			,CASE WHEN CARDIAC_ARRHYTHMIAS IS NOT NULL THEN TO_DOUBLE(CARDIAC_ARRHYTHMIAS) ELSE TO_DOUBLE(-32768) END AS CARDIAC_ARRHYTHMIAS
			,CASE WHEN VALVULAR_DISEASE IS NOT NULL THEN TO_DOUBLE(VALVULAR_DISEASE) ELSE TO_DOUBLE(-32768) END AS VALVULAR_DISEASE
			,CASE WHEN PULMONARY_CIRCULATION IS NOT NULL THEN TO_DOUBLE(PULMONARY_CIRCULATION) ELSE TO_DOUBLE(-32768) END AS PULMONARY_CIRCULATION
			,CASE WHEN PERIPHERAL_VASCULAR IS NOT NULL THEN TO_DOUBLE(PERIPHERAL_VASCULAR) ELSE TO_DOUBLE(-32768) END AS PERIPHERAL_VASCULAR
			,CASE WHEN HYPERTENSION IS NOT NULL THEN TO_DOUBLE(HYPERTENSION) ELSE TO_DOUBLE(-32768) END AS HYPERTENSION
			,CASE WHEN PARALYSIS IS NOT NULL THEN TO_DOUBLE(PARALYSIS) ELSE TO_DOUBLE(-32768) END AS PARALYSIS
			,CASE WHEN OTHER_NEUROLOGICAL IS NOT NULL THEN TO_DOUBLE(OTHER_NEUROLOGICAL) ELSE TO_DOUBLE(-32768) END AS OTHER_NEUROLOGICAL
			,CASE WHEN CHRONIC_PULMONARY IS NOT NULL THEN TO_DOUBLE(CHRONIC_PULMONARY) ELSE TO_DOUBLE(-32768) END AS CHRONIC_PULMONARY
			,CASE WHEN DIABETES_UNCOMPLICATED IS NOT NULL THEN TO_DOUBLE(DIABETES_UNCOMPLICATED) ELSE TO_DOUBLE(-32768) END AS DIABETES_UNCOMPLICATED
			,CASE WHEN DIABETES_COMPLICATED IS NOT NULL THEN TO_DOUBLE(DIABETES_COMPLICATED) ELSE TO_DOUBLE(-32768) END AS DIABETES_COMPLICATED
			,CASE WHEN HYPOTHYROIDISM IS NOT NULL THEN TO_DOUBLE(HYPOTHYROIDISM) ELSE TO_DOUBLE(-32768) END AS HYPOTHYROIDISM
			,CASE WHEN RENAL_FAILURE IS NOT NULL THEN TO_DOUBLE(RENAL_FAILURE) ELSE TO_DOUBLE(-32768) END AS RENAL_FAILURE
			,CASE WHEN LIVER_DISEASE IS NOT NULL THEN TO_DOUBLE(LIVER_DISEASE) ELSE TO_DOUBLE(-32768) END AS LIVER_DISEASE
			,CASE WHEN PEPTIC_ULCER IS NOT NULL THEN TO_DOUBLE(PEPTIC_ULCER) ELSE TO_DOUBLE(-32768) END AS PEPTIC_ULCER
			,CASE WHEN AIDS IS NOT NULL THEN TO_DOUBLE(AIDS) ELSE TO_DOUBLE(-32768) END AS AIDS
			,CASE WHEN LYMPHOMA IS NOT NULL THEN TO_DOUBLE(LYMPHOMA) ELSE TO_DOUBLE(-32768) END AS LYMPHOMA
			,CASE WHEN METASTATIC_CANCER IS NOT NULL THEN TO_DOUBLE(METASTATIC_CANCER) ELSE TO_DOUBLE(-32768) END AS METASTATIC_CANCER
			,CASE WHEN SOLID_TUMOR IS NOT NULL THEN TO_DOUBLE(SOLID_TUMOR) ELSE TO_DOUBLE(-32768) END AS SOLID_TUMOR
			,CASE WHEN RHEUMATOID_ARTHRITIS IS NOT NULL THEN TO_DOUBLE(RHEUMATOID_ARTHRITIS) ELSE TO_DOUBLE(-32768) END AS RHEUMATOID_ARTHRITIS
			,CASE WHEN COAGULOPATHY IS NOT NULL THEN TO_DOUBLE(COAGULOPATHY) ELSE TO_DOUBLE(-32768) END AS COAGULOPATHY
			,CASE WHEN OBESITY IS NOT NULL THEN TO_DOUBLE(OBESITY) ELSE TO_DOUBLE(-32768) END AS OBESITY
			,CASE WHEN WEIGHT_LOSS IS NOT NULL THEN TO_DOUBLE(WEIGHT_LOSS) ELSE TO_DOUBLE(-32768) END AS WEIGHT_LOSS
			,CASE WHEN FLUID_ELECTROLYTE IS NOT NULL THEN TO_DOUBLE(FLUID_ELECTROLYTE) ELSE TO_DOUBLE(-32768) END AS FLUID_ELECTROLYTE
			,CASE WHEN BLOOD_LOSS_ANEMIA IS NOT NULL THEN TO_DOUBLE(BLOOD_LOSS_ANEMIA) ELSE TO_DOUBLE(-32768) END AS BLOOD_LOSS_ANEMIA
			,CASE WHEN DEFICIENCY_ANEMIAS IS NOT NULL THEN TO_DOUBLE(DEFICIENCY_ANEMIAS) ELSE TO_DOUBLE(-32768) END AS DEFICIENCY_ANEMIAS
			,CASE WHEN ALCOHOL_ABUSE IS NOT NULL THEN TO_DOUBLE(ALCOHOL_ABUSE) ELSE TO_DOUBLE(-32768) END AS ALCOHOL_ABUSE
			,CASE WHEN DRUG_ABUSE IS NOT NULL THEN TO_DOUBLE(DRUG_ABUSE) ELSE TO_DOUBLE(-32768) END AS DRUG_ABUSE
			,CASE WHEN PSYCHOSES IS NOT NULL THEN TO_DOUBLE(PSYCHOSES) ELSE TO_DOUBLE(-32768) END AS PSYCHOSES
			,CASE WHEN DEPRESSION IS NOT NULL THEN TO_DOUBLE(DEPRESSION) ELSE TO_DOUBLE(-32768) END AS DEPRESSION
			
			
		-- OUTCOMES
			,CASE WHEN HOSP_EXP_FLG IS NOT NULL THEN TO_DOUBLE(HOSP_EXP_FLG) ELSE TO_DOUBLE(-32768) END AS HOSP_EXP_FLG
			,CASE WHEN ICU_EXP_FLG IS NOT NULL THEN TO_DOUBLE(ICU_EXP_FLG) ELSE TO_DOUBLE(-32768) END AS ICU_EXP_FLG
			,CASE WHEN SURVIVAL_DAY IS NOT NULL THEN TO_DOUBLE(SURVIVAL_DAY) ELSE TO_DOUBLE(-32768) END AS SURVIVAL_DAY
			,CASE WHEN ICU_LOS_DAY IS NOT NULL THEN TO_DOUBLE(ICU_LOS_DAY) ELSE TO_DOUBLE(-32768) END AS ICU_LOS_DAY
			,CASE WHEN HOSPITAL_LOS_DAY IS NOT NULL THEN TO_DOUBLE(HOSPITAL_LOS_DAY) ELSE TO_DOUBLE(-32768) END AS HOSPITAL_LOS_DAY
			FROM (SELECT ICUSTAY_ID
			,ICU_LOS_DAY
			,HOSPITAL_LOS_DAY
			,AGE
			,GENDER_NUM AS GENDER_MALE
		--,WEIGHT_FIRST
		--,BMI
		--,CASE WHEN IMPUTED_INDICATOR = 'FALSE' THEN 0 
		--      WHEN IMPUTED_INDICATOR = 'TRUE' THEN 1
		--      ELSE NULL END AS IMPUTED_INDICATOR
			,SAPSI_FIRST
			,SOFA_FIRST
		----,SERVICE_UNIT
			, CASE WHEN SERVICE_NUM = 0 THEN 1 ELSE 0 END AS MICU_FLG
			, CASE WHEN SERVICE_NUM = 1 THEN 1 ELSE 0 END AS SICU_FLG
			, CASE WHEN SERVICE_NUM = 2 THEN 1 ELSE 0 END AS CCU_FLG
			, CASE WHEN SERVICE_NUM = 3 THEN 1 ELSE 0 END AS CSRU_FLG
		--,ICUSTAY_INTIME
		--,ICUSTAY_OUTTIME
		--,DAY_ICU_INTIME
			,DAY_ICU_INTIME_NUM
			,HOUR_ICU_INTIME
			,HOSP_EXP_FLG
			,ICU_EXP_FLG
			,SURVIVAL_DAY
			,CONGESTIVE_HEART_FAILURE
			,CARDIAC_ARRHYTHMIAS
			,VALVULAR_DISEASE
			,PULMONARY_CIRCULATION
			,PERIPHERAL_VASCULAR
			,HYPERTENSION
			,PARALYSIS
			,OTHER_NEUROLOGICAL
			,CHRONIC_PULMONARY
			,DIABETES_UNCOMPLICATED
			,DIABETES_COMPLICATED
			,HYPOTHYROIDISM
			,RENAL_FAILURE
			,LIVER_DISEASE
			,PEPTIC_ULCER
			,AIDS
			,LYMPHOMA
			,METASTATIC_CANCER
			,SOLID_TUMOR
			,RHEUMATOID_ARTHRITIS
			,COAGULOPATHY
			,OBESITY
			,WEIGHT_LOSS
			,FLUID_ELECTROLYTE
			,BLOOD_LOSS_ANEMIA
			,DEFICIENCY_ANEMIAS
			,ALCOHOL_ABUSE
			,DRUG_ABUSE
			,PSYCHOSES
			,DEPRESSION
			,ELIX_HOSPITAL_MORT_PT
		--,ELIX_TWENTY_EIGHT_DAY_MORT_PT
		--,PT_ONE_YR_MORT_PT
		--,PT_TWO_YR_MORT_PT
		--,PT_ONE_YEAR_SURVIVAL_PT
		--,PT_TWO_YEAR_SURVIVAL_PT
			FROM (SELECT DISTINCT POP.*
			, ELIX.CONGESTIVE_HEART_FAILURE
			, ELIX.CARDIAC_ARRHYTHMIAS
			, ELIX.VALVULAR_DISEASE
			, ELIX.PULMONARY_CIRCULATION
			, ELIX.PERIPHERAL_VASCULAR
			, ELIX.HYPERTENSION
			, ELIX.PARALYSIS
			, ELIX.OTHER_NEUROLOGICAL
			, ELIX.CHRONIC_PULMONARY
			, ELIX.DIABETES_UNCOMPLICATED
			, ELIX.DIABETES_COMPLICATED
			, ELIX.HYPOTHYROIDISM
			, ELIX.RENAL_FAILURE
			, ELIX.LIVER_DISEASE
			, ELIX.PEPTIC_ULCER
			, ELIX.AIDS
			, ELIX.LYMPHOMA
			, ELIX.METASTATIC_CANCER
			, ELIX.SOLID_TUMOR
			, ELIX.RHEUMATOID_ARTHRITIS
			, ELIX.COAGULOPATHY
			, ELIX.OBESITY
			, ELIX.WEIGHT_LOSS
			, ELIX.FLUID_ELECTROLYTE
			, ELIX.BLOOD_LOSS_ANEMIA
			, ELIX.DEFICIENCY_ANEMIAS
			, ELIX.ALCOHOL_ABUSE
			, ELIX.DRUG_ABUSE
			, ELIX.PSYCHOSES
			, ELIX.DEPRESSION
			, PT.HOSPITAL_MORT_PT AS ELIX_HOSPITAL_MORT_PT
			, PT.TWENTY_EIGHT_DAY_MORT_PT AS ELIX_TWENTY_EIGHT_DAY_MORT_PT
			, PT.ONE_YR_MORT_PT AS PT_ONE_YR_MORT_PT
			, PT.TWO_YR_MORT_PT AS PT_TWO_YR_MORT_PT
			, PT.ONE_YEAR_SURVIVAL_PT AS PT_ONE_YEAR_SURVIVAL_PT
			, PT.TWO_YEAR_SURVIVAL_PT AS PT_TWO_YEAR_SURVIVAL_PT
			FROM (SELECT DISTINCT
			POP.*
			, ROUND(ICUD.ICUSTAY_LOS/60/24, 2) AS ICU_LOS_DAY
			, ROUND(ICUD.HOSPITAL_LOS/60/24,2) AS HOSPITAL_LOS_DAY
			, CASE WHEN ICUD.ICUSTAY_ADMIT_AGE>120 THEN 91.4 ELSE  ICUD.ICUSTAY_ADMIT_AGE END AS AGE
		--, ICUD.GENDER AS GENDER
			, CASE WHEN ICUD.GENDER IS NULL THEN NULL
			  WHEN ICUD.GENDER = 'M' THEN 1 ELSE 0 END AS GENDER_NUM
			, ICUD.WEIGHT_FIRST
			, BMI.BMI
			, BMI.IMPUTED_INDICATOR
			, ICUD.SAPSI_FIRST
			, ICUD.SOFA_FIRST
			, ICUD.ICUSTAY_FIRST_SERVICE AS SERVICE_UNIT
			, CASE WHEN ICUSTAY_FIRST_SERVICE='SICU' THEN 1
				  WHEN ICUSTAY_FIRST_SERVICE='CCU' THEN 2
				  WHEN ICUSTAY_FIRST_SERVICE='CSRU' THEN 3
				  ELSE 0 --MICU & FICU
				  END
			  AS SERVICE_NUM
			, ICUD.ICUSTAY_INTIME 
			, ICUD.ICUSTAY_OUTTIME
			, TO_CHAR(ICUD.ICUSTAY_INTIME, 'Day') AS DAY_ICU_INTIME
			, TO_NUMBER(TO_CHAR(ICUD.ICUSTAY_INTIME, 'D')) AS DAY_ICU_INTIME_NUM
			, EXTRACT(HOUR FROM ICUD.ICUSTAY_INTIME) AS HOUR_ICU_INTIME
			, CASE WHEN ICUD.HOSPITAL_EXPIRE_FLG='Y' THEN 1 ELSE 0 END AS HOSP_EXP_FLG
			, CASE WHEN ICUD.ICUSTAY_EXPIRE_FLG='Y' THEN 1 ELSE 0 END AS ICU_EXP_FLG
			, ROUND(SECONDS_BETWEEN(D.DOD, ICUD.ICUSTAY_INTIME)/(24*60*60),2) AS SURVIVAL_DAY
			FROM (SELECT DISTINCT SUBJECT_ID, HADM_ID, ICUSTAY_ID
			FROM MIMIC2V26."icustay_detail"
			WHERE ICUSTAY_SEQ=1 
			AND ICUSTAY_AGE_GROUP='adult'
			AND ICUSTAY_LOS>=48*60 -- AT LEAST 48 HOUR OF ICU STAY
		--AND ICUSTAY_ID<100
			) POP 
			LEFT JOIN  MIMIC2V26."icustay_detail" ICUD ON POP.ICUSTAY_ID = ICUD.ICUSTAY_ID
			LEFT JOIN MIMIC2DEVEL.OBESITY_BMI BMI ON BMI.ICUSTAY_ID=POP.ICUSTAY_ID
			LEFT JOIN MIMIC2DEVEL.D_PATIENTS D ON D.SUBJECT_ID=POP.SUBJECT_ID
			) AS POP
			LEFT JOIN MIMIC2DEVEL.ELIXHAUSER_REVISED ELIX ON ELIX.HADM_ID=POP.HADM_ID
			LEFT JOIN MIMIC2DEVEL.ELIXHAUSER_POINTS PT ON PT.HADM_ID=POP.HADM_ID
			) AS POPULATION
			) AS TEMP
			WHERE
			ICUSTAY_ID IS NOT NULL
		--AND ICU_LOS_DAY IS NOT NULL
		--AND HOSPITAL_LOS_DAY IS NOT NULL
			AND AGE IS NOT NULL
			AND GENDER_MALE IS NOT NULL
			AND SAPSI_FIRST IS NOT NULL
			AND SOFA_FIRST IS NOT NULL
			AND MICU_FLG IS NOT NULL
			AND SICU_FLG IS NOT NULL
			AND CCU_FLG IS NOT NULL
			AND CSRU_FLG IS NOT NULL
			AND DAY_ICU_INTIME_NUM IS NOT NULL
			AND HOUR_ICU_INTIME IS NOT NULL
		--AND HOSP_EXP_FLG IS NOT NULL
		--AND ICU_EXP_FLG IS NOT NULL
		--AND SURVIVAL_DAY IS NOT NULL
			AND CONGESTIVE_HEART_FAILURE IS NOT NULL
			AND CARDIAC_ARRHYTHMIAS IS NOT NULL
			AND VALVULAR_DISEASE IS NOT NULL
			AND PULMONARY_CIRCULATION IS NOT NULL
			AND PERIPHERAL_VASCULAR IS NOT NULL
			AND HYPERTENSION IS NOT NULL
			AND PARALYSIS IS NOT NULL
			AND OTHER_NEUROLOGICAL IS NOT NULL
			AND CHRONIC_PULMONARY IS NOT NULL
			AND DIABETES_UNCOMPLICATED IS NOT NULL
			AND DIABETES_COMPLICATED IS NOT NULL
			AND HYPOTHYROIDISM IS NOT NULL
			AND RENAL_FAILURE IS NOT NULL
			AND LIVER_DISEASE IS NOT NULL
			AND PEPTIC_ULCER IS NOT NULL
			AND AIDS IS NOT NULL
			AND LYMPHOMA IS NOT NULL
			AND METASTATIC_CANCER IS NOT NULL
			AND SOLID_TUMOR IS NOT NULL
			AND RHEUMATOID_ARTHRITIS IS NOT NULL
			AND COAGULOPATHY IS NOT NULL
			AND OBESITY IS NOT NULL
			AND WEIGHT_LOSS IS NOT NULL
			AND FLUID_ELECTROLYTE IS NOT NULL
			AND BLOOD_LOSS_ANEMIA IS NOT NULL
			AND DEFICIENCY_ANEMIAS IS NOT NULL
			AND ALCOHOL_ABUSE IS NOT NULL
			AND DRUG_ABUSE IS NOT NULL
			AND PSYCHOSES IS NOT NULL
			AND DEPRESSION IS NOT NULL
			AND ELIX_HOSPITAL_MORT_PT IS NOT NULL
		
		) "TIER1_VARIABLES" LEFT OUTER JOIN (
		SELECT "ICU"."ICUSTAY_ID", "NOTES".* FROM "MIMIC2V26"."icustay_detail" "ICU"
			JOIN (SELECT 
				"HADM_ID",
				"MEDICATION/DiabeticMedication",
				"MEDICATION/BetaBlocker",
				"MEDICATION/Diuretics",
				"MEDICATION/ACEInhibitor",
				"MEDICATION/CalciumChannelBlocker",
				"MEDICATION/ARB"
				FROM (
					SELECT 
						"NOTE_ID",
						MAX(CASE WHEN TA_TYPE = 'MEDICATION/DiabeticMedication' THEN 1 ELSE 0 END) AS "MEDICATION/DiabeticMedication",
						MAX(CASE WHEN TA_TYPE = 'MEDICATION/BetaBlocker' THEN 1 ELSE 0 END) AS "MEDICATION/BetaBlocker",
						MAX(CASE WHEN TA_TYPE = 'MEDICATION/Diuretics' THEN 1 ELSE 0 END) AS "MEDICATION/Diuretics",
						MAX(CASE WHEN TA_TYPE = 'MEDICATION/ACEInhibitor' THEN 1 ELSE 0 END) AS "MEDICATION/ACEInhibitor",
						MAX(CASE WHEN TA_TYPE = 'MEDICATION/CalciumChannelBlocker' THEN 1 ELSE 0 END) AS "MEDICATION/CalciumChannelBlocker",
						MAX(CASE WHEN TA_TYPE = 'MEDICATION/ARB' THEN 1 ELSE 0 END) AS "MEDICATION/ARB"
					
					FROM "$TA_MEDS_IN_DISCH_NOTES" WHERE TA_TYPE LIKE 'MEDICATION%'
					GROUP BY "NOTE_ID"
				) "MEDS" LEFT JOIN "DISCHARGE_SUMMARIES" ON "MEDS"."NOTE_ID" = "DISCHARGE_SUMMARIES"."NOTE_ID" ) "NOTES"
				ON "NOTES".HADM_ID = "ICU" .HADM_ID
		) "NLP_MED_VARIABLES"
		ON "TIER1_VARIABLES"."ID" = "NLP_MED_VARIABLES"."ICUSTAY_ID"
);

DROP TYPE PAL_KMEANS_DATA_T;
CREATE TYPE PAL_KMEANS_DATA_T AS TABLE(
	"ID" INTEGER, 
	"AGE" DOUBLE,
	"GENDER_MALE" DOUBLE,
	"SAPSI_FIRST" DOUBLE,
	"SOFA_FIRST" DOUBLE,
	"ELIX_HOSPITAL_MORT_PT" DOUBLE,
	"MICU_FLG" DOUBLE,
	"SICU_FLG" DOUBLE,
	"CCU_FLG" DOUBLE,
	"CSRU_FLG" DOUBLE,
	"DAY_ICU_INTIME_NUM" DOUBLE,
	"HOUR_ICU_INTIME" DOUBLE,
	"CONGESTIVE_HEART_FAILURE" DOUBLE,
	"CARDIAC_ARRHYTHMIAS" DOUBLE,
	"VALVULAR_DISEASE" DOUBLE,
	"PULMONARY_CIRCULATION" DOUBLE,
	"PERIPHERAL_VASCULAR" DOUBLE,
	"HYPERTENSION" DOUBLE,
	"PARALYSIS" DOUBLE,
	"OTHER_NEUROLOGICAL" DOUBLE,
	"CHRONIC_PULMONARY" DOUBLE,
	"DIABETES_UNCOMPLICATED" DOUBLE,
	"DIABETES_COMPLICATED" DOUBLE,
	"HYPOTHYROIDISM" DOUBLE,
	"RENAL_FAILURE" DOUBLE,
	"LIVER_DISEASE" DOUBLE,
	"PEPTIC_ULCER" DOUBLE,
	"AIDS" DOUBLE,
	"LYMPHOMA" DOUBLE,
	"METASTATIC_CANCER" DOUBLE,
	"SOLID_TUMOR" DOUBLE,
	"RHEUMATOID_ARTHRITIS" DOUBLE,
	"COAGULOPATHY" DOUBLE,
	"OBESITY" DOUBLE,
	"WEIGHT_LOSS" DOUBLE,
	"FLUID_ELECTROLYTE" DOUBLE,
	"BLOOD_LOSS_ANEMIA" DOUBLE,
	"DEFICIENCY_ANEMIAS" DOUBLE,
	"ALCOHOL_ABUSE" DOUBLE,
	"DRUG_ABUSE" DOUBLE,
	"PSYCHOSES" DOUBLE,
	"DEPRESSION" DOUBLE
);

DROP TYPE PAL_CONTROL_T;
CREATE TYPE PAL_CONTROL_T AS TABLE( 
	"NAME" VARCHAR (100), 
	"INTARGS" INTEGER, 
	"DOUBLEARGS" DOUBLE, 
	"STRINGARGS" VARCHAR (100)
);

DROP TYPE PAL_KMEANS_ASSIGNED_T;
CREATE TYPE PAL_KMEANS_ASSIGNED_T AS TABLE(
	"ID" INTEGER,
	"CLUSTER" INTEGER,
	"DISTANCE" DOUBLE,
	"SLIGHT_SILHOUETTE" DOUBLE
);

DROP TYPE PAL_KMEANS_CENTERS_T;
CREATE TYPE PAL_KMEANS_CENTERS_T AS TABLE(
	"CLUSTER_ID" INTEGER,
	"AGE" DOUBLE,
	"GENDER_MALE" DOUBLE,
	"SAPSI_FIRST" DOUBLE,
	"SOFA_FIRST" DOUBLE,
	"ELIX_HOSPITAL_MORT_PT" DOUBLE,
	"MICU_FLG" DOUBLE,
	"SICU_FLG" DOUBLE,
	"CCU_FLG" DOUBLE,
	"CSRU_FLG" DOUBLE,
	"DAY_ICU_INTIME_NUM" DOUBLE,
	"HOUR_ICU_INTIME" DOUBLE,
	"CONGESTIVE_HEART_FAILURE" DOUBLE,
	"CARDIAC_ARRHYTHMIAS" DOUBLE,
	"VALVULAR_DISEASE" DOUBLE,
	"PULMONARY_CIRCULATION" DOUBLE,
	"PERIPHERAL_VASCULAR" DOUBLE,
	"HYPERTENSION" DOUBLE,
	"PARALYSIS" DOUBLE,
	"OTHER_NEUROLOGICAL" DOUBLE,
	"CHRONIC_PULMONARY" DOUBLE,
	"DIABETES_UNCOMPLICATED" DOUBLE,
	"DIABETES_COMPLICATED" DOUBLE,
	"HYPOTHYROIDISM" DOUBLE,
	"RENAL_FAILURE" DOUBLE,
	"LIVER_DISEASE" DOUBLE,
	"PEPTIC_ULCER" DOUBLE,
	"AIDS" DOUBLE,
	"LYMPHOMA" DOUBLE,
	"METASTATIC_CANCER" DOUBLE,
	"SOLID_TUMOR" DOUBLE,
	"RHEUMATOID_ARTHRITIS" DOUBLE,
	"COAGULOPATHY" DOUBLE,
	"OBESITY" DOUBLE,
	"WEIGHT_LOSS" DOUBLE,
	"FLUID_ELECTROLYTE" DOUBLE,
	"BLOOD_LOSS_ANEMIA" DOUBLE,
	"DEFICIENCY_ANEMIAS" DOUBLE,
	"ALCOHOL_ABUSE" DOUBLE,
	"DRUG_ABUSE" DOUBLE,
	"PSYCHOSES" DOUBLE,
	"DEPRESSION" DOUBLE
);

DROP TYPE PAL_KMEANS_SIL_CENTERS_T;
CREATE TYPE PAL_KMEANS_SIL_CENTERS_T AS TABLE(
	"CLUSTER_ID" INTEGER,
	"SLIGHT_SILHOUETTE" DOUBLE
);

DROP TYPE PAL_KMEANS_STATISTIC_T;
CREATE TYPE PAL_KMEANS_STATISTIC_T AS TABLE(
	"NAME" VARCHAR(50),
	"VALUE" DOUBLE
);

DROP TABLE PAL_KMEANS_PDATA_TBL;
CREATE COLUMN TABLE PAL_KMEANS_PDATA_TBL("POSITION" INTEGER, "SCHEMA_NAME" VARCHAR(100), "TYPE_NAME" VARCHAR(100), "PARAMETER_TYPE" VARCHAR(100));
INSERT INTO PAL_KMEANS_PDATA_TBL VALUES (1, CURRENT_SCHEMA, 'PAL_KMEANS_DATA_T', 'IN'); 
INSERT INTO PAL_KMEANS_PDATA_TBL VALUES (2, CURRENT_SCHEMA, 'PAL_CONTROL_T', 'IN'); 
INSERT INTO PAL_KMEANS_PDATA_TBL VALUES (3, CURRENT_SCHEMA, 'PAL_KMEANS_ASSIGNED_T', 'OUT');
INSERT INTO PAL_KMEANS_PDATA_TBL VALUES (4, CURRENT_SCHEMA, 'PAL_KMEANS_CENTERS_T', 'OUT');
INSERT INTO PAL_KMEANS_PDATA_TBL VALUES (5, CURRENT_SCHEMA, 'PAL_KMEANS_SIL_CENTERS_T', 'OUT');
INSERT INTO PAL_KMEANS_PDATA_TBL VALUES (6, CURRENT_SCHEMA, 'PAL_KMEANS_STATISTIC_T', 'OUT'); 


CALL "SYS".AFLLANG_WRAPPER_PROCEDURE_DROP(CURRENT_SCHEMA, 'PAL_KMEANS_PROC');

CALL "SYS".AFLLANG_WRAPPER_PROCEDURE_CREATE('AFLPAL', 'KMEANS', CURRENT_SCHEMA, 'PAL_KMEANS_PROC', PAL_KMEANS_PDATA_TBL);

DROP TABLE PAL_CLSTR_TIER1_L1_DATA_TBL;
CREATE COLUMN TABLE PAL_CLSTR_TIER1_L1_DATA_TBL AS (
	SELECT 
		"ID", 
		"AGE",
		"GENDER_MALE",
		"SAPSI_FIRST",
		"SOFA_FIRST",
		"ELIX_HOSPITAL_MORT_PT",
		"MICU_FLG",
		"SICU_FLG",
		"CCU_FLG",
		"CSRU_FLG",
		"DAY_ICU_INTIME_NUM",
		"HOUR_ICU_INTIME",
		"CONGESTIVE_HEART_FAILURE",
		"CARDIAC_ARRHYTHMIAS",
		"VALVULAR_DISEASE",
		"PULMONARY_CIRCULATION",
		"PERIPHERAL_VASCULAR",
		"HYPERTENSION",
		"PARALYSIS",
		"OTHER_NEUROLOGICAL",
		"CHRONIC_PULMONARY",
		"DIABETES_UNCOMPLICATED",
		"DIABETES_COMPLICATED",
		"HYPOTHYROIDISM",
		"RENAL_FAILURE",
		"LIVER_DISEASE",
		"PEPTIC_ULCER",
		"AIDS",
		"LYMPHOMA",
		"METASTATIC_CANCER",
		"SOLID_TUMOR",
		"RHEUMATOID_ARTHRITIS",
		"COAGULOPATHY",
		"OBESITY",
		"WEIGHT_LOSS",
		"FLUID_ELECTROLYTE",
		"BLOOD_LOSS_ANEMIA",
		"DEFICIENCY_ANEMIAS",
		"ALCOHOL_ABUSE",
		"DRUG_ABUSE",
		"PSYCHOSES",
		"DEPRESSION"
	FROM PAL_CLSTR_TIER1_DATA_TBL
);

DROP TABLE PAL_CONTROL_TBL;
CREATE COLUMN TABLE PAL_CONTROL_TBL(
	"NAME" VARCHAR (100), 
	"INTARGS" INTEGER, 
	"DOUBLEARGS" DOUBLE, 
	"STRINGARGS" VARCHAR (100)
);
INSERT INTO PAL_CONTROL_TBL VALUES ('THREAD_NUMBER', 2, null, null);
INSERT INTO PAL_CONTROL_TBL VALUES ('GROUP_NUMBER_MIN', 2, null, null);
INSERT INTO PAL_CONTROL_TBL VALUES ('GROUP_NUMBER_MAX', 10, null, null);
INSERT INTO PAL_CONTROL_TBL VALUES ('INIT_TYPE', 1, null, null);
INSERT INTO PAL_CONTROL_TBL VALUES ('DISTANCE_LEVEL',2, null, null);
INSERT INTO PAL_CONTROL_TBL VALUES ('MAX_ITERATION', 100, null, null);
INSERT INTO PAL_CONTROL_TBL VALUES ('EXIT_THRESHOLD', null, 1.0E-6, null);
INSERT INTO PAL_CONTROL_TBL VALUES ('CATEGORY_WEIGHTS', null, 0.5, null);

DROP TABLE PAL_KMEANS_ASSIGNED_TBL;
CREATE COLUMN TABLE PAL_KMEANS_ASSIGNED_TBL LIKE PAL_KMEANS_ASSIGNED_T;

DROP TABLE PAL_KMEANS_CENTERS_TBL;
CREATE COLUMN TABLE PAL_KMEANS_CENTERS_TBL LIKE PAL_KMEANS_CENTERS_T;

DROP TABLE PAL_KMEANS_SIL_CENTERS_TBL;
CREATE COLUMN TABLE PAL_KMEANS_SIL_CENTERS_TBL LIKE PAL_KMEANS_SIL_CENTERS_T;

DROP TABLE PAL_KMEANS_STATISTIC_TBL;
CREATE COLUMN TABLE PAL_KMEANS_STATISTIC_TBL LIKE PAL_KMEANS_STATISTIC_T;
		
CALL PAL_KMEANS_PROC(PAL_CLSTR_TIER1_L1_DATA_TBL, PAL_CONTROL_TBL, PAL_KMEANS_ASSIGNED_TBL, PAL_KMEANS_CENTERS_TBL, PAL_KMEANS_SIL_CENTERS_TBL, PAL_KMEANS_STATISTIC_TBL) with OVERVIEW;

--SELECT * FROM PAL_KMEANS_ASSIGNED_TBL;
--SELECT * FROM PAL_KMEANS_CENTERS_TBL;
--SELECT * FROM PAL_KMEANS_SIL_CENTERS_TBL;
--SELECT * FROM PAL_KMEANS_STATISTIC_TBL;

DROP TYPE PAL_KMEANS_DATA_T;
CREATE TYPE PAL_KMEANS_DATA_T AS TABLE(
	"ID" INTEGER, 
	"NOTES_DIABETICMEDICATION" DOUBLE,
	"NOTES_BETABLOCKER" DOUBLE,
	"NOTES_DIURECTICS" DOUBLE,
	"NOTES_ACEINHIBITOR" DOUBLE,
	"NOTES_CALCIUMCHANNELBLOCKER" DOUBLE,
	"NOTES_ARB" DOUBLE
);

DROP TYPE PAL_KMEANS_CENTERS_T;
CREATE TYPE PAL_KMEANS_CENTERS_T AS TABLE(
	"CLUSTER_ID" INTEGER,
	"NOTES_DIABETICMEDICATION" DOUBLE,
	"NOTES_BETABLOCKER" DOUBLE,
	"NOTES_DIURECTICS" DOUBLE,
	"NOTES_ACEINHIBITOR" DOUBLE,
	"NOTES_CALCIUMCHANNELBLOCKER" DOUBLE,
	"NOTES_ARB" DOUBLE
);

CALL "SYS".AFLLANG_WRAPPER_PROCEDURE_DROP(CURRENT_SCHEMA, 'PAL_KMEANS_PROC');

CALL "SYS".AFLLANG_WRAPPER_PROCEDURE_CREATE('AFLPAL', 'KMEANS', CURRENT_SCHEMA, 'PAL_KMEANS_PROC', PAL_KMEANS_PDATA_TBL);

DROP TABLE PAL_CLSTR_TIER1_L2_DATA_TBL;
CREATE COLUMN TABLE PAL_CLSTR_TIER1_L2_DATA_TBL AS (
	SELECT 
		"ID", 
		"NOTES_DIABETICMEDICATION",
		"NOTES_BETABLOCKER",
		"NOTES_DIURECTICS",
		"NOTES_ACEINHIBITOR",
		"NOTES_CALCIUMCHANNELBLOCKER",
		"NOTES_ARB"
	FROM PAL_CLSTR_TIER1_DATA_TBL
);

DROP TABLE TEMP_PAL_KMEANS_STATISTIC_TBL;
CREATE COLUMN TABLE TEMP_PAL_KMEANS_STATISTIC_TBL LIKE PAL_KMEANS_STATISTIC_T;

DROP PROCEDURE PAL_KMEANS_TIER1_L2;

CREATE PROCEDURE PAL_KMEANS_TIER1_L2 () 
	LANGUAGE SQLSCRIPT AS
BEGIN

	DECLARE t1l1_cluster_count INT := 0;
	DECLARE table_exists INT := 0;
	DECLARE iteration_count INT := 0;
	DECLARE cluster_count INT := 1;
	DECLARE output_cluster_count INT := 1;
	DECLARE old_silhouette DOUBLE := 0;
	DECLARE new_silhouette DOUBLE := 0;


	SELECT MAX("CLUSTER") INTO t1l1_cluster_count FROM PAL_KMEANS_ASSIGNED_TBL;

	SELECT COUNT(*) INTO table_exists FROM "TABLES" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "TABLE_NAME" = 'PAL_CLSTR_TIER1_L2X_DATA_TBL' ;
	IF :table_exists = 1 THEN
		EXECUTE IMMEDIATE 'DROP TABLE PAL_CLSTR_TIER1_L2X_DATA_TBL';
	END IF;
	
	WHILE :iteration_count <= :t1l1_cluster_count DO
		EXECUTE IMMEDIATE 'CREATE COLUMN TABLE PAL_CLSTR_TIER1_L2X_DATA_TBL AS ( SELECT * FROM PAL_CLSTR_TIER1_L2_DATA_TBL WHERE ID IN ( SELECT ID FROM PAL_KMEANS_ASSIGNED_TBL WHERE "CLUSTER" = ' || :iteration_count || ') )';
		table_exists := 0;
		SELECT COUNT(*) INTO table_exists FROM "TABLES" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "TABLE_NAME" = 'PAL_KMEANS_ASSIGNED_TBL' || :iteration_count ;
		IF :table_exists = 1 THEN
			EXECUTE IMMEDIATE 'DROP TABLE PAL_KMEANS_ASSIGNED_TBL' || :iteration_count;
		END IF;
		EXECUTE IMMEDIATE 'CREATE COLUMN TABLE PAL_KMEANS_ASSIGNED_TBL' || :iteration_count || ' LIKE PAL_KMEANS_ASSIGNED_T';

		table_exists := 0;
		SELECT COUNT(*) INTO table_exists FROM "TABLES" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "TABLE_NAME" = 'PAL_KMEANS_CENTERS_TBL' || :iteration_count ;
		IF :table_exists = 1 THEN
			EXECUTE IMMEDIATE 'DROP TABLE PAL_KMEANS_CENTERS_TBL' || :iteration_count;
		END IF;
		EXECUTE IMMEDIATE 'CREATE COLUMN TABLE PAL_KMEANS_CENTERS_TBL' || :iteration_count || ' LIKE PAL_KMEANS_CENTERS_T';
		
		table_exists := 0;
		SELECT COUNT(*) INTO table_exists FROM "TABLES" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "TABLE_NAME" = 'PAL_KMEANS_SIL_CENTERS_TBL' || :iteration_count ;
		IF :table_exists = 1 THEN
			EXECUTE IMMEDIATE 'DROP TABLE PAL_KMEANS_SIL_CENTERS_TBL' || :iteration_count;
		END IF;
		EXECUTE IMMEDIATE 'CREATE COLUMN TABLE PAL_KMEANS_SIL_CENTERS_TBL' || :iteration_count || ' LIKE PAL_KMEANS_SIL_CENTERS_T';
		
		table_exists := 0;
		SELECT COUNT(*) INTO table_exists FROM "TABLES" WHERE "SCHEMA_NAME" = CURRENT_SCHEMA AND "TABLE_NAME" = 'PAL_KMEANS_STATISTIC_TBL' || :iteration_count ;
		IF :table_exists = 1 THEN
			EXECUTE IMMEDIATE 'DROP TABLE PAL_KMEANS_STATISTIC_TBL' || :iteration_count;
		END IF;
		EXECUTE IMMEDIATE 'CREATE COLUMN TABLE PAL_KMEANS_STATISTIC_TBL' || :iteration_count || ' LIKE PAL_KMEANS_STATISTIC_T';
		
		EXECUTE IMMEDIATE 'COMMIT';

		EXECUTE IMMEDIATE 'DELETE FROM "PAL_KMEANS_ASSIGNED_TBL' || :iteration_count || '"';
		EXECUTE IMMEDIATE 'DELETE FROM "PAL_KMEANS_CENTERS_TBL' || :iteration_count || '"';
		EXECUTE IMMEDIATE 'DELETE FROM "PAL_KMEANS_SIL_CENTERS_TBL' || :iteration_count || '"';
		EXECUTE IMMEDIATE 'DELETE FROM "PAL_KMEANS_STATISTIC_TBL' || :iteration_count || '"';
			
		EXECUTE IMMEDIATE 'CALL PAL_KMEANS_PROC(PAL_CLSTR_TIER1_L2X_DATA_TBL, PAL_CONTROL_TBL, PAL_KMEANS_ASSIGNED_TBL' || :iteration_count || ', PAL_KMEANS_CENTERS_TBL' || :iteration_count || ', PAL_KMEANS_SIL_CENTERS_TBL' || :iteration_count || ', PAL_KMEANS_STATISTIC_TBL' || :iteration_count || ') with OVERVIEW';
		EXECUTE IMMEDIATE 'DROP TABLE PAL_CLSTR_TIER1_L2X_DATA_TBL';
		iteration_count := :iteration_count + 1;
		EXECUTE IMMEDIATE 'COMMIT';
		
	END WHILE;

END;

CALL PAL_KMEANS_TIER1_L2();

