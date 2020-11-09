* Project: WB COVID
* Created on: July 2020
* Created by: jdm
* Edited by: jdm
* Last edited: 16 September 2020 
* Stata v.16.1

* does
	* cleans Nigeria panel

* assumes
	* raw Nigeria data

* TO DO:
	* need to revist access variables in round 2


* **********************************************************************
* 0 - setup
* **********************************************************************

* define list of waves
	global 			waves "1" "2" "3"
	
* define 
	global	root	=	"$data/nigeria/raw"
	global	export	=	"$data/nigeria/refined"
	global	logout	=	"$data/nigeria/logs"

* Define root folder globals
    if `"`c(username)'"' == "jdmichler" {
        global 		code  	"C:/Users/jdmichler/git/wb_covid"
		global 		data	"G:/My Drive/wb_covid/data"
    }

    if `"`c(username)'"' == "aljosephson" {
        global 		code  	"C:/Users/aljosephson/git/wb_covid"
		global 		data	"G:/My Drive/wb_covid/data"
    }

	if `"`c(username)'"' == "annfu" {
		global 		code  	"C:/Users/annfu/git/wb_covid"
		global 		data	"G:/My Drive/wb_covid/data"
	}
	
* open log
	cap log 		close
	log using		"$logout/nga_build", append

	
* **********************************************************************
* 1 - run do files for each round & generate variable comparison excel
* **********************************************************************

* run do files for all rounds and create crosswalk of variables by wave
	foreach 		r in "$waves" {
		do 			"$code/nigeria/nga_build_0`r'"
		ds
		clear
		set 		obs 1
		gen 		variables = ""
		local 		counter = 1
		foreach 	var in `r(varlist)' {
			replace variables = "`var'" in `counter'
			local 	counter = `counter' + 1
			set 	obs `counter'
			recast str30 variables
		}
		gen 		wave`r' = 1
		tempfile 	t`r'
		save 		`t`r''
	}
	use 			`t1',clear
	foreach 		r in "$waves" {
		merge 		1:1 variables using `t`r'', nogen
	}
	drop 			if variables == ""
	export 			excel using "$export/nga_variable_crosswalk.xlsx", first(var) replace
	

* ***********************************************************************
* 2 - create panel 
* ***********************************************************************

* append round datasets to build master panel
	foreach 		r in "$waves" {
	    if 			`r' == 1 {
			use		"$export/wave_01/r1", clear
		}
		else {
			append 	using "$export/wave_0`r'/r`r'"
		}
	}

* adjust household id
	recast 			long hhid
	format 			%12.0g hhid
	
* merge in baseline data 
	merge m:1		hhid using "$root/wave_00/Nigeria GHS-Panel 2018-19 Quintiles", nogenerate

* rename quintile variable
	rename 			quintile quints
	lab var			quints "Quintiles based on the national population"
	lab def			lbqui 1 "Quintile 1" 2 "Quintile 2" 3 "Quintile 3" ///
						4 "Quintile 4" 5 "Quintile 5"
	lab val			quints lbqui	
	

* ***********************************************************************
* 3 - clean nigeria panel
* ***********************************************************************	
	
* rationalize variables across waves
	gen				phw = wt_baseline if wt_baseline != . & wave == 1
	replace			phw = wt_round2 if wt_round2 != . & wave == 2
	replace			phw = wt_round3 if wt_round3 != . & wave == 3
	lab var			phw "sampling weights"
	order			phw, after(wt_baseline)
	drop			wt_baseline wt_round2 wt_round3 weight	
	
* administrative variables 	
	rename			sector urb_rural 
	gen				sector = 2 if urb_rural == 1
	replace			sector = 1 if urb_rural == 2
	lab var			sector "Sector"
	lab def			nga_sec 1 "Rural" 2 "Urban"
	lab val			sector nga_sec
	drop			urb_rural
	order			sector, after(phw)	

