*** G001 ASSIGN MACRO VARIABLES ---------------------------------- ***;
*** G002 Bring in loan data - LOAN1 ------------------------------ ***;
*** G003 Bring in Borrower Data - BORRNLS ------------------------ ***;

**********************************************************************;
*** CHANGE DATES IN THE LINES IMMEDIATELY BELOW ALONG WITH FILE    ***;
*** PATHS. FOR THE FILES PATHS, YOU WILL LIKELY NEED TO CREATE A   ***;
*** NEW FOLDER "CAD" IN THE APPROPRIATE MONTH FILE. DO NOT CHANGE  ***;
*** THE ARGUMENT TO THE LEFT OF THE COMMA - ONLY CHANGE WHAT IS TO ***;
*** THE RIGHT OF THE COMMA. -------------------------------------- ***;
**********************************************************************;

*** G001 ASSIGN MACRO VARIABLES ---------------------------------- ***;

*** ASSIGN MACRO VARIABLES --------------------------------------- ***;

*** TODAYS RUN DATE IS THE TIMEFRAME REFERENCE = 2018-03-01 ------ ***;
OPTIONS MPRINT MLOGIC SYMBOLGEN; /* SET DEBUGGING OPTIONS */

%LET PULLDATE = %SYSFUNC(today(), yymmdd10.);
%PUT "&PULLDATE";

%LET _3YR_NUM = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-1095);
%LET _3YR = %SYSFUNC(putn(&_3YR_NUM,yymmdd10.));
%PUT "&_3YR";

%LET _2YR_NUM = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-730);
%LET _2YR = %SYSFUNC(putn(&_2YR_NUM,yymmdd10.));
%PUT "&_2YR";

%LET _5YR_NUM = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-1825);
%LET _5YR = %SYSFUNC(putn(&_5YR_NUM,yymmdd10.));
%PUT "&_5YR";

%LET _16MO_NUM = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-487);
%LET _16MO = %SYSFUNC(putn(&_16MO_NUM,yymmdd10.));
%PUT "&_16MO";

%LET _13MO_NUM = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-395);
%LET _13MO = %SYSFUNC(putn(&_13MO_NUM,yymmdd10.));
%PUT "&_13MO";

%LET _120DAYS_NUM = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-120);
%LET _120DAYS = %SYSFUNC(putn(&_120DAYS_NUM,yymmdd10.));
%PUT "&_120DAYS";

%LET _90DAYS_NUM = %EVAL(%SYSFUNC(inputn(&pulldate,yymmdd10.))-90);
%LET _90DAYS = %SYSFUNC(putn(&_90DAYS_NUM,yymmdd10.));
%PUT "&_90DAYS";

%PUT "&_3YR" "&_2YR" "&_5YR" "&_16MO";

*** G002 Bring in loan data - LOAN1 ------------------------------ ***;

*** READ IN DATA FROM `dw.vw_loan_NLS` TABLE. SUBSET FOR RELEVANT  ***;
*** VARIABLES. FILTER TO ISOLATE XS LOANS. STORE AS `XS_L` DATASET ***;
DATA LOAN1;

	*** SUBSET `dw.vw_loan_NLS` USING RELEVANT VARIABLES --------- ***;
	SET dw.vw_loan_NLS(
		KEEP = PURCD CIFNO BRACCTNO XNO_AVAILCREDIT XNO_TDUEPOFF ID 
			   OWNBR OWNST SSNO1 SSNO2 SSNO1_RT7 LNAMT FINCHG LOANTYPE 
			   ENTDATE LOANDATE CLASSID CLASSTRANSLATION 
		       XNO_TRUEDUEDATE FIRSTPYDATE SRCD POCD POFFDATE PLCD 
			   PLDATE PLAMT BNKRPTDATE BNKRPTCHAPTER DATEPAIDLAST 
			   APRATE CRSCORE NETLOANAMOUNT XNO_AVAILCREDIT 
			   XNO_TDUEPOFF CURBAL CONPROFILE1 Acctrefno);

	*** FILTER DATA. REMOVE NULLS FROM `CIFNO`. KEEP ONLY NULLS    ***;
	*** FROM `POCD`. KEEP ONLY NULLS FROM `PLCD`. KEEP ONLY NULLS  ***;
	*** FROM `PLDATE`. KEEP ONLY NULLS FROM `POFFDATE`. KEEP ONLY  ***;
	*** NULLS FROM `BNKRPTDATE`. --------------------------------- ***;
	WHERE CIFNO NE "" & 
		  POCD = "" & 
		  PLCD = "" & 
		  PLDATE = "" & 
		  POFFDATE = "" &
		  BNKRPTDATE = "" & 
		  OWNST IN ("NC","VA","NM","SC","OK","TX", "AL", "GA", "TN", 
					"MO", "WI");

	*** CREATE `SS7BRSTATE` VARIABLE ----------------------------- ***;
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	IF CIFNO NOT =: "B";
RUN;

*** G003 Bring in Borrower Data - BORRNLS ------------------------ ***;

*** READ IN DATA FROM `dw.vw_borrower_nls` TABLE. SUBSET FOR       ***;
*** RELEVANT VARIABLES. STORE AS `BORRNLS` DATASET --------------- ***;
DATA BORRNLS;

	*** SET LENGTH FOR `FIRSTNAME`, `MIDDLENAME`, `LASTNAME` ----- ***;
	LENGTH FIRSTNAME $20 MIDDLENAME $20 LASTNAME $30;

	*** SUBSET `dw.vw_borrower_nls` USING RELEVANT VARIABLES ----- ***;
	SET dw.vw_borrower(
		KEEP = CIFNO SSNO SSNO_RT7 FNAME LNAME ADR1 ADR2 CITY STATE ZIP 
			   BRNO AGE CONFIDENTIAL SOLICIT CEASEANDDESIST CREDITSCORE
			   RMC_UPDATED);
	WHERE CIFNO NOT =: "B"; /* REMOVE `CIFNO`S THAT BEGIN WITH "B" */
	
	*** STRIP WHITE SPACE FROM `FNAME`, `LNAME`, `ADR1`, `ADR2`,   ***;
	*** `CITY`, `STATE`, `ZIP` ----------------------------------- ***;
	FNAME = STRIP(FNAME);
	LNAME = STRIP(LNAME);
	ADR1 = STRIP(ADR1);
	ADR2 = STRIP(ADR2);
	CITY = STRIP(CITY);
	STATE = STRIP(STATE);
	ZIP = STRIP(ZIP);

	*** FIND ALL INSTANCES OF "JR" IN `FNAME`. REMOVE "JR" FROM    ***;
	*** STRING AND STORE AS `FIRSTNAME`. STORE ALL OCCURENCES OF   ***;
	*** "JR" IN NEW VARIABLE, `SUFFIX` --------------------------- ***;
	IF FIND(FNAME, "JR") GE 1 THEN DO;
		FIRSTNAME = COMPRESS(FNAME, "JR");
		SUFFIX = "JR";
	END;

	*** FIND ALL INSTANCES OF "SR" IN `FNAME`. REMOVE "SR" FROM    ***;
	*** STRING AND STORE AS `FIRSTNAME`. STORE ALL OCCURENCES OF   ***;
	*** "SR" IN NEW VARIABLE, `SUFFIX` --------------------------- ***;
	IF FIND(FNAME, "SR") GE 1 THEN DO;
		FIRSTNAME = COMPRESS(FNAME, "SR");
		SUFFIX = "SR";
	END;

	*** IF `SUFFIX` IS NULL, TAKE 1ST WORD IN `FNAME` AND STORE AS ***;
	*** `FIRSTNAME`. TAKE 2ND, 3RD, AND 4TH WORDS IN `FNAME` AND   ***;
	*** STORE AS `MIDDLENAME` ------------------------------------ ***;
	IF SUFFIX = "" THEN DO;
		FIRSTNAME = SCAN(FNAME, 1, 1);
		MIDDLENAME = CATX(" ", SCAN(FNAME, 2, " "), 
						  SCAN(FNAME, 3, " "), SCAN(FNAME,4," "));
	END;
	NWORDS = COUNTW(FNAME, " "); /* COUNT # OF WORDS IN `FNAME` */

	*** IF MORE THAN 2 WORDS IN `FNAME`, TAKE 1ST WORD AND STORE IN***; 
	*** `FIRSTNAME`, AND TAKE SECOND WORD AND ADD TO `MIDDLENAME`  ***;
	IF NWORDS > 2 & SUFFIX NE "" THEN DO;
		FIRSTNAME = SCAN(FNAME, 1, " ");
		MIDDLENAME = SCAN(FNAME, 2, " ");
	END;

	LASTNAME = LNAME; /* STORE `LNAME` AS `LASTNAME` */
	DOB = COMPRESS(AGE, "-"); /* REMOVE HYPHEN, STORE `AGE` AS `DOB` */
	DROP FNAME LNAME NWORDS AGE; /* DROP VARIABLES FROM TABLE */
	IF CIFNO NE ""; /* FILTER SET OF NULL `CIFNO`S */
RUN;

*** SPLIT: GROUP LOAN1 BY `CIFNO` - APPLY: FIND MAX `ENTDATE` PER  ***; 
*** `CIFNO` - COMBINE: STORE RECORDS WITH MAX `ENTDATE` PER `CIFNO`***;
*** IN `LOAN1NLS` TABLE ------------------------------------------ ***;
PROC SQL;
	CREATE TABLE LOAN1NLS AS
	SELECT *
	FROM LOAN1
	GROUP BY CIFNO
	HAVING ENTDATE = MAX(ENTDATE);
QUIT;

*** REMOVE RECORDS WITH DUPLICATE `CIFNO` FROM `LOAN1NLS` -------- ***;
PROC SORT 
	DATA = LOAN1NLS NODUPKEY; 
	BY CIFNO; 
RUN;

