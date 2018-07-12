-- Q1: 
create or replace view Q1_1(unswid, name)
as
SELECT unswid, name
FROM people
WHERE id IN (
	SELECT student 
	FROM course_enrolments 
	WHERE mark >=85
	GROUP BY student
	HAVING count(*) >20
);
-- Q1_1 seeks for the students who got at least 85 marks in more than 20 courses, foreign key is unswid

create or replace view Q1_2(unswid, name)
as
SELECT unswid, name
FROM people
WHERE id IN (
	SELECT id
	FROM students
	WHERE stype = 'intl'
);
-- Q1_2 seeks for the international students, foreign key is unswid

create or replace view Q1(unswid, name)
as
SELECT unswid, name
FROM Q1_1
WHERE unswid IN (
	SELECT unswid
	FROM Q1_2
);
-- Q1 seeks for the intersection of Q1_1 and Q1_2

-- Q2: 
create or replace view Q2_1(unswid, longname, building, rtype)
as
SELECT unswid, longname, building, rtype
FROM rooms
WHERE capacity >= 20;
-- Q2_1 seeks for the rooms capacity no less than 20, foregin key is unswid

create or replace view Q2_2(unswid, longname, rtype)
as
SELECT unswid, longname, rtype
FROM Q2_1
WHERE building = (
	SELECT id from buildings
	WHERE name = 'Computer Science Building'
);
-- Q2_2 seeks for the rooms belong to CSE, foregin key is unswid

create or replace view Q2(unswid, longname)
as
SELECT unswid,longname
FROM Q2_2
WHERE rtype = (
	SELECT id from room_types
	WHERE description = 'Meeting Room'
);
-- Q2 seeks for the intersection of Q2_1 and Q2_2, and the description

-- Q3: 
create or replace view Q3_1(course)
as
SELECT course 
FROM course_enrolments
WHERE student = (
	SELECT id
	FROM people
	WHERE name =  'Stefan Bilek'
);
-- Q3_1 seeks for course this student enrolled

create or replace view Q3(unswid, name)
as
SELECT unswid, name 
FROM people
WHERE id IN (
	SELECT staff
	FROM Course_staff
	WHERE course IN (
		SELECT course
		FROM Q3_1
	)
);
-- Q3 seeks for the staff, from the course id which Q3_1 provides

-- Q4: 
create or replace view Q4_1(student)
as
SELECT student 
FROM Course_enrolments
WHERE course IN (
	SELECT id
	FROM Courses
	WHERE subject IN (
		SELECT id
		FROM Subjects
		WHERE code = 'COMP3331'
	)
);
-- Q4_1 seeks for the students enrolled in COMP3331

create or replace view Q4_2(student)
as
SELECT student 
FROM Course_enrolments
WHERE course IN (
	SELECT id
	FROM Courses
	WHERE subject IN (
		SELECT id
		FROM Subjects
		WHERE code = 'COMP3231'
	)
);
-- Q4_2 seeks for the students enrolled in COMP3231

create or replace view Q4_3(student)
as
SELECT student    
FROM Q4_1 
INTERSECT  
SELECT student   
FROM Q4_2;
-- Q4_3 seeks for the students both enrolled in COMP3331 and COMP3231

create or replace view Q4(unswid, name)
as
SELECT unswid, name    
FROM people
WHERE id IN (
	SELECT student
	FROM Q4_1
	WHERE student
	NOT IN(
		SELECT student
		FROM Q4_3
	)
);
-- Q4 seeks for the students enrolled in COMP3331 but not enrolled in both

-- Q5a: 
create or replace view Q5a_1(student)
as
SELECT student
FROM Program_enrolments
WHERE id IN(
	SELECT partOf
	FROM Stream_enrolments
	WHERE stream IN(
		SELECT id
		FROM Streams
		WHERE name = 'Chemistry'
		)
	)
AND
semester =(
	SELECT id
	FROM semesters
	WHERE name = 'Sem1 2011'
);
-- Q5a_1 seeks for the students enrolled in 11S1, stream is chemistry

create or replace view Q5a_2(id)
as
SELECT id
FROM Students
WHERE stype = 'local';
-- Q5a_2 seeks for all local students

create or replace view Q5a(num)
as
SELECT count(DISTINCT student)
FROM Q5a_1
WHERE student IN(
	SELECT id
	FROM Q5a_2
);
-- Q5a seeks for all local students in Q5a_1

-- Q5b: 
create or replace view Q5b_1(student)
as
SELECT student
FROM Program_enrolments
WHERE program IN(
	SELECT id
	FROM Programs
	WHERE offeredBy = (
		SELECT id
		FROM OrgUnits
		WHERE name = 'Computer Science and Engineering, School of'
		)
	)
AND
semester =(
	SELECT id
	FROM semesters
	WHERE name = 'Sem1 2011'
);
-- Q5b_1 seeks for the students enrolled in 11S1, program offered by CSE

create or replace view Q5b_2(id)
as
SELECT id
FROM Students
WHERE stype = 'intl';
-- Q5b_2 seeks for all international students