* covid variables
 * know
	rename 			s3q1  know
	rename			s3q2__1 know_1
	lab var			know_1 "Handwashing with Soap Reduces Risk of Coronavirus Contraction"
	rename			s3q2__2 know_9
	lab var			know_9 "Use of Sanitizer Reduces Risk of Coronavirus Contraction" 
	rename			s3q2__3 know_2
	lab var			know_2 "Avoiding Handshakes/Physical Greetings Reduces Risk of Coronavirus Contract"
	rename 			s3q2__4 know_3 
	lab var			know_3 "Using Masks and/or Gloves Reduces Risk of Coronavirus Contraction"
	rename			s3q2__5 know_10
	lab var			know_10 "Using Gloves Reduces Risk of Coronavirus Contraction"
	rename			s3q2__6 know_4
	lab var			know_4 "Avoiding Travel Reduces Risk of Coronavirus Contraction"
	rename			s3q2__7 know_5
	lab var			know_5 "Staying at Home Reduces Risk of Coronavirus Contraction"
	rename			s3q2__8 know_6
	lab var			know_6 "Avoiding Crowds and Gatherings Reduces Risk of Coronavirus Contraction"
	rename			s3q2__9 know_7
	lab var			know_7 "Mainting Social Distance of at least 1 Meter Reduces Risk of Coronavirus Contraction"
	rename			s3q2__10 know_8
	lab var			know_8 "Avoiding Face Touching Reduces Risk of Coronavirus Contraction" 
	
 * gov
	rename 			s3q3__1 gov_1
	label var 		gov_1 "government taken steps to advise citizens to stay home"
	rename 			s3q3__2 gov_10
	label var 		gov_10 "government taken steps to advise to avoid social gatherings"
	rename 			s3q3__3 gov_2
	label var 		gov_2 "government restricted travel within country"
	rename 			s3q3__4 gov_3
	label var 		gov_3 "government restricted international travel"
	rename 			s3q3__5 gov_4
	label var 		gov_4 "government closure of schools and universities"
	rename 			s3q3__6 gov_5
	label var		gov_5 "government institute government / lockdown"
	rename 			s3q3__7 gov_6
	label var 		gov_6 "government closure of non-essential businesses"
	rename 			s3q3__8 gov_11
	label var 		gov_11 "government steps of sensitization / public awareness"
	rename			s3q3__9 gov_14
	label var		gov_14 "government establish isolation centers"
	rename 			s3q3__10 gov_15
	label var 		gov_15 "government disinfect public spaces"
	rename 			s3q3__96 gov_16
	label var		gov_16 "government take other steps"
	rename 			s3q3__11 gov_none 
	label var 		gov_none "government has taken no steps"
	rename 			s3q3__98 gov_dnk
	label var 		gov_dnk "do not know steps government has taken"
	
* satisfaction + government perspectives 
	rename 			s3q4 satis 
	rename 			s3q5__1 satis_1
	rename			s3q5__2 satis_2 
	rename 			s3q5__3 satis_3
	rename 			s3q5__4 satis_4 
	rename 			s3q5__5 satis_5 
	rename 			s3q5__6 satisf_6 
	rename 			s3q5__96 satis_7 
	
* behavior
	rename			s4q1 bh_1
	rename			s4q2 bh_2
	rename 			s4q3 bh_3
	rename			s4q4 bh_4

