libname aday "C:\SAS\AnalyticsDay";
dm 'output; clear; log; clear;';
options nodate nonumber;
title;

PROC IMPORT datafile="C:\Users\newei\Downloads\HPS_Week60_PUF_CSV\pulse2023_puf_60.csv"
dbms=csv
out=aday.censusdata
replace;
getnames=yes;
RUN;

proc summary data=aday.censusdata;
run;

proc logistic data=aday.censusdata descending order=data;
	*where down > 0;
	*where ms > 0;
	model down = eeduc ms sexual_orientation / link=clogit scale=none aggregate;
run;

*Examining Imputation;

*testing something;

proc contents data=censusdata;
run;

%let vars = ms sexual_orientation recvdvacc hadcovidrv test_yn wrklossrv anywork ui_applyrv ui_recvrv
		pricechng priceconcrn expns_dif twdays curfoodsuf freefood tspndfood tspndprpd nd_displace
		worry interest hlthins1 hlthins2 hlthins3 hlthins4 hlthins5 hlthins6 hlthins7 hlthins8
		seeing hearing mobility remembering selfcare understand tenure livqtrrv energy hse_temp
		enrgy_bill income enrollnone
	    kids_lt5y kids_5_11y kids_12_17y enrpubchk tenrollpub
		enrprvchk tenrollprv enrhmschk tenrollhmsch actvduty1 actvduty2 actvduty3 actvduty4 actvduty5
		whendoses kidvacwhen_lt5y kidvacwhen_5_11y kidvacwhen_12_17y whencovidrv1 whencovidrv2
		whencovidrv3 covidtrt_yndk symptoms longcovid symptmnow symptmimpct test_obtain1 test_obtain2
		test_obtain3 test_obtain4 test_obtain5 test_obtain6 testingplan1 testingplan2 testingplan3
		testingplan4 testingplan5 kindwork rsnnowrkrv rsnnowrk_why setting ui_recvnow pricestress
		pricecope1 pricecope2 pricecope3 pricecope4 pricecope5 pricecope6 pricecope7 pricecope8
		pricecope9 pricecope10 pricecope11 pricecope12 pricecope13 pricecope14 pricecope15 pricecope16
		pricecope17 pricecope18 pricecope19 twdays_resp spnd_srcrv1 spnd_srcrv2 spnd_srcrv3
		spnd_srcrv4 spnd_srcrv5 spnd_srcrv6 spnd_srcrv7 spnd_srcrv8 spnd_srcrv9 spnd_srcrv10
		spnd_srcrv11 childfood foodrsnrv1 foodrsnrv2 foodrsnrv3 foodrsnrv4 schlfdhlp_rv1 schlfdhlp_rv2
		schlfdhlp_rv3 schlfdhlp_rv4 schlfdhlp_rv5 schlfdhlp_rv6 schlfdhlp_rv7 schlfdhlp_rv8 fdbenefit1
		fdbenefit2 fdbenefit3 schlfdexpns frmla_yn frmla_age frmla_affct frmla_deal1 frmla_deal2
		frmla_deal3 frmla_deal4 frmla_deal5 frmla_deal6 frmla_deal7 frmla_deal8 frmla_deal9
		frmla_deal10 frmla_deal11 frmla_deal12 baby_fed frmla_diffclt frmla_amntrv frmla_typ1
		frmla_typ2 frmla_typ3 frmla_typ4 frmla_typ5 nd_type1 nd_type2 nd_type3 nd_type4 nd_type5
		nd_howlong nd_damage nd_fdshrtage nd_water nd_elctrc nd_unsanitary nd_crime nd_scam
		mhlth_need mhlth_get mhlth_satisfd mhlth_diffclt medicaid medicaid_no rentchng rentcur
		mortcur tmnthsbhnd movewhy1 movewhy2 movewhy3 movewhy4 movewhy5 movewhy6 movewhy7 movewhy8
		moved evict forclose gas1 gas2 gas3 gas4 privhlth pubhlth;

*attempt to make all numbers positive;
*before;
proc means data=censusdata;
var anxious;
run;

data wantedcensusdata;
set censusdata;
array t(*) &vars;
do i=1 to dim(t);
if index(t(i), '-')>0 then t(i)=abs(t(i));
else t(i) = t(i);
end;
run;

%IMPV3(DSN=work.wantedcensusdata, VARS = &vars, EXCLUDE=scram week region pweight hweight est_msa est_st abirth_year agenid_birth ahispanic arace 
		aeduc ahhld_numper ahhld_numkid tbirth_year rhispanic rrace eeduc egenid_birth genid_describe thhld_numper thhld_numkid thhld_numadult 
		anxious	down, 
		PCTREM = 0.85, MSTD = 4);

