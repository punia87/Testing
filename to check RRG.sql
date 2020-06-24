with term_accs as 
(select ast1.account_num, 
ast1.effective_dtm, 
ast1.account_status, 
aa.ACC_PRISON_BOO, 
aa.ACC_FINANCIAL_DIFFICULTY_BOO, 
aa.ACC_BANKRUPT_BOO,
aa.ACC_FRAUDULENT_BOO, 
aa.ACC_DECEASED_BOO, 
aa.ACC_GONEAWAY_BOO 
from accountstatus ast1 
left join accountattributes aa 
on aa.account_num = ast1.account_num 
where ast1.account_status in ('TA', 'TX') 
and ast1.effective_dtm = 
(select max(effective_dtm) 
from accountstatus ast 
where ast.account_num = ast1.account_num) 
and ast1.effective_dtm <= GNVGEN.SYSTEMDATE), 
accbal as 
(select ta.account_num, 
ta.effective_dtm, 
pva.account_balance, 
ta.account_status, 
ta.ACC_PRISON_BOO, 
ta.ACC_FINANCIAL_DIFFICULTY_BOO, 
ta.ACC_BANKRUPT_BOO,
ta.ACC_FRAUDULENT_BOO, 
ta.ACC_DECEASED_BOO, 
ta.ACC_GONEAWAY_BOO, 
pva.unbilled_usage 
from pvaccountbalance15 pva, term_accs ta 
where ta.account_num = pva.account_num 
and pva.account_balance < 0 
), 
paymethod as 
(select ab.account_num, 
ab.effective_dtm, 
ab.account_balance, 
ab.account_status, 
ad.payment_method_id, 
ab.ACC_PRISON_BOO, 
ab.ACC_FINANCIAL_DIFFICULTY_BOO, 
ab.ACC_BANKRUPT_BOO,
ab.ACC_FRAUDULENT_BOO, 
ab.ACC_DECEASED_BOO, 
ab.ACC_GONEAWAY_BOO, 
ab.unbilled_usage 
from accountdetails ad, accbal ab 
where ab.account_num = ad.account_num 
and ad.start_dat <= GNVGEN.SYSTEMDATE 
and (ad.end_dat >= trunc(GNVGEN.SYSTEMDATE) or ad.end_dat is null)) 
select acc.account_num, 
acc.customer_ref, 
pm.effective_dtm, 
upper(pm.ACC_PRISON_BOO), 
upper(pm.ACC_FINANCIAL_DIFFICULTY_BOO), 
upper(pm.ACC_BANKRUPT_BOO),
upper(pm.ACC_FRAUDULENT_BOO), 
upper(pm.ACC_DECEASED_BOO), 
upper(pm.ACC_GONEAWAY_BOO), 
pm.account_balance, 
pm.payment_method_id, 
pm.account_status, 
pm.unbilled_usage, 
acc.unbilled_adjustment_mny 
from paymethod pm, account acc 
where acc.account_num = pm.account_num