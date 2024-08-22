libname Army 'D:\Retention Data\Dissertation_p1_2013';
libname Zais 'D:\Retention Data\Zais';
/**/
options MPRINT MLOGIC SYMBOLGEN ERRORS=300000 NOFMTERR INVALIDDATA = .;

options dtreset; *reset time for output printing;
options ps=255 ls=100; *page size and line size of output;

/*proc contents data = Zais.Master_Inv_200610_200909;*/
/*run;*/

/********************INVENTORY*******************************************/
*Reduce the number of columns for our analysis;
proc sql;
create table Zais.Zais_Inv_Condensed as 
	select distinct YM_DT, EP_SSN, MSV_QY,DEPL_DT, SEX_CATEGORY_CD, SVC_TERM_CD,MARST_CD, MINOR_DEP_QY,PAY_GRADE_ID,AFQT_PCNT_QY,TIG_QY,CAREER_STAT, REENL_QY, 
					TDA_TOE_CAT_CD as TOE_UNIT, PMOS_CD, CMF_CD, CIV_ED_QY, BIRTH_DT, REDCAT_CD, METS_QY
	from Army.Master_Inv_200610_200909
	where YM_DT >= 0 
	order by YM_DT,EP_SSN,MSV_QY,TIG_QY, CAREER_STAT, REENL_QY,DEPL_DT, SEX_CATEGORY_CD, SVC_TERM_CD, MARST_CD,MINOR_DEP_QY,PAY_GRADE_ID,AFQT_PCNT_QY, PMOS_CD, 
			CIV_ED_QY, BIRTH_DT, REDCAT_CD, METS_QY, CMF_CD;
quit;

data Zais.Zais_Inv_Condensed2 (rename = (SSN=EP_SSN)); *converted SSN to numeric;
set Zais.Zais_Inv_Condensed;
if verify(EP_SSN,'0123456789') gt 0 then delete;* then put "Invalid value of SSN:" EP_SSN;
/*if SVC_TERM_CD = . then delete;*/

if PAY_GRADE_ID in (1 2 3) THEN PAY_GRADE_ID = 4;
SSN = EP_SSN*1;
drop EP_SSN;
run;

/********************TRANSACTIONS*******************************************/
proc sort data = Army.All_Transactions_200610_200909 out = Zais.Zais_All_Trans_NoDup (KEEP = PROC_MONTH_ID PROC_YEAR_ID SSN_ID LOSS_TYPE_CD TRANS_DT);
by SSN_ID TRANS_DT LOSS_TYPE_CD;
run;

data Zais.Zais_All_Trans_LIMR_LETS (rename = (SSN = EP_SSN));
set Zais.Zais_All_Trans_NoDup;
informat YM_DT 6.;
if PROC_MONTH_ID < 10 then YM_DT = cat(PROC_YEAR_ID,'0',PROC_MONTH_ID);
else YM_DT = cat(PROC_YEAR_ID,PROC_MONTH_ID);
if LOSS_TYPE_CD in ('LIMR' 'LETS' 'LNDR');

SSN = SSN_ID *1;

DATE_INDEX = (round(YM_DT/100)-2000)*12 + (YM_DT -  round(YM_DT/100)*100);

drop SSN_ID;
format YM_DT 6. SSN 9.;
drop PROC_MONTH_ID PROC_YEAR_ID;
run;

*Final try, keep only SSNs that appear in Transaction file;
proc sql;
create table Zais.Zais_Inv_Condensed3
as select a.* from Zais.Zais_Inv_Condensed2 as a
where a.EP_SSN in (select EP_SSN from Zais.Zais_All_Trans_LIMR_LETS)
order by a.YM_DT, a.EP_SSN, a.PMOS_CD;
quit;

proc sort data = Zais.Zais_Inv_Condensed3 nodup;
by YM_DT EP_SSN;
run; *No futher duplicates;

*Pre-process data.  Convert YM_DT to true "date";
data Zais.Zais_Inv_Condensed_Dates (rename = (YM_DT_PREVNUM = YM_DT));
set Zais.Zais_Inv_Condensed3; 

