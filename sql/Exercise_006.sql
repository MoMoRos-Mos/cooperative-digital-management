-- เขียน Query Outstanding
SELECT 
	l.loan_id,
	l.loan_no,
	m.member_no,
	m.full_name,
	l.principal AS origina_principal,

	COALESCE(
		SUM(p.principal_paid),
		0
	) AS total_pricipal_paid,

	l.principal
	- COALESCE(
		SUM(p.principal_paid),
		0
	) AS outstanding_principal

FROM loans l

JOIN members m
ON l.member_id = m.member_id

LEFT JOIN payments p
ON l.loan_id = p.loan_id

GROUP BY 
	l.loan_id,
	l.loan_no,
	m.member_no,
	m.full_name,
	l.principal
ORDER BY outstanding_principal DESC;

-- 3. ต่อไป Aggregate ระดับ Member
/*โจทย์:
สมาชิกแต่ละคน “กู้ทั้งหมดเท่าไร / จ่ายเงินต้นแล้วเท่าไร / เหลือเท่าไร”*/

SELECT
	l.loan_id,
	l.loan_no,
	m.member_no,
	m.full_name,
	l.principal AS origina_principal,

	COALESCE (
	SUM(p.principal_paid),
	0
	) AS total_principal_paid,

	l.principal -
	COALESCE (
	SUM(p.total_paid),
	0
	) AS outstanding_principal

FROM loans l

JOIN members m
ON l.member_id = m.member_id

LEFT JOIN payments p
ON l.loan_id = p.loan_id

GROUP BY l.loan_id, l.loan_no, m.member_no, m.full_name, l.principal
ORDER BY outstanding_principal DESC;
-- สงสัยทำไมใส่ member_no ไม่ได้ใส่ใน GROUP BY ก็ไม่ได้เพราะม่สามารถรวมค่าแบบ UNIQUE ได้หรอ

-- แบบฝึก Exercise 6
SELECT
	trigger_name,
	event_manipulation,
	event_object_table
FROM information_schema.triggers
WHERE event_object_table = 'loans';

-- TEST เช็ก Trigger ใน loans และให้เหลือ Trigger Final ที่ต้องใช้จริง
SELECT
	trigger_name,
	event_manipulation,
	event_object_table
FROM information_schema.triggers
WHERE event_object_table = 'loans'

-- TEST  Query Outstanding Loan
SELECT
	m.member_no,
	l.loan_id,
	l.loan_no,
	m.full_name,
	l.principal AS original_principal,

	COALESCE (
	SUM(p.total_paid),
	0
	) AS total_principal_paid,

	l.principal - 
	COALESCE (
	SUM(p.total_paid),
	0
	)

FROM loans l

JOIN members m
ON l.member_id = m.member_id

LEFT JOIN payments p
ON l.loan_id = p.loan_id

GROUP BY m.member_no, l.loan_id, l.loan_no, m.full_name, l.principal
ORDER BY total_principal_paid DESC;
	
-- เพิ่ม Loan 1 รายการที่ ยังไม่มี Payment แล้วพิสูจน์ว่า Report ยังแสดง
INSERT INTO loans
(member_id, loan_no, loan_type, principal, annual_rate, start_date)
VALUES
(9, 'L_TEST_01', 'TEST', 100000.00, 300.00, '2026-01-09');
-- ทำงานมีรานชื่อเพิ่มมาอีก 1 ที่ไมไ่ด้จ่ายค่าหนี้เป็น 0 เพราะใช้ LEFT JOIN

-- CHECK audit
SELECT * FROM audit_logs;

-- ทดลอง COALESCE โดยดู Loan ที่ไม่มี Payment ที่ผมเข้าใจคือโชวแค่คนที่ไม่เคยจ่ายเลยเท่านั้น
SELECT 
	m.member_no,
	l.loan_id,
	l.loan_no,
	m.full_name,
	l.principal AS originl_principal, -- ยอดกู้เริ่มต้น

	-- ยอดที่จ่ายแล้ว
	COALESCE (
	SUM(p.total_paid),
	0
	) AS total_pricipal_paid,

	-- ยอดที่เหลือที่ต้องจ่าย
	l.principal
	- COALESCE (
	SUM(p.total_paid),
	0
	) AS out_standing_principal

