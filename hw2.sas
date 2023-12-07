/* input data */
libname lib "/meta/db4/epbi515/homework/hmwk2/data";

DATA data98;
        SET lib.deaths98;
RUN;

DATA data99;
        SET lib.deaths99;
RUN;



/* Question 1 */
* PROC CONTENTS DATA = data98; RUN;
* PROC CONTENTS DATA = data99; RUN;



/* Question 2, leading CODs */
PROC FREQ DATA = data98 ORDER = freq;
        TABLE cause;
RUN;



/* Question 3, leading CODs */
PROC FREQ DATA = data99 ORDER = freq;
        TABLE cause;
RUN;



/* Question 4, leading CODs */
PROC FREQ DATA = data99 ORDER = freq;
        TABLE nchs_1;
RUN;



/* Question 5, leading CODs */
PROC FREQ DATA = data99 ORDER = freq;
        TABLE nchs_2;
RUN;



/* Question 6, leading CODs by age group */
PROC FREQ DATA = data99 ORDER = freq;
        TABLE nchs_1; 
        WHERE AGE >= 0 AND AGE < 15;
RUN;

PROC FREQ DATA = data99 ORDER = freq;
        TABLE nchs_1;
        WHERE AGE >= 15 AND AGE < 35;
RUN;

PROC FREQ DATA = data99 ORDER = freq;
        TABLE nchs_1;
        WHERE AGE >= 34 AND AGE < 65;
RUN;

PROC FREQ DATA = data99 ORDER = freq;
        TABLE nchs_1;
        WHERE AGE >= 65;
RUN;



/* Question 8, poisonings and deaths by age group and intent */
DATA q8;
        SET data98 data99;

		/* poisonings */
        IF ('8500' <= cause <= '8699') OR ('X40' <= cause <= 'X49') THEN DO;
                isPois = 1;
                reason = 'accident';
        END;
        IF ('9500' <= cause <= '9529') OR ('X60' <= cause <= 'X69') THEN DO;
                isPois = 1;
                reason = 'suicide';
        END;
        IF ('9620' <= cause <= '9629') OR ('X85' <= cause <= 'X90') OR ('U016' <= cause <= 'U017') THEN DO;
                isPois = 1;
                reason = 'homicide';
        END;

		/* firearms */
        IF ('9220' <= cause <= '9229') OR ('W32' <= cause <= 'W34') THEN DO;
                isFire = 1;
                reason = 'accident';
        END;
        IF ('9550' <= cause <= '9554') OR ('X72' <= cause <= 'X74') THEN DO;
                isFire = 1;
                reason = 'suicide';
        END;
        IF ('9650' <= cause <= '9654') OR ('X93' <= cause <= 'X95') OR (cause = 'U014') THEN DO;
                isFire = 1;
                reason = 'homicide';
        END;

        KEEP cause AGE isPois isFire reason;
RUN;

/* age group subsets of data */
DATA q8_1_14;
        SET q8;
        WHERE AGE >= 1 AND AGE <= 14;
RUN;

DATA q8_15_34;
        SET q8;
        WHERE AGE >= 15 AND AGE <= 34;
RUN;

DATA q8_35_64;
        SET q8;
        WHERE AGE >= 35 AND AGE <= 64;
RUN;

DATA q8_65;
        SET q8;
        WHERE AGE >= 65;
RUN;


/* frequency tables for each age group and cause of death */
PROC FREQ DATA = q8_1_14;
        TABLE isPois * reason;
        TABLE isFire * reason;
RUN;

PROC FREQ DATA = q8_15_34;
        TABLE isPois * reason;
        TABLE isFire * reason;
RUN;

PROC FREQ DATA = q8_35_64;
        TABLE isPois * reason;
        TABLE isFire * reason;
RUN;

PROC FREQ DATA = q8_65;
        TABLE isPois * reason;
        TABLE isFire * reason;
RUN;


/* get number of observations for each age group */
PROC MEANS DATA = q8_1_14 n;
RUN;

PROC MEANS DATA = q8_15_34 n;
RUN;

PROC MEANS DATA = q8_35_64 n;
RUN;

PROC MEANS DATA = q8_65 n;
RUN; 
