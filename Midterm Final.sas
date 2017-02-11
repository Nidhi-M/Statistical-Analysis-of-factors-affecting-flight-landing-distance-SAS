PROC IMPORT
DATAFILE = '/Path to the file/FAA1.xls'
DBMS = xls
OUT =FlightDetailsB; /* Flight details belonging to sheet 1*/

PROC IMPORT
DATAFILE = 'Path to the file/FAA2.xls'
DBMS = xls
OUT =FlightDetailsA; /* Flight details belonging to sheet 2*/

options missing=' ';
DATA FlightDetails;
Set FlightDetailsB FlightDetailsA;
IF missing(cats(of _all_)) THEN delete; /* removing empty rows*/
PROC print Data=FlightDetails;
RUN;

PROC MEANS DATA=FLightDetails NMISS N; /* finding the number of missing values for each variable*/
RUN;

PROC UNIVARIATE DATA=flightdetails;
RUN;

/*validating the data for abnormality in values  */
option missing ='.';
DATA FlightDetailsValidated;
SET FlightDetails;
IF    (Duration ^=.)and Duration < 40 then validity = 'abnormal' ; Else validity = 'normal';
IF (validity = 'normal') and (Speed_ground < 30 OR Speed_ground > 140) then validity = 'abnormal' ;
IF  (validity = 'normal') and (speed_air ^=.) and (Speed_air <30 OR Speed_air > 140) then validity = 'abnormal' ;
IF  (validity = 'normal') and Height< 6 then validity = 'abnormal' ;
IF  (validity = 'normal') and Distance >= 6000 then validity = 'abnormal' ;
Proc print data=flightdetailsvalidated;
run;
proc freq data=flightdetailsvalidated;
tables validity;
run;

/* check for duplication of observation */
PROC SORT DATA=FlightDetailsValidated
OUT = FlightDetailsRemovedDuplication
NODUPKEY ;
BY Speed_ground Speed_air height Distance;
run;
 
PROC FREQ DATA=FlightDetailsRemovedDuplication;
TABLES VALIDITY;
RUN;

/* finding the number of missing values for each variable*/
PROC MEANS DATA=FlightDetailsRemovedDuplication NMISS N; 
RUN;

PROC MEANS DATA=FlightDetailsRemovedDuplication  MEAN MEDIAN MIN MAX;

PROC UNIVARIATE DATA=FlightDetailsRemovedDuplication PLOT;

/* keeping only that data which is normal for further analysis */
DATA FlightDetailsNormal;
SET FlightDetailsRemovedDuplication (where=(validity='normal'));
drop validity;
PROC PRINT DATA=FlightDetailsNormal;
RUN;

/* converting the non-numeric make column to binary */
DATA FlightDetailsNormal1;
set FlightDetailsNormal;
IF aircraft = "boeing" THEN make = 0;
else make = 1;
PROC PRINT DATA=FlightDetailsNormal1;
RUN;

/* using scatter plot to get the relation between variables */
PROC SGSCATTER DATA=FlightDetailsNormal;
MATRIX distance make speed_air speed_ground height pitch duration no_pasg;
RUN;
/* Box plot for seeinng the difference in distance w.r.t to make*/
PROC SORT DATA=flightdetailsnormal;
BY AIRCRAFT;
run;
PROC BOXPLOT DATA=FlightDetailsNormal;
PLOT DISTANCE*AIRCRAFT/
      nohlabel
      boxstyle      = schematic
      boxwidthscale = 1
      bwslegend;
run;

/* finding the correlation between variables */
PROC CORR DATA=flightdetailsnormal;
VAR distance make duration no_pasg speed_ground speed_air height pitch;
RUN;

/* creating a regression analysis for the variables that seemed to be correrated with distance */


PROC REG DATA=flightdetailsnormal;
MODEL distance = make height speed_air speed_ground /r ;
output out=diagnostics r=residual;
run;

PROC REG DATA=flightdetailsnormal;
MODEL distance = make height speed_air speed_ground /r;
output out=diagnostics r=residual;
run;

/* creating a regression model uas an alternative to better fit the distance*/

DATA FlightDetailsNormal;
set FlightDetailsNormal;
speed_air_sq = speed_air**2;
speed_air_log = log(speed_air);
PROC PRINT DATA=FlightDetailsNormal;
RUN;

PROC REG DATA=flightdetailsnormal;
MODEL distance = make height speed_air_sq /r ;
output out=diagnostics r=residual;
run;

PROC REG DATA=flightdetailsnormal;
MODEL distance = make height speed_air_log /r ;
output out=diagnostics r=residual;
run;


/* checking the normality of the residuals */
proc univariate data=diagnostics normal;
var residual;
run;

/* counting the number of observations in the data set */
proc sql ;
   select count(*) into : nobs
   from WORK.FlightDetailsNormal;

   /* plotting variables to find the relationship between the variables */

PROC PLOT DATA=FlightDetailsNormal;
PLOT DISTANCE*duration='*';
PLOT DISTANCE*no_pasg='#';
PLOT DISTANCE*speed_ground='^';
PLOT DISTANCE*speed_air='@';
PLOT DISTANCE*height='^';
PLOT DISTANCE*pitch='^';
RUN;

/* checking the variation of distance with make of aircraft */
PROC CHART DATA=flightdetailsnormal;
VBAR distance / subgroup=aircraft;
run;