/*
remaining vars at each pctrem (subtract 14 from each number below, i made a mistake):
		0.2 - 97
		0.5 - 106
		0.6 - 111

		0.8 - 129
		0.85 - 143
		0.9 - 152
		1 - 234
*/

proc contents data=work.wantedcensusdataout order=varnum;
run;

proc means data=work.wantedcensusdataout;
var worry anxious;
run;

data aday.censusdata1;
set wantedcensusdataout;
drop i;
if anxious < 0 then delete;
if down < 0 then delete;
run;

*Running a model with backwards selection;

data censusdata1;
set aday.censusdata1;
run;

proc contents data=censusdata1;
run;

proc sort data=censusdata1 out=test1;
by down anxious;
run;

proc freq data=test1;
	tables down anxious;
run;

proc surveyselect data=test1 samprate=.67 out=moddevfile method=srs seed=061301 outall;
strata down anxious;
run;

proc freq data=moddevfile;
tables down*selected anxious*selected;
run;

data train valid;
set moddevfile;
if selected then output train;
else output valid;
run;

data aday.train;
set train;
data aday.valid;
set valid;
run;

proc contents data=aday.train;
run;

proc contents data=aday.censusdata;
run;

%let remvars =  ACTVDUTY1 AHHLD_NUMKID AHHLD_NUMPER ANYWORK COVIDTRT_YNDK CURFOODSUF EEDUC EGENID_BIRTH ENERGY ENRGY_BILL ENRPUBCHK EST_MSA EST_ST EXPNS_DIF WRKLOSSRV
				FDBENEFIT3 FOODRSNRV1 FREEFOOD FRMLA_DIFFCLT GAS1 GAS2 GAS4 GENID_DESCRIBE HADCOVIDRV HEARING HLTHINS1 HLTHINS2 HLTHINS3 HLTHINS4 HLTHINS5 HLTHINS6 HLTHINS7 HLTHINS8 HSE_TEMP HWEIGHT INCOME
				KIDS_12_17Y KIDS_5_11Y KIDVACWHEN_12_17Y KINDWORK LIVQTRRV LONGCOVID MEDICAID MHLTH_NEED MOBILITY MORTCUR MOVEWHY8 MS ND_DISPLACE ND_ISOLATE PRICECHNG PRICECONCRN PRICECOPE1 PRICECOPE2 PRICECOPE3
				PRICECOPE4 PRICECOPE5 PRICECOPE6 PRICECOPE7 PRICECOPE8 PRICECOPE9 PRICECOPE11 PRICECOPE12 PRICECOPE13 PRICESTRESS PRIVHLTH PUBHLTH PWEIGHT RECVDVACC REGION REMEMBERING RENTCHNG RENTCUR RHISPANIC
				RRACE RSNNOWRKRV SCHLFDEXPNS SCHLFDHLP_RV8 SEEING SELFCARE SETTING SEXUAL_ORIENTATION SPND_SRCRV1 SPND_SRCRV2 SPND_SRCRV3 SYMPTMNOW SYMPTOMS TENROLLPUB TENURE TESTINGPLAN1 TESTINGPLAN2 TESTINGPLAN3
				TESTINGPLAN4 TESTINGPLAN5 TEST_OBTAIN1 TEST_OBTAIN2 TEST_YN THHLD_NUMADLT THHLD_NUMKID THHLD_NUMPER TWDAYS TWDAYS_RESP UI_APPLYRV UI_RECVRV UNDERSTAND WEEK WHENCOVIDRV2 WHENCOVIDRV3 WHENDOSES;

*full model including potentially correlated variables interest and worry down below;
proc logistic data=aday.train descending order=data outest=betas outmodel=scoringdata;
model down = &remvars worry interest/selection=backward link=clogit scale=none aggregate
CTABLE pprob = (0.05 to 0.25 by .01)
LACKFIT RISKLIMITS;
output out = output p = predicted;
score data=aday.valid out=aday.scoreten;
run;

proc logistic data=aday.train descending order=data outest=betas2 outmodel=scoringdata2;
model anxious = &remvars worry interest/selection=backward link=clogit scale=none aggregate
CTABLE pprob = (0.05 to 0.25 by .01)
LACKFIT RISKLIMITS;
output out = output2 p = predicted2;
score data=aday.valid out=aday.scoreten;
run;

*full model without worry or interest;
proc logistic data=aday.train descending order=data outest=betas outmodel=scoringdata;
model down = &remvars/selection=backward link=clogit scale=none aggregate
CTABLE pprob = (0.05 to 0.25 by .01)
LACKFIT RISKLIMITS;
output out = output p = predicted;
score data=aday.valid out=aday.scoreten;
run;

