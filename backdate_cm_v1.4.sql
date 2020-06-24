declare 
  out_param       GENEVA_ADMIN.GNVSQLACCBUDGETPLAN.ACCBUDGETPLANCURTYPE; 
  i_accountNumber   varchar2(20) := '0000000081'; -- fill-in with you billing account number;
  i_customerRef     varchar2(20); 
  i_subscriptionRef varchar2(20); 
  i_newDate     varchar2(20); 
  i_nextBillDate    varchar2(20); 
  i_effectiveDate   varchar2(20);
  old_effectiveDate varchar2(20);
  old_statusReason  varchar2(20);
  min_v         number;
  max_v         number;
  countCompanyInfo  number(10);
  countOtc        number(10);
  productSeqExists  number(10);
begin 
  select customer_ref into i_customerRef from account where account_num = i_accountNumber; 
  
  
  Select to_char(add_months(sysdate,-4),'DD.MM.YYYY') into i_newDate from dual; 
  /*select to_char(trunc(add_months(sysdate,-3),'MM'),'DD.MM.YYYY') into i_nextBillDate from dual; */
  select to_char(add_months(next_bill_dtm,-4),'DD.MM.YYYY') into i_nextBillDate from account where account_num = i_accountNumber;
  update accountstatus a set a.effective_dtm = TO_DATE (i_newDate || ' 10:00:00', 'DD.MM.YYYY HH:MI:SS') where a.account_num = i_accountNumber and a.account_status='OK'; 
  update accountstatus a set a.effective_dtm = TO_DATE (i_newDate, 'DD.MM.YYYY') where a.account_num = i_accountNumber and a.account_status='PE'; 
  update accountdetails a set a.start_dat = TO_DATE (i_newDate, 'DD.MM.YYYY') where a.account_num = i_accountNumber and a.end_dat is null; 
  update account a set a.next_bill_dtm = to_date (i_nextBillDate, 'DD.MM.YYYY') /*current date*/ where a.account_num = i_accountNumber;
select count(*) into countOtc from acchasonetimecharge where ACCOUNT_NUM = i_accountNumber;
  IF countOtc > 0 THEN
    update acchasonetimecharge set otc_dtm = TO_DATE (i_newDate || ' 10:00:00', 'DD.MM.YYYY HH:MI:SS') where ACCOUNT_NUM = i_accountNumber; 
    update acchasonetimecharge set created_dtm = TO_DATE (i_newDate || ' 10:00:00', 'DD.MM.YYYY HH:MI:SS') where ACCOUNT_NUM = i_accountNumber;
  END IF;  
  

  
  
  select to_char(add_months(sysdate,-4)+1,'yyyymmdd') into i_effectiveDate from dual;
  
   for c in ( select subscription_ref into i_subscriptionRef from custhasproduct where customer_ref = i_customerRef and subscription_boo = 'T' )
    loop 
     i_subscriptionRef := c.subscription_ref;
     
     
  select min(product_seq) into min_v from custhasproduct where customer_ref = i_customerRef and subscription_boo = 'T' and subscription_ref=i_subscriptionRef ;
  select max(product_seq) into max_v from custhasproduct where customer_ref = i_customerRef and subscription_boo = 'T' and subscription_ref=i_subscriptionRef ;   
  FOR i IN min_v..max_v 
  LOOP 
    select count(*) into productSeqExists from custproductstatus where product_seq = i and customer_ref = i_customerRef and product_status = 'PE';
    IF productSeqExists > 0 THEN
      select to_char(effective_dtm, 'yyyymmddhh24miss'), status_reason_txt into old_effectiveDate, old_statusReason from custproductstatus where product_seq = i and customer_ref = i_customerRef and product_status = 'PE';
      
        Gnvsubscriptionstatus.modifySubscriptionStatus1NC(i_subscriptionRef, 'PE', to_date(old_effectiveDate, 'yyyymmddhh24miss'),
        old_statusReason,to_date(i_effectiveDate||'180000', 'yyyymmddhh24miss'), 'change date','');
    END IF;
  END LOOP;
  
  FOR i IN min_v..max_v 
  LOOP 
    select count(*) into productSeqExists from custproductstatus where product_seq = i and customer_ref = i_customerRef and product_status = 'OK';
    IF productSeqExists > 0 THEN
      select to_char(effective_dtm, 'yyyymmddhh24miss'), status_reason_txt into old_effectiveDate, old_statusReason from custproductstatus where product_seq = i and customer_ref = i_customerRef and product_status = 'OK';
      Gnvsubscriptionstatus.modifySubscriptionStatus1NC(i_subscriptionRef, 'OK', to_date(old_effectiveDate, 'yyyymmddhh24miss'),
        old_statusReason,to_date(i_effectiveDate||'190000', 'yyyymmddhh24miss'), 'change date','');
    END IF;
  END LOOP; 
  
  
select min(product_seq) into min_v from custhasproduct where customer_ref = i_customerRef and subscription_boo = 'F' and subscription_ref=i_subscriptionRef;
select max(product_seq) into max_v from custhasproduct where customer_ref = i_customerRef and subscription_boo = 'F' and subscription_ref=i_subscriptionRef;
FOR i IN min_v..max_v 
  LOOP 
    select count(*) into productSeqExists from custproductstatus where product_seq = i and customer_ref = i_customerRef and product_status = 'PE';
 IF productSeqExists > 0 THEN
      select to_char(effective_dtm, 'yyyymmddhh24miss'), status_reason_txt into old_effectiveDate, old_statusReason from custproductstatus where product_seq = i and customer_ref = i_customerRef and product_status = 'PE';
      gnvproductstatus.modifycustprodstatus2nc(i_customerRef,i,'PE',to_date(old_effectiveDate, 'yyyymmddhh24miss'),old_statusReason,to_date(i_effectiveDate||'180000', 'yyyymmddhh24miss'),'change date','',out_param);
    

    END IF;
  END LOOP;
FOR i IN min_v..max_v 
  LOOP 
    select count(*) into productSeqExists from custproductstatus where product_seq = i and customer_ref = i_customerRef and product_status = 'OK';
 IF productSeqExists > 0 THEN
      select to_char(effective_dtm, 'yyyymmddhh24miss'), status_reason_txt into old_effectiveDate, old_statusReason from custproductstatus where product_seq = i and customer_ref = i_customerRef and product_status = 'OK';
      gnvproductstatus.modifycustprodstatus2nc(i_customerRef,i,'OK',to_date(old_effectiveDate, 'yyyymmddhh24miss'),old_statusReason,to_date(i_effectiveDate||'190000', 'yyyymmddhh24miss'),'change date','',out_param);
     update custeventsource set start_dtm=to_date(i_effectiveDate||'180000', 'yyyymmddhh24miss') where customer_ref=i_customerRef and product_seq = i;
    END IF;
  END LOOP;
END LOOP;


  update contactdetails cd set cd.start_dat = TO_DATE (i_newDate, 'DD.MM.YYYY') where cd.customer_ref = i_customerRef; 
  select count(*) into countCompanyInfo from CompanyDetails where customer_ref = i_customerRef;
    IF countCompanyInfo > 0 THEN
        update CompanyDetails set START_DAT = TO_DATE (i_newDate || ' 10:00:00', 'DD.MM.YYYY      HH:MI:SS') where CUSTOMER_REF = i_customerRef;
     END IF;
  
  
  
  commit;
end;
# added sql changes
