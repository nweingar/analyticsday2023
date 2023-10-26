%MACRO IMPV3(DSN=,VARS=,EXCLUDE=,PCTREM=.6,MSTD=4)/MINOPERATOR;
%PUT IMPUTE 3.0 IS NOW RUNNING YOU ARE THE GREATEST;

*DETERMING LOG STUFF;
FILENAME LOG1 DUMMY;
PROC PRINTTO LOG=LOG1;
RUN;

/*FILE AND DATA SET REFERENCES*/
%IF %INDEX(&DSN,.) %THEN %DO;
        %LET LIB=%UPCASE(%SCAN(&DSN,1,.));
        %LET DATA=%UPCASE(%SCAN(&DSN,2,.));
%END;
%ELSE %DO;
        %LET LIB=WORK;
        %LET DATA=%UPCASE(&DSN);
%END;

%LET DSID=%SYSFUNC(OPEN(&LIB..&DATA));
%LET NOBS=%SYSFUNC(ATTRN(&DSID,NOBS));
%LET CLOSE=%SYSFUNC(CLOSE(&DSID));

%PUT &NOBS;

DATA TEMP;
        SET &LIB..&DATA;
RUN;

/*MODULE IF _ALL_ KEYWORD IS PRESENT*/
%IF %UPCASE(&VARS)=_ALL_ AND &EXCLUDE= %THEN %DO;
PROC PRINTTO;
RUN;

%PUT ============================================;
%PUT XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;
%PUT ;
%PUT XXX: EXCLUDE PARAMETER IS NULL;
%PUT XXX: IMPUTE MACRO IS TERMINATING PREMATURELY;
%PUT;
%PUT XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;
%PUT ============================================;

%RETURN;
%END;

%ELSE %IF %UPCASE(&VARS)=_ALL_ AND &EXCLUDE^= %THEN %DO;

%LET NEXC=%SYSFUNC(COUNTW(&EXCLUDE,%STR( )));
/*SELECTING ALL THE VARIABLES TO BE IMPUTED*/

PROC SQL NOPRINT;
        SELECT NAME INTO: VARNAME SEPARATED BY ' '
                FROM DICTIONARY.COLUMNS
                WHERE UPCASE(LIBNAME)="&LIB" AND UPCASE(MEMNAME)="&DATA"
                                AND NAME NOT IN("%SCAN(&EXCLUDE,1,%STR( ))" %DO A=2 %TO &NEXC;
                                                                                                                 ,"%SCAN(&EXCLUDE,&A,%STR( ))"
                                                                                                                %END;);
QUIT;

%DO B=1 %TO %SYSFUNC(COUNTW(&VARNAME,%STR( )));
                
%LET CURR=%SCAN(&VARNAME,&B,%STR( ));
/*FINDING OUT IF VAR CONTAINS CODES*/
PROC MEANS DATA=TEMP(KEEP=&CURR) NOPRINT MAX;
        VAR &CURR;
        OUTPUT OUT=MAX MAX=MAX;
RUN;

DATA _NULL_;
        SET MAX;
        CALL SYMPUTX('MAX',MAX);
RUN;
/*IF NO CODED VALUES ARE DETECTED THEN IMPUTATION OF MISSING VALUES OCCURS*/
/*I KNOW THERE ARE MSSING VALUES WITHIN THE DATA SET BUT JUST IN CASE*/
%IF %EVAL(%SYSFUNC(INDEXW(%STR(9999999 9999 999 99 9.9999),&MAX))<1) %THEN %DO;
PROC SQL NOPRINT;
        SELECT MISSING(&CURR) INTO: MISS
        FROM TEMP;
QUIT;
/*THIS DROPS VARS IF PROBALITY OF FINDING A MISSING VALUES IS GREATER THEN PCTREM*/
%IF %SYSEVALF((&MISS/&NOBS)>&PCTREM) %THEN %DO;
PROC SQL NOPRINT;
        ALTER TABLE TEMP
        DROP &CURR;
QUIT;

PROC PRINTTO;
RUN;
%PUT &CURR HAS BEEN REMOVED BECAUSE IT DOES NOT MEET &PCTREM CRITERION;
PROC PRINTTO LOG=LOG1
RUN;
%END;

%ELSE %DO;
/*FINDING MEDIAN*/
PROC MEANS DATA=TEMP(KEEP=&CURR) NOPRINT MEDIAN;
        VAR &CURR;
        OUTPUT OUT=MEDI MEDIAN=MEDIAN;
RUN;

DATA _NULL_;
        SET MEDI;
        CALL SYMPUTX('MEDIAN',MEDIAN);
RUN;
/*MISSING IMPUTATION*/
DATA TEMP;
        SET TEMP;
        IF &CURR=. THEN &CURR=&MEDIAN;
RUN;
%END;
%END;
/*THIS NEXT PART IS SAME AS ABOVE WITH THE EXCEPTION THIS HANDLES CODED VALUES*/
%ELSE %DO;
DATA _NULL_;
        IF &MAX=99 THEN CALL SYMPUTX('LOW',77);
                ELSE IF &MAX=999 THEN CALL SYMPUTX('LOW',992);
                        ELSE IF &MAX=9999 THEN CALL SYMPUTX('LOW',9992);
                ELSE IF &MAX=9.9999 THEN CALL SYMPUTX('LOW',9.9992);
        ELSE CALL SYMPUTX('LOW',9999992);
RUN;

PROC SQL NOPRINT;
        SELECT COUNT(&CURR) INTO: CCODE
                        FROM TEMP
                        WHERE &CURR BETWEEN &LOW AND &MAX;
        SELECT MISSING(&CURR) INTO: MISS
                        FROM TEMP;
