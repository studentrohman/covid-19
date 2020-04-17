/*==============================================================================
                  How to siklus pasients covic 19?
				  survival analysis 
				  created by muhammad abdul rohman 
				  

================================================================================*/
clear
set more off
capture log close
log using logfile_data_23maret2020.log, replace

cd "D:\COVID-19-master\COVID-19-master\kumpulan"
import excel "D:\COVID-19-master\Kasus_COVID19_Indonesia_gsheet.xlsx", sheet("Kasus_COVID19_Indonesia_gsheet ") firstrow clear
merge m:1 No using id_new
drop _m No
gen No=_n
reshape long k, i(No) j(waktu)
*menyesuaikan kondisi pasien dengan tanggal tersebut
foreach k in Kontak_dgn_pasien_COVID_19 Mulai_Gejala Mulai_Diisolasi Positif Sembuh Meninggal {



gen `k'_cor= `k'== k
gen `k'_num= `k'-k
replace `k'_cor=1 if `k'_num<=0
*drop `k'_num
}




*mengedit berdasarkan  
ren Usia age 
recode age (57/max=5 "baby boomers") ///
			(37/56=4 "generasi x") ///
			(23/36= 3 "millenials") ///
			(7/22= 2 "generasi Z") ///
			(min/6=1 "generasi alfa"), gen(generasi)  
la val generasi generasi
recode generasi(3=0) , gen(Generasi)
gen sex=JK=="L"
replace sex=. if JK=="?"
la def sex 1 "Male" 0 "Female"
la val sex sex
 *Jenis_kasus
 foreach o in  Jenis_kasus Provinsi Kluster Sumber_Kontak Keterangan Status Dirawat_di{
 encode `o', gen(`o'_num)
 
 }
 
 
 
*memnyesuaikan 

replace Positif_cor=0 if Sembuh_cor==1
replace Positif_cor=0 if Meninggal_cor==1
 xtset  No k
 


gen status=0 
replace status=1  if Positif_cor==1
replace status=2 if Sembuh_cor==1
replace  status=3 if Meninggal_cor==1
la def status 0 "normal" 1"positif corona" 2"sembuh virus korona" 3 "meninggal"
la val status status

 gen X2=106.82649
 gen Y2=-6.17148 

geodist Y X  Y2 X2 , gen(distance)

recode Provinsi_num(2=0)(.=3)
la def Provinsi_num 3"Lainnya" 0 "DKI Jakarta", modify
la val Provinsi_num Provinsi_num
*age
recode age (min/19=1 "0-19 Tahun")(20/29=2 "20-29 Tahun") (30/49=3 "30-49 Tahun") ///
 (50/59=4 "50-59 Tahun") (60/69=5 "60-69 Tahun")(70/79=6 "70-79 Tahun") (80/max=7 "80+"), gen(age_group)

 
 
 /*------------------------------------------------------------------------------

		percobaan mengolah survival analyasis
--------------------------------------------------------------------------------*/
*setting enviromnetal variabel
global time waktu 
global xlist sex i.age_group i.Kluster_num i.Jenis_kasus_num  i.Provinsi_num
global date date 

*set data as survival time
stset    waktu Positif_cor
describe 
stsum


*install asdoc, outreg2 

stcox age i.sex i.Kluster_num, vce(robust)
gen sample=e(sample)
asdoc sum age  *_cor *_num if sample==1, save(statdes)

sts graph, by(sex)
sts list, by(sex) compare
sts test sex
*regresi 
stcox age i.sex

stcox, nohr

stcox age i.sex i.Kluster_num i.Jenis_kasus_num , vce(robust)
outreg2 using pleminaray_result.doc, replace ctitle(peminaiminary result) label
/*------------------------------------------------------------------------------
*nonparametric estimation 
-------------------------------------------------------------------------------*/

*graph of hazard ratio 

sts graph , hazard 
*graph of cumulative hazard ratio (nelson-aalen sumumlatif hazard curve)
sts graph , cumhaz
*Graph of survival fuction (kaplan-maier survival curve)
sts graph, survival
*list of survival function 
sts list , survival
*Test for equality of survival fuctions between two groups
sts test sex
/*------------------------------------------------------------------------------

*parametric model
-------------------------------------------------------------------------------*/
*exponential regression coefisient
streg $xlist, nohr dist(exponential)
streg $xlist, dist(exponential)

*weibull regression coefisients and hazard rates
streg $xlist, nohr dist(weibull)
streg $xlist, dist(weibull)
*Gompertz regression coefisions
streg $xlist, nohr dist(gompertz)
streg $xlist, dist(gompertz)

*cox propotional hazard model coefisients and hazard rates
stcox  $xlist, nohr 
log close 