*** SORT `BORRNLS` BY `CIFNO` DEFAULT ASCENDING THEN BY            ***;
*** `RMC_UPDATED` DESCENDING ------------------------------------- ***;
PROC SORT 
	DATA = BORRNLS; 
	BY CIFNO DESCENDING RMC_UPDATED; 
RUN;

*** REMOVE RECORDS WITH DUPLICATE `CIFNO` FROM `BORRNLS`. OUTPUT   ***;
*** AS `BORRNLS2` ------------------------------------------------ ***;
PROC SORT 
	DATA = BORRNLS OUT = BORRNLS2 NODUPKEY; 
	BY CIFNO; 
RUN;

*** MERGE `LOAN1NLS` AND `BORRNLS2` BY INNER JOIN ON `CIFNO` AS    ***;
*** `LOANNLS` ---------------------------------------------------- ***;
DATA LOANNLS;
	MERGE LOAN1NLS(IN = x) BORRNLS2(IN = y);
	BY CIFNO;
	IF x AND y;
RUN;

*** CREATE `LOANEXTRA` TABLE FROM `dw.vw_loan` AND FLAG BAD SSNs - ***;
DATA LOANEXTRA;
	
	*** SUBSET `dw.vw_loan` USING RELEVANT VARIABLES ------------- ***;
	SET dw.vw_loan(
		KEEP = PURCD BRACCTNO XNO_AVAILCREDIT XNO_TDUEPOFF ID OWNBR
			   OWNST SSNO1 SSNO2 SSNO1_RT7 LNAMT FINCHG LOANTYPE 
			   ENTDATE LOANDATE CLASSID CLASSTRANSLATION 
			   XNO_TRUEDUEDATE FIRSTPYDATE SRCD POCD POFFDATE PLCD 
			   PLDATE PLAMT BNKRPTDATE BNKRPTCHAPTER DATEPAIDLAST 
			   APRATE CRSCORE NETLOANAMOUNT XNO_AVAILCREDIT 
			   XNO_TDUEPOFF CURBAL CONPROFILE1);

	*** CONCATENATE `SSNO1_RT7` WITH THE FIRST 2 NUMBERS IN `OWNBR`***; 
	*** AND STORE IN NEW VARIABLE, `SS7BRSTATE` ------------------ ***;
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));

	*** FILTER `POCD`S THAT ARE NULL, `PLCD`S THAT ARE NULL,       ***;
	*** `BNKRPTDATE`S THAT ARE NULL, `PLDATE`S THAT ARE NULL, AND  ***;
	*** `POFFDATE`S THAT ARE NULL. ------------------------------- ***;
	WHERE  POCD = "" & 
		   PLCD = "" & 
		   BNKRPTDATE = "" & 
		   PLDATE = "" & 
		   POFFDATE = "" &
		   OWNST IN ("NC","VA","NM","SC","OK","TX", "AL", "GA", "TN", 
					 "MO", "WI");

	*** FLAG BAD `SSNO1`S THAT BEGIN WITH "99" OR "98" AS          ***;
	*** `BADSSN`S ------------------------------------------------ ***;
	IF SSNO1 =: "99" THEN BADSSN = "X";
	IF SSNO1 =: "98" THEN BADSSN = "X";
RUN;

*** STORE `BRACCTNO` FROM `LOAN1` IN DATASET `LOAN1_2` ----------- ***;
DATA LOAN1_2;
	SET LOAN1;
	KEEP BRACCTNO;
RUN;

*** SORT `LOAN1_2` BY `BRACCTNO` --------------------------------- ***;
PROC SORT 
	DATA = LOAN1_2;
	BY BRACCTNO; 
RUN;

*** SORT `LOANEXTRA` BY `BRACCTNO` ------------------------------- ***;
PROC SORT 
	DATA = LOANEXTRA; 
	BY BRACCTNO; 
RUN;

*** MERGE `LOANEXTRA` AND `LOAN1_2` ON `BRACCTNO` AS `LOANEXTRA2`  ***;
*** KEEPING ONLY DATA CONTRIBUTED BY `LOANEXTRA` ----------------- ***;
DATA LOANEXTRA2;
	MERGE LOANEXTRA(IN = x) LOAN1_2(IN = y);
	BY BRACCTNO;
	IF x AND NOT y;
RUN;

*** CREATE `LOANPARADATA` TABLE FROM `dw.vw_loan` AND FLAG BAD     ***; 
*** `SSN`S ------------------------------------------------------- ***;
DATA LOANPARADATA;

	*** SUBSET `dw.vw_loan` USING RELEVANT VARIABLES ------------- ***;
	SET dw.vw_loan(
		KEEP = PURCD BRACCTNO XNO_AVAILCREDIT XNO_TDUEPOFF ID OWNBR 
			   OWNST SSNO1 SSNO2 SSNO1_RT7 LNAMT FINCHG LOANTYPE 
			   ENTDATE LOANDATE CLASSID CLASSTRANSLATION 
			   XNO_TRUEDUEDATE FIRSTPYDATE SRCD POCD POFFDATE PLCD
			   PLDATE PLAMT BNKRPTDATE BNKRPTCHAPTER DATEPAIDLAST
			   APRATE CRSCORE NETLOANAMOUNT XNO_AVAILCREDIT 
			   XNO_TDUEPOFF CURBAL CONPROFILE1);

	*** FILTER `PLCD`S THAT ARE NULL, `POCD`S THAT ARE NULL,       ***;
	*** `POFFDATE`S THAT ARE NULL, `PLDATE`S THAT ARE NULL, AND    ***;
	*** `BNKRPTDATE`S THAT ARE NULL. ----------------------------- ***;
	WHERE PLCD = "" & 
		  POCD = "" & 
		  POFFDATE = "" & 
		  PLDATE = "" & 
		  BNKRPTDATE = "" &
		  OWNST NOT IN ("NC","VA","NM","SC","OK","TX", "AL", "GA", 
						"TN", "MO", "WI");

	*** CONCATENATE `SSNO1_RT7` WITH THE FIRST 2 NUMBERS IN        ***;
	*** `OWNBR` AND STORE IN NEW VARIABLE, `SS7BRSTATE` ---------- ***;
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));

	*** FLAG BAD `SSNO1`S THAT BEGIN WITH "99" OR "98" AS          ***;
	*** `BADSSN`S ------------------------------------------------ ***;
	IF SSNO1 =: "99" THEN BADSSN = "X";
	IF SSNO1 =: "98" THEN BADSSN = "X"; 
RUN;

*** TO CREATE A TABLE OF RECORDS NOT IN `vw_Loan_NLS`, CONCATENATE ***;
*** `LOANPARADATA` AND `LOANEXTRA2` TABLES AND STORE IN `SET1` --- ***;
DATA SET1;
	SET LOANPARADATA LOANEXTRA2;
RUN;

*** CREATE `BORRPARADATA` TABLE FROM `dw.vw_borrower` AND FLAG BAD ***;
*** `SSN`S ------------------------------------------------------- ***;
DATA BORRPARADATA;

	*** SET LENGTH FOR `FIRSTNAME`, `MIDDLENAME`, `LASTNAME` ----- ***;
	LENGTH FIRSTNAME $20 MIDDLENAME $20 LASTNAME $30;
	
	*** SUBSET `dw.vw_borrower` USING RELEVANT VARIABLES --------- ***;
	SET dw.vw_borrower (
		KEEP = RMC_UPDATED CIFNO SSNO SSNO_RT7 FNAME LNAME ADR1 ADR2
			   CITY STATE ZIP BRNO AGE CONFIDENTIAL SOLICIT
			   CEASEANDDESIST CREDITSCORE);

	*** STRIP WHITE SPACE FROM `FNAME`, `LNAME`, `ADR1`, `ADR2`,   ***;
	*** `CITY`, `STATE`, `ZIP` ----------------------------------- ***;
	FNAME = STRIP(FNAME);
	LNAME = STRIP(LNAME);
	ADR1 = STRIP(ADR1);
	ADR2 = STRIP(ADR2);
	CITY = STRIP(CITY);
	STATE = STRIP(STATE);
	ZIP = STRIP(ZIP);

	*** FIND ALL INSTANCES OF "JR" IN `FNAME`. REMOVE "JR" FROM    ***;
	*** STRING AND STORE AS `FIRSTNAME`. STORE ALL OCCURENCES OF   ***;
	*** "JR" IN NEW VARIABLE, `SUFFIX` --------------------------- ***;
	IF FIND(FNAME, "JR") GE 1 THEN DO;
		FIRSTNAME = COMPRESS(FNAME, "JR");
		SUFFIX = "JR";
	END;

	*** FIND ALL INSTANCES OF "SR" IN `FNAME`. REMOVE "SR" FROM    ***;
	*** STRING AND STORE AS `FIRSTNAME`. STORE ALL OCCURENCES OF   ***;
	*** "SR" IN NEW VARIABLE, `SUFFIX` --------------------------- ***;
	IF FIND(FNAME, "SR") GE 1 THEN DO;
		FIRSTNAME = COMPRESS(FNAME, "SR");
		SUFFIX = "SR";
	END;

	*** IF `SUFFIX` IS NULL, TAKE 1ST WORD IN `FNAME` AND STORE AS ***;
	*** `FIRSTNAME`. TAKE 2ND, 3RD, AND 4TH WORDS IN `FNAME` AND   ***;
	*** STORE AS `MIDDLENAME` ------------------------------------ ***;
	IF SUFFIX = "" THEN DO;
		FIRSTNAME = SCAN(FNAME, 1, 1);
		MIDDLENAME = CATX(" ", SCAN(FNAME, 2, " "), 
						  SCAN(FNAME, 3, " "), SCAN(FNAME, 4, " "));
	END;
	NWORDS = COUNTW(FNAME, " "); /* COUNT # OF WORDS IN `FNAME` */

	*** IF MORE THAN 2 WORDS IN `FNAME`, TAKE 1ST WORD AND STORE IN***; 
	*** `FIRSTNAME`, AND TAKE SECOND WORD AND ADD TO `MIDDLENAME`  ***;
	IF NWORDS > 2 & SUFFIX NE "" THEN DO;
		FIRSTNAME = SCAN(FNAME, 1, " ");
		MIDDLENAME = SCAN(FNAME, 2, " ");
	END;
	SS7BRSTATE = CATS(SSNO_RT7, SUBSTR(BRNO, 1, 2));
	LASTNAME = LNAME; /* STORE `LNAME` AS `LASTNAME` */
	*** RENAME `SSNO` AS `SSNO1`. RENAME `SSNO_RT7` AS `SSNO1_RT7` ***;
	RENAME SSNO_RT7 = SSNO1_RT7 SSNO = SSNO1;
	IF SSNO =: "99" THEN BADSSN = "X"; /* FLAG BAD `SSN`S */
	IF SSNO =: "98" THEN BADSSN = "X"; /* FLAG BAD `SSN`S */
	DOB = COMPRESS(AGE, "-"); /* REMOVE HYPHEN, STORE `AGE` AS `DOB` */
	DROP NWORDS AGE FNAME LNAME; /* DROP VARIABLES FROM TABLE */
