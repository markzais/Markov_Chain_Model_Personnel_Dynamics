/*
  Derived from Zais_Data_20131105.sas (the inventory-condense PROC SQL, orig
  lines 14-22, plus the SSN->numeric DATA step, orig lines 24-32). The SQL
  projects a distinct column subset from the source inventory, filters on
  YM_DT, and orders on the full key; the DATA step then drops rows whose SSN
  isn't all digits (verify), recodes low pay grades, and converts the SSN to
  numeric. In the original the source is the Army.Master_Inv_200610_200909
  libname table on a D:\ drive; here a small inline stand-in of the projected
  columns feeds the query so the logic runs unmodified.
*/
data Master_Inv_200610_200909;
  infile datalines dsd truncover;
  input YM_DT EP_SSN :$9. MSV_QY DEPL_DT :date9. SEX_CATEGORY_CD :$1.
        SVC_TERM_CD :$1. MARST_CD :$1. MINOR_DEP_QY PAY_GRADE_ID
        AFQT_PCNT_QY TIG_QY CAREER_STAT :$1. REENL_QY PMOS_CD :$3. CMF_CD
        CIV_ED_QY BIRTH_DT :date9.;
  format DEPL_DT BIRTH_DT date9.;
  datalines;
200610,100000001,96,01JAN2006,M,I,M,2,1,72,40,Y,1,11B,11,14,20JUN1985
200611,100000002,48,,F,I,S,0,4,65,18,N,0,68W,68,12,10FEB1988
200612,10000000X,60,,M,I,M,1,2,55,24,Y,1,13B,13,16,05DEC1979
200701,100000004,36,01JAN2007,M,I,M,3,3,80,12,Y,1,19D,19,12,30SEP1990
200610,100000001,96,01JAN2006,M,I,M,2,1,72,40,Y,1,11B,11,14,20JUN1985
;
run;

*Reduce the number of columns for our analysis;
proc sql;
create table Zais_Inv_Condensed as
	select distinct YM_DT, EP_SSN, MSV_QY, DEPL_DT, SEX_CATEGORY_CD, SVC_TERM_CD, MARST_CD, MINOR_DEP_QY, PAY_GRADE_ID, AFQT_PCNT_QY, TIG_QY, CAREER_STAT, REENL_QY,
					PMOS_CD, CMF_CD, CIV_ED_QY, BIRTH_DT
	from Master_Inv_200610_200909
	where YM_DT >= 0
	order by YM_DT, EP_SSN, MSV_QY, TIG_QY, CAREER_STAT, REENL_QY, DEPL_DT, SEX_CATEGORY_CD, SVC_TERM_CD, MARST_CD, MINOR_DEP_QY, PAY_GRADE_ID, AFQT_PCNT_QY, PMOS_CD,
			BIRTH_DT, CMF_CD;
quit;

data Zais_Inv_Condensed2 (rename = (SSN=EP_SSN)); *converted SSN to numeric;
set Zais_Inv_Condensed;
if verify(EP_SSN,'0123456789') gt 0 then delete;* then put "Invalid value of SSN:" EP_SSN;

if PAY_GRADE_ID in (1 2 3) THEN PAY_GRADE_ID = 4;
SSN = EP_SSN*1;
drop EP_SSN;
run;

proc print data = Zais_Inv_Condensed2;
  var YM_DT EP_SSN MSV_QY PAY_GRADE_ID PMOS_CD CMF_CD;
  title "Condensed inventory: distinct projection, SSN->numeric, pay-grade recode";
run;
