libname in1 "/meta/db4/epbi515/homework/hmwk1/data";

/* input data */
DATA temp1;
        SET in1.nis2014sample;
        KEEP key_nis hosp_nis dx1-dx15 pr1-pr15 died female age totchg;
RUN;


/* question 1, find shape of data */
* PROC CONTENTS DATA = temp1; RUN;


/* queston 2 */
/* stratify on female and died (2 results)  */
PROC FREQ DATA = temp1;
        TABLE female died;   
RUN;


/* question 3 */
/* summary stats on total charge */
PROC MEANS DATA = temp1 MEAN MEDIAN MIN MAX;
        VAR totchg;
RUN;


/* question 4 */
/* summary stats on age stratified by sex */
PROC MEANS DATA = temp1 MEAN MEDIAN MIN MAX;
        VAR age;
        CLASS female;
RUN;


/* question 5 */
/* get people with c-section procedure (741) and then get frequency */
DATA cSection;
        SET temp1;
        hasCSection = 0;
        IF pr1 = '741' THEN hasCSection = 1;
RUN;

PROC FREQ DATA = cSection;
        TABLE hasCSection;
RUN;


/* question 6 */
/* get people diagnosed with flu (487.0) and get frequency */
DATA fluDat;
        SET temp1;
        hasFlu = 0;
        ARRAY varNames(15) dx1 - dx15;

        DO i = 1 to 15;
                IF substr(varNames(i), 1, 4) = '4870' THEN hasFlu = 1;
        END;
	DROP i;
RUN;

PROC FREQ DATA = fluDat;
        TABLE hasFlu;
RUN;


/* queston 7 */
/* see how many hospitals had over 1000 patients */
PROC FREQ DATA = temp1;
        TABLE hosp_nis / out = hosp_freq noprint;
RUN;

DATA hosp_over_1k;
        SET hosp_freq;
        IF COUNT >= 1000;
RUN;

PROC PRINT DATA = hosp_over_1k; RUN;



/* test code to see all hospital patient count and order
PROC FREQ DATA = temp1 ORDER = freq;
        TABLE hosp_nis;
RUN;
*/