RUN;

DATA GOODSSN_L BADSSN_L;
	SET SET1;
	IF BADSSN = "X" THEN OUTPUT BADSSN_L;
	ELSE OUTPUT GOODSSN_L;
RUN;

DATA GOODSSN_B BADSSN_B;
	SET BORRPARADATA;
	IF BADSSN = "X" THEN OUTPUT BADSSN_B;
	ELSE OUTPUT GOODSSN_B;
RUN;

PROC SORT 
	DATA = GOODSSN_L; 
	BY SSNO1;
RUN;

PROC SQL;
	CREATE TABLE GOODSSN_L AS
	SELECT *
	FROM GOODSSN_L
	GROUP BY SSNO1
	HAVING ENTDATE = MAX(ENTDATE);
QUIT;

PROC SORT 
	DATA = GOODSSN_L NODUPKEY; 
	BY SSNO1; 
RUN;

PROC SORT 
	DATA = GOODSSN_B; 
	BY SSNO1 DESCENDING RMC_UPDATED; 
RUN;

PROC SORT 
	DATA = GOODSSN_B NODUPKEY; 
	BY SSNO1; 
RUN;

DATA MERGEDGOODSSN;
	MERGE GOODSSN_L(IN = x) GOODSSN_B(IN = y);
	BY SSNO1;
	IF x AND y;
RUN;

PROC SORT 
	DATA = BADSSN_L; 
	BY SS7BRSTATE; 
RUN;

PROC SQL;
	CREATE TABLE BADSSN_L AS
	SELECT *
	FROM BADSSN_L
	GROUP BY SS7BRSTATE
	HAVING ENTDATE = MAX(ENTDATE);
QUIT;

PROC SORT 
	DATA = BADSSN_L NODUPKEY;
	BY SS7BRSTATE;
RUN;

PROC SORT 
	DATA = BADSSN_B; 
	BY SS7BRSTATE DESCENDING RMC_UPDATED; 
RUN;

PROC SORT
	DATA = BADSSN_B NODUPKEY; 
	BY SS7BRSTATE; 
RUN;

DATA MERGEDBADSSN;
	MERGE BADSSN_L(IN = x) BADSSN_B(IN = y);
	BY SS7BRSTATE;
	IF x AND y;
RUN;

DATA SSNS;
	SET MERGEDGOODSSN MERGEDBADSSN;
RUN;

PROC SORT 
	DATA = SSNS NODUPKEY; 
	BY BRACCTNO; 
RUN;

PROC SORT 
	DATA = LOANNLS NODUPKEY; 
	BY BRACCTNO; 
RUN;

DATA PARADATA;
	MERGE LOANNLS(IN = x) SSNS(IN = y);
	BY BRACCTNO;
	IF NOT x AND y;
RUN;

DATA MERGED_L_B2;
	SET LOANNLS PARADATA;
	acctrefno1 = input(acctrefno, 8.);
    drop acctrefno;
   	rename acctrefno1=acctrefno;
RUN; 

PROC SORT 
	DATA = MERGED_L_B2 OUT = MERGED_L_B2_2 NODUPKEY; 
	BY BRACCTNO; 
RUN;

*** PULL IN INFORMATION FOR STATFLAGS ---------------------------- ***;
DATA STATFLAGS;
	SET dw.vw_loan(
		KEEP = OWNBR SSNO1_RT7 ENTDATE STATFLAGS);
	WHERE ENTDATE > "&_3YR" & STATFLAGS NE "";
RUN;

PROC SQL; /* IDENTIFYING BAD STATFLAGS */
 	CREATE TABLE STATFLAGS2 AS
	SELECT * 
	FROM STATFLAGS 
	WHERE STATFLAGS CONTAINS "1" OR STATFLAGS CONTAINS "2" OR 
		  STATFLAGS CONTAINS "3" OR STATFLAGS CONTAINS "4" OR 
		  STATFLAGS CONTAINS "5" OR STATFLAGS CONTAINS "6" OR 
		  STATFLAGS CONTAINS "7" OR STATFLAGS CONTAINS "A" OR 
		  STATFLAGS CONTAINS "B" OR STATFLAGS CONTAINS "C" OR 
		  STATFLAGS CONTAINS "D" OR STATFLAGS CONTAINS "I" OR 
		  STATFLAGS CONTAINS "J" OR STATFLAGS CONTAINS "L" OR 
		  STATFLAGS CONTAINS "P" OR STATFLAGS CONTAINS "R" OR 
		  STATFLAGS CONTAINS "V" OR STATFLAGS CONTAINS "W" OR 
		  STATFLAGS CONTAINS "X" OR STATFLAGS CONTAINS "S";
RUN;

DATA STATFLAGS2; /* TAGGING BAD STATFLAGS */
	SET STATFLAGS2;
	STATFL_FLAG = "X";
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	DROP ENTDATE OWNBR SSNO1_RT7;
RUN;

PROC SORT DATA = STATFLAGS2 NODUPKEY;
	BY SS7BRSTATE;
RUN;

PROC SORT 
	DATA = MERGED_L_B2_2;
	BY SS7BRSTATE;
RUN;

DATA MERGED_L_B2; /* MERGE FILE WITH STATFLAG FLAGS */
	MERGE MERGED_L_B2_2(IN = x) STATFLAGS2;
	BY SS7BRSTATE;
	IF x = 1;
	IF CIFNO NOT =: "B";
RUN;

*** BKCODE ***********************************************************;
PROC SQL;
	CREATE TABLE BK2YRDROPS AS
	SELECT
    	t1.CreditBankruptcyID, 
    	t1.CreditProfileID, 
    	t1.DateFiled, 
    	t1.DateReported, 
    	t2.cifno
	FROM NLSPROD.CreditBankruptcy t1
	INNER JOIN NLSPROD.CreditProfile t2 
	ON t1.CreditProfileID = t2.CreditProfileID;
QUIT;

DATA BK2YRDROPS;
	SET BK2YRDROPS;
	DateFiled_NUM = DATEPART(DateFiled);
	DateFiled_format = PUT(DateFiled_NUM, yymmdd10.);
	Put DateFiled_format=;
	DateReported_NUM = DATEPART(DateReported);
	DateReported_format = PUT(DateReported_NUM, yymmdd10.);
	Put DateReported_format=;
RUN;

DATA BK2YRDROPS;
	SET BK2YRDROPS;
	WHERE DateFiled_format >= "&_2YR" &
		  DateReported_format >= "&_2YR";
RUN;

DATA BK2YRDROPS;
	SET BK2YRDROPS;
	BK2_FLAG = "X";
	DROP CreditBankruptcyID CreditProfileID DateFiled DateReported 
		 DateFiled_NUM DateFiled_format DateReported_NUM 
		 DateReported_format;
RUN;

PROC SORT 
	DATA = BK2YRDROPS NODUPKEY;
	BY cifno;
RUN;

DATA MERGED_L_B2;
	SET MERGED_L_B2;
	cifno_num = input(cifno, 8.);
    drop cifno;
    rename cifno_num=cifno;
RUN;

PROC SORT 
	DATA = MERGED_L_B2 NODUPKEY;
	BY cifno;
RUN;

DATA MERGED_L_B2;
	MERGE MERGED_L_B2(IN = x) BK2YRDROPS;
	BY cifno;
	IF x;
RUN;

*** FLAG BAD TRW STATUS ------------------------------------------ ***;
DATA TRWSTATUS_FL; /* FIND FROM 5 YEARS BACK */
	SET dw.vw_loan(
		KEEP = OWNBR SSNO1_RT7 ENTDATE TRWSTATUS);

	*** VALUES RELATE TO FRAUD ----------------------------------- ***;
	WHERE ENTDATE > "&_5YR" & TRWSTATUS NE "";
RUN;

DATA TRWSTATUS_FL; /* FLAG FOR BAD `TRW`S */
	SET TRWSTATUS_FL;
	TRW_FLAG = "X";
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	DROP SSNO1_RT7 OWNBR ENTDATE;
RUN;

PROC SORT 
	DATA = TRWSTATUS_FL NODUPKEY;
	BY SS7BRSTATE;
RUN;

PROC SORT 
	DATA = MERGED_L_B2 NODUPKEY;
	BY SS7BRSTATE;
RUN;

DATA MERGED_L_B2; /* MERGE PULL WITH TRW FLAGS */
	MERGE MERGED_L_B2(IN = x) TRWSTATUS_FL;
	BY SS7BRSTATE;
	IF x;
RUN;

*** IDENTIFY BAD PO CODES ---------------------------------------- ***;
DATA PO_CODES_5YR;
	SET dw.vw_loan(
		KEEP = ENTDATE POCD SSNO1_RT7 OWNBR);
	WHERE ENTDATE > "&_16MO" & 
		  POCD IN ("49", "61", "62", "63", "64", "66", "68", "97");
RUN;

