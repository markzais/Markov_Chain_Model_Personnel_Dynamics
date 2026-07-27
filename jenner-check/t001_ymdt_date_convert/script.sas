/*
  Derived from Zais_Data_20131105.sas (the Zais_Inv_Condensed_Dates DATA step,
  original lines 68-194): converts the numeric YM_DT (YYYYMM) into a true SAS
  date, maps CMF_CD to a career-management-field text label, and computes the
  integer DATE_INDEX. The two external libname datasets in the original point
  at a local D:\ drive; here a small inline inventory of the same column shape
  stands in so the transformation logic runs unmodified. The original's
  previous-month text block (DATETXT_PREV) is trimmed here since it feeds a
  downstream merge not exercised by this slice; everything else is verbatim.
*/
data Zais_Inv_Condensed3;
  input YM_DT CMF_CD PMOS_CD $ EP_SSN;
  datalines;
200610 11 11B 100000001
200611 68 68W 100000002
200612 13 13B 100000003
200701 19 19D 100000004
200702 88 88M 100000005
200703 . 92A 100000006
200704 18 18B 100000007
200812 31 31B 100000008
;
run;

*Pre-process data.  Convert YM_DT to true "date";
data Zais_Inv_Condensed_Dates (rename = (YM_DT_PREVNUM = YM_DT));
set Zais_Inv_Condensed3;

format REDCAT_CD $1. MONTHN NEWMONTH 2. TEXT_MONTH $3. DATETXT $9.;
format YM_DT 6. YM_DT2 $6. YEARN 4. DAY 2. NEWYEAR 4.;
format YM_DT_PREVNUM 6. YM_DT_NUMPRE_TXT $6.;
length YM_DT_PREVNUM 6.;

*First convert YM_DT format into regular date format;
DAY = 15;

YM_DT2=PUT(YM_DT,6.); *Convert from number to text format to prepare for SAS date conversion;
STRINGYEAR=COMPRESS(YM_DT2,'');
YEARN=SUBSTR(STRINGYEAR,1,4)*1;
MONTHN=SUBSTR(STRINGYEAR,5,2)*1;
if MONTHN = 1 then TEXT_MONTH = 'JAN';
if MONTHN = 2 then TEXT_MONTH = 'FEB';
if MONTHN = 3 then TEXT_MONTH = 'MAR';
if MONTHN = 4 then TEXT_MONTH = 'APR';
if MONTHN = 5 then TEXT_MONTH = 'MAY';
if MONTHN = 6 then TEXT_MONTH = 'JUN';
if MONTHN = 7 then TEXT_MONTH = 'JUL';
if MONTHN = 8 then TEXT_MONTH = 'AUG';
if MONTHN = 9 then TEXT_MONTH = 'SEP';
if MONTHN = 10 then TEXT_MONTH = 'OCT';
if MONTHN = 11 then TEXT_MONTH = 'NOV';
if MONTHN = 12 then TEXT_MONTH = 'DEC';

DATETXT= catt(DAY,TEXT_MONTH,YEARN);
GREGORIAN_DT=INPUT(DATETXT,DATE9.); *Now it's in date format, text to number format;

if MONTHN = 12 then	NEWMONTH = 1;
else NEWMONTH = (MONTHN)*1 + 1;

if NEWMONTH = 12 then NEWMONTH_TXT = '12';
if NEWMONTH  = 11 THEN NEWMONTH_TXT = '11';
if NEWMONTH = 10 then NEWMONTH_TXT = '10';
if NEWMONTH = 9 then NEWMONTH_TXT = '09';
if NEWMONTH = 8 then NEWMONTH_TXT = '08';
if NEWMONTH = 7 then NEWMONTH_TXT = '07';
if NEWMONTH = 6 then NEWMONTH_TXT = '06';
if NEWMONTH = 5 then NEWMONTH_TXT = '05';
if NEWMONTH = 4 then NEWMONTH_TXT = '04';
if NEWMONTH = 3 then NEWMONTH_TXT = '03';
if NEWMONTH = 2 then NEWMONTH_TXT = '02';
if NEWMONTH = 1 then NEWMONTH_TXT = '01';

if MONTHN = 12 	then NEWYEAR = YEARN + 1;
else NEWYEAR = YEARN;

NEWYEAR_TXT = PUT(NEWYEAR,4.);

YM_DT_NUMPRE_TXT = CATT(NEWYEAR,NEWMONTH_TXT); *In format 200809, text ;
YM_DT_PREVNUM = 1*YM_DT_NUMPRE_TXT; *In 200809, number format;
drop YM_DT;

*Setup CMF text names;
	format CMF_CD 2.;
	if CMF_CD = 13 then CMF_TEXT = 'FIELD ARTILLERY';
	if CMF_CD = 0 then CMF_TEXT = 'OTHER';
	if CMF_CD = 09 then CMF_TEXT = 'OTHER';
	if CMF_CD = 11 then CMF_TEXT = 'INFANTRY';
	if CMF_CD = 12 then CMF_TEXT = 'ENGINEER';
	if CMF_CD = 18 then CMF_TEXT = 'SPECIAL FORCES';
	if CMF_CD = 19 then CMF_TEXT = 'ARMOR';
	if CMF_CD = 31 then CMF_TEXT = 'MP';
	if CMF_CD = 68 then CMF_TEXT = 'MEDICAL CORPS';
	if CMF_CD = 88 then CMF_TEXT = 'TRANSPORTATION';
	if CMF_CD = . then CMF_TEXT = 'OTHER';
	if CMF_CD = ' ' then CMF_TEXT = 'OTHER';

	format YM_DT 6. GREGORIAN_DT date9.;

	DATE_INDEX = (round(YM_DT/100)-2000)*12 + (YM_DT -  round(YM_DT/100)*100);

	drop MONTHN TEXT_MONTH DATETXT YM_DT2 YEARN DAY NEWYEAR YM_DT_NUMPRE_TXT STRINGYEAR NEWMONTH_TXT
		  NEWYEAR_TXT CMF_CD NEWMONTH;
run;

proc print data = Zais_Inv_Condensed_Dates;
  var YM_DT PMOS_CD GREGORIAN_DT CMF_TEXT DATE_INDEX;
  title "YM_DT to SAS date conversion + CMF label + DATE_INDEX";
run;
