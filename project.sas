/*************************************************
*****
***** CREATE FULL DATASET
*****
*************************************************/

/* input data library */
LIBNAME dataLib "/meta/databases/HCUP/neds/sas_raw";


/* core data  */ 
DATA coreData;
        SET dataLib.neds2016core;
        KEEP AGE I10_DX1-I10_DX5 DIED_VISIT AMONTH FEMALE
                PL_NCHS ZIPINC_QRTL HOSP_ED;
RUN;


/* hospital data */
DATA hospData;
        SET dataLib.neds2016hosp;
        KEEP HOSP_ED HOSP_REGION;
RUN;


*PROC CONTENTS DATA = coreData; RUN;
*PROC CONTENTS DATA = hospData; RUN;


/* merge data files */
DATA fullData;
    MERGE coreData hospData;
    BY HOSP_ED;
RUN;


*PROC CONTENTS DATA = fullData; RUN;





/*************************************************
*****
***** FILTER PATIENTS/CASES
*****
*************************************************/

/* filter to adults */
DATA temp;
        SET fullData;
        WHERE AGE >= 18;
RUN;


/* known admission month */
DATA temp2;
        SET temp;
        WHERE AMONTH IS NOT MISSING;
RUN;


/* known death outcome */
DATA temp3;
        SET temp2;
        WHERE DIED_VISIT IS NOT MISSING;
RUN;


/* flag those with opioid ICD 10 codes */
DATA temp4;
        SET temp3;
        hasOpi = 0;
        ARRAY diagVars(5) I10_DX1-I10_DX5;

        DO i = 1 to 5;
                IF SUBSTR(diagVars(i), 1, 4) IN 
                        ('F111', 'F112', 'F119',
                         'T400', 'T401', 'T402',
                         'T403', 'T404', 'T406')
                THEN hasOpi = 1;
        END;
        DROP i;
RUN;


/* distribution of yes/no to opiates */
PROC FREQ DATA = temp4;
        TABLE hasOpi;
RUN;


/* filter to those with opiates + make death variable binary */
DATA opiData;
        SET temp4;
        WHERE hasOpi = 1;

        IF DIED_VISIT ^= 0 THEN DID_DIE= "Yes";
        ELSE DID_DIE = "No";

        LENGTH AGE_GROUP $ 7;

        IF AGE >= 18 AND AGE < 30 THEN AGE_GROUP = "18-29";
        ELSE IF AGE >= 30 AND AGE < 40 THEN AGE_GROUP = "30-39";
        ELSE IF AGE >= 40 AND AGE < 50 THEN AGE_GROUP = "40-49";
        ELSE IF AGE >= 50 AND AGE < 60 THEN AGE_GROUP = "50-59";
        ELSE IF AGE >= 60 THEN AGE_GROUP = "60+";
        ELSE AGE_GROUP = "Missing";

        LENGTH MONTH $ 7;

        IF AMONTH = 1 THEN MONTH = "JAN";
        ELSE IF AMONTH = 2 THEN MONTH = "FEB";
        ELSE IF AMONTH = 3 THEN MONTH = "MAR";
        ELSE IF AMONTH = 4 THEN MONTH = "APR";
        ELSE IF AMONTH = 5 THEN MONTH = "MAY";
        ELSE IF AMONTH = 6 THEN MONTH = "JUN";
        ELSE IF AMONTH = 7 THEN MONTH = "JUL";
        ELSE IF AMONTH = 8 THEN MONTH = "AUG";
        ELSE IF AMONTH = 9 THEN MONTH = "SEP";
        ELSE IF AMONTH = 10 THEN MONTH = "OCT";
        ELSE IF AMONTH = 11 THEN MONTH = "NOV";
        ELSE IF AMONTH = 12 THEN MONTH = "DEC";
        ELSE MONTH = "Missing"; 

        LENGTH SEX $ 7;

        IF FEMALE = 1 THEN SEX = "Female";
        ELSE IF FEMALE = 0 THEN SEX = "Male";
        ELSE SEX = "Missing";

        LENGTH ZIP_MED_INC $ 13;

        IF ZIPINC_QRTL = 1 THEN ZIP_MED_INC = "<43,000";
        ELSE IF ZIPINC_QRTL = 2 THEN ZIP_MED_INC = "43,000-53,999";
        ELSE IF ZIPINC_QRTL = 3 THEN ZIP_MED_INC = "54,000-70,999";
        ELSE IF ZIPINC_QRTL = 4 THEN ZIP_MED_INC = "71,000+";
        ELSE ZIP_MED_INC = "Missing";

        LENGTH PAT_LOC $ 7;

        IF PL_NCHS = 1 THEN PAT_LOC = "1";
        ELSE IF PL_NCHS = 2 THEN PAT_LOC = "2";
        ELSE IF PL_NCHS = 3 THEN PAT_LOC = "3";
        ELSE IF PL_NCHS = 4 THEN PAT_LOC = "4";
        ELSE IF PL_NCHS = 5 THEN PAT_LOC = "5";
        ELSE IF PL_NCHS = 6 THEN PAT_LOC = "6";
        ELSE PAT_LOC = "Missing";

        LENGTH HOSP_REG $ 9;

        IF HOSP_REGION = 1 THEN HOSP_REG = "Northeast";
        ELSE IF HOSP_REGION = 2 THEN HOSP_REG = "Midwest";
        ELSE IF HOSP_REGION = 3 THEN HOSP_REG = "South";
        ELSE IF HOSP_REGION = 4 THEN HOSP_REG = "West";
        ELSE HOSP_REG = "Missing";

        KEEP AGE_GROUP MONTH SEX ZIP_MED_INC PAT_LOC HOSP_REG DID_DIE;
