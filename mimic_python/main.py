import conn_setup

pre_conn = conn_setup.conn_setup()
conn = pre_conn.connect2server()

curs = conn.cursor()

# calls AVG_HEIGH procedure from python
try:
    curs.execute('DROP VIEW "SYSTEM"."HEIGHT_ONLY_IN"')
except:
    print 'HEIGHT_ONLY_IN VIEW HAS NOT BEEN CREATED, NOW CREATING'
    
curs.execute('create VIEW "SYSTEM"."HEIGHT_ONLY_IN" as select "VALUE1NUM" from "MIMIC2V26"."chartevents"'
             'where "ITEMID" = 5813 and "VALUE1NUM" is not null')


try:
    curs.execute('drop table "SYSTEM"."OUTPUT"')
except:
    print 'OUTPUT TABLE HAS NOT BEEN CREATED, NOW CREATING'
    
curs.execute('create table "SYSTEM"."OUTPUT"(MEAN INTEGER)')
curs.execute('call "SYSTEM"."AVG_HEIGHT"("SYSTEM"."HEIGHT_ONLY_IN", "SYSTEM"."OUTPUT") with OVERVIEW')
curs.execute('select top 20 * from "SYSTEM"."OUTPUT"')


result = curs.fetchall()
print result