* access variables
	rename 			s5q1a2 ac_soap_need
	rename 			s5q1b2 ac_soap 
	generate		ac_soap_why = . 
	replace			ac_soap_why = 1 if s5q1c2__1 == 1 
	replace 		ac_soap_why = 2 if s5q1c2__2 == 1
	replace 		ac_soap_why = 3 if s5q1c2__3 == 1
	replace 		ac_soap_why = 4 if s5q1c2__4 == 1
	replace 		ac_soap_why = 5 if s5q1c2__5 == 1
	replace 		ac_soap_why = 6 if s5q1c2__6 == 1
	lab def			ac_soap_why 1 "shops out" 2 "markets closed" 3 "no transportation" /// 
								4 "restrictions to go out" 5 "increase in price" 6 "no money"
	label var 		ac_soap_why "reason for unable to purchase soap"
								
	rename 			s5q1a3 ac_clean_need 
	rename 			s5q1b3 ac_clean
	gen 			ac_clean_why = . 
	replace			ac_clean_why = 1 if s5q1c3__1 == 1 
	replace 		ac_clean_why = 2 if s5q1c3__2 == 1
	replace 		ac_clean_why = 3 if s5q1c3__3 == 1
	replace 		ac_clean_why = 4 if s5q1c3__4 == 1
	replace 		ac_clean_why = 5 if s5q1c3__5 == 1
	replace 		ac_clean_why = 6 if s5q1c3__6 == 1
	lab def			ac_clean_why 1 "shops out" 2 "markets closed" 3 "no transportation" /// 
								4 "restrictions to go out" 5 "increase in price" 6 "no money"
	label var 		ac_clean_why "reason for unable to purchase cleaning supplies" 			

	rename 			s5q1a4 ac_rice_need
	rename 			s5q1b4 ac_rice
	gen 			ac_rice_why = . 
	replace			ac_rice_why = 1 if s5q1c4__1 == 1 
	replace 		ac_rice_why = 2 if s5q1c4__2 == 1
	replace 		ac_rice_why = 3 if s5q1c4__3 == 1 
	replace 		ac_rice_why = 4 if s5q1c4__4 == 1 
	replace 		ac_rice_why = 5 if s5q1c4__5 == 1 
	replace 		ac_rice_why = 6 if s5q1c4__6 == 1 
	lab def			ac_rice_why 1 "shops out" 2 "markets closed" 3 "no transportation" /// 
								4 "restrictions to go out" 5 "increase in price" 6 "no money" 
	label var 		ac_rice_why "reason for unable to purchase rice"
	
	rename 			s5q1a5 ac_beans_need
	rename 			s5q1b5 ac_beans
	gen 			ac_beans_why = . 
	replace			ac_beans_why = 1 if s5q1c5__1 == 1 
	replace 		ac_beans_why = 2 if s5q1c5__2 == 1
	replace 		ac_beans_why = 3 if s5q1c5__3 == 1 
	replace 		ac_beans_why = 4 if s5q1c5__4 == 1 
	replace 		ac_beans_why = 5 if s5q1c5__5 == 1 
	replace 		ac_beans_why = 6 if s5q1c5__6 == 1 
	lab def			ac_beans_why 1 "shops out" 2 "markets closed" 3 "no transportation" /// 
								4 "restrictions to go out" 5 "increase in price" 6 "no money" 
	label var 		ac_beans_why "reason for unable to purchase beans"
		
	rename 			s5q1a6 ac_cass_need
	rename 			s5q1b6 ac_cass
	gen 			ac_cass_why = . 
	replace			ac_cass_why = 1 if s5q1c6__1 == 1 
	replace 		ac_cass_why = 2 if s5q1c6__2 == 1
	replace 		ac_cass_why = 3 if s5q1c6__3 == 1 
	replace 		ac_cass_why = 4 if s5q1c6__4 == 1 
	replace 		ac_cass_why = 5 if s5q1c6__5 == 1 
	replace 		ac_cass_why = 6 if s5q1c6__6 == 1 
	lab def			ac_cass_why 1 "shops out" 2 "markets closed" 3 "no transportation" /// 
								4 "restrictions to go out" 5 "increase in price" 6 "no money" 
	label var 		ac_cass_why "reason for unable to purchase cassava"
	
	rename 			s5q1a7 ac_yam_need
	rename 			s5q1b7 ac_yam
	gen 			ac_yam_why = . 
	replace			ac_yam_why = 1 if s5q1c7__1 == 1 
	replace 		ac_yam_why = 2 if s5q1c7__2 == 1
	replace 		ac_yam_why = 3 if s5q1c7__3 == 1 
	replace 		ac_yam_why = 4 if s5q1c7__4 == 1 
	replace 		ac_yam_why = 5 if s5q1c7__5 == 1 
	replace 		ac_yam_why = 6 if s5q1c7__6 == 1 
	lab def			ac_yam_why 1 "shops out" 2 "markets closed" 3 "no transportation" /// 
								4 "restrictions to go out" 5 "increase in price" 6 "no money" 
	label var 		ac_yam_why "reason for unable to purchase yam"
	
	rename 			s5q1a8 ac_sorg_need
	rename 			s5q1b8 ac_sorg
	gen 			ac_sorg_why = . 
	replace			ac_sorg_why = 1 if s5q1c8__1 == 1 
	replace 		ac_sorg_why = 2 if s5q1c8__2 == 1
	replace 		ac_sorg_why = 3 if s5q1c8__3 == 1 
	replace 		ac_sorg_why = 4 if s5q1c8__4 == 1 
	replace 		ac_sorg_why = 5 if s5q1c8__5 == 1 
	replace 		ac_sorg_why = 6 if s5q1c8__6 == 1 
	lab def			ac_sorg_why 1 "shops out" 2 "markets closed" 3 "no transportation" /// 
								4 "restrictions to go out" 5 "increase in price" 6 "no money" 
	label var 		ac_sorg_why "reason for unable to purchase sorghum"
	
	rename 			s5q1a1 ac_med_need
	rename 			s5q1b1 ac_med
	gen 			ac_med_why = . 
	replace			ac_med_why = 1 if s5q1c1__1 == 1 
	replace 		ac_med_why = 2 if s5q1c1__2 == 1 
	replace 		ac_med_why = 3 if s5q1c1__3 == 1 
	replace 		ac_med_why = 4 if s5q1c1__4 == 1 
	replace 		ac_med_why = 5 if s5q1c1__5 == 1 
	replace 		ac_med_why = 6 if s5q1c1__6 == 1 
	lab def			ac_med_why 1 "shops out" 2 "markets closed" 3 "no transportation" /// 
								4 "restrictions to go out" 5 "increase in price" 6 "no money" 
	label var 		ac_med_why "reason for unable to purchase medicine"


	rename 			s5q2 ac_medserv_need
	rename 			s5q3 ac_medserv
	rename 			s5q4 ac_medserv_why 
	replace 		ac_medserv_why = 6 if ac_medserv_why == 4
	replace 		ac_medserv_why = 4 if ac_medserv_why == 96 
	lab def			ac_medserv_why 1 "no money" 2 "no med personnel" 3 "facility full" /// 
								4 "other" 5 "no transportation" 6 "restrictions to go out" /// 
								7 "afraid of virus" 
	label var 		ac_med_why "reason for unable to access medical services"
	
	rename 			filter1 children520
	rename 			s5q4a sch_child
	rename 			s5q4b edu_act 
	rename 			s5q5__1 edu_1 
	rename 			s5q5__2 edu_2  
	rename 			s5q5__3 edu_3 
	rename 			s5q5__4 edu_4 
	rename 			s5q5__7 edu_5 
	rename 			s5q5__96 edu_other 
	rename 			s5q5__5 edu_6 
	rename 			s5q5__6 edu_7 
	
	rename 			s5q6 edu_cont
	rename			s5q7__1 edu_cont_1
	rename 			s5q7__2 edu_cont_2 
	rename 			s5q7__3 edu_cont_3 
	rename 			s5q7__4 edu_cont_5 
	rename 			s5q7__5 edu_cont_6 
	rename 			s5q7__6 edu_cont_7 
	rename 			s5q7__7	educ_cont_8 
	
	rename 			s5q8 bank
	rename 			s5q9 ac_bank 
	rename 			s5q10 ac_bank_why 
	
