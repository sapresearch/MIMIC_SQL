
DROP VIEW ABP_TEST_VIEW;
create view ABP_TEST_VIEW as 
(select SAMPLE_ID, AMPLITUDE 
from "MIMIC2V26"."wav_sig_ABP"
where "MIMIC2V26"."wav_sig_ABP"."RECORD_ID" =2   
and SAMPLE_ID > 14430740 
AND SAMPLE_ID < 14439740 ORDER BY "SAMPLE_ID");


drop table HEART_BEAT_R;
create table HEART_BEAT_R("Heart_Beat" double);


drop procedure abp_test_procedure;
create procedure abp_test_procedure(IN input1 ABP_TEST_VIEW, OUT result HEART_BEAT_R)
language RLANG as
begin
	dyn.load("/sapmnt/HOME/i842142/beat_detection/beat_detection/beat_detection.so");
	rr = rep(0,40);
	xxx <- .C("pipeline_beat_detection",as.double(input1$AMPLITUDE),as.integer(length(input1$AMPLITUDE)),as.double(rr));
	result <- as.data.frame(xxx[[3]]);
	names(result) <- c("Heart_Beat");
	
end;


call abp_test_procedure (ABP_TEST_VIEW, HEART_BEAT_R) with OVERVIEW;
select * from HEART_BEAT_R;