*** 49 = BANKRUPTCY, 61 = VOLUNTARY SURRENDER, 62 = PD COLLECTION  ***;
*** ACCT, 63 = PD REPO, 64 = PD CHARGE OFF, 66 = REPO PD BY        ***;
*** DEALER, 68 = PD LESS THAN BALANCE, 97 = NON-FILE PAY OFF ----- ***;
DATA PO_CODES_5YR;
	SET PO_CODES_5YR;
	BADPOCODE_FLAG = "X";
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	DROP ENTDATE SSNO1_RT7 OWNBR POCD;
RUN;

PROC SORT 
	DATA = PO_CODES_5YR NODUPKEY;
	BY SS7BRSTATE;
RUN;

DATA MERGED_L_B2;
	MERGE MERGED_L_B2(IN = x) PO_CODES_5YR;
	BY SS7BRSTATE;
	IF x;
RUN;

*** 21 = DECEASED, 94 = PD AH INSURANCE, 95 = PD LIFE INSURANCE -- ***;
DATA PO_CODES_FOREVER;
	SET dw.vw_loan(
		KEEP = POCD SSNO1_RT7 OWNBR);
	WHERE POCD IN ("21", "94", "95");
RUN;

DATA PO_CODES_FOREVER;
	SET PO_CODES_FOREVER;
	DECEASED_FLAG = "X";
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	DROP POCD SSNO1_RT7 OWNBR;
RUN;

PROC SORT 
	DATA = PO_CODES_FOREVER NODUPKEY;
	BY SS7BRSTATE;
RUN;

DATA MERGED_L_B2;
	MERGE MERGED_L_B2(IN = x) PO_CODES_FOREVER;
	BY SS7BRSTATE;
	IF x;
RUN;

*** DEFERMENTS --------------------------------------------------- ***;
DATA DEFERMENTS;
	SET dw.vw_payment(
		KEEP = BRACCTNO TRDATE TRCD);
	WHERE TRDATE >= "&_90DAYS"; /* 120 days back */
	IF TRCD IN ("DF","D2","RV") THEN DEFERMENT_FLAG = "X";
RUN;

DATA LOAN_TEMP;
	SET dw.vw_loan_NLS(
		KEEP = BRACCTNO ACCTREFNO);
	ACCTREFNO2 = input(ACCTREFNO, 10.);
	drop ACCTREFNO;
	rename ACCTREFNO2 = ACCTREFNO;
RUN;

PROC SORT 
	DATA = DEFERMENTS;
	BY BRACCTNO;
RUN;

PROC SORT 
	DATA = LOAN_TEMP;
	BY BRACCTNO;
RUN;

DATA DEFERMENTS;
	MERGE DEFERMENTS(IN = x) LOAN_TEMP;
	BY BRACCTNO;
	IF x;
RUN;

PROC IMPORT 
	DATAFILE = 
		"\\mktg-app01\E\cepps\CAD\Reports\11_2019\dorian.xlsx" 
		DBMS = XLSX OUT = DORIAN REPLACE;
	GETNAMES = YES;
RUN;

PROC SORT 
	DATA = DEFERMENTS;
	BY ACCTREFNO;
RUN;

PROC SORT 
	DATA = DORIAN;
	BY ACCTREFNO;
RUN;

DATA DEFERMENTS;
	MERGE DEFERMENTS(IN = x) DORIAN;
	BY ACCTREFNO;
	IF x;
	IF DORIAN_FLAG = "X" THEN DEFERMENT_FLAG = "";
RUN;

PROC SORT 
	DATA = DEFERMENTS;
	BY BRACCTNO DESCENDING TRDATE DESCENDING DEFERMENT_FLAG;
RUN;

PROC SORT 
	DATA = DEFERMENTS OUT = DEFERMENTS2 NODUPKEY;
	BY BRACCTNO;
RUN;

PROC SORT 
	DATA = MERGED_L_B2;
	BY BRACCTNO;
RUN;

DATA MERGED_L_B2;
	MERGE MERGED_L_B2(IN = x) DEFERMENTS2;
	BY BRACCTNO;
	IF x;
RUN;

**********************************************************************;
DATA loanacct_detail;
	SET NLSPROD.loanacct_detail(
		KEEP = acctrefno userdef19 userdef20 userdef21 userdef22 
			   userdef23 userdef26);
	Original_Proceeds = input(userdef19, 8.2);
	Available_Credit = input(userdef20, 8.2);
	Net_Tangible_Benefit = input(userdef21, 8.2);
	Pay_Down_NTB = input(userdef22, 8.2);
	Payoff_Amount = input(userdef23, 8.2);
	drop userdef19 userdef20 userdef21 userdef22 userdef23;
	rename userdef26 = NTB_Eligible;
RUN;

PROC SORT 
	DATA = loanacct_detail;
	BY acctrefno;
RUN;

PROC SORT 
	DATA = MERGED_L_B2;
	BY acctrefno;
RUN;

DATA MERGED_L_B2;
	MERGE MERGED_L_B2(IN = x) loanacct_detail;
	BY acctrefno;
	IF x;
RUN;

PROC SORT 
	DATA = MERGED_L_B2;
	BY BRACCTNO;
RUN;

*** BAD BRANCH FLAGS --------------------------------------------- ***;
DATA MERGED_L_B2;
	LENGTH OFFER_TYPE $20;
	SET MERGED_L_B2;
	DOB_NUM = input(DOB, 8.);
	DOB_DATE = input(put(DOB_NUM,best8.),yymmdd8.);
  	format DOB_DATE date9.;
	age = int((today()-DOB_DATE)/365.25);
	IF OWNBR IN ("1", "0001", "198", "0198", "398", "0398", "498", 
				 "0498", "580", "0580", "600", "0600", "698", "0698", 
				 "898", "0898", "9000", "9000") 
		THEN BADBRANCH_FLAG = "X";
	IF SUBSTR(OWNBR, 3, 2) = "99" THEN BADBRANCH_FLAG = "X";
	FIRSTNAME = COMPRESS(FIRSTNAME, '1234567890!@#$^&*()''"%');
	LASTNAME = COMPRESS(LASTNAME, '1234567890!@#$^&*()''"%');

	*** FLAG INCOMPLETE INFO ------------------------------------- ***;
	IF ADR1 = "" THEN MISSINGINFO_FLAG = "X";
	IF STATE = "" THEN MISSINGINFO_FLAG = "X";
	IF FIRSTNAME = "" THEN MISSINGINFO_FLAG = "X";
	IF LASTNAME = "" THEN MISSINGINFO_FLAG = "X";

	*** FIND STATES OUTSIDE OF FOOTPRINT ------------------------- ***;
	IF STATE NOT IN ("AL", "GA", "NC", "NM", "OK", "SC", "TN", "TX", 
					 "VA", "MO", "WI") 
		THEN OOS_FLAG = "X"; 

	*** FLAG DNS DNH --------------------------------------------- ***;
	IF CONFIDENTIAL = "Y" THEN DNS_DNH_FLAG = "X"; 
	IF SOLICIT = "N" THEN DNS_DNH_FLAG = "X";
	IF CEASEANDDESIST = "Y" THEN DNS_DNH_FLAG = "X";

	*** FLAG NONMATCHING BRANCH STATE AND BORROWER STATE --------- ***;
	IF OWNST NE STATE THEN STATE_MISMATCH_FLAG = "X";

	IF SSNO1 = "" THEN SSNO1 = SSNO;

	*** IDENTIFY RETAIL LOANS ------------------------------------ ***;
	IF CLASSTRANSLATION = "Retail" THEN RETAILDELETE_FLAG = "X";

	IF Payoff_Amount < 50 THEN CURBAL_FLAG = "X";
	IF PURCD IN ("011", "015", "020") THEN DLQREN_FLAG = "X";
	IF Available_Credit = . THEN XNO_MISSING = 1;
		ELSE XNO_MISSING = 0;
	if brno = "0668" then brno = "0680";
	if brno = "1003" and zip =: "87112" then brno = "1013";
	if brno = "1016" then brno = "1008";
	if brno = "1018" then brno = "1008";
	if ownbr = "0152" then ownbr = "0115";
	if ownbr = "0159" then ownbr = "0132";
	if ownbr = "0251" then ownbr = "0580";
	if ownbr = "0252" then ownbr = "0683";
	if ownbr = "0253" then ownbr = "0581";
	if ownbr = "0254" then ownbr = "0582";
	if ownbr = "0255" then ownbr = "0583";
	if ownbr = "0256" then ownbr = "1103";
	if ownbr = "0302" then ownbr = "0133";
	if ownbr = "0668" then ownbr = "0680";
	if ownbr = "0877" then ownbr = "0806";
	if ownbr = "0885" then ownbr = "0802";
	if ownbr = "1003" and zip =: "87112" then ownbr = "1013";
	if ownbr = "1016" then ownbr = "1008";
	if ownbr = "1018" then ownbr = "1008";
	if zip =: "29659" & ownbr = "0152" then ownbr = "0121";
	if zip =: "36264" & ownbr = "0877" then ownbr = "0870";
RUN;

*** ED'S DNSDNH - NEED TO CHANGE FILE NAMES BASED ON UPDATE DATE - ***;
PROC IMPORT 
	DATAFILE = "\\server-lcp\LiveCheckService\DNHCustomers\DNHFile-09-26-2019-06-28.xlsx" 
		OUT = DNS DBMS = EXCEL;
	SHEET = "DNS";
RUN;

PROC IMPORT 
	DATAFILE = "\\server-lcp\LiveCheckService\DNHCustomers\DNHFile-09-26-2019-06-28.xlsx" 
		OUT = DNH DBMS = EXCEL;
	SHEET = "DNH";
RUN;

PROC IMPORT 
	DATAFILE = "\\server-lcp\LiveCheckService\DNHCustomers\DNHFile-09-26-2019-06-28.xlsx"
		OUT = DNHC DBMS = EXCEL; 
	SHEET = "DNH-C";
RUN;