/* round 2 access differs from round 1 access 
	
	rename 			s5q1e suff_waterdrink
	rename 			s5q1f suff_waterdrink_why 
	rename 			s5q1a suff_soap_ac
	rename 			s5q1b suff_waterwash 
	rename 			s5q1c freq_washsoap 
	rename 			s5q1d freq_mask
*/	

* employment variables 
	rename			s6q1 emp
	rename			s6q2 emp_pre
	rename			s6q3 emp_pre_why
	rename			s6q4 emp_pre_act
	rename			s6q5 emp_act
	rename			s6q6 emp_stat
	rename			s6q7 emp_able
	rename			s6q8 emp_unable	
	rename			s6q8a emp_unable_why	
	rename			s6q9 emp_hh
	rename			s6q11 bus_emp
	rename			s6q12 bus_sect
	rename			s6q13 bus_emp_inc
	rename			s6q14 bus_why
	rename			s6q15 farm_emp 
	rename			s6q16 farm_norm
	rename			s6q17__1 farm_why_1
	rename			s6q17__2 farm_why_2
	rename			s6q17__3 farm_why_3
	rename			s6q17__4 farm_why_4
	rename			s6q17__5 farm_why_5
	rename			s6q17__6 farm_why_6
	rename			s6q17__96 farm_why_7
	
