-- CAHNGE data culum
ALTER TABLE deposit_accounts
ALTER COLUMN account_no TYPE VARCHAR(30);
-- Read data
SELECT * FROM deposit_accounts;


-- INSERT data to column
INSERT INTO deposit_accounts
(member_id, account_no, account_type, balance, opened_date)
VALUES
(1, 'D001', 'SAVING', 5000.00, '2018-02-08');
-- Read data
SELECT * FROM deposit_accounts;

-- JOIN
SELECT
m.member_no,
m.full_name,
d.account_no,
d.account_type,
d.balance
FROM members m
JOIN deposit_accounts d
ON m.member_id = d.member_id;

-- TEST 2
-- 1. ดู member_id ที่มีจริง
SELECT member_id, member_no, full_name
FROM members
ORDER BY member_id;
-- 3. ดูบัญชีทั้งหมด
SELECT * FROM deposit_accounts;


-- 4. JOIN สมาชิกกับบัญชี
SELECT
  	m.member_no,
    m.full_name,
    d.account_no,
    d.account_type,
    d.balance
FROM members m
JOIN deposit_accounts d
ON m.member_id = d.member_id
ORDER BY member_no ASC;

-- 1. SUM — รวมยอดทั้งหมด
SELECT SUM(balance) AS Total_balance
FROM deposit_accounts;

-- 2. AVG — ค่าเฉลี่ย
SELECT AVG(balance) AS Average_balance
FROM deposit_accounts;

-- 3. MIN / MAX
SELECT
	MIN(balance) AS Minimum_Balance,
	MAX(balance) AS Maximun_Balance
FROM deposit_Accounts;

-- 4. GROUP BY ประเภทบัญชี
SELECT
    account_type,
    SUM(balance) AS total_balance
FROM deposit_accounts
GROUP BY account_type

-- 5. GROUP BY สมาชิก
SELECT
	member_id,
	SUM(balance) AS total_balance
FROM deposit_accounts
GROUP BY member_id;

-- 6. JOIN + GROUP BY
SELECT
	m.member_no,
	m.full_name,
	SUM(d.balance) AS total_deposit
FROM members m
JOIN deposit_accounts d
ON m.member_id = d.member_id
GROUP BY m.member_no, m.full_name
ORDER BY total_deposit DESC;

-- 8. HAVING
SELECT 
	m.member_no,
	m.full_name,
	SUM(d.balance) AS total_deposit
FROM members m
LEFT JOIN deposit_accounts d
ON m.member_id = d.member_id
GROUP BY m.member_no, m.full_name
HAVING SUM(d.balance) > 500
ORDER BY total_deposit DESC;

-- 9. LEFT JOIN
SELECT
    m.member_no,
    m.full_name,
    d.account_no,
    d.balance
FROM members m
LEFT JOIN deposit_accounts d
ON m.member_id = d.member_id
ORDER BY m.member_no;

-- 10. หา “สมาชิกที่ยังไม่มีบัญชี”
SELECT 
	m.member_id,
	m.full_name
FROM members m
LEFT JOIN deposit_accounts d
ON m.member_id = d.member_id
WHERE d.account_id IS NULL;

-- ลองทำ Query SQL ก่อนใน pgAdmin โดยไม่เขียน FastAPI
-- Checl status member
SELECT
	COUNT(*) AS total_member,
	COUNT(*) FILTER (
		WHERE status = 'OffLine'
	) AS ofline_members,
	COUNT(*) FILTER (
		WHERE status = 'ACTIVE'
	) AS active_members
FROM members;

SELECT * FROM members;

-- Check balance
SELECT 
	COALESCE(SUM(balance), 0) AS total_deposit
FROM deposit_accounts;

-- Check principal
SELECT
	COALESCE(SUM(principal), 0) AS total_principal
FROM loans;

-- Check original princcipal
SELECT
	COALESCE(SUM(principal_paid), 0) AS total_principal_paid
FROM payments;





WITH member_summary AS (
    SELECT
        COUNT(*) AS total_members,
        COUNT(*) FILTER (
            WHERE status = 'ACTIVE'
        ) AS active_members,
		COUNT(*) FILTER (
   			WHERE status = 'INACTIVE'
		) AS inactive_members
    FROM members
),

deposit_summary AS (
    SELECT
        COALESCE(SUM(balance), 0) AS total_deposits
    FROM deposit_accounts
),

loan_summary AS (
    SELECT
        COALESCE(SUM(principal), 0) AS total_loan_principal
    FROM loans
),

payment_summary AS (
    SELECT
        COALESCE(SUM(principal_paid), 0) AS total_principal_paid
    FROM payments
)

SELECT
    ms.total_members,
    ms.active_members,
	ms.inactive_members,
    ds.total_deposits,
    ls.total_loan_principal,
    ps.total_principal_paid,
    ls.total_loan_principal - ps.total_principal_paid AS outstanding_principal

FROM member_summary ms
CROSS JOIN deposit_summary ds
CROSS JOIN loan_summary ls
CROSS JOIN payment_summary ps;

-- How to use group
SELECT 
    department, 
    COUNT(member_id) AS total_people 
FROM members
GROUP BY department;

SELECT 
    member_id, 
    SUM(principal) AS total_principal
FROM loans
GROUP BY member_id;


-- Set status
UPDATE members
SET status = 'INACTIVE'
WHERE status = 'OffLine';


SELECT column_name
FROM information_schema.columns
WHERE table_name = 'payments';
