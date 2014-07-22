---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl F and replace 'findlab_column_t' with something unique.
-- 2. THE OUTPUTS HERE MUST MATCH THE OUTPUT OF YOUR FUNCTION
create or replace force type findlab_column_t as object 
(ITEMID	NUMBER(7,0),
 TEST_NAME	VARCHAR2(100 BYTE),
 COUNT_ITEMID	NUMBER(7,0)
);

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl + F, and replace 'findlab_t' with a unique name
create or replace type findlab_t as table of findlab_column_t;

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- 1. Ctrl+F and replace 'return_labs' with name of function 
-- 2. specify your inputs: q_lab_name in D_LABITEMS.TEST_NAME%type
create or replace function return_labs(q_lab_name in D_LABITEMS.TEST_NAME%type)
return findlab_t as
  v_ret   findlab_t;
begin
  select 
  cast(
  multiset(
  -- PUT YOUR QUERY FROM HERE...
     SELECT ev.ITEMID,
        di.TEST_NAME,
        COUNT(ev.ITEMID)
    FROM LABEVENTS ev
    JOIN D_LABITEMS di 
    ON di.ITEMID = ev.ITEMID
    WHERE lower(di.test_name) like '%'|| q_lab_name || '%' -- NOTE THAT YOU INPUT THINGS LIKE q_lab_name like this.
    GROUP BY ev.ITEMID, di.TEST_NAME
    ORDER BY COUNT(ev.ITEMID) DESC
  -- TILL HERE  
    ) 
    as findlab_t)
    into
      v_ret
    from 
      dual;

  return v_ret;
  
end return_labs; -- CHANGE ME

-- THIS SHOWS HOW TO CALL THE FUNCTION
select * from table(return_labs('po'));