/*
แบบฝึกหัดวันนี้
ลองทำเองก่อน 6 ข้อนี้:

1. ใช้ ROLLBACK แล้วพิสูจน์ว่าข้อมูลไม่ถูกบันทึก
2. ใช้ SAVEPOINT
3. สรุป SUM(total_paid) ต่อสมาชิก
4. หา Loan ที่ยังไม่มี Payment
5. สร้าง Index 1 ตัว
6. สร้าง View 1 ตัว

แล้วเพิ่มโจทย์อีก 2 ข้อ:
7. หาเฉพาะสมาชิกที่จ่ายรวมมากกว่า 5000
8. เรียงสมาชิกจากยอดจ่ายมาก → น้อย

ใบ้ข้อ 7 ว่าจะต้องใช้:
HAVING

พอคุณทำชุดนี้แล้วส่งโค้ดมา เดี๋ยวผมตรวจต่อให้ และขั้นต่อไปเราจะไป Trigger + Audit Log ซึ่งจะเริ่มใกล้ระบบการเงินจริงมากขึ้นครับ
*/

-- 1. ใช้ ROLLBACK แล้วพิสูจน์ว่าข้อมูลไม่ถูกบันทึก
BEGIN;

-- Create Data
INSERT INTO payments
(loan_id, payment_date, principal_paid, interest_paid, total_paid)
VALUES
(9, '2026-05-01', 5000.00, 500.00, 5500.00);

-- Minus principal
UPDATE loans
SET principal = principal - 5000 -- แก้ไขเป็นยอดจ่ายจริง ที่ไม่รวมดอกเบี้ย
WHERE loan_id = 9;

-- Test use ROLLBACK
ROLLBACK; -- Transaction จบไปแล้ว จึงไม่ต้อง COMMIT;
--COMMIT; -- Transaction จบไปแล้ว จึงไม่ต้อง COMMIT;
-- END transaction


-- Check ข้อมูล Loans / Payments ของ member_id 9
-- loans
SELECT *
FROM loans
WHERE loan_id = 9;
-- payments
SELECT *
FROM payments
WHERE loan_id = 9;




-- 2. ใช้ SAVEPOINT
-- Start transaction
BEGIN;

-- Create payment data
INSERT INTO payments
(loan_id, payment_date, principal_paid, interest_paid, total_paid)
VALUES
(9, '2026-09-15', 4000.00, 500.00, 4500.00);

-- SAVE 
SAVEPOINT before_minus_principal;

-- Minus principal 
UPDATE loans
SET principal = principal - 4000.00
WHERE loan_id = 9;
-- ลดเฉพาะ principal_paid ไม่รวม interest_paid

-- BACK to savepoint
ROLLBACK TO SAVEPOINT before_minus_principal; -- จริงๆไม่ควรใช้เพราะไม่จำเป็ฯในเคสนี้แคทดลอง

COMMIT;
-- End transaction



-- 3. สรุป SUM(total_paid) ต่อสมาชิก
SELECT
	m.member_no,
	m.full_name,
	l.loan_no,
	l.loan_type,
	l.principal,
	SUM(p.total_paid) AS Total_Paid_Amount
FROM members m
JOIN loans l
ON m.member_id = l.member_id
JOIN payments p
ON l.loan_id = p.loan_id
GROUP BY m.member_no, m.full_name, l.loan_no, l.loan_type, l.principal
ORDER BY m.full_name ASC;
-- NEW 3 by ai
SELECT
    m.member_id,
    m.member_no,
    m.full_name,
    SUM(p.total_paid) AS total_paid_amount
FROM members m
JOIN loans l
ON m.member_id = l.member_id
JOIN payments p
ON l.loan_id = p.loan_id
GROUP BY
    m.member_id,
    m.member_no,
    m.full_name
ORDER BY total_paid_amount DESC;
-- จุดนี้ผมคิดว่ามันมีอีกวิธีหนึ่งที่ทำแล้วไม่จำเป็นต้องสร้าง GROUP BY รึป่าวหรือมีแค่วิธีนี้
-- คำถามที่คุณเขียนว่า “มีวิธีไม่ใช้ GROUP BY ไหม” — มี เช่น Window Function:
SELECT DISTINCT
	m.member_id,
	m.member_no,
	m.full_name,
	SUM(p.total_paid) OVER (
		PARTITION BY m.member_id
	) AS total_paid_amount
FROM members m
JOIN loans l
ON m.member_id = l.member_id
JOIN payments p
ON l.loan_id = p.loan_id
ORDER BY total_paid_amount DESC;

-- 4. หา Loan ที่ยังไม่มี Payment
SELECT
    m.member_no,
    m.full_name,
    l.loan_no,
    l.loan_type,
    l.start_date,
    l.principal,
    l.annual_rate
FROM members m
JOIN loans l
ON m.member_id = l.member_id
LEFT JOIN payments p
ON l.loan_id = p.loan_id
WHERE p.payment_id IS NULL
ORDER BY m.member_id ASC;
-- ไม่แน่ใจทำถูกไหมแต่ผลลัพธ์คือไม่มีบัญชีไหนขึ้นมาหรือทุกบัญชีมี payment หมดแล้ว
-- Add loan data to member version ai
INSERT INTO loans
(member_id, loan_no, loan_type, principal, annual_rate, start_date)
SELECT
    member_id,
    'L004',
    'ORDINARY',
    15000.00,
    10.00,
    '2024-01-01'
