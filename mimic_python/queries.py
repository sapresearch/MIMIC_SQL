import conn_setup

# extract ItemId and solutionID according to icd9 Code group by subject_id
def Treatment2ICD9Code(curs,code):
    querystring = ('select "MIMIC2V26"."icd9"."SUBJECT_ID",'
                  '"MIMIC2V26"."medevents"."ITEMID","MIMIC2V26"."medevents"."SOLUTIONID" '
                  'FROM "MIMIC2V26"."icd9","MIMIC2V26"."medevents" '
                  'WHERE "MIMIC2V26"."icd9"."SUBJECT_ID" = "MIMIC2V26"."medevents"."SUBJECT_ID"'
                  '"MIMIC2V26"."medevents"."ITEMID" is not null'
                  'and "MIMIC2V26"."medevents"."SOLUTIONID" is not null'
                  'AND "MIMIC2V26"."icd9"."CODE" = ')
    code = '\''+code+'\''
    curs.execute(querystring+code)
    result = curs.fetchall()
    return result


# extract signal names and adc modifier according to subject id
def signal_name2Subject(curs,subject_list):
    subject_string = '('+str(subject_list[0])
    for sub_id in subject_list[1:]:
        subject_string = subject_string+','+str(sub_id)

    subject_string = subject_string + ')'
    querystring =('SELECT "RECORD"."SUBJECT_ID",'
                  '"MIMIC2V26"."wav_num_signals"."RECORD_ID",'
                  '"MIMIC2V26"."wav_num_signals"."SIGNAL_NAME",'
                  '"MIMIC2V26"."wav_num_signals"."ADC_RESOLUTION" '
                  'FROM "MIMIC2V26"."wav_num_signals",'
                  '(select "MIMIC2V26"."wav_num_records"."SUBJECT_ID",'
                  ' "MIMIC2V26"."wav_num_records"."RECORD_ID"'
                  ' FROM "MIMIC2V26"."wav_num_records"'
                  ' WHERE "MIMIC2V26"."wav_num_records"."SUBJECT_ID" in ') + subject_string +(' ) AS "RECORD"'
                  'WHERE "MIMIC2V26"."wav_num_signals"."RECORD_ID" = "RECORD"."RECORD_ID"'
                  'ORDER BY "RECORD"."SUBJECT_ID" , "MIMIC2V26"."wav_num_signals"."RECORD_ID"')
    curs.execute(querystring)
    result=curs.fetchall()
    return result


# extract modified signal amplitude according to signal names and subject_id
# signalname is the output of function signal_name2Subject
def signal2Amplitude(curs,signalnames):
    result = []
    for row in signalnames:
        sub_id = str(row.SUBJECT_ID)
        rec_id = str(row.RECORD_ID)
        sig_name = row.SIGNAL_NAME
        adc = str(row.ADC_RESOLUTION)
        table_name = '"MIMIC2V26"."wav_num_sig_'+sig_name+'"'
        querystring = ('SELECT ' + sub_id + ' AS "SUBJECT_ID",'
                       + table_name + '."RECORD_ID",'
                       + table_name + '."AMPLITUDE"/'+ adc
                       + ' FROM ' + table_name
                       + 'WHERE ' + table_name + '."RECORD_ID" = ' +rec_id
                       + ' AND ' + table_name + '."AMPLITUDE" > 0' )

        
        print 'executing queries:' 
        print querystring + '\n\n' 

        
        curs.execute(querystring)
        result.append(curs.fetchall())
    return result


# extract mean modified signal amplitude according to signal names and subject_id
# signalname is the output of function signal_name2Subje     
def signal2MeanAmplitude(curs,signalnames):
    result = []
    for row in signalnames:
        sub_id = str(row.SUBJECT_ID)
        rec_id = str(row.RECORD_ID)
        sig_name = row.SIGNAL_NAME
        adc = str(row.ADC_RESOLUTION)
        table_name = '"MIMIC2V26"."wav_num_sig_'+sig_name+'"'
        querystring = ('SELECT ' + sub_id + ' AS "SUBJECT_ID",'
                       + table_name + '."RECORD_ID",'
                       + 'mean('+table_name + '."AMPLITUDE"/'+ adc + ')'
                       + ' FROM ' + table_name
                       + 'WHERE ' + table_name + '."RECORD_ID" = ' +rec_id
                       + ' AND ' + table_name + '."AMPLITUDE" > 0 group by "SUBJECT_ID"' )

        
        print 'executing queries:' 
        print querystring + '\n\n' 

        
        curs.execute(querystring)
        result.append(curs.fetchall())
    return result



# extract patients diagnosed with specified icd9 code,
# then calculate mean amplitude for a specified signal 
def meanAmp2icd9code(curs,code,sig):

    code = '\''+code+'\''
    sig = '\''+sig+'\''
    querystring = ('select distinct("MIMIC2V26"."icd9"."SUBJECT_ID") '
                  'FROM "MIMIC2V26"."icd9","MIMIC2V26"."medevents" '
                  'WHERE "MIMIC2V26"."icd9"."SUBJECT_ID" = "MIMIC2V26"."medevents"."SUBJECT_ID"'
                  ' and "MIMIC2V26"."medevents"."ITEMID" is not null '
                  'and "MIMIC2V26"."medevents"."SOLUTIONID" is not null '
                  'AND "MIMIC2V26"."icd9"."CODE" = ')


    curs.execute(querystring+code)
    result = curs.fetchall()
    sub_list = []
    for ob in result:
        sub_list.append(ob[0])

    subject_string = '('+str(sub_list[0])
    for sub_id in sub_list[1:]:
        subject_string = subject_string+','+str(sub_id)
    subject_string = subject_string + ')'

    querystring =('SELECT "RECORD"."SUBJECT_ID",'
                  '"MIMIC2V26"."wav_num_signals"."RECORD_ID",'
                  '"MIMIC2V26"."wav_num_signals"."SIGNAL_NAME",'
                  '"MIMIC2V26"."wav_num_signals"."ADC_RESOLUTION" '
                  'FROM "MIMIC2V26"."wav_num_signals",'
                  '(select "MIMIC2V26"."wav_num_records"."SUBJECT_ID",'
                  ' "MIMIC2V26"."wav_num_records"."RECORD_ID"'
                  ' FROM "MIMIC2V26"."wav_num_records"'
                  ' WHERE "MIMIC2V26"."wav_num_records"."SUBJECT_ID" in ') + subject_string +(' ) AS "RECORD"'
                  'WHERE "MIMIC2V26"."wav_num_signals"."RECORD_ID" = "RECORD"."RECORD_ID"'
                  ' and "MIMIC2V26"."wav_num_signals"."SIGNAL_NAME" = ' + sig +
                  ' ORDER BY "RECORD"."SUBJECT_ID" , "MIMIC2V26"."wav_num_signals"."RECORD_ID"')
    curs.execute(querystring)

    signal_name = curs.fetchall()
    result = signal2MeanAmplitude(curs,signal_name)


    return result