DATA DNSDNH;
	SET DNS DNH DNHC;
	DNS_DNH_FLAG = "X";
	KEEP SSN DNS_DNH_FLAG;
RUN;

PROC DATASETS;
	MODIFY DNSDNH;
	RENAME SSN = SSNO1;
RUN;

PROC SORT 
	DATA = DNSDNH NODUPKEY;
	BY SSNO1;
RUN;

PROC SORT 
	DATA = MERGED_L_B2;
	BY SSNO1;
RUN;

DATA MERGED_L_B2;
	MERGE MERGED_L_B2(IN = x) DNSDNH;
	BY SSNO1;
	IF x;
RUN;

*** Identify candidates with multiple open loans ----------------- ***;
DATA OPENLOANS2;
	SET dw.vw_loan(
		KEEP = OWNBR SSNO2 SSNO1_RT7 POCD PLCD POFFDATE PLDATE 
			   BNKRPTDATE);
	WHERE POCD = "" &
		  PLCD = "" & 
		  POFFDATE = "" & 
		  PLDATE = "" & 
		  BNKRPTDATE = "";
	SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
RUN;

DATA SSNO2S;
	SET OPENLOANS2;
	SS7BRSTATE = CATS((SUBSTR(SSNO2, MAX(1, LENGTH(SSNO2) - 6))), 
		SUBSTR(OWNBR, 1, 2));
	IF SSNO2 NE "" THEN OUTOUT SSNO2S;
RUN;

DATA OPENLOANS3;
	SET OPENLOANS2 SSNO2S;
RUN;

DATA OPENLOANS4;
	SET OPENLOANS3;
	OPEN_FLAG2 = "X";
	IF SS7BRSTATE = "" 
		THEN SS7BRSTATE = CATS(SSNO1_RT7, SUBSTR(OWNBR, 1, 2));
	DROP POCD SSNO2 SSNO1_RT7 OWNBR PLCD POFFDATE PLDATE BNKRPTDATE;
RUN;

PROC SORT 
	DATA = OPENLOANS4;
	BY SS7BRSTATE;
RUN;

DATA ONE_OPEN MULT_OPEN;
	SET OPENLOANS4;
	BY SS7BRSTATE;
	IF FIRST.SS7BRSTATE AND LAST.SS7BRSTATE THEN OUTPUT ONE_OPEN;
	ELSE OUTPUT MULT_OPEN;
RUN;

PROC SORT 
	DATA = MULT_OPEN NODUPKEY;
	BY SS7BRSTATE;
RUN;

PROC SORT 
	DATA = MERGED_L_B2;
	BY SS7BRSTATE;
RUN;

DATA MERGED_L_B2;
	MERGE MERGED_L_B2(IN = x) MULT_OPEN;
	BY SS7BRSTATE;
	IF x;
RUN;

*** PULL AND MERGE DLQ INFO FOR PB'S ----------------------------- ***;
PROC FORMAT; /* DEFINE FORMAT FOR DELQ */
	VALUE CDFMT
		1 = 'Current'
		2 = '1-29cd'
		3 = '30-59cd'
		4 = '60-89cd'
		5 = '90-119cd'
		6 = '120-149cd'
		7 = '150-179cd'
		8 = '180+cd'
		OTHER = ' ';
RUN;

DATA ATB_data;
	SET dw.vw_ATB_Data(
		KEEP = BRACCTNO NetBal);
RUN;

PROC SORT 
	DATA = ATB_data; /* SORT TO MERGE */
	BY BRACCTNO;
RUN;

PROC SORT 
	DATA = MERGED_L_B2; /* SORT TO MERGE */
	BY BRACCTNO;
RUN;

DATA MERGED_L_B2; /* MERGE PULL AND DQL INFORMATION */
	MERGE MERGED_L_B2(IN = x) ATB_data(IN = y);
	BY BRACCTNO;
	IF x = 1;
RUN;

DATA ATB;
	SET dw.vw_AgedTrialBalance(
		KEEP = LoanNumber AGE2 BOM 
			WHERE = (BOM > "&_13MO")); /* ENTER DATE RANGE */
	
	BRACCTNO = LoanNumber;
	YEARMONTH = BOM;
  	ATBDT = INPUT(SUBSTR(YEARMONTH, 6, 2) || '/' || 
		    SUBSTR(YEARMONTH, 9, 2) || '/' || 
		    SUBSTR(YEARMONTH, 1, 4), mmddyy10.);

	*** AGE IS MONTH NUMBER OF LOAN WHERE 1 IS MOST RECENT MONTH - ***;
	AGE = INTCK('month', ATBDT, "&sysdate"d); 
	CD = SUBSTR(AGE2, 1, 1) * 1;

	*** I.E. FOR AGE = 1: THIS IS MOST RECENT MONTH. FILL DELQ1,   ***;
	*** WHICH IS DELQ FOR MONTH 1, WITH DELQ STATUS (CD) --------- ***;
	IF AGE = 1 THEN DELQ1 = CD;
	ELSE IF AGE = 2 THEN DELQ2 = CD;
	ELSE IF AGE = 3 THEN DELQ3 = CD;
	ELSE IF AGE = 4 THEN DELQ4 = CD;
	ELSE IF AGE = 5 THEN DELQ5 = CD;
	ELSE IF AGE = 6 THEN DELQ6 = CD;
	ELSE IF AGE = 7 THEN DELQ7 = CD;
	ELSE IF AGE = 8 THEN DELQ8 = CD;
	ELSE IF AGE = 9 THEN DELQ9 = CD;
	ELSE IF AGE =10 THEN DELQ10= CD;
	ELSE IF AGE =11 THEN DELQ11= CD;
	ELSE IF AGE =12 THEN DELQ12= CD;

	*** IF CD IS GREATER THAN 60-89 DAYS LATE, SET CD60 TO 1 ----- ***;
	IF CD > 3 THEN CD60 = 1;

	*** IF CD IS GREATER THAN 30-59 DAYS LATE, SET CD30 TO 1 ----- ***;
	IF CD > 2 THEN CD30 = 1;
	IF AGE < 4 THEN DO;
		IF CD > 2 THEN RECENT3 = 1; /* NOTE 30-59S IN LAST 6 MONTHS */
	END;
	ELSE IF 3 < AGE < 7 THEN DO;

		*** NOTE 30-59S FROM 7 TO 12 MONTHS AGO ------------------ ***;
		IF CD > 2 THEN RECENT4TO6 = 1; 
	END;
	IF AGE < 7 THEN DO;
		IF CD > 2 THEN RECENT6 = 1; /* NOTE 30-59S IN LAST 6 MONTHS */
		IF CD > 3 THEN RECENT6_60 = 1;
	END;
	ELSE IF 6 < AGE < 13 THEN DO;
		
		*** NOTE 30-59S FROM 7 TO 12 MONTHS AGO ------------------ ***;
		IF CD > 2 THEN FIRST6 = 1;
		IF CD > 3 THEN FIRST6_60 = 1;
	END;
	KEEP BRACCTNO DELQ1-DELQ12 CD CD30 CD60 AGE2 ATBDT AGE RECENT3 
		 RECENT4TO6 RECENT6_60 FIRST6_60 FIRST6 RECENT6;
RUN;

DATA ATB2;
	SET ATB;

	*** COUNT THE NUMBER OF 30-59s IN the last year -------------- ***;
	LAST12 = SUM(RECENT6, FIRST6); 
	LAST12_60 = SUM(RECENT6_60, FIRST6_60);
RUN;

*** COUNT CD30, CD60,RECENT6,FIRST6 BY BRACCTNO (*RECALL LOAN      ***;
*** POTENTIALLY COUNTED FOR EACH MONTH) -------------------------- ***;
PROC SUMMARY 
	DATA = ATB2 NWAY MISSING;
	CLASS BRACCTNO;
	VAR DELQ1-DELQ12 RECENT6 LAST12 FIRST6 LAST12_60 CD60 CD30;
	OUTPUT OUT = ATB3(DROP = _TYPE_ _FREQ_) SUM =;
RUN; 

DATA ATB4; /* CREATE NEW COUNTER VARIABLES */
	SET ATB3;
	TIMES30 = CD30;
	IF TIMES30 = . THEN TIMES30 = 0;
	IF RECENT6 = NULL THEN RECENT6 = 0;
	IF FIRST6 = NULL THEN FIRST6 = 0;
	IF LAST12 = NULL THEN LAST12 = 0;
	IF RECENT6_60 = NULL THEN RECENT6_60 = 0;
	IF FIRST6_60 = NULL THEN FIRST6_60 = 0;
	IF LAST12_60 = NULL THEN LAST12_60 = 0;
	IF RECENT3 = NULL THEN RECENT3 = 0;
	IF RECENT4TO6 = NULL THEN RECENT4TO6 = 0;
	DROP CD30;
	FORMAT DELQ1-DELQ12 cdfmt.;
RUN;

PROC SORT 
	DATA = ATB4 NODUPKEY; 
	BY BRACCTNO; 
RUN; /* SORT TO MERGE */

DATA DLQ;
	SET ATB4;
	DROP NULL; /* DROPPING THE NULL COLUMN (NOT NULLS IN DATASET) */
RUN;

PROC PRINT 
	DATA = DLQ (OBS = 5); /* CHECK DATASET */
RUN;

PROC SORT 
	DATA = MERGED_L_B2; /* SORT TO MERGE */
	BY BRACCTNO;
RUN;

DATA MERGED_L_B2; /* MERGE PULL AND DQL INFORMATION */
	MERGE MERGED_L_B2(IN = x) DLQ(IN = y);
	BY BRACCTNO;
	IF x = 1;
RUN;

DATA MERGED_L_B2; /* FLAG FOR BAD DLQ */
	SET MERGED_L_B2;
	IF RECENT3 > 0 OR RECENT6 >= 1 OR LAST12 > 2 OR LAST12_60 > 0 THEN 
		DLQ_FLAG = "X";
	IF DELQ1 NOT IN (1, .) THEN CURRENTLY_DELQ = "X";