create or replace view Q5b(num)
as
SELECT COUNT(DISTINCT student)
FROM Q5b_1
WHERE student IN(
	SELECT id
	FROM Q5b_2
);
-- Q5b seeks for all international students in Q5b_1

-- Q6: 
create or replace function
	Q6(code_no text) returns text
as
$$
	SELECT concat(code,' ',name,' ',uoc)
	FROM Subjects 
	WHERE code = code_no

$$ language sql;
-- Q6 defined a function input code returns code, name and uoc, use concat to add the blank

-- Q7: 
create or replace view Q7_1(program, total_student)
as
SELECT program, CAST(COUNT(student) AS DECIMAL(10,3))
FROM Program_enrolments
GROUP BY program;
-- Q7_1 seeks for the total students of each program, decimal used to change the int type to decimal type for division
-- IF NOT USE DECIMAL, the answer will be interger 0 or 1, cannot be displayed as percent 

create or replace view Q7_2(program, intl_student)
as
SELECT program, CAST(COUNT(student) AS DECIMAL(10,3))
FROM Program_enrolments
WHERE student IN(
	SELECT id
	FROM Students
	WHERE stype = 'intl'
)
GROUP BY program;
-- Q7_2 seeks for the intl students of each program, decimal used to change the int type to decimal type for division
-- IF NOT USE DECIMAL, the answer will be interger 0 or 1, cannot be displayed as percent 

create or replace view Q7_3(program, ratio)
as
SELECT Q7_1.program, Q7_2.intl_student / Q7_1.total_student
FROM Q7_1, Q7_2
WHERE Q7_1.program = Q7_2.program;
-- Q7_3 makes the division of intl student ratio

create or replace view Q7(code, name)
as
SELECT code, name
FROM Programs
WHERE id IN(
	SELECT program
	FROM Q7_3
	WHERE ratio > 0.5
);
-- Q7 seeks for the programs ratio more than 50 percent

-- Q8: 
create or replace view Q8_1(course, avg_mark)
as
SELECT course, AVG(mark)
FROM course_enrolments
WHERE mark IS NOT NULL
GROUP BY course
HAVING COUNT(mark IS NOT NULL) >= 15;
-- Q8_1 seeks for the average mark of each courses if they have at least 15 no null marks, and null mark will not be calculated

create or replace view Q8_2(max_avg_mark)
as
SELECT MAX(avg_mark)
FROM Q8_1;
-- Q8_2 calculates the maximum average mark

create or replace view Q8_3(course, max_avg_mark)
as
SELECT Q8_1.course, Q8_2.max_avg_mark
FROM Q8_1, Q8_2
WHERE Q8_1.avg_mark = Q8_2.max_avg_mark;
-- Q8_3 seeks for which course have its average mark equals to max average mark

create or replace view Q8(code, name, semester)
as
SELECT Subjects.code, Subjects.name, Semesters.name
FROM Subjects, Semesters, Courses, Q8_3
WHERE Subjects.id = Courses.subject
AND
Courses.id = Q8_3.course
AND
Semesters.id = Courses.semester;
-- Q8 displays the code, name and semester of this course

-- Q9: 
create or replace view Q9_1(staff, orgunit, starting)
as
SELECT staff, orgunit, starting
FROM Affiliations
WHERE role = (
	SELECT id 
	FROM staff_roles 
	WHERE name = 'Head of School')
	AND
	isprimary = 't'
	AND
	ending IS NULL
	AND
	orgunit IN(
	SELECT id
	FROM Orgunits
	WHERE utype = (
		SELECT id
		FROM Orgunit_types
		WHERE name = 'School'
	)
);
-- Q9_1 seeks for the heads of school who satisfy the four requirements, staff id is foreign key

create or replace view Q9_2(id, name, email, school)
as
SELECT People.id, people.name, people.email, Orgunits.longname
FROM Q9_1, People, Orgunits
WHERE People.id = Q9_1.staff
AND Orgunits.id = Q9_1.orgunit;
-- Q9_2 displays the heads of school information, id is foreign key

create or replace view Q9_3(staff, num_subjects)
as
SELECT Course_staff.staff, COUNT(DISTINCT Subjects.code)
FROM Course_staff, Subjects, Courses, Q9_1
WHERE Subjects.id = Courses.subject
AND
Courses.id = Course_staff.course
AND
Course_staff.staff = Q9_1.staff
GROUP BY Course_staff.staff
HAVING COUNT(DISTINCT Subjects.code) >= 1;
-- Q9_3 seeks for those heads of school who taught and least 1 subject

create or replace view Q9(name, school, email, starting, num_subjects)
as
SELECT Q9_2.name, Q9_2.school, Q9_2.email, Q9_1.starting, Q9_3.num_subjects
FROM Q9_1, Q9_2, Q9_3
WHERE Q9_1.staff = Q9_2.id
AND Q9_1.staff = Q9_3.staff
AND Q9_2.id = Q9_3.staff;
-- Q9 displays the information