* round 2 access differs from round 1 employment 

	rename 			s6q1a emp_7
	rename 			s6q1b emp_7ret 
	rename 			s6q1c emp_7why
	rename 			s6q3a emp_search_month
	rename 			s6q3b emp_search 
	rename			s6q4a emp_same
	rename			s6q4b emp_chg_why 
	rename 			s6q8b emp_hours7
	rename 			s6q8c emp_hoursmarch 
	rename			s6q8d__1 emp_cont_1
	rename			s6q8d__2 emp_cont_2
	rename			s6q8d__3 emp_cont_3
	rename			s6q8d__4 emp_cont_4
	rename			s6q8e contrct
	rename 			s6q11a bus_status 
	rename 			s6q11b bus_closed 
	rename 			s6q15__1 bus_chal_1	
	rename 			s6q15__2 bus_chal_2 
	rename 			s6q15__3 bus_chal_3 
	rename 			s6q15__4 bus_chal_4 
	rename 			s6q15__5 bus_chal_5 
	rename 			s6q15__6 bus_chal_6 
	rename 			s6q15__96 bus_chal_7 
	rename 			s6q15a bus_beh
	rename 			s6q15b__1 bus_beh_1 
	rename 			s6q15b__2 bus_beh_2 
	rename 			s6q15b__3 bus_beh_3 
	rename 			s6q15b__4 bus_beh_4 
	rename 			s6q15b__5 bus_beh_5 
	rename 			s6q15b__6 bus_beh_6 
	rename 			s6q15b__96 bus_beh_7 
	
* agriculture
	rename			s6q17 ag_prep
	rename			s6q18_1 ag_crop_1
	rename			s6q18_2 ag_crop_2
	rename			s6q18_3 ag_crop_3
	rename 			s6q19 ag_chg	
	rename			s6q20__1 ag_chg_1
	rename			s6q20__2 ag_chg_2
	rename			s6q20__3 ag_chg_3
	rename			s6q20__4 ag_chg_4
	rename			s6q20__5 ag_chg_5
	rename			s6q20__6 ag_chg_6
	rename			s6q20__7 ag_chg_7
	rename 			s6q20__96 ag_chg_13
	rename			s6q21a__1 agcovid_chg_why_1 
	rename 			s6q21a__2 agcovid_chg_why_2
	rename 			s6q21a__3 agcovid_chg_why_3
	rename			s6q21a__4 agcovid_chg_why_4
	rename			s6q21a__5 agcovid_chg_why_5	 
	rename 			s6q21a__6 agcovid_chg_why_6
	rename 			s6q21a__7 agcovid_chg_why_7
	rename 			s6q21a__8 agcovid_chg_why_8	
	rename 			s6q21a__96 agcovid_chg_why_9 
	rename 			s6q21b__1 ag_nocrop_1 
	rename 			s6q21b__2 ag_nocrop_2 
	rename 			s6q21b__3 ag_nocrop_3 
	rename 			s6q21b__4 ag_nocrop_4 
	rename 			s6q21b__5 ag_nocrop_5 
	rename 			s6q21b__6 ag_nocrop_6 
	rename 			s6q21b__7 ag_nocrop_7 
	rename 			s6q21b__8 ag_nocrop_8 
	rename 			s6q21b__96 ag_nocrop_9 
	rename			s6q22__1 ag_seed_1
	rename			s6q22__2 ag_seed_2
	rename			s6q22__3 ag_seed_3
	rename			s6q22__4 ag_seed_4
	rename			s6q22__5 ag_seed_5
	rename			s6q22__6 ag_seed_6
	rename 			s6q22__96 ag_seed_7 
	rename 			s6q23 ag_live_lost 
	