format REDCAT_CD $1. MONTHN NEWMONTH 2. TEXT_MONTH $3. DATETXT $9.;
format DATETXT_PREV $9. YM_DT 6. YM_DT2 $6. YEARN 4. DAY 2. NEWYEAR 4.; 
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

/**Create previous months data;*/
/*if MONTHN =1 then NEWMONTH = 12;*/
/*else NEWMONTH = (MONTHN)*1 - 1;*/

if MONTHN = 12 then	NEWMONTH = 1;
else NEWMONTH = (MONTHN)*1 + 1;

*Setup for future merging, date in text format;
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

*Previous dates in text format;
/*if MONTHN = 1 then NEWYEAR = YEARN-1;*/
/*else NEWYEAR = YEARN;*/
if MONTHN = 12 	then NEWYEAR = YEARN + 1;
else NEWYEAR = YEARN;

if NEWMONTH = 1 then TEXT_MONTHNEW = 'JAN';
if NEWMONTH = 2 then TEXT_MONTHNEW = 'FEB';
if NEWMONTH = 3 then TEXT_MONTHNEW = 'MAR';
if NEWMONTH = 4 then TEXT_MONTHNEW = 'APR';
if NEWMONTH = 5 then TEXT_MONTHNEW = 'MAY';
if NEWMONTH = 6 then TEXT_MONTHNEW = 'JUN';
if NEWMONTH = 7 then TEXT_MONTHNEW = 'JUL';
if NEWMONTH = 8 then TEXT_MONTHNEW = 'AUG';
if NEWMONTH = 9 then TEXT_MONTHNEW = 'SEP';
if NEWMONTH = 10 then TEXT_MONTHNEW = 'OCT';
if NEWMONTH = 11 then TEXT_MONTHNEW = 'NOV';
if NEWMONTH = 12 then TEXT_MONTHNEW = 'DEC';

NEWYEAR_TXT = PUT(NEWYEAR,4.);
DATETXT_PREV= catt(DAY,TEXT_MONTHNEW,NEWYEAR_TXT);*in text format;

*setup YM_DT for later use by merging with other data tables;
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
	if CMF_CD = 14 then CMF_TEXT =  'AIR DEFENSE';
	if CMF_CD = 15 then CMF_TEXT =  'AVIATION';
	if CMF_CD = 18 then CMF_TEXT = 'SPECIAL FORCES';
	if CMF_CD = 19 then CMF_TEXT = 'ARMOR';
	if CMF_CD = 21 then CMF_TEXT = 'ENGINEERS';
	if CMF_CD = 25 then CMF_TEXT = 'SIGNAL';
	if CMF_CD = 27 then CMF_TEXT = 'LEGAL';
	if CMF_CD = 29 then CMF_TEXT = 'ELEC_WAR';
	if CMF_CD = 31 then CMF_TEXT = 'MP';
	if CMF_CD = 33 then CMF_TEXT = 'INTEL';
	if CMF_CD = 35 then CMF_TEXT = 'INTEL';
	if CMF_CD = 36 then CMF_TEXT = 'FINANCE';
	if CMF_CD = 37 then CMF_TEXT = 'PSYCH OPS';
	if CMF_CD = 38 then CMF_TEXT = 'CIVIL AFFAIRS';
	if CMF_CD = 42 then CMF_TEXT = 'ADMIN';
	if CMF_CD = 44 then CMF_TEXT = 'FINANCE';
	if CMF_CD = 46 then CMF_TEXT = 'PUBLIC AFFAIRS';
	if CMF_CD = 51 then CMF_TEXT = 'ACQUISITION';
	if CMF_CD = 56 then CMF_TEXT = 'CHAPLAIN';
	if CMF_CD = 63 then CMF_TEXT = 'SUSTAINMENT';
	if CMF_CD = 68 then CMF_TEXT = 'MEDICAL CORPS';
	if CMF_CD = 71 then CMF_TEXT = 'ADMIN';
	if CMF_CD = 74 then CMF_TEXT = 'CHEMICAL';
	if CMF_CD = 79 then CMF_TEXT = 'RECRUIT_RETENT';
	if CMF_CD = 88 then CMF_TEXT = 'TRANSPORTATION';
	if CMF_CD = 89 then CMF_TEXT = 'EOD';
	if CMF_CD = 91 then CMF_TEXT = 'MEDICAL CORPS';
	if CMF_CD = 92 then CMF_TEXT = 'SUSTAINMENT';
	if CMF_CD = 94 then CMF_TEXT = 'SUSTAINMENT';
	if CMF_CD = 96 then CMF_TEXT = 'INTEL';
	if CMF_CD = 98 then CMF_TEXT = 'INTEL';
	if CMF_CD = . then CMF_TEXT = 'OTHER';
	if CMF_CD = ' ' then CMF_TEXT = 'OTHER';

	format YM_DT 6. GREGORIAN_DT date9.;

	DATE_INDEX = (round(YM_DT/100)-2000)*12 + (YM_DT -  round(YM_DT/100)*100);
	
	drop MONTHN TEXT_MONTH DATETXT DATETXT_PREV YM_DT2 YEARN DAY NEWYEAR YM_DT_NUMPRE_TXT STRINGYEAR NEWMONTH_TXT TEXT_MONTHNEW
		  NEWYEAR_TXT CMF_CD NEWMONTH;