RUN;

*** CONPROFILE FLAGS --------------------------------------------- ***;
DATA MERGED_L_B2;
	SET MERGED_L_B2;
	CON_RECENT6 = SUBSTR(CONPROFILE1, 1, 6);
	_30_RECENT6 = COUNTC(CON_RECENT6, "1");
	_60_RECENT6 = COUNTC(CON_RECENT6, "2");
	_30 = COUNTC(CONPROFILE1, "1");
	_60 = COUNTC(CONPROFILE1, "2");
	_90 = COUNTC(CONPROFILE1, "3");
	_120A = COUNTC(CONPROFILE1, "4");
	_120B = COUNTC(CONPROFILE1, "5");
	_120C = COUNTC(CONPROFILE1, "6");
	_120D = COUNTC(CONPROFILE1, "7");
	_120E = COUNTC(CONPROFILE1, "8");
	_90PLUS = SUM(_90, _120A, _120B, _120C, _120D, _120E);
	IF _30_RECENT6 > 0 | _30 > 2 | _60 > 0 | _90PLUS > 0 
		THEN CONPROFILE_FLAG = "X";
	_9S = COUNTC(CONPROFILE1, "9");
	if _9S > 10 THEN LESSTHAN2_FLAG = "X";
	XNO_TRUEDUEDATE2 = INPUT(SUBSTR(XNO_TRUEDUEDATE, 6, 2) || '/' || 
					   SUBSTR(XNO_TRUEDUEDATE, 9, 2) || '/' || 
					   SUBSTR(XNO_TRUEDUEDATE, 1, 4), mmddyy10.);
	FIRSTPYDATE2 = INPUT(SUBSTR(FIRSTPYDATE, 6, 2) || '/' || 
				   SUBSTR(FIRSTPYDATE, 9, 2) || '/' || 
				   SUBSTR(FIRSTPYDATE, 1, 4), mmddyy10.);
	PMT_DAYS = XNO_TRUEDUEDATE2 - FIRSTPYDATE2;
	IF PMT_DAYS < 60 THEN LESSTHAN2_FLAG = "X";
	IF PMT_DAYS = . & _9S < 10 THEN LESSTHAN2_FLAG = "";
	IF PMT_DAYS < 122 THEN LESSTHAN4_FLAG = "X";
	
	*** pmt_days calculation wINs over conprofile ---------------- ***;
	IF PMT_DAYS > 59 & _9S > 10 THEN LESSTHAN2_FLAG = "";
RUN;

PROC SQL;
	CREATE TABLE loanacct_statuses AS
	SELECT
    	t1.acctrefno, 
    	t1.cifno, 
    	t1.name, 
    	t1.loan_number, 
    	t1.input_date,
    	t1.open_date, 
    	t2.status_code_no
	FROM NLSPROD.loanacct t1
	INNER JOIN NLSPROD.loanacct_statuses t2 
	ON t1.acctrefno = t2.acctrefno;
QUIT;

DATA loanacct_statuses;
	SET loanacct_statuses;
	BRACCTNO = loan_number;
	KEEP BRACCTNO status_code_no;
RUN;

PROC SORT 
	DATA = MERGED_L_B2; /* SORT TO MERGE */
	BY BRACCTNO;
RUN;

PROC SORT 
	DATA = loanacct_statuses; /* SORT TO MERGE */
	BY BRACCTNO;
RUN;

DATA MERGED_L_B2; /* MERGE PULL AND DQL INFORMATION */
	MERGE MERGED_L_B2(IN = x) loanacct_statuses(IN = y);
	BY BRACCTNO;
	IF x = 1;
RUN;

DATA MERGED_L_B2;
	SET MERGED_L_B2;
	IF status_code_no IN (10, 11, 13, 16, 21, 22, 23, 40, 41, 42, 43, 
						  44, 45, 46, 47, 49, 50, 51, 52, 9001, 9002, 
						  9003, 9004, 9005, 9006, 9007, 9008, 9009, 
						  9010, 9011, 9012, 9013, 9014, 9016, 9018, 
						  9020, 9022) 
		THEN STATFL_FLAG = "X";
RUN;

PROC SQL;
	CREATE TABLE ll_approved AS
	SELECT
    	t1.LoanNumber, 
    	t1.LargeApprovedAmount
	FROM DW.AppData t1;
QUIT;

DATA ll_approved;
	SET ll_approved;
	BRACCTNO = LoanNumber;
	KEEP BRACCTNO LargeApprovedAmount;
RUN;

PROC SORT 
	DATA = MERGED_L_B2; /* SORT TO MERGE */
	BY BRACCTNO;
RUN;

PROC SORT 
	DATA = ll_approved; /* SORT TO MERGE */
	BY BRACCTNO;
RUN;

DATA MERGED_L_B2; /* MERGE PULL AND DQL INFORMATION */
	MERGE MERGED_L_B2(IN = x) ll_approved(IN = y);
	BY BRACCTNO;
	IF x = 1;
RUN;

PROC SORT
	DATA = MERGED_L_B2 OUT = DEDUPED NODUPKEY; 
	BY BRACCTNO; 
RUN;

PROC EXPORT 
	DATA = DEDUPED 
	    OUTFILE = '\\mktg-app01\E\cepps\CAD\Reports\11_2019\November_CAD_2019_flagged_10032019.txt' 
		DBMS = TAB;
RUN;

DATA FINALL_OFFERS;
	SET DEDUPED;
	pr_offer = "";
	sl_pq_offer = "";
	ll_pq_offer = "";
	pr_amount = .;
	sl_pq_amount = .;
	ll_pq_amount = .;
*** small loan preapproved criteria ------------------------------ ***;
	IF classtranslation = "Small" and
	   Available_Credit > Payoff_Amount * 0.10 and
	   Available_Credit >= 100 and
	   _9S <= 8 and
	   Payoff_Amount > 50
		then pr_offer = "X";
	IF classtranslation = "Checks" and
	   Available_Credit > Payoff_Amount * 0.10 and
	   Available_Credit >= 100 and
	   Payoff_Amount > 50
		then pr_offer = "X";
	IF classtranslation IN("Small" "Checks") and 
	   RECENT4TO6 > 0 
		then pr_offer = "";
	IF classtranslation IN("Small" "Checks") and
	   pr_offer = "X" and
	   Payoff_Amount <= 2300 
		then pr_amount = available_credit;
	IF classtranslation IN("Small" "Checks") and
	   pr_offer = "X" and
	   Payoff_Amount > 2300 
		then pr_amount = Original_Proceeds - 2300;
	IF classtranslation IN("Small" "Checks") and
	   pr_offer = "X" and
	   ownst = "AL" and
	   1500 <= pr_amount + Payoff_Amount <= 2000
	   	then pr_amount = 1400 - Payoff_Amount;
	IF classtranslation IN("Small" "Checks") and
	   pr_offer = "X" and
	   ownst = "GA" and
	   1500 <= pr_amount + Payoff_Amount <= 3000
	   	then pr_amount = 1400 - Payoff_Amount;
	IF classtranslation IN("Small" "Checks") and
	   pr_offer = "X" and
	   ownst = "OK" and
	   1500 <= pr_amount + Payoff_Amount <= 2500
	   	then pr_amount = 1400 - Payoff_Amount;
	IF classtranslation IN("Small" "Checks") and
	   pr_offer = "X" and
	   ownst = "TX" and
	   1400 <= pr_amount + Payoff_Amount <= 2500
	   	then pr_amount = 1300 - Payoff_Amount;
	IF pr_amount < 100 THEN pr_amount = .;
	IF pr_amount > 1000 THEN pr_amount = 1000;

*** small loan prequalified offer criteria ***;
	IF classtranslation = "Small" and
	   _9S <= 8 and
	   Available_Credit >= 100 and
	   Payoff_Amount > 50
	   	then sl_pq_offer = "X";
	IF classtranslation = "Checks" and
	   Available_Credit >= 100 and
	   Payoff_Amount > 50
		then sl_pq_offer = "X";
	IF classtranslation IN("Small" "Checks") and
	   sl_pq_offer = "X" and
	   ownst IN('GA' 'OK') and
	   LargeApprovedAmount > 0
		then ll_pq_offer = "X" and
			 ll_pq_amount = 3500 - Payoff_Amount;
	IF classtranslation IN("Small" "Checks") and
	   sl_pq_offer = "X" and
	   ownst IN('AL' 'MO' 'NM' 'SC', 'TN', 'WI')
		then sl_pq_amount = 2300 - Payoff_Amount; 
	IF classtranslation IN("Small" "Checks") and
	   sl_pq_offer = "X" and
	   ownst IN('GA' 'OK' 'TX' 'NC' 'VA') and
	   LargeApprovedAmount > 0
		then ll_pq_offer = "X";
	IF classtranslation IN("Small" "Checks") and
	   sl_pq_offer = "X" and
	   ownst IN('GA' 'OK' 'TX' 'NC' 'VA') and
	   LargeApprovedAmount > 0
		then ll_pq_amount = 3500 - Payoff_Amount;
	IF classtranslation IN("Small" "Checks") and
	   sl_pq_offer = "X" and
	   ownst IN('GA' 'OK')
	   	then sl_pq_amount = 1400 - Payoff_Amount;
	IF classtranslation IN("Small" "Checks") and
	   sl_pq_offer = "X" and
	   ownst IN('TX')
	   	then sl_pq_amount = 1300 - Payoff_Amount;
	IF classtranslation IN("Small" "Checks") and
	   sl_pq_offer = "X" and
	   ownst IN('NC' 'VA')
	   	then sl_pq_amount = 2300 - Payoff_Amount;
	IF sl_pq_amount < 100 THEN sl_pq_amount = .;
RUN;

DATA FINALL_OFFERS2;
	SET FINALL_OFFERS;