* fies
	rename			s8q4 fies_7
	lab var			fies_7 "Skipped a meal"
	rename			s8q6 fies_1
	lab var			fies_1 "Ran out of food"
	rename			s8q8 fies_3
	lab var			fies_3 "Went without eating for a whole day"	 
 * round 2 additional questions 
	rename			s8q1 fies_4
	lab var			fies_4 "Worried about not having enough food to eat"
	rename			s8q2 fies_5
	lab var			fies_5 "Unable to eat healthy and nutritious/preferred foods"
	rename			s8q3 fies_6
	lab var			fies_6 "Ate only a few kinds of food"
	rename			s8q5 fies_8
	lab var			fies_8 "Ate less than you thought you should"
	rename			s8q7 fies_2
	lab var			fies_2 "Hungry but did not eat"

* concerns
	rename			s9q1 concern_1
	rename			s9q2 concern_2

* drop unnecessary variables
	drop			interviewer_id *_os  s6q10_* s12q3__* s12q4__* /// 
						s12q5 s12q9 s12q10 s12q10_os s12q11 s12q14 baseline_date ///
						s12q10a s5*  
	drop if			wave ==  .
	
* create country variables
	gen				country = 3
	order			country
	lab def			country 1 "Ethiopia" 2 "Malawi" 3 "Nigeria" 4 "Uganda"
	lab val			country country	
	
* reorder variables
	order			fies_2 fies_3 fies_4 fies_5 fies_6 fies_7 fies_8, after(fies_1)

* income variables	
	rename 			s7q11 farm_inc
	lab	var			farm_inc "Income from farming, fishing, livestock in last 12 months"
	rename			s7q21 farm_chg
	lab var			farm_chg "Change in income from farming since covid"
	rename 			s7q12 bus_inc
	lab var			bus_inc "Income from non-farm family business in last 12 months"
	rename			s7q22 bus_chg
	lab var			bus_chg "Change in income from non-farm family business since covid"	
	rename 			s7q13 wage_inc
	lab var			wage_inc "Income from wage employment in last 12 months"
	rename			s7q23 wage_chg
	lab var			wage_chg "Change in income from wage employment since covid"	
	rename 			s7q14 rem_for
	label 			var rem_for "Income from remittances abroad in last 12 months"
	rename			s7q24 rem_for_chg
	label 			var rem_for_chg "Change in income from remittances abroad since covid"	
	rename 			s7q15 rem_dom
	label 			var rem_dom "Income from remittances domestic in last 12 months"
	rename			s7q25 rem_dom_chg
	label 			var rem_dom_chg "Change in income from remittances domestic since covid"	
	rename 			s7q16 asst_inc
	label 			var asst_inc "Income from assistance from non-family in last 12 months"
	rename			s7q26 asst_chg
	label 			var asst_chg "Change in income from assistance from non-family since covid"
	rename 			s7q17 isp_inc
	label 			var isp_inc "Income from properties, investment in last 12 months"
	rename			s7q27 isp_chg
	label 			var isp_chg "Change in income from properties, investment since covid"
	rename 			s7q18 pen_inc
	label 			var pen_inc "Income from pension in last 12 months"
	rename			s7q28 pen_chg
	label 			var pen_chg "Change in income from pension since covid"
	rename 			s7q19 gov_inc
	label 			var gov_inc "Income from government assistance in last 12 months"
	rename			s7q29 gov_chg
	label 			var gov_chg "Change in income from government assistance since covid"	
	rename 			s7q110 ngo_inc
	label 			var ngo_inc "Income from NGO assistance in last 12 months"
	rename			s7q210 ngo_chg
	label 			var ngo_chg "Change in income from NGO assistance since covid"
	rename 			s7q196 oth_inc
	label 			var oth_inc "Income from other source in last 12 months"
	rename			s7q296 oth_chg
	label 			var oth_chg "Change in income from other source since covid"	
	rename			s7q299 tot_inc_chg
	label 			var tot_inc_chg "Change in income from other source since covid"	

	drop			s7q199

