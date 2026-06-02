*------------------------------------------------------------------------------
* File:     explorations/charls_t2dm_survival/dofiles/01_charls_t2dm_survival.do
* Project:  CHARLS T2DM survival analysis
* Author:   Codex
* Purpose:  估计孤独、社会隔离与2型糖尿病发生风险的生存模型
* Inputs:   data/raw/CHARLS_260602/Song2023_charls_analytic_t2dm.csv
* Outputs:  explorations/charls_t2dm_survival/output/tables/
*           explorations/charls_t2dm_survival/output/figures/
* Log:      explorations/charls_t2dm_survival/logs/01_charls_t2dm_survival.log
*------------------------------------------------------------------------------

version 15
clear all
set more off
set varabbrev off
capture log close
log using "explorations/charls_t2dm_survival/logs/01_charls_t2dm_survival.log", replace text

set seed 20260602

*--- 1. 导入数据并完成基本核查 -----------------------------------------------
import delimited "data/raw/CHARLS_260602/Song2023_charls_analytic_t2dm.csv", ///
    clear varnames(1) stringcols(1) case(preserve)

compress

isid panel_ID
assert !missing(time_t2dm)
assert time_t2dm > 0
assert inlist(event_t2dm, 0, 1)
assert inlist(lonely, 0, 1)
assert inlist(isolated, 0, 1)
assert si_score >= 0 & si_score <= 4

label define yesno 0 "No" 1 "Yes", replace
label values lonely yesno
label values isolated yesno
label values male yesno
label values han yesno
label values hypert_bl yesno
label values heart_bl yesno
label values dyslip_bl yesno
label values stroke_bl yesno

label variable lonely "Loneliness"
label variable isolated "Social isolation"
label variable si_score "Social isolation score"
label variable age "Age"
label variable male "Male"
label variable han "Han ethnicity"
label variable edu_num "Education category"
label variable log_income "Log household income"
label variable totmet "Total MET"
label variable bmi "BMI"
label variable hypert_bl "Baseline hypertension"
label variable heart_bl "Baseline heart disease"
label variable dyslip_bl "Baseline dyslipidemia"
label variable stroke_bl "Baseline stroke"
label variable time_t2dm "Follow-up time to T2DM"
label variable event_t2dm "Incident T2DM"

gen byte si_cat = .
replace si_cat = 0 if si_score == 0
replace si_cat = 1 if si_score == 1
replace si_cat = 2 if si_score >= 2 & !missing(si_score)
label define si_cat 0 "0" 1 "1" 2 "2-4", replace
label values si_cat si_cat
label variable si_cat "Social isolation score category"

gen double log_totmet1 = log(totmet + 1)
label variable log_totmet1 "Log(Total MET + 1)"

gen byte any_social_risk = (lonely == 1 | isolated == 1) if !missing(lonely, isolated)
label values any_social_risk yesno
label variable any_social_risk "Lonely or socially isolated"

gen byte both_social_risk = (lonely == 1 & isolated == 1) if !missing(lonely, isolated)
label values both_social_risk yesno
label variable both_social_risk "Lonely and socially isolated"