*** large loan prequalified offer criteria ***;
	IF classtranslation IN('Large' 'Auto-I' 'Auto-D') and
	   _9S <= 8 and
	   Available_Credit >= 100 and 
	   Available_Credit > Payoff_Amount * 0.1 
	   	then ll_pq_offer = "X";
	IF classtranslation IN('Auto-I' 'Auto-D') and 
	   ll_pq_offer = "X" and
	   Payoff_Amount > 7500
	   	then ll_pq_offer = "";
	IF classtranslation IN('Large' 'Auto-I' 'Auto-D') and
	   ll_pq_offer = "X"
	   	then ll_pq_amount =  Available_Credit;
	IF classtranslation IN('Large' 'Auto-I' 'Auto-D') and
	   ll_pq_offer = "X" and
	   Available_Credit < 500
	   	then ll_pq_amount =  500;
	IF classtranslation IN('Large' 'Auto-I' 'Auto-D') and
	   ll_pq_offer = "X" and
	   Available_Credit > 7000
	   	then ll_pq_amount =  7000;
	IF ll_pq_amount = . THEN ll_pq_offer = "";
	IF sl_pq_amount = . THEN sl_pq_offer = "";
	IF pr_amount = . THEN pr_offer = "";
RUN;

*** Determine the best offer ------------------------------------- ***;
DATA FINALL_OFFERS3;
	SET FINALL_OFFERS2;
	OFFER_TYPE = "Branch ITA";
	IF pr_amount > sl_pq_amount and
	   pr_amount > ll_pq_amount
	   	then OFFER_TYPE = "Preapproved";
	IF pr_amount > sl_pq_amount and
	   pr_amount > ll_pq_amount
	   	then OFFER_AMOUNT = pr_amount;
	IF sl_pq_amount > pr_amount and
	   sl_pq_amount > ll_pq_amount
	   	then OFFER_TYPE = "Prequalified";
	IF sl_pq_amount > pr_amount and
	   sl_pq_amount > ll_pq_amount
	   	then OFFER_AMOUNT = sl_pq_amount;
	
	IF ll_pq_amount > pr_amount and
	   ll_pq_amount > sl_pq_amount
	   	then OFFER_TYPE = "Prequalified";
	IF ll_pq_amount > pr_amount and
	   ll_pq_amount > sl_pq_amount
	   	then OFFER_AMOUNT = ll_pq_amount;

	IF Available_Credit < 100 then OFFER_TYPE = "Branch ITA";
	IF classtranslation = "Large" and
	   Net_Tangible_Benefit = "NO"
	   	then OFFER_TYPE = "Branch ITA";
	IF classtranslation = "Large" and
	   Net_Tangible_Benefit = ""
	   	then OFFER_TYPE = "Branch ITA";

	IF RECENT4TO6 > 0 then OFFER_TYPE = "Branch ITA";
	IF OFFER_TYPE = "Branch ITA" then OFFER_AMOUNT = .;

RUN;

DATA FINAL;
	SET FINALL_OFFERS3;
RUN;

*** COUNT OBS FROM LOAN ------------------------------------------ ***;
PROC SQL; 
	CREATE TABLE COUNT AS SELECT COUNT(*) AS COUNT FROM DEDUPED; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF BADBRANCH_FLAG = ""; 
RUN;

PROC SQL;
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF MISSINGINFO_FLAG = ""; 
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT; 

DATA FINAL; 
	SET FINAL; 
	IF OOS_FLAG = ""; 
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF STATE_MISMATCH_FLAG = ""; 
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT; 

DATA FINAL; 
	SET FINAL; 
	IF AUTODELETE_FLAG = ""; 
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF RETAILDELETE_FLAG = ""; 
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF OPEN_FLAG2 = ""; 
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL; 
	IF BADPOCODE_FLAG = ""; 
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL;
	IF DECEASED_FLAG = "";
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL;
	IF LESSTHAN2_FLAG = "";
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL;
	IF DLQ_FLAG = "";
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL;
	IF CONPROFILE_FLAG = "";
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL;
	IF BK2_FLAG = "";
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL;
	IF STATFL_FLAG = "";
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL;
	IF TRW_FLAG = "";
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL;
	IF DNS_DNH_FLAG = "";
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL;
	IF DLQREN_FLAG = "";
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL;
	IF CURRENTLY_DELQ = "";
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

DATA FINAL; 
	SET FINAL;
	IF DEFERMENT_FLAG = "";
RUN;

PROC SQL; 
	INSERT INTO COUNT SELECT COUNT(*) AS COUNT FROM FINAL; 
QUIT;

PROC PRINT 
	DATA = COUNT NOOBS;
RUN;

DATA FINAL;
	SET FINAL;
	CAMPAIGN_ID="CAD11.0_2019";
RUN;

PROC SORT
	DATA = FINAL NODUPKEY;
	BY BRACCTNO;
RUN;

PROC EXPORT
	DATA = FINAL 
	 /* OUTFILE = '\\mktg-app01\E\Production\2018\CAD_BTS_2018\August_BTS_2018_final_06082018.txt' */
		OUTFILE = '\\mktg-app01\E\cepps\CAD\Reports\11_2019\November_CAD_2019_final_10032019.txt'
		REPLACE DBMS = TAB;
 RUN;

 DATA WATERFALL;
	LENGTH CRITERIA $50 COUNT 8.;
	INFILE DATALINES DLM = "," TRUNCOVER;
	INPUT CRITERIA $ COUNT;
	DATALINES;
Final Open Total,			
Delete customers IN Bad Branches,	
Delete customers with MissINg INfo,	
Delete customers Outside of FootprINt,	
Delete where State/OWNST Mismatch,
Delete Auto Loans,
Delete Retail Loans,
Delete if customer has multiple loans,
Delete customers with a "bad" POCODE,
Delete if deceased,
Delete if Less than Two Payments Made,	
Delete for ATB DelINquency,	
Delete for Conprofile DelINquency,
Delete for Bankruptcy (5yr),
Delete for Statflag (5yr),
Delete for TRW Status (5yr),
Delete if DNS or DNH,
Delete if DelINquent Renewal,
Delete if Not Current (ATB),
Delete if Deferment IN last 90 days,
;/*Delete Harvey Deferrals*/
RUN;

*** SEND TO DOD -------------------------------------------------- ***;
DATA MLA;
	SET FINAL;
	KEEP SSNO1 DOB LASTNAME FIRSTNAME MIDDLENAME BRACCTNO;
	LASTNAME = compress(LASTNAME,"ABCDEFGHIJKLMNOPQRSTUVWXYZ " , "kis");
	MIDDLENAME = compress(MIDDLENAME,"ABCDEFGHIJKLMNOPQRSTUVWXYZ " , "kis");
	FIRSTNAME = compress(FIRSTNAME,"ABCDEFGHIJKLMNOPQRSTUVWXYZ " , "kis");
	SSNO1_A = compress(SSNO1,"1234567890 " , "kis");
	SSNO1 = put(input(SSNO1_A,best9.),z9.);
	DOB = compress(DOB,"1234567890 " , "kis");
	if DOB = ' ' then delete;
RUN;

DATA MLA;
	SET MLA;
	IDENTIFIER = "S";
RUN;

PROC DATASETS;
	MODIFY MLA;
	RENAME DOB = "Date of Birth"n 
		   SSNO1 = "Social Security Number (SSN)"n
		   LASTNAME = "Last NAME"n 
		   FIRSTNAME = "First NAME"n 
		   MIDDLENAME = "Middle NAME"n 
		   BRACCTNO = "Customer Record ID"n
		   IDENTIFIER = "Person Identifier CODE"n;
RUN;

DATA FINALMLA;
	LENGTH "Social Security Number (SSN)"n $ 9 
		   "Date of Birth"n $ 8
		   "Last NAME"n $ 26
		   "First NAME"n $20
		   "Middle NAME"n $ 20
		   "Customer Record ID"n $ 28
		   "Person Identifier CODE"n $ 1;
	SET MLA;
RUN;

PROC PRINT 
	DATA = FINALMLA(OBS = 10);
RUN;

PROC CONTENTS
	DATA = FINALMLA;
RUN;

DATA _NULL_;
	SET FINALMLA;
	FILE "\\mktg-app01\E\Production\MLA\MLA-INput files TO WEBSITE\CAD_20191003.txt";
	PUT @ 1 "Social Security Number (SSN)"n 
		@ 10 "Date of Birth"n 
		@ 18 "Last NAME"n 
		@ 44 "First NAME"n 
		@ 64 "Middle NAME"n 
		@ 84 "Customer Record ID"n
		@ 112 "Person Identifier CODE"n;
RUN;

*** RUN AFTER RECEIVING RESULTS FROM MLA ------------------------- ***; 

FILENAME MLA1
 "\\mktg-app01\E\Production\MLA\MLA-Output files FROM WEBSITE\MLA_5_1_CAD_20191003.txt";

DATA MLA1;
	INFILE MLA1;
	INPUT SSNO1 $ 1-9 DOB $ 10-17 LASTNAME $ 18-43 FIRSTNAME $ 44-63
		  MIDDLENAME $ 64-83  BRACCTNO $ 84-120 MLA_DOD $121-145;
	MLA_STATUS = SUBSTR(MLA_DOD, 1, 1);
RUN;

PROC PRINT
	DATA = MLA1(OBS = 10);
RUN;

PROC SORT
	DATA = FINAL;
	BY BRACCTNO;
RUN;

PROC SORT
	DATA = MLA1;
	BY BRACCTNO;
RUN;

DATA FINALHH;
	MERGE FINAL(IN = x) MLA1;
	BY BRACCTNO;
	IF x;
RUN;

*** COUNT FOR WATERFALL ------------------------------------------ ***;
PROC FREQ
	DATA = FINALHH;
	TABLE MLA_STATUS;
RUN;

DATA FICOS;
	SET FINALHH;
	RENAME CRSCORE = FICO;
RUN;

