---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl F and replace 'findchart_column_t' with something unique.
-- 2. THE OUTPUTS HERE MUST MATCH THE OUTPUT OF YOUR FUNCTION
create or replace force type findchart_column_t as object 
(ITEMID	NUMBER(7,0),
 LABEL	VARCHAR2(100 BYTE),
 COUNT_ITEMID	NUMBER(7,0)
);

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl + F, and replace 'findchart_t' with a unique name
create or replace type findchart_t as table of findchart_column_t;

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl+F and replace 'return_chart_ids' with name of function 
-- 2. specify your inputs: q_lab_name in D_LABITEMS.TEST_NAME%type
create or replace function return_chart_ids(q_chart_name in D_CHARTITEMS.LABEL%type)
return findchart_t as
  v_ret   findchart_t;
begin
  select 
  cast(
  multiset(
  -- PUT YOUR QUERY FROM HERE...
     SELECT ev.ITEMID,
        di.LABEL,
        COUNT(ev.ITEMID)
    FROM CHARTEVENTS ev
    JOIN D_CHARTITEMS di 
    ON di.ITEMID = ev.ITEMID
    WHERE lower(di.LABEL) like '%'|| q_chart_name || '%' -- NOTE THAT YOU INPUT THINGS LIKE q_lab_name like this.
    GROUP BY ev.ITEMID, di.LABEL
    ORDER BY COUNT(ev.ITEMID) DESC
  -- TILL HERE  
    ) 
    as findchart_t)
    into
      v_ret
    from 
      dual;

  return v_ret;
  
end return_chart_ids; -- CHANGE ME

-- THIS SHOWS HOW TO CALL THE FUNCTION
select * from table(return_chart_ids('po'));