*shocks
* need to make shock variables match uganda 
* shock 2 - 9 need to be change
* shock 1 is okay
	rename 			shock_8 shock_12 
	rename 			shock_9 shock_14 
	rename 			shock_5 shock_8 
	rename			shock_6 shock_10
	rename 			shock_7 shock_11 
	rename 			shock_2 shock_5
	rename			shock_3 shock_6
	rename 			shock_4 shock_7
	
* rename cope variables
	rename			s10q3__1 cope_1
	rename			s10q3__6 cope_2
	rename			s10q3__7 cope_3
	rename			s10q3__8 cope_4
	rename			s10q3__9 cope_5
	rename			s10q3__11 cope_6
	rename			s10q3__12 cope_7
	rename			s10q3__13 cope_8
	rename			s10q3__14 cope_9
	rename			s10q3__15 cope_10
	rename			s10q3__16 cope_11
	rename			s10q3__17 cope_12
	rename			s10q3__18 cope_13
	rename			s10q3__19 cope_14
	rename			s10q3__20 cope_15
	rename			s10q3__21 cope_16
	rename			s10q3__96 cope_17
	
* label variables
	lab var			shock_1 "Death of disability of an adult working member of the household"
	lab var			shock_5 "Job loss"
	lab var			shock_6 "Non-farm business failure"
	lab var			shock_7 "Theft of crops, cash, livestock or other property"
	lab var			shock_8 "Destruction of harvest by insufficient labor"
	lab var			shock_10 "Increase in price of inputs"
	lab var			shock_11 "Fall in the price of output"
	lab var			shock_12 "Increase in price of major food items c"
	lab var			shock_14 "Other shock"
	* differs from uganda (other country with shock questions) - asked binary here
	
	foreach 		var of varlist shock_1-shock_14 {
		lab val		`var' shock 
		}
		
* generate any shock variable
	gen				shock_any = 1 if shock_1 == 1 | shock_5 == 1 | ///
						shock_6 == 1 | shock_7 == 1 | shock_8 == 1 | ///
						shock_10 == 1 | shock_11 == 1 | shock_12 == 1 | ///
						shock_14 == 1
	replace			shock_any = 0 if shock_any == .
	lab var			shock_any "Experience some shock"
	
	lab var			cope_1 "Sale of assets (Agricultural and Non_agricultural)"
	lab var			cope_2 "Engaged in additional income generating activities"
	lab var			cope_3 "Received assistance from friends & family"
	lab var			cope_4 "Borrowed from friends & family"
	lab var			cope_5 "Took a loan from a financial institution"
	lab var			cope_6 "Credited purchases"
	lab var			cope_7 "Delayed payment obligations"
	lab var			cope_8 "Sold harvest in advance"
	lab var			cope_9 "Reduced food consumption"
	lab var			cope_10 "Reduced non_food consumption"
	lab var			cope_11 "Relied on savings"
	lab var			cope_12 "Received assistance from NGO"
	lab var			cope_13 "Took advanced payment from employer"
	lab var			cope_14 "Received assistance from government"
	lab var			cope_15 "Was covered by insurance policy"
	lab var			cope_16 "Did nothing"
	lab var			cope_17 "Other"
	
* assistance
	gen				asst_food = 1 if s11q11 == 1
	replace			asst_food = 0 if s11q11 == 2
	replace			asst_food = 0 if asst_food == .
	lab var			asst_food "Recieved food assistance"
	lab def			assist 0 "No" 1 "Yes"
	lab val			asst_food assist
	
	gen				asst_cash = 1 if s11q12 == 1
	replace			asst_cash = 0 if s11q12 == 2
	replace			asst_cash = 0 if asst_cash == .
	lab var			asst_cash "Recieved cash assistance"
	lab val			asst_cash assist
	
	gen				asst_kind = 1 if s11q13 == 1
	replace			asst_kind = 0 if s11q13 == 2
	replace			asst_kind = 0 if asst_kind == .
	lab var			asst_kind "Recieved in-kind assistance"
	lab val			asst_kind assist
	
	gen				asst_any = 1 if asst_food == 1 | asst_cash == 1 | ///
						asst_kind == 1
	replace			asst_any = 0 if asst_any == .
	lab var			asst_any "Recieved any assistance"
	lab val			asst_any assist

* drop variables
	drop			s11q11 s11q12 s11q13
	
	gen 			region = 3000 + state

	lab def			region 3001 "Abia" 3002 "Adamawa" 3003 ///
						"Akwa Ibom" 3004 "Anambra" 3005 "Bauchi" 3006 ///
						"Bayelsa" 3007 "Benue" 3008 "Borno" 3009 ///
						"Cross River" 3010 "Delta" 3011 "Ebonyi" 3012 ///
						"Edo" 3013 "Ekiti" 3014 "Enugu" 3015 "Gombe" 3016 ///
						"Imo" 3017 "Jigawa" 3018 "Kaduna" 3019 "Kano" 3020 ///
						"Katsina" 3021 "Kebbi" 3022 "Kogi" 3023 "Kwara" 3024 ///
						"Lagos" 3025 "Nasarawa" 3026 "Niger" 3027 "Ogun" 3028 ///
						"Ondo" 3029 "Osun" 3030 "Oyo" 3031 "Plateau" 3032 ///
						"Rivers" 3033 "Sokoto" 3034 "Taraba" 3035 "Yobe" 3036 ///
						"Zamfara" 3037 "FCT", replace
						
	lab val 		region region
	drop			zone state
	order			region, after(sector)
	lab var			region "Region"	
	
	rename 			s2q0a hhleft
	rename 			s2q0b hhjoin 
	

* **********************************************************************
* 4 - QC check 
* **********************************************************************

* compare numerical variables to other rounds & flag if 25+ percentage points different
	tostring 		wave, replace
	ds, 			has(type numeric)
	foreach 		var in `r(varlist)' {
		preserve
		keep 		`var' wave
		destring 	wave, replace
		gen 		counter = 1
		collapse 	(sum) counter, by(`var' wave)
		reshape 	wide counter, i(`var') j(wave)
		drop 		if `var' == .
		foreach 	x in "$waves" {
			egen 	tot_`x' = total(counter`x')
			gen 	per_`x' = counter`x' / tot_`x'
		}
		keep 		per*
		foreach 	x in "$waves"  {
			foreach q in "$waves"  {
				gen flag_`var'_`q'`x' = 1 if per_`q' - per_`x' > .25 & per_`q' != . & per_`x' != .
			}
		}	
		keep 		*flag*

	* drop if all missing	
		foreach 	v of varlist _all {
			capture assert mi(`v')
			if 		!_rc {
				drop `v'
			}
		}
		gen 		n = _n
		tempfile 	temp`var'
		save 		`temp`var''
		restore   
	}
		
* create dataset of flags
	preserve
	ds, 			has(type numeric)
	clear
	set 			obs 15
	gen 			n = _n
	foreach 		var in `r(varlist)' {
		merge 		1:1 n using `temp`var'', nogen
	}
	reshape 		long flag_, i(n) j(variables) string 
	drop 			if flag_ == .
	drop 			n
	sort 			variable	
	export 			excel using "$export/nga_qc_flags.xlsx", first(var) sheetreplace sheet(flags)
	restore
	destring 		wave, replace


* **********************************************************************
* 5 - end matter, clean up to save
* **********************************************************************

* final clean 
	compress
	describe
	summarize 
	rename hhid hhid_nga 

* save file
		customsave , idvar(hhid_nga) filename("nga_panel.dta") ///
			path("$export") dofile(nga_build) user($user)

* close the log
	log	close

/* END */