---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl F and replace 'first_values_column_t' with something unique.
-- 2. THE OUTPUTS HERE MUST MATCH THE OUTPUT OF YOUR FUNCTION
create or replace force type first_values_column_t as object 
(ICUSTAY_ID	NUMBER(7,0),
 LAB_VALUE NUMBER(7,0)
);

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl + F, and replace 'first_values_subs_t' with a unique name
create or replace type first_values_subs_t as table of first_values_column_t;

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl+F and replace 'first_values' with name of function 
-- 2. specify your inputs: q_lab_name in D_LABITEMS.TEST_NAME%type
create or replace function first_values(q_item_id in LABEVENTS.ITEMID%type)
return first_values_subs_t as
  v_ret   first_values_subs_t;
begin
  select 
  cast(
  multiset(
  -- PUT YOUR QUERY FROM HERE...
  SELECT DISTINCT icud.icustay_id,
    FIRST_VALUE ( cr.valuenum ) over ( partition BY icud.icustay_id order by cr.charttime ) first_cr
  FROM LABEVENTS cr,
       ICUSTAY_DETAIL icud
  WHERE cr.itemid   = q_item_id 
  AND cr.icustay_id = icud.icustay_id

  -- TILL HERE  
    ) 
    as first_values_subs_t)
    into
      v_ret
    from 
      dual;

  return v_ret;
  
end first_values; -- CHANGE ME

-- THIS SHOWS HOW TO CALL THE FUNCTION
select * from table(first_values('50090'));