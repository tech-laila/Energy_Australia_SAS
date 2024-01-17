/*
DP SAS Assignment 1 2023
Question 3: Australian Electricity Transitions 1900 to 2050: 
What will it take for Australia to transition to a net-zero electricity system by 2050?

Name:Laila Lima Alves
Student ID: 14344509


Complete the missing code between the numbered comments.
Save and submit the completed SAS file.

[3.1] Define an empty library GENCAP to save the imported time series data 
*/

libname GENCAP "/home/u60923758/A2023/A1";

/* 
[3.2] Import the Generation table from GenCapData1900-2050.xlsx
Put it into GENCAP.gen_all_raw
Data for Australia overall is in range 'Generation'$B3:K
Column names have spaces in them, make sure SAS fixes that during import
According to the data dictionary all figures are in gigawatt-hours (GWh)
*/

*make sure the names are aceptable;
options validvarname= v7;


proc import datafile="/home/u60923758/A2023/A1/GenCapData1900-2050.xlsx"
dbms = xlsx
out = GENCAP.gen_all_raw
replace;
GETNAMES=YES;
range= "Generation$B3:K";
run;


/* 
[3.3] Check that we imported data for 151 years and it's all numeric */


Title1 "[3.3] Check that we imported data for 151 years and it's all numeric";
Title2 "The Number of Observations on the first table confirms 151 inputs";
proc contents data=GENCAP.gen_all_raw;
run;



/* 
[3.4] 
Add these variables to the dataset:
* non_renewable		: Total generation from coal, natural gas, and oil sources
* renewable			: Total generation from hydro, biomass, wind, and solar sources
* total				: Total from all 9 sources
* renewable_ratio	: Percentage of total generation that's renewable
* renewable_diff	: Difference between non-renewable and renewable generation

Rename variable B to Year

Save transformed dataset as GENCAP.gen_all
*/


data GENCAP.gen_all;
set GENCAP.gen_all_raw;
Format non_renewable best8.0 
renewable best8.0 
total best8.0 
renewable_diff best8.0
renewable_ratio PERCENT8.2;
non_renewable = Black_coal+Brown_coal+Natural_gas+Oil_products;	
renewable =	Hydro+Biomass+Wind+Large_scale_solar_PV	+Rooftop_solar_PV;
total = non_renewable + renewable;
renewable_ratio = renewable/total;
renewable_diff= non_renewable - renewable; 
rename B = Year;
run;



/* 
[3.5] Print the first row from GENCAP.gen_all
in which non renewable energy generation is less than renewable energy generation
Show that the year is 2027 and the forecast renewable generation is approx 157TWh
*/


Title "[3.5] Print the first row from GENCAP.gen_all where year is 2027 and the forecast renewable generation is approx 157TWh";
proc print data=gencap.gen_all;
Format non_renewable comma8.0 renewable comma8.0 total comma8.0 renewable_diff comma8.0;
where Year = 2027;
var Year non_renewable renewable total renewable_diff;
run;



/* 
There are no more assignment questions below this point.
The following code is a macro to do the same thing as the previous code
so maybe there's something in it you could use?
*/




/* turn the code into a macro so we can reuse it for each state */

%macro import_sheet(region, startcol, endcol);
	/* 
	Import and analyse power generation data for one region
	
	Imports the columns between startcol and endcol
	from row 3 to the last row of the sheet
	from GenCapData1900-2050.xlsx
	into a dataset in GENCAP named after the region
	
	Adds columns for renewable, non-renewable, and total generation
	Calculates % renewable and renewable shortfall (non-renewable - renewable)
	
	Params:
	- region: name of state or territory, used to name the output dataset
	- startcol: starting column of the data range, in Excel format (e.g. B for col 2, AD for col 30)
	- endcol: ending column of the data range, inclusive, in Excel format
	
	Outputs:
	- new dataset in GENCAP.gen_[region]
	- results table for year when [region] will reach 50% renewable generation
	- results table for renewable generation shortfall in 2023
	
	*/
	
	/* put a message in the SAS log to keep track of what's happening */
	%put Importing generation data for &region. (columns &startcol. - &endcol.);

	/* make sure we zap any spaces in column names */
	options validvarname=v7;

	/*
	Import the columns between startcol and endcol 
	starting at row 3
	into a table named after the region
	*/
	proc import  
		datafile="~/my_shared_file_links/u58011001/DP using SAS/A1/GenCapData1900-2050.xlsx" 
		dbms=xlsx
		out=GENCAP.gen_&region.
		replace
		;
		
		range="'Generation'$&startcol.3:&endcol.";
		* this will turn into: range="'Generation'$B3:K" etc;
	run;
	
	/* Process imported raw data */
	data GENCAP.gen_&region.;
		set GENCAP.gen_&region.;
		
		* add the region name to each row;
		length Region $ 9;
		Region = "&region.";
		
		* column name for Year is missing on the spreadsheet, fix it up here;
		rename &startcol. = year;
		
		* calculate the stuff Chris wants;
		non_renewable = sum(black_coal, brown_coal, natural_gas, oil_products);
		renewable = sum(hydro, biomass, wind, large_scale_solar_pv, rooftop_solar_pv);
		total = sum(non_renewable, renewable);
		renewable_diff = sum(non_renewable, -1 * renewable);
		renewable_ratio = divide(renewable, total);
		
		* label and format;
		label 
			&startcol.="Year" non_renewable="Non-renewable" renewable="Renewable" total="Total" 
			renewable_diff="Renewable shortfall" renewable_ratio="Renewable %";
		format renewable_ratio percent.;
		format non_renewable renewable total renewable_diff comma12.0;

	run;
	
	* print the first obs where renewable >= non_renewable;
	
	title "Renewable energy generation (&region., GWh)";
	title2 "Year when &region. will reach 50% renewable generation";
	proc print data=GENCAP.gen_&region.(obs=1) noobs label;
		var region year renewable_ratio non_renewable renewable;
		where renewable >= non_renewable;
	run;
	
	* print renewables ratio and difference for 2023;
	
	title2 "Renewable generation shortfall in 2023";
	proc print data=GENCAP.gen_&region.(obs=1) noobs label;
		var region year renewable_ratio renewable_diff;
		where year = 2023;
	run;
	
%mend;


/* run the macro 8 times to import Australia and the 7 states/territories */
%import_sheet(Australia, 	B,  	K);
%import_sheet(NSW, 			M,  	V);
%import_sheet(VIC, 			X,  	AG);
%import_sheet(QLD, 			AI, 	AR);
%import_sheet(SA,  			AT, 	BC);
%import_sheet(WA,  			BE, 	BN);
%import_sheet(Tas, 			BP, 	BY);
%import_sheet(NT,  			CA, 	CJ);

/* ends */