proc logistic data=aday.train descending order=data outest=betas2 outmodel=scoringdata2;
model anxious = &remvars/selection=backward link=clogit scale=none aggregate
CTABLE pprob = (0.05 to 0.25 by .01)
LACKFIT RISKLIMITS;
output out = output2 p = predicted2;
score data=aday.valid out=aday.scoreten;
run;

*full model with worry included for down and interest included for anxious;
proc logistic data=aday.train descending order=data outest=betas outmodel=scoringdata;
model down = &remvars worry/selection=backward link=clogit scale=none aggregate
CTABLE pprob = (0.05 to 0.25 by .01)
LACKFIT RISKLIMITS;
output out = output p = predicted;
score data=aday.valid out=aday.scoreten;
run;

proc logistic data=aday.train descending order=data outest=betas2 outmodel=scoringdata2;
model anxious = &remvars interest/selection=backward link=clogit scale=none aggregate
CTABLE pprob = (0.05 to 0.25 by .01)
LACKFIT RISKLIMITS;
output out = output2 p = predicted2;
score data=aday.valid out=aday.scoreten;
run;

*vifs;
%let downvars = remembering ms expns_dif pricestress selfcare hlthins3 curfoodsuf sexual_orientation priceconcrn seeing;
%let anxvars = remembering expns_dif pricestress ms hlthins3 eeduc rrace selfcare curfoodsuf sexual_orientation;

proc reg data=aday.train;
	model down = &downvars / vif;
run;

proc reg data=aday.train;
	model anxious = &anxvars / vif;
run;

*reduced model down below - worry and interest not included;
proc logistic data=aday.train descending order=data outest=betas outmodel=scoringdata;
model down = &downvars/selection=backward link=clogit scale=none aggregate
CTABLE pprob = (0.05 to 0.25 by .01)
LACKFIT RISKLIMITS;
output out = output p = predicted;
score data=aday.valid out=aday.scoreten;
run;

proc logistic data=aday.train descending order=data outest=betas2 outmodel=scoringdata2;
model anxious = &anxvars/selection=backward link=clogit scale=none aggregate
CTABLE pprob = (0.05 to 0.25 by .01)
LACKFIT RISKLIMITS;
output out = output2 p = predicted2;
score data=aday.valid out=aday.scoreten;
run;

*Comparing to week 52 data;
PROC IMPORT datafile="C:\Users\newei\Downloads\HPS_Week52_PUF_CSV\pulse2022_puf_52.csv"
dbms=csv
out=aday.censusdata52
replace;
getnames=yes;
RUN;

proc contents data=aday.censusdata52;
run;

%let allvars52 = 	abirth_year actvduty1 actvduty2 actvduty3 actvduty4 actvduty5 aeduc agenid_birth
					ahhld_numkid ahhld_numper ahispanic anxious anywork arace ccarepay ccaretyp1 
					ccaretyp2 ccaretyp3 ccaretyp4 ccaretyp5 ccaretyp6 ccaretyp7 ccaretyp8 childfood
					curfoodsuf down eeduc egenid_birth energy enrgy_bill enrhmschk enrollnone enrprvchk
					enrpubchk est_msa est_st evict expns_dif fdbenefit1 fdbenefit2 foodrsnrv1 foodrsnrv2
					foodrsnrv3 foodrsnrv4 forclose freefood frmla_affct frmla_age frmla_amntrv frmla_deal1
					frmla_deal2 frmla_deal3 frmla_deal4 frmla_deal5 frmla_deal6 frmla_deal7 frmla_deal8
					frmla_deal9 frmla_deal10 frmla_deal11 frmla_deal12 frmla_diffclt frmla_typ1 frmla_typ2
					frmla_typ3 frmla_typ4 frmla_typ5 frmla_yn gas1 gas2 gas3 gas4 genid_describe
					hadcovidrv hearing hlthins1 hlthins2 hlthins3 hlthins4 hlthins5 hlthins6 hlthins7
					hlthins8 hse_temp hweight income interest kidbhvr1 kidbhvr2 kidbhvr3 kidbhvr4 kidbhvr5
					kidbhvr6 kidbhvr7 kidbhvr8 kidbhvr9 kidgetvac_12_17y kidgetvac_5_11y kidgetvac_lt5y
					kids_12_17y kids_5_11y kids_lt5y kidvacwhen_12_17y kidvacwhen_5_11y kidvacwhen_lt5y
					kidwhynorv1 kidwhynorv2 kidwhynorv3 kidwhynorv4 kidwhynorv5 kidwhynorv6 kidwhynorv7
					kidwhynorv8 kidwhynorv9 kidwhynorv10 kindwork livqtrrv longcovid medicaid medicaid_no
					mobility mortcur ms nd_crime nd_damage nd_displace nd_elctrc nd_fdshrtage nd_howlong
					nd_isolate nd_scam nd_type1 nd_type2 nd_type3 nd_type4 nd_type5 nd_unsanitary nd_water
					pricechng priceconcrn pricecope1 pricecope2 pricecope3 pricecope4 pricecope5
					pricecope6 pricecope7 pricecope8 pricecope9 pricecope10 pricecope11 pricecope12
					pricecope13 pricecope14 pricecope15 pricecope16 pricecope17 pricecope18 pricecope19
					pricestress privhlth pubhlth pweight rcveduc1 rcveduc2 rcveduc3 rcveduc4 rcveduc5
					rcveduc6 rcveduc7 rcveduc8 rcveduc9 recvdvacc region remembering rentassist rentchng
					rentcur rhispanic rrace rsnnowrkrv rsnnowrk_why schlfdexpns schlfdhlp_rv1
					schlfdhlp_rv2 schlfdhlp_rv3 schlfdhlp_rv4 schlfdhlp_rv5 schlfdhlp_rv6 schlfdhlp_rv7
					schlfdhlp_rv8 seeing selfcare setting sexual_orientation spnd_srcrv1 spnd_srcrv2
					spnd_srcrv3 spnd_srcrv4 spnd_srcrv5 spnd_srcrv6 spnd_srcrv7 spnd_srcrv8 spnd_srcrv9
					spnd_srcrv10 spnd_srcrv11 symptmimpct symptmnow symptoms tbirth_year tccarecost
					tenrollhmsch tenrollprv tenrollpub tenure thhld_numadlt thhld_numkid thhld_numper
					tmnthsbhnd trentamt tspndfood tspndprpd twdays twdays_resp ui_applyrv ui_recvnow
					ui_recvrv understand week whencovid whendoses whynobstrrv1 whynobstrrv2 whynobstrrv3
					whynobstrrv4 whynobstrrv5 whynobstrrv6 whynobstrrv7 whynobstrrv8 whynobstrrv9 worry
					wrklossrv;

