-- Insert data to table
INSERT INTO members
(member_no, full_name, department, join_date)
VALUES
--('M001', 'Somchai Jaidee', 'Information Technology', '2026-01-10'),
--('M002', 'Suda Meesuk', 'Finance', '2026-02-15'),
--('M003', 'Anan Wongdee', 'Administration', '2026-03-20');
('M004', 'Sathit Jitbumrung', 'Tutot', '12-09-20')

-- Read all data on table
SELECT * FROM members;

-- Read data by 'member_no'
SELECT * FROM members
WHERE member_no = 'M001'

-- Update 'full_name' data on table
UPDATE members
SET full_name = 'Chaiyaphat Panthong'
WHERE member_no = 'M001';

-- Delte data on table by member_no