RUN;


*PROC CONTENTS DATA = opiData; RUN;


/* distribution of deaths */
PROC FREQ DATA = opiData;
        TABLE DID_DIE;
RUN;





/*************************************************
*****
***** TABLE 1 VALUES
*****
*************************************************/

PROC TABULATE DATA = opiData;
        CLASS AGE_GROUP DID_DIE;
        TABLE AGE_GROUP, DID_DIE;
RUN;


PROC TABULATE DATA = opiData;
        CLASS MONTH DID_DIE;
        TABLE MONTH, DID_DIE;
RUN;


PROC TABULATE DATA = opiData;
        CLASS SEX DID_DIE;
        TABLE SEX, DID_DIE;
RUN;


PROC TABULATE DATA = opiData;
        CLASS ZIP_MED_INC DID_DIE;
        TABLE ZIP_MED_INC, DID_DIE;
RUN;


PROC TABULATE DATA = opiData;
        CLASS PAT_LOC DID_DIE;
        TABLE PAT_LOC, DID_DIE;
RUN;


PROC TABULATE DATA = opiData;
        CLASS HOSP_REG DID_DIE;
        TABLE HOSP_REG, DID_DIE;
RUN;





/*************************************************
*****
***** TABLE 2 VALUES [unadjusted odds ratios]
*****
*************************************************/

PROC LOGISTIC DATA = opiData;
        CLASS AGE_GROUP (REF = "18-29") / PARAM = REFERENCE;
        MODEL DID_DIE (EVENT = "Yes") = AGE_GROUP / EXPB;
RUN;


PROC LOGISTIC DATA = opiData;
        CLASS MONTH (REF = "JAN") / PARAM = REFERENCE;
        MODEL DID_DIE (EVENT = "Yes") = MONTH / EXPB;
RUN;


PROC LOGISTIC DATA = opiData;
        CLASS SEX (REF = "Male") / PARAM = REFERENCE;
        MODEL DID_DIE (EVENT = "Yes") = SEX / EXPB;
RUN;


PROC LOGISTIC DATA = opiData;
        CLASS ZIP_MED_INC (REF = "<43,000") / PARAM = REFERENCE;
        MODEL DID_DIE (EVENT = "Yes") = ZIP_MED_INC / EXPB;
RUN;


