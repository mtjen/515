/* Data Import */

LIBNAME lib1 "/meta/databases/HCUP/FL_SIDC_2017";
LIBNAME lib2 "/meta/databases/HCUP_SASD/FL_SASDC_2017_CORE";
LIBNAME lib3 "/meta/databases/HCUP/FL_SIDC_2018/FL_SIDC_2018_CORE";
LIBNAME lib4 "/meta/databases/HCUP_SASD/FL_SASDC_2018_CORE";

DATA sidc2017;
        SET lib1.FL_SIDC_2017_CORE;
RUN;

DATA sasdc2017;
        SET lib2.FL_SASD_2017_CORE;
RUN;

DATA sidc2018;
        SET lib3.FL_SIDC_2018_CORE;
RUN;

DATA sasdc2018;
        SET lib4.FL_SASDC_2018_CORE;
RUN;

*PROC CONTENTS DATA = sidc2017;RUN;
*PROC CONTENTS DATA = sasdc2017;RUN;
*PROC CONTENTS DATA = sidc2018;RUN;
*PROC CONTENTS DATA = sasdc2018;RUN;  



/* Question 1 */

/* stack datasets */
DATA fullData;
        SET sidc2017 sasdc2017 sidc2018 sasdc2018;
RUN;


/* only keep those with known visit link */
DATA fullData_wVisit;
        SET fullData;
        IF VISITLINK ne "";
RUN;


/* keep unique patients */
PROC SORT DATA = fullData_wVisit NODUPKEY OUT = sortedFull;
        BY VISITLINK;
RUN;



/* Question 2 */

DATA q2_data;
        SET fullData_wVisit;
        hadTKA = 0;
        ARRAY varNames(31) I10_PR1-I10_PR31;

        DO i = 1 to 31;
                IF varNames(i) IN ("0SRD069", "0SRD06A", "0SRD06Z",
                        "0SRD0J9", "0SRD0JA", "0SRD0JZ", "0SRD0KZ", 
                        "0SRC069", "0SRC06A", "0SRC06Z", "0SRC0J9", 
                        "0SRC0JA", "0SRC0JZ", "0SRC0KZ") THEN hadTKA = 1;
        END;
        DROP i; 
RUN;


DATA q2_wTKA;
        SET q2_data;
        WHERE hadTKA = 1;
RUN;


/* account for person and procedure */
PROC SORT DATA = q2_wTKA;
        BY VISITLINK DAYSTOEVENT;
RUN;


/* get first tka date */
DATA tka_first;
        SET q2_wTKA;
        BY VISITLINK;
        IF first.VISITLINK;
RUN;


DATA tka_first (KEEP = VISITLINK tkaDate);
        SET tka_first;
        RENAME DAYSTOEVENT = tkaDate;
RUN;



/* Question 3 */

DATA q3_data;
        SET fullData_wVisit;
        hadMUA = 0;
        ARRAY varNames(31) CPT1-CPT31;

        DO i = 1 to 31;
                IF varNames(i) = "27570" THEN hadMUA = 1;
        END;
        DROP i;
RUN;


DATA q3_wMUA;
        SET q3_data;
        WHERE hadMUA = 1;
RUN;


PROC SORT DATA = q3_wMUA;
        BY VISITLINK DAYSTOEVENT;
RUN;


/* get first mua date */
DATA mua_first;
        SET q3_wMUA;
        BY VISITLINK;
        IF first.VISITLINK;
RUN;


DATA mua_first (KEEP = VISITLINK hadMUA muaDate);
        SET mua_first;
        RENAME DAYSTOEVENT = muaDate;
RUN;


PROC SORT DATA = tka_first;
        BY VISITLINK;
RUN;

PROC SORT DATA = mua_first;
        BY VISITLINK;
RUN;


/* left join - only keep those that had tka */
DATA q3_merged;
        MERGE tka_first (in = inTka) mua_first (in = inMua);
        BY VISITLINK;
        IF inTka = 1;
RUN;


PROC FREQ DATA = q3_merged;
        TABLE hadMUA;
RUN;



/* Question 4 */

DATA q4_elapsed;
        SET q3_merged;
        eTime = muaDate - tkaDate;
RUN;


PROC MEANS DATA = q4_elapsed MEAN STDDEV MEDIAN Q1 Q3;
        VAR eTime;
RUN;



/* Question 5 */

DATA q5_data;
        SET fullData_wVisit;
        hadMUA = 0;
        ARRAY muaVars(31) CPT1-CPT31;

        DO i = 1 to 31;
                IF muaVars(i) = "27570" THEN hadMUA = 1;
        END;
        DROP i;
RUN;


DATA q5_wMUA;
        SET q5_data;
        WHERE hadMUA = 1;
RUN;


/* get patients with multiple muas */
PROC SORT DATA = q5_wMUA NODUPKEY DUPOUT = multiMUA;
        BY VISITLINK;
RUN;


/* get unique patients with multiple muas */
PROC SORT DATA = multiMUA NODUPKEY;
        BY VISITLINK;
RUN;