di as text "变量变异性核查：以下变量在本文件中若无变异，不进入Cox模型。"
foreach v in rural_r employed smoke_cur drink_cur {
    quietly tabulate `v', missing
    di as text "`v': distinct categories shown above"
    tabulate `v', missing
}

stset time_t2dm, failure(event_t2dm == 1) id(panel_ID)
stsum

*--- 2. 输出描述性统计 --------------------------------------------------------
tempname sampleh charh
tempfile sample_summary_tbl baseline_characteristics_tbl cox_models_tbl

postfile `sampleh' str40 metric double value using ///
    "`sample_summary_tbl'", replace

quietly count
post `sampleh' ("N") (r(N))
quietly count if event_t2dm == 1
post `sampleh' ("T2DM events") (r(N))
quietly summarize time_t2dm, detail
post `sampleh' ("Mean follow-up years") (r(mean))
post `sampleh' ("Median follow-up years") (r(p50))
quietly summarize lonely
post `sampleh' ("Loneliness prevalence") (r(mean))
quietly summarize isolated
post `sampleh' ("Social isolation prevalence") (r(mean))
quietly summarize si_score
post `sampleh' ("Mean social isolation score") (r(mean))
quietly summarize age
post `sampleh' ("Mean age") (r(mean))
quietly summarize male
post `sampleh' ("Male prevalence") (r(mean))
postclose `sampleh'

preserve
use "`sample_summary_tbl'", clear
export delimited using "explorations/charls_t2dm_survival/output/tables/sample_summary.csv", replace
restore

postfile `charh' str20 exposure str60 characteristic str20 statistic ///
    double n_unexposed value_unexposed aux_unexposed n_exposed value_exposed aux_exposed ///
    using "`baseline_characteristics_tbl'", replace

foreach exp in lonely isolated {
    quietly count if `exp' == 0
    local n0 = r(N)
    quietly count if `exp' == 1
    local n1 = r(N)

    foreach v in age log_income log_totmet1 bmi {
        quietly summarize `v' if `exp' == 0
        local m0 = r(mean)
        local s0 = r(sd)
        quietly summarize `v' if `exp' == 1
        local m1 = r(mean)
        local s1 = r(sd)
        post `charh' ("`exp'") ("`v'") ("mean_sd") (`n0') (`m0') (`s0') (`n1') (`m1') (`s1')
    }

    foreach v in event_t2dm male han hypert_bl heart_bl dyslip_bl stroke_bl {
        quietly summarize `v' if `exp' == 0
        local p0 = r(mean)
        quietly summarize `v' if `exp' == 1
        local p1 = r(mean)
        post `charh' ("`exp'") ("`v'") ("proportion") (`n0') (`p0') (.) (`n1') (`p1') (.)
    }

    forvalues k = 0/3 {
        quietly count if edu_num == `k' & `exp' == 0
        local c0 = r(N)
        quietly count if edu_num == `k' & `exp' == 1
        local c1 = r(N)
        local p0 = `c0' / `n0'
        local p1 = `c1' / `n1'
        post `charh' ("`exp'") ("edu_num=`k'") ("proportion") (`n0') (`p0') (.) (`n1') (`p1') (.)
    }
}
postclose `charh'

preserve
use "`baseline_characteristics_tbl'", clear
export delimited using ///
    "explorations/charls_t2dm_survival/output/tables/baseline_characteristics.csv", replace
restore

*--- 3. Cox比例风险模型：协变量逐步增加 --------------------------------------
tempname coxh
postfile `coxh' str24 analysis str20 exposure str18 model str40 term ///
    double n events hr ci_low ci_high p_value ///
    using "`cox_models_tbl'", replace

local cov_m1 "c.age i.male"
local cov_m2 "c.age i.male i.han i.edu_num c.log_income"
local cov_m3 "c.age i.male i.han i.edu_num c.log_income c.log_totmet1 c.bmi"
local cov_m4 "c.age i.male i.han i.edu_num c.log_income c.log_totmet1 c.bmi"
local cov_m4 "`cov_m4' i.hypert_bl i.heart_bl i.dyslip_bl i.stroke_bl"

foreach exp in lonely isolated {
    forvalues m = 1/4 {
        quietly stcox c.`exp' `cov_m`m'', vce(robust)
        estimates store `exp'_m`m'
        local b = _b[`exp']
        local se = _se[`exp']
        local hr = exp(`b')
        local lo = exp(`b' - invnormal(0.975) * `se')
        local hi = exp(`b' + invnormal(0.975) * `se')
        local p = 2 * normal(-abs(`b' / `se'))
        post `coxh' ("stepwise") ("`exp'") ("M`m'") ("`exp'") ///
            (e(N)) (e(N_fail)) (`hr') (`lo') (`hi') (`p')
    }
}

quietly stcox c.lonely c.isolated `cov_m4', vce(robust)
estimates store joint_m4
foreach term in lonely isolated {
    local b = _b[`term']
    local se = _se[`term']
    local hr = exp(`b')
    local lo = exp(`b' - invnormal(0.975) * `se')
    local hi = exp(`b' + invnormal(0.975) * `se')
    local p = 2 * normal(-abs(`b' / `se'))
    post `coxh' ("joint") ("lonely+isolated") ("M4") ("`term'") ///
        (e(N)) (e(N_fail)) (`hr') (`lo') (`hi') (`p')
}

quietly stcox c.si_score `cov_m4', vce(robust)
estimates store si_score_m4
local b = _b[si_score]
local se = _se[si_score]
local hr = exp(`b')
local lo = exp(`b' - invnormal(0.975) * `se')
local hi = exp(`b' + invnormal(0.975) * `se')
local p = 2 * normal(-abs(`b' / `se'))
post `coxh' ("score") ("si_score") ("M4") ("si_score") (e(N)) (e(N_fail)) (`hr') (`lo') (`hi') (`p')

quietly stcox i.si_cat `cov_m4', vce(robust)
estimates store si_cat_m4
foreach term in 1.si_cat 2.si_cat {
    local b = _b[`term']
    local se = _se[`term']
    local hr = exp(`b')
    local lo = exp(`b' - invnormal(0.975) * `se')
    local hi = exp(`b' + invnormal(0.975) * `se')
    local p = 2 * normal(-abs(`b' / `se'))
    post `coxh' ("category") ("si_cat") ("M4") ("`term'") ///
        (e(N)) (e(N_fail)) (`hr') (`lo') (`hi') (`p')
}

foreach sex in 0 1 {
    foreach exp in lonely isolated {
        quietly stcox c.`exp' c.age i.han i.edu_num c.log_income c.log_totmet1 c.bmi ///
            i.hypert_bl i.heart_bl i.dyslip_bl i.stroke_bl if male == `sex', vce(robust)
        estimates store `exp'_sex`sex'
        local b = _b[`exp']
        local se = _se[`exp']
        local hr = exp(`b')
        local lo = exp(`b' - invnormal(0.975) * `se')
        local hi = exp(`b' + invnormal(0.975) * `se')
        local p = 2 * normal(-abs(`b' / `se'))
        post `coxh' ("sex=`sex'") ("`exp'") ("M4") ("`exp'") ///
            (e(N)) (e(N_fail)) (`hr') (`lo') (`hi') (`p')
    }
}

quietly stcox c.any_social_risk `cov_m4', vce(robust)
estimates store any_social_risk_m4
local b = _b[any_social_risk]
local se = _se[any_social_risk]
local hr = exp(`b')
local lo = exp(`b' - invnormal(0.975) * `se')
local hi = exp(`b' + invnormal(0.975) * `se')
local p = 2 * normal(-abs(`b' / `se'))
post `coxh' ("robustness") ("any_social_risk") ("M4") ///
    ("any_social_risk") (e(N)) (e(N_fail)) (`hr') (`lo') (`hi') (`p')

quietly stcox c.both_social_risk `cov_m4', vce(robust)
estimates store both_social_risk_m4
local b = _b[both_social_risk]
local se = _se[both_social_risk]
local hr = exp(`b')
local lo = exp(`b' - invnormal(0.975) * `se')
local hi = exp(`b' + invnormal(0.975) * `se')
local p = 2 * normal(-abs(`b' / `se'))
post `coxh' ("robustness") ("both_social_risk") ("M4") ///
    ("both_social_risk") (e(N)) (e(N_fail)) (`hr') (`lo') (`hi') (`p')

quietly streg c.lonely `cov_m4', distribution(weibull) vce(robust)
estimates store lonely_weibull
local b = _b[lonely]
local se = _se[lonely]
local hr = exp(`b')
local lo = exp(`b' - invnormal(0.975) * `se')
local hi = exp(`b' + invnormal(0.975) * `se')
local p = 2 * normal(-abs(`b' / `se'))
post `coxh' ("weibull") ("lonely") ("M4") ("lonely") (e(N)) (e(N_fail)) (`hr') (`lo') (`hi') (`p')

quietly streg c.isolated `cov_m4', distribution(weibull) vce(robust)
estimates store isolated_weibull
local b = _b[isolated]
local se = _se[isolated]
local hr = exp(`b')
local lo = exp(`b' - invnormal(0.975) * `se')
local hi = exp(`b' + invnormal(0.975) * `se')
local p = 2 * normal(-abs(`b' / `se'))
post `coxh' ("weibull") ("isolated") ("M4") ("isolated") ///
    (e(N)) (e(N_fail)) (`hr') (`lo') (`hi') (`p')

postclose `coxh'

preserve
use "`cox_models_tbl'", clear
format hr ci_low ci_high p_value %9.4f
export delimited using "explorations/charls_t2dm_survival/output/tables/cox_models.csv", replace
restore

*--- 4. 比例风险假设检验 ------------------------------------------------------
di as text "PH test: fully adjusted loneliness model"
estimates restore lonely_m4
estat phtest, detail

di as text "PH test: fully adjusted social isolation model"
estimates restore isolated_m4
estat phtest, detail

di as text "PH test: joint fully adjusted model"
estimates restore joint_m4
estat phtest, detail

*--- 5. 图形输出 --------------------------------------------------------------
set scheme s2color

sts graph, by(lonely) failure ///
    title("Cumulative incidence of T2DM by loneliness", ///
        color("31 55 73") size(medsmall)) ///
    subtitle("CHARLS analytic sample", color("74 89 105") size(small)) ///
    xtitle("Follow-up time, years", color("31 55 73") size(small)) ///
    ytitle("Cumulative incidence", color("31 55 73") size(small)) ///
    legend(order(1 "Not lonely" 2 "Lonely") rows(1) size(small) ///
        region(lcolor(white) fcolor(white))) ///
    plot1opts(lcolor("142 164 184") lpattern(dash) lwidth(medthin)) ///
    plot2opts(lcolor("49 145 255") lpattern(solid) lwidth(medthick)) ///
    graphregion(color(white) lcolor(white)) ///
    plotregion(color(white) lcolor(white)) ///
    ylabel(0(.05).20, angle(horizontal) labsize(small) labcolor("31 55 73") ///
        grid glcolor(gs14) glwidth(vthin)) ///
    xlabel(0(1)7, labsize(small) labcolor("31 55 73") nogrid) ///
    name(km_t2dm_lonely, replace)
graph export "explorations/charls_t2dm_survival/output/figures/km_t2dm_lonely.pdf", replace
graph export "explorations/charls_t2dm_survival/output/figures/km_t2dm_lonely.png", ///
    replace width(1800)

sts graph, by(isolated) failure ///
    title("Cumulative incidence of T2DM by social isolation", ///
        color("31 55 73") size(medsmall)) ///
    subtitle("CHARLS analytic sample", color("74 89 105") size(small)) ///
    xtitle("Follow-up time, years", color("31 55 73") size(small)) ///
    ytitle("Cumulative incidence", color("31 55 73") size(small)) ///
    legend(order(1 "Not isolated" 2 "Isolated") rows(1) size(small) ///
        region(lcolor(white) fcolor(white))) ///
    plot1opts(lcolor("142 164 184") lpattern(dash) lwidth(medthin)) ///
    plot2opts(lcolor("49 145 255") lpattern(solid) lwidth(medthick)) ///
    graphregion(color(white) lcolor(white)) ///
    plotregion(color(white) lcolor(white)) ///
    ylabel(0(.05).20, angle(horizontal) labsize(small) labcolor("31 55 73") ///
        grid glcolor(gs14) glwidth(vthin)) ///
    xlabel(0(1)7, labsize(small) labcolor("31 55 73") nogrid) ///
    name(km_t2dm_isolated, replace)
graph export "explorations/charls_t2dm_survival/output/figures/km_t2dm_isolated.pdf", replace
graph export "explorations/charls_t2dm_survival/output/figures/km_t2dm_isolated.png", ///
    replace width(1800)

log close