FROM members
WHERE member_no = 'M007';
-- ทอสอบเพิ่มรายชื่อใหม่แล้วก็ยังไม่เห็นรายชื่อ


-- 5. สร้าง Index 1 ตัว
CREATE INDEX idx_payments_loan_date
ON payments(loan_id, payment_date);
-- Delete index
DROP INDEX idx_payments_loan_date;
-- View index
SELECT 
	indexname,
	indexdef
FROM pg_indexes
WHERE tablename = 'payments';

-- 6. สร้าง View 1 ตัว
CREATE OR REPLACE VIEW vw_member_payment_summary AS
SELECT
    m.member_id,
    m.member_no,
    m.full_name,
    COALESCE(SUM(p.total_paid), 0) AS total_paid
FROM members m
LEFT JOIN loans l
ON m.member_id = l.member_id
LEFT JOIN payments p
ON l.loan_id = p.loan_id
GROUP BY
    m.member_id,
    m.member_no,
    m.full_name;
-- Test View
SELECT *
FROM vw_member_payment_summary
ORDER BY total_paid DESC;
-- Delete view
DROP VIEW vw_members_loans_payments_01;


/* แล้วเพิ่มโจทย์อีก 2 ข้อ: 7. หาเฉพาะสมาชิกที่จ่ายรวมมากกว่า 5000 */
SELECT
	m.member_no,
	m.full_name,
	l.loan_no,
	l.loan_type,
	l.start_date,
	SUM(p.total_paid) AS Total_Paud_Amount
FROM members m
JOIN loans l
ON m.member_id = l.member_id
JOIN payments p
ON l.loan_id = p.loan_id
GROUP BY m.member_no,m.full_name,l.loan_no,l.loan_type,l.start_date
HAVING SUM(p.total_paid) > 5000
ORDER BY Total_Paud_Amount ASC;
-- Version AI
SELECT
    m.member_id,
    m.member_no,
    m.full_name,
    SUM(p.total_paid) AS total_paid_amount
FROM members m
JOIN loans l
ON m.member_id = l.member_id
JOIN payments p
ON l.loan_id = p.loan_id
GROUP BY
    m.member_id,
    m.member_no,
    m.full_name
HAVING SUM(p.total_paid) > 5000
ORDER BY total_paid_amount DESC;
-- พบแล้วผมใส่ ผิดตรง ON m.member_id = l.loan_id แก้เป็น ON m.member_id = l.member_id
/*
หลักจำสำคัญมาก:
WHERE  = กรองก่อน GROUP
HAVING = กรองผลหลัง GROUP/Aggregate
*/

/* 8. เรียงสมาชิกจากยอดจ่ายมาก → น้อย */
SELECT
	m.member_id,
	m.member_no,
	m.full_name,
	l.loan_no,
	l.loan_type,
	l.start_date,
	SUM(p.total_paid) AS Total_Paud_Amount
FROM members m	
JOIN loans l
ON m.member_id = l.member_id
JOIN payments p
ON l.loan_id = p.loan_id
GROUP BY m.member_id, m.member_no,m.full_name,l.loan_no,l.loan_type,l.start_date
ORDER BY Total_Paud_Amount DESC;
-- ผมทำแล้วพบว่ารายชื่อออกมาแค่ 2 คน ทั้งๆที่ใน Payments ก็มีหลายบัญชีที่จ่ายแล้ว
-- พบแล้วผมใส่ ผิดตรง ON m.member_id = l.loan_id แก้เป็น ON m.member_id = l.member_id
-- AI version
/*ถ้าต้องการเห็น สมาชิกทุกคน แม้ยังไม่เคยจ่าย:*/
SELECT
    m.member_id,
    m.member_no,
    m.full_name,
    COALESCE(SUM(p.total_paid), 0) AS total_paid_amount
FROM members m
LEFT JOIN loans l
ON m.member_id = l.member_id
LEFT JOIN payments p
ON l.loan_id = p.loan_id
GROUP BY
    m.member_id,
    m.member_no,
    m.full_name
ORDER BY total_paid_amount DESC;

-- เช็คทั้งตาราง
SELECT * FROM payments;

-- Check loan_id & full_name
SELECT
	m.member_id,
	m.full_name,
	l.loan_id
FROM members m
JOIN loans l
ON m.member_id = l.member_id;

--- หลัก SQL ที่อยากให้จำจากงานรอบนี้
/*
เรื่อง								จำสั้น ๆ
members → loans			member_id = member_id
loans → payments		loan_id = loan_id
INNER JOIN					เอาเฉพาะที่มีคู่
LEFT JOIN					เก็บฝั่งซ้ายแม้ไม่มีคู่
WHERE					กรองข้อมูลก่อน Aggregate
HAVING					กรองหลัง Aggregate
GROUP BY					รวมหลาย Row เป็น Summary
Window Function					คำนวณกลุ่มแต่ยังรักษา Row
Transaction					สำเร็จทั้งชุดหรือยกเลิกทั้งชุด
SAVEPOINT					จุดย้อนบางส่วนใน Transaction
Index					เร่ง Search/Join/Sort แต่มีต้นทุนตอนเขียน
Payment					เงินต้นลดด้วย principal_paid ไม่ใช่ยอดรวม
*/