-- Q10: 
create or replace view Q10_0(sem_id, year, term)
as
SELECT id, year, term
FROM Semesters
WHERE year BETWEEN 2003 AND 2012
AND
(term = 'S1' OR term = 'S2');
-- Q10_0 seeks the main terms of 2003 to 2012 

create or replace view Q10_1(code, name, id)
as
SELECT code, name, id
FROM Subjects
WHERE code LIKE 'COMP93%'
AND
id IN(
	SELECT subject
	FROM Courses
	WHERE semester IN(
		SELECT sem_id
		FROM Q10_0
	)
	GROUP BY subject
	HAVING COUNT(semester) >= 20
);
-- Q10_1 seeks the subjects provided in all period of Q10_0 

create or replace view Q10_2(id, year, term, num_of_HD)
as
SELECT Q10_1.id, Semesters.year, Semesters.term, COUNT(Course_enrolments.mark)
FROM Q10_0, Q10_1, Courses, Course_enrolments, Semesters
WHERE Course_enrolments.course = Courses.ID
AND
Courses.subject = Q10_1.id
AND
Courses.semester = Q10_0.sem_id
AND
Semesters.id = Courses.semester
GROUP BY Q10_1.id, Semesters.year, Semesters.term, Course_enrolments.mark
HAVING Course_enrolments.mark < 85;
-- Q10_2 seeks for the HD count of each subject in each term each year
-- NOTE: IF SEEKS FOR MARK NO LESS THAN 85, some subjects have no HD marks, which will result in LOSE RECORD(LOSE ROWS)

create or replace view Q10_3(id, year, term, num_of_HD)
as
SELECT Q10_2.id, Q10_2.year, Q10_2.term, SUM(Q10_2.num_of_HD)
FROM Q10_2
GROUP BY Q10_2.id, Q10_2.year, Q10_2.term
ORDER BY Q10_2.year, Q10_2.term;
-- Q10_3 sums up HD count of each subject in each term and year, because Q10_2's result is separated by course id

create or replace view Q10_4(id, year, term, num_of_marks)
as
SELECT Q10_1.id, Semesters.year, Semesters.term, COUNT(Course_enrolments.mark)
FROM Q10_0, Q10_1, Courses, Course_enrolments, Semesters
WHERE Course_enrolments.course = Courses.ID
AND
Courses.subject = Q10_1.id
AND
Courses.semester = Q10_0.sem_id
AND
Semesters.id = Courses.semester
GROUP BY Q10_1.id, Semesters.year, Semesters.term, Course_enrolments.mark
HAVING Course_enrolments.mark IS NOT NULL;
-- Q10_4 seeks for the count of valid marks of each subject in each term each year

create or replace view Q10_5(id, year, term, num_of_marks)
as
SELECT Q10_4.id, Q10_4.year, Q10_4.term, SUM(Q10_4.num_of_marks)
FROM Q10_4
GROUP BY Q10_4.id, Q10_4.year, Q10_4.term
ORDER BY Q10_4.year, Q10_4.term;
-- Q10_5 sums up valid marks count of each subject in each term and year, because Q10_4's result is separated by course id

create or replace view Q10_6(id, year, term, S1_ratio)
as
SELECT Q10_5.id, Q10_5.year, Q10_5.term, 1 - Q10_3.num_of_HD / Q10_5.num_of_marks
FROM Q10_3, Q10_5
WHERE Q10_3.id = Q10_5.id
AND
Q10_3.year = Q10_5.year
AND
Q10_3.term = Q10_5.term
AND
Q10_5.term = 'S1'
ORDER BY Q10_5.id, Q10_5.year, Q10_5.term;
-- Q10_6 calculates the ratio of HD rates in S1, using 1 minus the no HD rate

create or replace view Q10_7(id, year, term, S2_ratio)
as
SELECT Q10_5.id, Q10_5.year, Q10_5.term, 1 - Q10_3.num_of_HD / Q10_5.num_of_marks
FROM Q10_3, Q10_5
WHERE Q10_3.id = Q10_5.id
AND
Q10_3.year = Q10_5.year
AND
Q10_3.term = Q10_5.term
AND
Q10_5.term = 'S2'
ORDER BY Q10_5.id, Q10_5.year, Q10_5.term;
-- Q10_7 calculates the ratio of HD rates in S2, using 1 minus the no HD rate

create or replace view Q10(code, name, year, s1_HD_rate, s2_HD_rate)
as
SELECT Q10_1.code, Q10_1.name, SUBSTR(CAST(Q10_6.year AS CHAR(4)), 3, 2), CAST(Q10_6.S1_ratio AS NUMERIC(4,2)), CAST(Q10_7.S2_ratio AS NUMERIC(4,2))
FROM Q10_1, Q10_6, Q10_7
WHERE Q10_1.id = Q10_6.id
AND
Q10_6.id = Q10_7.id
AND
Q10_6.year = Q10_7.year
ORDER BY Q10_1.code, Q10_6.year;
-- Q10 displays all information, using substar to cut the year into 2-digit, using numeric to cut the ratio into 2-digit