---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl F and replace 'findmed_column_t' with something unique.
-- 2. THE OUTPUTS HERE MUST MATCH THE OUTPUT OF YOUR FUNCTION
create or replace force type findmed_column_t as object 
(ITEMID	NUMBER(7,0),
 LABEL	VARCHAR2(100 BYTE),
 COUNT_ITEMID	NUMBER(7,0)
);

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl + F, and replace 'findmed_t' with a unique name
create or replace type findmed_t as table of findmed_column_t;

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl+F and replace 'return_meds' with name of function 
-- 2. specify your inputs: q_lab_name in D_LABITEMS.TEST_NAME%type
create or replace function return_meds(q_med_name in D_MEDITEMS.LABEL%type)
return findmed_t as
  v_ret   findmed_t;
begin
  select 
  cast(
  multiset(
  -- PUT YOUR QUERY FROM HERE...
     SELECT ev.ITEMID,
        di.LABEL,
        COUNT(ev.ITEMID)
    FROM MEDEVENTS ev
    JOIN D_MEDITEMS di 
    ON di.ITEMID = ev.ITEMID
    WHERE lower(di.LABEL) like '%'|| q_med_name || '%' -- NOTE THAT YOU INPUT THINGS LIKE q_lab_name like this.
    GROUP BY ev.ITEMID, di.LABEL
    ORDER BY COUNT(ev.ITEMID) DESC
  -- TILL HERE  
    ) 
    as findmed_t)
    into
      v_ret
    from 
      dual;

  return v_ret;
  
end return_meds; -- CHANGE ME

-- THIS SHOWS HOW TO CALL THE FUNCTION
select * from table(return_meds('po'));