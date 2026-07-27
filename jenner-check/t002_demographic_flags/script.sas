/*
  Derived from Zais_Data_20131105.sas (the Zais_Inventory_Losses2 DATA step,
  original lines 206-243): builds one-hot demographic indicators from the
  SEX_CATEGORY_CD / MARST_CD / REDCAT_CD codes, then derives MO_SINCE_DEPLOY
  (floor of the day gap / 30.5), a DEPLOY flag, integer AGE via YRDIF, and
  EXPER (months of service / 12, rounded). The original's input is a PROC SQL
  merge of two D:\ libname tables; here a small inline stand-in of the same
  columns feeds the step so the derivation logic runs unmodified.
*/
data Zais_Inventory_Losses;
  infile datalines dsd truncover;
  input SEX_CATEGORY_CD :$1. MARST_CD :$1. REDCAT_CD :$1.
        TRANS_DT :date9. DEPL_DT :date9. BIRTH_DT :date9.
        GREGORIAN_DT :date9. MSV_QY TOE_UNIT;
  format TRANS_DT DEPL_DT BIRTH_DT GREGORIAN_DT date9.;
  datalines;
M,M,C,15MAR2007,01JAN2006,20JUN1985,15MAR2007,96,1
F,S,H,15APR2007,,10FEB1988,15APR2007,48,0
M,D,N,15MAY2007,15JUN2004,05DEC1979,15MAY2007,144,1
M,M,A,15JUN2007,01JAN2007,30SEP1990,15JUN2007,36,1
F,M,C,15JUL2007,,12MAR1983,15JUL2007,120,0
M,S,X,15AUG2007,10OCT2001,25JUL1986,15AUG2007,84,1
;
run;

data Zais_Inventory_Losses2;
set Zais_Inventory_Losses;
MALE = 0;
FEMALE = 0;
MARRIED = 0;
DIVORCED = 0;
SINGLE = 0;
WHITE = 0;
HISPANIC = 0;
BLACK = 0;
ASIAN_OTHER = 0;

if SEX_CATEGORY_CD eq 'F' then FEMALE = 1;
if SEX_CATEGORY_CD eq 'M' then MALE = 1;
if MARST_CD eq 'M' then MARRIED = 1;
if MARST_CD eq 'D' then DIVORCED = 1;
if MARST_CD eq 'S' then SINGLE = 1;
if REDCAT_CD eq 'C' then WHITE = 1;
if REDCAT_CD eq 'H' then HISPANIC = 1;
if REDCAT_CD eq 'N' then BLACK = 1;
if REDCAT_CD eq 'A' then ASIAN_OTHER = 1;
if REDCAT_CD eq 'X' then ASIAN_OTHER = 1;
if REDCAT_CD eq 'T' then ASIAN_OTHER = 1;

*Months since deployment;
MO_SINCE_DEPLOY = floor((TRANS_DT-DEPL_DT)/30.5);
if MO_SINCE_DEPLOY = . then MO_SINCE_DEPLOY = 0;
if MO_SINCE_DEPLOY < 0 then MO_SINCE_DEPLOY = 0;
DEPLOY = 0;
if MO_SINCE_DEPLOY <12*10 then DEPLOY = 1; *less than 10 years since deployment;
AGE = INT(YRDIF(BIRTH_DT, GREGORIAN_DT,'ACTUAL'));
EXPER = MSV_QY/12;
EXPER = ROUND(EXPER,.1);

TOE=(TOE_UNIT=1); *Binary variable;
format GREGORIAN_DT date9.;
drop SEX_CATEGORY_CD REDCAT_CD MARST_CD MSV_QY TOE_UNIT;
run;

proc print data = Zais_Inventory_Losses2;
  var MALE FEMALE MARRIED SINGLE DIVORCED WHITE HISPANIC BLACK ASIAN_OTHER
      MO_SINCE_DEPLOY DEPLOY AGE EXPER TOE;
  title "Demographic one-hot flags + derived deployment/age/experience";
run;