run;
 
*Massive Inventory and Transactions merge for later calculations;
proc sql;
create table Zais.Zais_Inventory_Losses as select distinct
a.*, b.LOSS_TYPE_CD, b.TRANS_DT
from Zais.Zais_Inv_Condensed_Dates a, Zais.Zais_All_Trans_LIMR_LETS b
where a.YM_DT eq b.YM_DT
and a.EP_SSN eq b.EP_SSN
order by a.YM_DT, a.PMOS_CD;
quit;

data Zais.Zais_Inventory_Losses2;
set Zais.Zais_Inventory_Losses; 
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

*Add employment rate 12-month moving averages to final Eligibles file, keep SSN data for later merging;
	proc sql;
	create table Zais.ZAIS_MERGED_ELIGIBLES_MA
	as select DISTINCT a.*, b.*
	from Zais.Zais_Inventory_Losses2 a LEFT JOIN Army.FEDEMPLOY_200610_201203_NUM b
	on a.YM_DT eq b.YM_DT 
	order by a.YM_DT, PMOS_CD, CMF_TEXT;
	quit;

*Locate missing data, further cleaning of FILE after LOGIT model;
data Zais.Zais_PreRegression;
set Zais.ZAIS_MERGED_ELIGIBLES_MA;

if SINGLE = 1 then MARRIED = 0;
if DIVORCED = 1 then MARRIED = 0;

if AGE = .  then delete;  *remove this for Mark' analysis;
if AGE < 18 then delete;
AGE_CENTER = AGE - 20;
EDUCATION_CENTER = max(0,CIV_ED_QY - 12);
CAREER_FIELD = SUBSTR(CMF_TEXT,1,8);

EMPLOYMENT = FED_EMPL_RATE * 100;
drop EP_SSN FED_EMPL_RATE;
run;
/**/
/**Test for missing data, and remove rows with missing data, removed 3 files;*/
/*data work.Missing_Temp;*/
/*set Zais.Zais_PreRegression;*/
/**/
/*array nums _numeric_;*/
/*do over nums;*/
/*	if nums=. then output Zais.Missing_Temp;*/
/*end;*/
/**/
/*array mychar(*) $ _character_;*/
/*do i = 1 to dim(mychar);*/
/*	if mychar(i) = " " then output Zais.Missing_Temp;*/
/*end;*/
/*drop i;*/
/*run;*/

