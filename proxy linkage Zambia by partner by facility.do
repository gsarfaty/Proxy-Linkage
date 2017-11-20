**Zam target analysis**

	global data "C:\Users\gsarfaty\Documents\Zambia POC\Q3\SiteXIMAug15"

	cd "$data"

	import delimited "ICPI_FactView_Site_IM_Zambia_20170815_v1_1.txt", clear

	save "ICPI_FactView_Site_IM_Zambia_20170815_v1_1.dta", replace

		u "ICPI_FactView_Site_IM_Zambia_20170815_v1_1.dta", clear



** WRANGLING **
	
	*keep only relevant indicators for analysis
		keep if ///
			inlist(indicator, "HTS_TST_POS", "TX_NEW") & disaggregate=="Total Numerator"
	drop if primepartner=="Dedup"
	drop if typecommunity=="Y"
	drop if psnu == "_Military Zambia"

			
	*create cumulative variable to sum up necessary variables
		egen fy2017cum = rowtotal(fy2017q*)
			replace fy2017cum = . if fy2017cum==0
		*adjust "snapshot" indicators since they are already cumulative
		replace fy2017cum =. if fy2017cum==0 //should be missing, but 0 due to egen

	*remove rows with no data (ie keep rows that contain FY16/17 data)
		egen kp = rowtotal(fy2*)
			drop if kp==0
			drop kp
			
	*aggregate so there is only one obvervation per mechanism
		collapse (sum) fy2*, by(operatingunit primepartner fundingagency ///
			mechanismid implementingmechanismname psnu facility indicator)

			

		

** Linkage **
		
	*linkage = TX_NEW/HTS_TST_POS

	*reshape long to allow dataset to become a timeseries & transform time variable to date format
		egen id = group(operatingunit primepartner fundingagency mechanismid ///
			implementingmechanismname psnu facility indicator)
		reshape long fy, i(id) j(qtr, string)
		drop id
		
	*recode 0s to missing
		recode fy (0 = .)
		
	*reshape for calculation
		reshape wide fy, i(qtr operatingunit primepartner fundingagency mechanismid implementingmechanismname psnu facility) j(indicator, string)
	
	*calc linkage
		gen fyLINKAGE =(fyTX_NEW/fyHTS_TST_POS *100)
	
	*remove rows with no data (ie keep rows that contain FY16/17 data)
		egen kp = rowtotal(fyHTS_TST_POS fyTX_NEW)
			drop if kp==0
			drop kp

	* replace
	replace qtr="fy"+qtr

	drop operatingunit
	
	export excel "Zambia_Proxy_Linkage by Partner by Facility.xlsx", firstrow(variables) replace