DATA FINALHH2;
	LENGTH FICO_RANGE_25PT $10 CAMPAIGN_ID $25;
	SET FICOS;
	IF MLA_STATUS NE "Y";
	IF FICO = 0 THEN FICO_RANGE_25PT = "0";
	IF 0 < FICO < 26 THEN FICO_RANGE_25PT = "1-25";
	IF 25 <= FICO <= 49	THEN FICO_RANGE_25PT = "25-49";
	IF 50 <= FICO <= 74	THEN FICO_RANGE_25PT = "50-74";
	IF 75 <= FICO <= 99	THEN FICO_RANGE_25PT = "75-99";
	IF 100 <= FICO <= 124 THEN FICO_RANGE_25PT = "100-124";	
	IF 125 <= FICO <= 149 THEN FICO_RANGE_25PT = "125-149";
	IF 150 <= FICO <= 174 THEN FICO_RANGE_25PT = "150-174";
	IF 175 <= FICO <= 199 THEN FICO_RANGE_25PT = "175-199";
	IF 200 <= FICO <= 224 THEN FICO_RANGE_25PT = "200-224";
	IF 225 <= FICO <= 249 THEN FICO_RANGE_25PT = "225-249";
	IF 300 <= FICO <= 324 THEN FICO_RANGE_25PT = "300-324";
	IF 350 <= FICO <= 374 THEN FICO_RANGE_25PT = "350-374";
	IF 400 <= FICO <= 424 THEN FICO_RANGE_25PT = "400-424";
	IF 425 <= FICO <= 449 THEN FICO_RANGE_25PT = "425-449";
	IF 450 <= FICO <= 474 THEN FICO_RANGE_25PT = "450-474";
	IF 475 <= FICO <= 499 THEN FICO_RANGE_25PT = "475-499";
	IF 500 <= FICO <= 524 THEN FICO_RANGE_25PT = "500-524";
	IF 525 <= FICO <= 549 THEN FICO_RANGE_25PT = "525-549";
	IF 550 <= FICO <= 574 THEN FICO_RANGE_25PT = "550-574";
	IF 575 <= FICO <= 599 THEN FICO_RANGE_25PT = "575-599";
	IF 600 <= FICO <= 624 THEN FICO_RANGE_25PT = "600-624";
	IF 625 <= FICO <= 649 THEN FICO_RANGE_25PT = "625-649";
	IF 650 <= FICO <= 674 THEN FICO_RANGE_25PT = "650-674";
	IF 675 <= FICO <= 699 THEN FICO_RANGE_25PT = "675-699";
	IF 700 <= FICO <= 724 THEN FICO_RANGE_25PT = "700-724";
	IF 725 <= FICO <= 749 THEN FICO_RANGE_25PT = "725-749";
	IF 750 <= FICO <= 774 THEN FICO_RANGE_25PT = "750-774";
	IF 775 <= FICO <= 799 THEN FICO_RANGE_25PT = "775-799";
	IF 800 <= FICO <= 824 THEN FICO_RANGE_25PT = "800-824";
	IF 825 <= FICO <= 849 THEN FICO_RANGE_25PT = "825-849";
	IF 850 <= FICO <= 874 THEN FICO_RANGE_25PT = "850-874";
	IF 875 <= FICO <= 899 THEN FICO_RANGE_25PT = "875-899";
	IF 975 <= FICO <= 999 THEN FICO_RANGE_25PT = "975-999";
	IF FICO = "" THEN FICO_RANGE_25PT = "";
RUN;

PROC EXPORT 
	DATA = FINALHH2 
	 /* OUTFILE = '\\mktg-app01\E\cepps\CAD\Reports\05_2018\August_CAD_BTS_2018_finalHH_05012018.txt' */
		OUTFILE = '\\mktg-app01\E\cepps\CAD\Reports\11_2019\November_CAD_2019_finalHH_10032019.txt'
		DBMS = DLM;
	DELIMITER = ",";
RUN;

PROC FREQ
	DATA = FINALHH2;
	TABLES DELQ1 DELQ2 DELQ3 DELQ4 DELQ5 DELQ6 DELQ7 DELQ8 DELQ9 DELQ10
		   DELQ11 DELQ12 / NOCUM NOPERCENT;
RUN;

PROC SORT
	DATA = FINALHH2;
	BY OFFER_TYPE;
RUN;

ODS EXCEL;

PROC TABULATE
	DATA = FINALHH2;
	CLASS OFFER_TYPE CLASSTRANSLATION;
	VAR OFFER_AMOUNT;
	TABLES OFFER_TYPE*CLASSTRANSLATION,
		(MIN*OFFER_AMOUNT MAX*OFFER_AMOUNT);
RUN;

PROC TABULATE
	DATA = FINALHH2;
	CLASS OWNST OWNBR OFFER_TYPE;
	TABLES OWNST*(OWNBR ALL) ALL, N/NOCELLMERGE;
	BY OFFER_TYPE;
RUN;

PROC TABULATE
	DATA = FINALHH2;
	CLASS OFFER_TYPE CLASSTRANSLATION;
	VAR OFFER_AMOUNT;
	TABLES OFFER_TYPE*(CLASSTRANSLATION ALL) ALL, 
		N (MIN*OFFER_AMOUNT MAX*OFFER_AMOUNT);
RUN;

ODS EXCEL CLOSE;

DATA FINALHH2;
	LENGTH VND_DROP $10 VND_DUP $10;
	SET FINALHH2;
RUN;

PROC SQL;
	CREATE TABLE FINALEC AS 
	SELECT BRACCTNO, OWNBR, CLASSTRANSLATION, SSNO1_RT7, CIFNO,
		   FIRSTNAME, MIDDLENAME, LASTNAME, ADR1, ADR2, CITY, STATE,
		   ZIP, DOB, OFFER_TYPE, OFFER_AMOUNT, CAMPAIGN_ID, /*DROPDATE,
		   EXPIRATIONDATE,*/ VND_DROP, VND_DUP, Acctrefno
	FROM FINALHH2;
QUIT;

PROC EXPORT
	DATA = FINALEC 
	 /* OUTFILE = '\\mktg-app01\E\cepps\CAD\Reports\05_2018\August_CAD_BTS_2018_final_EC_05012018.txt' */
		OUTFILE = '\\mktg-app01\E\cepps\CAD\Reports\11_2019\November_CAD_2019_final_EC_10032019.txt'
		DBMS = DLM;
	DELIMITER = ",";
RUN;

PROC EXPORT
	DATA = FINALEC 
	 /* OUTFILE = '\\rmc.local\dfsroot\Dept\MarketINg\2018 Programs\1) Direct Mail Programs\2018 CAD Programs\May 2018 CAD\August_CAD_BTS_2018_final_EC_05012018.xlsx' */
		OUTFILE = '\\mktg-app01\E\cepps\CAD\Reports\11_2019\November_CAD_2019_final_EC_10032019.xlsx'
	DBMS = EXCEL;
RUN;

DATA FINALEC2;
	SET FINALEC;
	IF OFFER_TYPE = "Preapproved";
RUN;

PROC EXPORT
	DATA = FINALEC2
	 /* OUTFILE = '\\rmc.local\dfsroot\Dept\MarketINg\2018 Programs\1) Direct Mail Programs\2018 CAD Programs\May 2018 CAD\August_CAD_BTS_2018_final_EC2_05012018.xlsx' */
		OUTFILE = '\\mktg-app01\E\cepps\CAD\Reports\11_2019\November_CAD_2019_final_preapproved_10032019.xlsx'
		DBMS = EXCEL;
RUN;

PROC EXPORT
	DATA = FINALEC2 
	 /* OUTFILE = '\\rmc.local\dfsroot\Dept\MarketINg\2018 Programs\1) Direct Mail Programs\2018 CAD Programs\May 2018 CAD\August_CAD_BTS_2018_final_EC2_05012018.txt' */
		OUTFILE = '\\mktg-app01\E\cepps\CAD\Reports\11_2019\November_CAD_2019_final_preapproved_10032019.txt'
		DBMS = DLM;
	DELIMITER = ",";
RUN;

PROC CONTENTS
	DATA = FINALEC2;
RUN;

DATA FINAL_PREQUAL;
	SET FINALEC;
	IF OFFER_TYPE = "Prequalified";
RUN;

PROC EXPORT
	DATA = FINAL_PREQUAL 
	 /* OUTFILE = '\\rmc.local\dfsroot\Dept\MarketINg\2018 Programs\1) Direct Mail Programs\2018 CAD Programs\May 2018 CAD\August_CAD_BTS_2018_final_ITA_05012018.xlsx' */
		OUTFILE = '\\mktg-app01\E\cepps\CAD\Reports\11_2019\November_CAD_2019_final_prequalified_10032019.xlsx'
	DBMS = EXCEL;
RUN;

PROC EXPORT
	DATA = FINAL_PREQUAL 
	 /* OUTFILE = '\\rmc.local\dfsroot\Dept\MarketINg\2018 Programs\1) Direct Mail Programs\2018 CAD Programs\May 2018 CAD\August_CAD_BTS_2018_final_EC2_05012018.txt' */
		OUTFILE = '\\mktg-app01\E\cepps\CAD\Reports\11_2019\November_CAD_2019_final_prequalified_10032019.txt'
		DBMS = DLM;
	DELIMITER = ",";
RUN;

PROC CONTENTS
	DATA = FINAL_PREQUAL;
RUN;

DATA FINAL_ITA;
	SET FINALEC;
	IF OFFER_TYPE = "Branch ITA";
RUN;

PROC EXPORT
	DATA = FINAL_ITA 
	 /* OUTFILE = '\\rmc.local\dfsroot\Dept\MarketINg\2018 Programs\1) Direct Mail Programs\2018 CAD Programs\May 2018 CAD\August_CAD_BTS_2018_final_ITA_05012018.xlsx' */
		OUTFILE = '\\mktg-app01\E\cepps\CAD\Reports\11_2019\November_CAD_2019_final_ITA_10032019.xlsx'
	DBMS = EXCEL;
RUN;
