/* Setting primary keys for dimension tables and fact tables */

ALTER TABLE dimension_drugform
ADD PRIMARY KEY (drug_form_code);

ALTER TABLE dimension_drugbrandgeneric
ADD PRIMARY KEY (drug_brand_generic_code);

ALTER TABLE dimension_drug
ADD PRIMARY KEY (drug_ndc);

ALTER TABLE dimension_patient
ADD PRIMARY KEY (member_id);

/*Surrogate key*/

ALTER TABLE fact_pharmacyclaim
ADD claim_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

/* Adding Foreign Keys for dimension_drug */

ALTER TABLE dimension_drug
ADD FOREIGN KEY FK_drug_form_code(drug_form_code)
REFERENCES dimension_drugform(drug_form_code)
ON UPDATE CASCADE
ON DELETE RESTRICT;

ALTER TABLE dimension_drug
ADD FOREIGN KEY FK_drug_brand_generic_code(drug_brand_generic_code)
REFERENCES dimension_drugbrandgeneric(drug_brand_generic_code)
ON UPDATE CASCADE
ON DELETE RESTRICT;

/* Adding Foreign Keys to fact table fact_pharmacyclaim */
ALTER TABLE fact_pharmacyclaim
ADD FOREIGN KEY FK_member_id(member_id)
REFERENCES dimension_patient(member_id)
ON UPDATE CASCADE
ON DELETE RESTRICT;

ALTER TABLE fact_pharmacyclaim
ADD FOREIGN KEY FK_drug_ndc(drug_ndc)
REFERENCES dimension_drug(drug_ndc)
ON UPDATE CASCADE
ON DELETE RESTRICT;

/*	Write a SQL query that identifies the number of prescriptions grouped by drug name.
 Paste your output to this query in the space below here; your code should be included in your .sql file.
o Also answer this question: How many prescriptions were filled for the drug Ambien? */
USE finalproject;
SELECT   dd.drug_name
        ,count(dd.drug_name) As drug_prescriptions
FROM fact_pharmacyclaim AS fp
JOIN dimension_drug AS dd
ON fp.drug_ndc = dd.drug_ndc
JOIN dimension_patient AS dp
ON dp.member_id = fp.member_id
GROUP BY dd.drug_name ORDER BY fp.member_id; 
/*	Write a SQL query that counts total prescriptions, counts unique (i.e. distinct) members, sums copay $$, and sums insurance paid $$, for members grouped as either ‘age 65+’ or ’ < 65’. Use case statement logic to develop this query similar to lecture 3. Paste your output in the space below here; your code should be included in your .sql file.
o	Also answer these questions: How many unique members are over 65 years of age? 
o	How many prescriptions did they fill? */
WITH cte AS 
(SELECT	 fp.member_id
		,YEAR(curdate())-YEAR(dp.member_birth_date) AS age
		,(CASE WHEN YEAR(curdate())-YEAR(dp.member_birth_date) < 65 THEN '<65'
			   WHEN YEAR(curdate())-YEAR(dp.member_birth_date) > 65 THEN 'age 65+'
			   ELSE 'out of age group'
		  END
		 )AS age_groups
		,dd.drug_name
		,fp.fill_date
	    ,fp.copay
	    ,fp.insurance_pay
FROM fact_pharmacyclaim AS fp
JOIN dimension_patient AS dp
ON dp.member_id = fp.member_id
LEFT JOIN dimension_drug AS dd
ON fp.drug_ndc = dd.drug_ndc
)
SELECT   age_groups
		,sum(prescriptioncount) As total_prescriptions
        ,count(distinct member_id) AS total_distinct_members
        ,sum(copay) As total_copay
        ,sum(insurance_pay) AS total_insurancepay
FROM
(SELECT member_id
		,age_groups
		,drug_name
		,count(*) As prescriptioncount
		,sum(copay) As copay
		,sum(insurance_pay) AS insurance_pay
FROM cte group by member_id) AS new_cte
group by age_groups;

/*	Write a SQL query that identifies the amount paid by the insurance for the most recent prescription fill date. Use the format that we learned with SQL Window functions. 
Your output should be a table with member_id, member_first_name, member_last_name, drug_name, fill_date (most recent), and most recent insurance paid. 
Paste your output in the space below here; your code should be included in your .sql file.
o	Also answer these questions: For member ID 10003, what was the drug name listed on their most recent fill date?
o	How much did their insurance pay for that medication? */

SELECT  mr.member_id
	   ,mr.member_first_name
	   ,mr.member_last_name
       ,mr.drug_name
       ,mr.fill_date
       ,mr.insurance_pay
FROM
(SELECT   fp.member_id
		,dp.member_first_name
        ,dp.member_last_name
		,dd.drug_name
        ,fp.fill_date
        ,ROW_NUMBER() OVER(PARTITION BY dp.member_id ORDER BY fp.fill_date desc) As counts
        ,fp.copay
        ,fp.insurance_pay
FROM fact_pharmacyclaim AS fp
JOIN dimension_drug AS dd
ON fp.drug_ndc = dd.drug_ndc
JOIN dimension_patient AS dp
ON dp.member_id = fp.member_id
ORDER BY fp.member_id,fp.fill_date desc
) AS mr
WHERE counts = 1;