FROM loans l

JOIN members m
ON l.member_id = m.member_id

LEFT JOIn payments p
ON l.loan_id = p.loan_id
WHERE p.loan_id IS NULL
GROUP BY m.member_no, l.loan_id, l.loan_no, m.full_name, l.principal
ORDER BY total_pricipal_paid DESC;
-- ไม่แน่ใจถูกไหมผมใช้ WHERE p.loan_id IS NULL โดยหากใครที่มีค่า p.loan_id เป็น Null ก็แปบว่าไม่เคยมีรายการ payments


-- ลองเขียน Report ระดับ Member: ยอดกู้ / จ่ายแล้ว / คงเหลือ
SELECT
	m.member_no,
	m.full_name,
	m.department,
	m.join_date,
	m.status,
	l.principal AS ยอดกู้, -- ยอดกู้

	COALESCE (
	SUM(p.total_paid), -- ยอดรวมที่จ่ายแล้ว
	0
	) AS ยอดรวมที่จ่ายแล้ว,

	l.principal -- ยอดคงเหลือ
	- COALESCE (
	SUM(p.total_paid),
	0
	) AS ยอดคงเหลือ

FROM loans l

JOIN members m
ON l.member_id = m.member_id

LEFT JOIN payments p
ON l.loan_id = p.loan_id

GROUP BY member_no, m.full_name,m.department,m.join_date,m.status,l.principal
ORDER BY ยอดรวมที่จ่ายแล้ว DESC;
	

-- วาด ERD แบบหยาบในกระดาษหรือ draw.io ของ 5 ตาราง members / deposit_accounts / loans / payments / audit_logs
/*อันนี้จะส่งแยกเป็นไฟล์นะครับ*/

SELECT * FROM deposit_accounts;
	

-- จากนั้นค่อย JOIN:
SELECT
	m.member_no,
	m.full_name,

	SUM(l.principal) AS original_principal , -- Original principal

	SUM -- Total principal paid
	(
		COALESCE (ps.total_principal_paid, 0)
	) AS total_principal_paid,

	SUM -- Outstanding principal
	(
		l.principal -
		COALESCE (ps.total_principal_paid, 0)
	) AS outstanding_principal

FROM members m

JOIN loans l
ON m.member_id = l.member_id

LEFT JOIN payment_summary ps
ON l.loan_id = ps.loan_id

GROUP BY m.member_id, m.member_no, m.full_name
ORDER BY outstanding_principal DESC;

SELECT * FROM loans;


-- Test view trigger
SELECT
	trigger_name,
	event_manipulation,
	event_object_table
FROM information_schema.triggers
WHERE event_object_table = 'loans';

	
-- ทำ Query ย่อยให้เสร็จก่อน แล้วตั้งชื่อผลลัพธ์ จากนั้นเอาผลนั้นมา Query ต่อ
WITH payment_summary AS
(
    SELECT
        loan_id,
        SUM(principal_paid) AS total_principal_paid
    FROM payments
    GROUP BY loan_id
),

-- Test create cte Coomon table expression
outstanding_payment AS (
	SELECT
		l.loan_id,
        -- คำนวณยอดคงเหลือ: เงินต้น - ยอดที่จ่ายไปแล้ว (ถ้ายังไม่เคยจ่ายให้ถือเป็น 0)
        l.principal - COALESCE(ps.total_principal_paid, 0) AS outstanding_principal
	FROM loans l

	LEFT JOIN payment_summary ps
	ON l.loan_id = ps.loan_id
)


-- Test show 2 CTE
SELECT 
	m.member_no,
	m.full_name,
	l.principal AS originl_pricnipal, -- Find by table
	COALESCE (ps.total_principal_paid, 0) AS total_principal_paid, -- Find by CTE 1
	op.outstanding_principal -- Find by CTE 2
FROM members m
JOIN loans l 
    ON m.member_id = l.member_id
LEFT JOIN payment_summary ps 
    ON l.loan_id = ps.loan_id
LEFT JOIN outstanding_payment op 
    ON l.loan_id = op.loan_id
ORDER BY total_principal_paid DESC;
	