*Remove labels;
/*proc datasets lib=Zais noprint;*/
/*   modify SUPERFILE_REGRESSION ; /* modify data set test */*/
/*     attrib _all_ label=' '; /* will remove all labels */*/
/*     *attrib _all_ format=; /* will remove all formats */*/
/*run;*/
/**/
/*data Zais.SUPERFILE_REGRESSION_LIMITED;*/
/*set Zais.SUPERFILE_REGRESSION_BINARY;*/
/*/**/*/
/*/*if PMOS_CD eq '11B';*/*/
/*/*if PMOS_CD in ('11B' '68W' '63B' '31B' '88M' '19D' '92A' '21B' '92F' '13B');*/*/
/*/*MOS_11B=(PMOS_CD='11B');*/*/
/*/*MOS_68W=(PMOS_CD='68W');*/*/
/*/*MOS_63B=(PMOS_CD='63B');*/*/
/*/*MOS_31B=(PMOS_CD='31B');*/*/
/*/*MOS_88M=(PMOS_CD='88M');*/*/
/*/*MOS_19D=(PMOS_CD='19D');*/*/
/*/*MOS_92A=(PMOS_CD='92A');*/*/
/*/*MOS_21B=(PMOS_CD='21B');*/*/
/*/*MOS_92F=(PMOS_CD='92F');*/*/
/*/*MOS_13B=(PMOS_CD='13B');*/*/
/*/**/*/
/*OPTION_1=(OPTION=1);*/
/*OPTION_2=(OPTION=2);*/
/*OPTION_3=(OPTION=3);*/
/*OPTION_4=(OPTION=4);*/
/*OPTION_5=(OPTION=5);*/
/*run;*/
/**/
/*ods html close; */
/*ods preferences;*/
/*ods html newfile=proc; */
/*ods pdf file = 'D:\Retention Data\Dissertation_p1_2013\Logit_Regression_Output_20130923.pdf';*/
/*title "MAX &Window.-Month Window:  Only Infantry Soldiers with Reenlistment Option = 2";*/
/*proc logistic data = Zais.Superfile_Regression_Infantry descending covout outest=Zais.RegressionOutputTests;*/
/*  class MARRIED WHITE /param=ref ref=last; *categorical variables;*/
/*  model REUP = MAX_BONUS /*AOS*/ MARRIED WHITE MINOR_DEP_QY EDUCATION_CENTER AGE_CENTER EMPLOYMENT*/
/*			/selection=stepwise link =logit /*nocheck*/ details */
/*				sle = .3 sls = .1 maxstep =100 maxiter = 1000 gconv = 1E-8 corrb;*/
/*run;*/
/**/
/*proc report data = Zais.CorrOutp nowd*/
/*       style(report)={font_size=9pt cellpadding=2pt*/
/*                      cellspacing=.15pt}*/
/*       style(header)={font_size=9pt}*/
/*       style(column)={font_size=8pt};*/
/*run;*/
/*ods pdf close;*/
/**/
/**Correlation Matrix;*/
/*proc corr data = Zais.Superfile_Regression_Infantry  outp = Zais.CorrOutp;*/
/*	var REUP MAX_BONUS AOS OPTION DEPLOY MARRIED WHITE HISPANIC BLACK MINOR_DEP_QY EDUCATION_CENTER AGE_CENTER EMPLOYMENT TOE_UNIT */
/*		MOS_11B /*MOS_68W MOS_63B MOS_31B MOS_88M MOS_19D MOS_92A MOS_21B MOS_92F MOS_13B*/ OPTION_1 OPTION_2 OPTION_3 OPTION_4 OPTION_5;*/
/*run;*/
/**/
/*ods pdf file = 'D:\Retention Data\Dissertation_p1_2013\Correlation_Matrix_20130922'; */
/*proc report data = Zais.CorrOutp nowd*/
/*       style(report)={font_size=9pt cellpadding=2pt*/
/*                      cellspacing=.15pt}*/
/*       style(header)={font_size=9pt}*/
/*       style(column)={font_size=8pt};*/
/*run;*/
/*ods pdf close;*/
