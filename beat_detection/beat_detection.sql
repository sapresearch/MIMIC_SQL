set schema "JUHUA_DEMO";
DROP VIEW ABP_TEST_VIEW;
create view ABP_TEST_VIEW as 
(select SAMPLE_ID, AMPLITUDE 
from "MIMIC2V26"."wav_sig_ABP"
where "MIMIC2V26"."wav_sig_ABP"."RECORD_ID" =2   
and SAMPLE_ID > 14430740 
AND SAMPLE_ID < 14439740 ORDER BY "SAMPLE_ID");


drop table output;
create table output(BEATS double);


drop procedure abp_test_procedure;
create procedure abp_test_procedure(IN input1 ABP_TEST_VIEW, OUT result output)
language RLANG as
begin
	dyn.load("/sapmnt/HOME/i842142/beat_detection/beat_detection/beat_detection.so");
	rr = rep(0,40);
	xxx <- .C("pipeline_beat_detection",as.double(input1$AMPLITUDE),as.integer(length(input1$AMPLITUDE)),as.double(rr));
	result <- as.data.frame(xxx[[3]]);
	names(result) <- c("BEATS");
	
end;


call abp_test_procedure (ABP_TEST_VIEW, output) with OVERVIEW;
select * from output;