QUIT;

%IF %SYSEVALF(((&CCODE+&MISS)/&NOBS)>&PCTREM) %THEN %DO;

PROC SQL;
        ALTER TABLE TEMP
        DROP &CURR;
QUIT;

PROC PRINTTO;
RUN;
%PUT &CURR HAS BEEN REMOVED, TOO MUCH DATA IS CODED        OR MISSING;
PROC PRINTTO LOG=LOG1;
RUN;
%END;
                        
%ELSE %DO;
PROC MEANS DATA=TEMP(KEEP=&CURR) NOPRINT MEDIAN STD MEAN;
        VAR &CURR;
        OUTPUT OUT=NUM MEDIAN=MEDIAN STD=STD MEAN=MEAN;
        WHERE &CURR<&LOW;
RUN;

DATA _NULL_;
        SET NUM;
        CALL SYMPUTX('MEDIAN',MEDIAN);
        CALL SYMPUTX('STD',STD);
        CALL SYMPUTX('MEAN',MEAN);
RUN;

DATA TEMP;
        SET TEMP;
        IF &LOW<=&CURR<=&MAX | &CURR>&MEAN+&MSTD*&STD | &CURR<&MEAN-&MSTD*&STD THEN &CURR=&MEDIAN;
RUN;
%END;
%END;
%END;
%END;

/*THIS NEXT PART HANDLES A LIST OF VARIABLES PROVIDED IN THE VAR STATEMENT*/
%ELSE %DO;
%LET NVAR=%SYSFUNC(COUNTW(&VARS,%STR( )));

%DO C=1 %TO &NVAR;
%LET CURR=%SCAN(&VARS,&C,%STR( ));

PROC MEANS DATA=TEMP(KEEP=&CURR) NOPRINT MAX;
VAR &CURR;
OUTPUT OUT=MAX MAX=MAX;
RUN;

DATA _NULL_;
        SET MAX;
        CALL SYMPUTX('MAX',MAX);
RUN;
                
%IF %EVAL(%SYSFUNC(INDEXW(%STR(9999999 9999 999 99 9.9999),&MAX))<1) %THEN %DO;
PROC SQL NOPRINT;
        SELECT MISSING(&CURR) INTO: MISS
                FROM TEMP;
QUIT;

%IF %SYSEVALF((&MISS/&NOBS)>&PCTREM) %THEN %DO;
PROC SQL NOPRINT;
        ALTER TABLE TEMP
        DROP &CURR;
QUIT;
%END;

%ELSE %DO;
PROC MEANS DATA=TEMP(KEEP=&CURR) NOPRINT MEDIAN;
        VAR &CURR;
        OUTPUT OUT=MEDI MEDIAN=MEDIAN;
RUN;

DATA _NULL_;
        SET MEDI;
        CALL SYMPUTX('MEDIAN',MEDIAN);
RUN;

DATA TEMP;
        SET TEMP;
        IF &CURR=. THEN &CURR=&MEDIAN;
RUN;
%END;
%END;

%ELSE %DO;
DATA _NULL_;
        IF &MAX=99 THEN CALL SYMPUTX('LOW',77);
                ELSE IF &MAX=999 THEN CALL SYMPUTX('LOW',992);
                        ELSE IF &MAX=9999 THEN CALL SYMPUTX('LOW',9992);
                ELSE IF &MAX=9.9999 THEN CALL SYMPUTX('LOW',9.9992);
        ELSE CALL SYMPUTX('LOW',9999992);
RUN;

PROC SQL NOPRINT;
        SELECT COUNT(&CURR) INTO: CCODE
                FROM TEMP
                WHERE &CURR BETWEEN &LOW AND &MAX;
        SELECT MISSING(&CURR) INTO: MISS
                FROM TEMP;
QUIT;

%IF %SYSEVALF(((&CCODE+&MISS)/&NOBS)>&PCTREM) %THEN %DO;

PROC SQL;
        ALTER TABLE TEMP
        DROP &CURR;
QUIT;

PROC PRINTTO;
RUN;
%PUT &CURR HAS BEEN REMOVED, TOO MUCH DATA IS CODED        OR MISSING;
PROC PRINTTO LOG=LOG1;
RUN;
%END;
                        
%ELSE %DO;
PROC MEANS DATA=TEMP(KEEP=&CURR) NOPRINT MEDIAN STD MEAN;
        VAR &CURR;
        OUTPUT OUT=NUM MEDIAN=MEDIAN STD=STD MEAN=MEAN;
        WHERE &CURR<&LOW;
RUN;

DATA _NULL_;
        SET NUM;
        CALL SYMPUTX('MEDIAN',MEDIAN);
        CALL SYMPUTX('STD',STD);
        CALL SYMPUTX('MEAN',MEAN);
RUN;

DATA TEMP;
        SET TEMP;
        IF &LOW<=&CURR<=&MAX | &CURR>(&MEAN + &MSTD*&STD) | &CURR<(&MEAN -&MSTD*&STD) THEN &CURR=&MEDIAN;
RUN;
%END;
%END;
%END;
%END;

/*CREATING NEW DATASET*/
DATA &LIB..&DATA.OUT;
        SET TEMP;
RUN;

PROC DATASETS NOLIST;
        DELETE NUM TEMP MEDI MAX;
QUIT;

PROC PRINTTO;
RUN;

%PUT THIS MACRO HAS FINISHED RUNNING HAVE A NICE DAY;
%MEND IMPV3;