PROC LOGISTIC DATA = opiData;
        CLASS PAT_LOC (REF = "1") / PARAM = REFERENCE;
        MODEL DID_DIE (EVENT = "Yes") = PAT_LOC / EXPB;
RUN;


PROC LOGISTIC DATA = opiData;
        CLASS HOSP_REG (REF = "Northeast") / PARAM = REFERENCE;
        MODEL DID_DIE (EVENT = "Yes") = HOSP_REG / EXPB;
RUN;





/*************************************************
*****
***** TABLE 3 VALUES [adjusted odds ratios]
*****
*************************************************/

PROC LOGISTIC DATA = opiData OUTEST = testFile;
        CLASS AGE_GROUP (REF = "18-29") 
                MONTH (REF = "JAN")
                SEX (REF = "Male")
                ZIP_MED_INC (REF = "<43,000")
                PAT_LOC (REF = "1") 
                HOSP_REG (REF = "Northeast") / PARAM = REFERENCE;
        MODEL DID_DIE (EVENT = "Yes") = 
                AGE_GROUP MONTH SEX ZIP_MED_INC PAT_LOC HOSP_REG / EXPB;
RUN;




DATA northeast;
        SET opiData;
        WHERE HOSP_REG = "Northeast";
RUN;

PROC LOGISTIC DATA = northeast;
        CLASS AGE_GROUP (REF = "18-29") 
                MONTH (REF = "JAN")
                SEX (REF = "Male")
                ZIP_MED_INC (REF = "<43,000")
                PAT_LOC (REF = "1") / PARAM = REFERENCE;
        MODEL DID_DIE (EVENT = "Yes") = 
                AGE_GROUP MONTH SEX ZIP_MED_INC PAT_LOC / EXPB;
RUN;



DATA midwest;
        SET opiData;
        WHERE HOSP_REG = "Midwest";
RUN;

PROC LOGISTIC DATA = midwest;
        CLASS AGE_GROUP (REF = "18-29")
                MONTH (REF = "JAN")
                SEX (REF = "Male")
                ZIP_MED_INC (REF = "<43,000")
                PAT_LOC (REF = "1") / PARAM = REFERENCE;
        MODEL DID_DIE (EVENT = "Yes") =
                AGE_GROUP MONTH SEX ZIP_MED_INC PAT_LOC / EXPB;
RUN;



DATA south;
        SET opiData;
        WHERE HOSP_REG = "South";
RUN;

PROC LOGISTIC DATA = south;
        CLASS AGE_GROUP (REF = "18-29")
                MONTH (REF = "JAN")
                SEX (REF = "Male")
                ZIP_MED_INC (REF = "<43,000")
                PAT_LOC (REF = "1") / PARAM = REFERENCE;
        MODEL DID_DIE (EVENT = "Yes") =
                AGE_GROUP MONTH SEX ZIP_MED_INC PAT_LOC / EXPB;
RUN;



DATA west;
        SET opiData;
        WHERE HOSP_REG = "West";
RUN;

PROC LOGISTIC DATA = west;
        CLASS AGE_GROUP (REF = "18-29")
                MONTH (REF = "JAN")
                SEX (REF = "Male")
                ZIP_MED_INC (REF = "<43,000")
                PAT_LOC (REF = "1") / PARAM = REFERENCE;
        MODEL DID_DIE (EVENT = "Yes") =
                AGE_GROUP MONTH SEX ZIP_MED_INC PAT_LOC / EXPB;
RUN;


/* get breakdown of survival by month for each region */
PROC TABULATE DATA = midwest;
        CLASS MONTH DID_DIE;
        TABLE MONTH, DID_DIE;
RUN;

PROC TABULATE DATA = west;
        CLASS MONTH DID_DIE;
        TABLE MONTH, DID_DIE;
RUN;


/* get total amount of ED visits by month for each region */
PROC TABULATE DATA = midwest;
        CLASS MONTH;
        TABLE MONTH;
RUN;

PROC TABULATE DATA = west;
        CLASS MONTH;
        TABLE MONTH;
RUN;