data censusdata52;
set aday.censusdata52;
run;

proc means data=censusdata52;
var anxious;
run;

data wantedcensusdata52;
set censusdata52;
array t(*) &allvars52;
do i=1 to dim(t);
if index(t(i), '-')>0 then t(i)=abs(t(i));
else t(i) = t(i);
end;
run;

proc contents data=wantedcensusdata52;
run;

%IMPV3(DSN=work.wantedcensusdata52, VARS = &allvars52, EXCLUDE=scram week region pweight hweight est_msa est_st abirth_year agenid_birth ahispanic arace 
		aeduc ahhld_numper ahhld_numkid tbirth_year rhispanic rrace eeduc egenid_birth genid_describe thhld_numper thhld_numkid thhld_numadult 
		anxious	down, 
		PCTREM = 0.85, MSTD = 4);

proc contents data=work.wantedcensusdata52out order=varnum;
run;

data aday.censusdata52;
set wantedcensusdata52out;
drop i;
if anxious < 0 then delete;
if down < 0 then delete;
run;

*Running a model with backwards selection;

data censusdata52;
set aday.censusdata52;
run;

proc sort data=censusdata52 out=test1;
by down anxious;
run;

proc surveyselect data=test1 samprate=.67 out=moddevfile52 method=srs seed=061301 outall;
strata down anxious;
run;

data train52 valid52;
set moddevfile52;
if selected then output train52;
else output valid52;
run;

data aday.train52;
set train52;
data aday.valid52;
set valid52;
run;

proc contents data=censusdata52;
run;

%let downvars = remembering ms expns_dif pricestress selfcare hlthins3 curfoodsuf sexual_orientation priceconcrn seeing;
%let anxvars = remembering expns_dif pricestress ms hlthins3 eeduc rrace selfcare curfoodsuf sexual_orientation;

proc reg data=aday.train52;
	model down = &downvars / vif;
run;

proc reg data=aday.train52;
	model anxious = &anxvars / vif;
run;

*reduced model down below - worry and interest not included;
proc logistic data=aday.train52 descending order=data outest=betas outmodel=scoringdata;
model down = &downvars/selection=backward link=clogit scale=none aggregate
CTABLE pprob = (0.05 to 0.25 by .01)
LACKFIT RISKLIMITS;
output out = output p = predicted;
score data=aday.valid52 out=aday.scoreten52;
run;

proc logistic data=aday.train52 descending order=data outest=betas2 outmodel=scoringdata2;
model anxious = &anxvars/selection=backward link=clogit scale=none aggregate
CTABLE pprob = (0.05 to 0.25 by .01)
LACKFIT RISKLIMITS;
output out = output2 p = predicted2;
score data=aday.valid52 out=aday.scoreten52;
run;
