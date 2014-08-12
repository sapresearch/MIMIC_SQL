---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl F and replace 'rrt_column_t' with something unique.
-- 2. THE OUTPUTS HERE MUST MATCH THE OUTPUT OF YOUR FUNCTION
create or replace force type rrt_column_t as object 
(SUBJECT_ID	NUMBER(7,0),
 ICUSTAY_ID NUMBER(7,0)
);

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl + F, and replace 'rrt_subs_t' with a unique name
create or replace type rrt_subs_t as table of rrt_column_t;

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl+F and replace 'rrt' with name of function 
-- 2. specify your inputs: q_lab_name in D_LABITEMS.TEST_NAME%type
create or replace function rrt(dummy in LABEVENTS.ITEMID%type)
return rrt_subs_t as
  v_ret   rrt_subs_t;
begin
  select 
  cast(
  multiset(
  -- PUT YOUR QUERY FROM HERE...
 SELECT DISTINCT icud.SUBJECT_ID,
    icud.icustay_id
  FROM ICUSTAY_DETAIL icud
  JOIN procedureevents p
  ON icud.hadm_id=p.hadm_id
  AND p.itemid  IN (60887,60491,100586,100622,100977,100991)
  ORDER BY icud.subject_id

  -- TILL HERE  
    ) 
    as rrt_subs_t)
    into
      v_ret
    from 
      dual;

  return v_ret;
  
end rrt; -- CHANGE ME

-- THIS SHOWS HOW TO CALL THE FUNCTION
select * from table(rrt(''));