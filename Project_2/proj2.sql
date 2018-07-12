--Q1:

drop type if exists RoomRecord cascade;
create type RoomRecord as (valid_room_number integer, bigger_room_number integer);

create or replace function Q1(course_id integer)
    returns RoomRecord
as 
$$
  DECLARE result RoomRecord;
  BEGIN
    IF course_id NOT IN(
      SELECT course
      FROM course_enrolments
    ) 
    THEN
    RAISE EXCEPTION 'INVALID COURSEID';
    END IF;
    -- check if course_id is invalid, if so, raise error

    SELECT COUNT(id) INTO result.valid_room_number
    FROM rooms
    WHERE capacity IS NOT NULL
    AND
    capacity >= (
      SELECT COUNT(student) 
      FROM course_enrolments
      WHERE course = course_id
    );
    -- count rooms within the number of enrolled students, null capacity excepted
    
    SELECT COUNT(id) INTO result.bigger_room_number
    FROM rooms
    WHERE capacity IS NOT NULL
    AND
    capacity >= ((
      SELECT COUNT(student) 
      FROM course_enrolments
      WHERE course = course_id
    )
    + (
      SELECT COUNT(student) 
      FROM course_enrolment_waitlist
      WHERE course = course_id
    ));
    -- count rooms within the number of enrolled students and waitlist students, null capacity excepted

    RETURN result;
  END;

$$ language plpgsql;

--Q2:

drop type if exists TeachingRecord cascade;
create type TeachingRecord as (cid integer, term char(4), code char(8), name text, uoc integer, average_mark integer, highest_mark integer, median_mark integer, totalEnrols integer);

create or replace function median (a integer[]) 
returns float as
$median$ 
  DECLARE     
    result float; 
  BEGIN    
    SELECT (CASE WHEN cardinality(a)%2=0 and cardinality(a)>1 THEN 
           (a[(cardinality(a)/2)] + a[((cardinality(a)/2)+1)])/2::float   
           ELSE a[(cardinality(a)+1)/2]::float END) INTO result;    
    RETURN result; 
  END;    
$median$ language plpgsql;
-- create a function to calculate the median, use cardinality to determine the position of median, then extract it

create or replace function Q2(staff_id integer)
	returns setof TeachingRecord
as 
$$
  DECLARE result TeachingRecord;
  BEGIN
    IF staff_id NOT IN(
      SELECT staff
      FROM course_staff
    )
    THEN
    RAISE EXCEPTION 'INVALID STAFFID';
    END IF;
    -- check if staff_id is invalid, if so, raise error

    FOR result IN
      SELECT DISTINCT course_staff.course, right(semesters.year || lower(semesters.term),4), subjects.code, subjects.name, subjects.uoc, 
      ROUND(AVG(course_enrolments.mark)), MAX(course_enrolments.mark), ROUND(MEDIAN(course_enrolments.mark)), COUNT(course_enrolments.student)
      FROM course_staff, courses, semesters, subjects, course_enrolments
      WHERE course_staff.staff = staff_id
      AND courses.id = course_staff.course
      AND semesters.id = courses.semester
      AND subjects.id = courses.subject
      AND course_enrolments.course = courses.id
      AND course_enrolments.mark IS NOT NULL
      GROUP BY course_staff.course, semesters.year, semesters.term, subjects.code, subjects.name, subjects.uoc
      ORDER BY course_staff.course
    LOOP
      RETURN NEXT result;
    END LOOP;
  RETURN;
  END;

$$ language plpgsql;
-- using loop to select all of this staff's courses, null mark excepted
-- then use right to select rightmost 4 digits(year and semeseter), round all mark into integers

--Q3:

drop type if exists SeparatedRecord cascade;
create type SeparatedRecord as (unswid integer, student_name text, subjects_code text, subjects_name text, semesters_name text, 
orgunits_name text, course_enrolments_mark integer, course_id integer ,number_of_row integer);
-- this type only used in q3_1, it is the separated course records

drop type if exists CourseRecord cascade;
create type CourseRecord as (unswid integer, student_name text, course_records text);

create or replace function Q3_0(org_id integer)
  returns TABLE(all_org_id INTEGER)
as 
$$
  BEGIN
  RETURN QUERY WITH RECURSIVE all_org_id(member) 
  as(
    SELECT a.member
    FROM orgunit_groups a
    WHERE owner = org_id
    AND a.member != a.owner
    UNION ALL
      SELECT b.member
      FROM orgunit_groups b
      INNER JOIN all_org_id ON all_org_id.member = b.owner
  )
  SELECT member
  FROM all_org_id
  UNION
  SELECT org_id;
  -- union means including parents node
  END;
$$ language plpgsql;
-- q3_0 using recursion to check all org_id which owner is given org_id, then recursively check children nodes


create or replace function Q3_1(org_id integer)
  returns setof SeparatedRecord
as 
$$
  DECLARE rawrecord SeparatedRecord;
  BEGIN
  FOR rawrecord IN
    SELECT people.unswid, people.name, subjects.code, subjects.name, semesters.name, orgunits.name, course_enrolments.mark, courses.id,
    ROW_NUMBER() OVER (partition by people.unswid ORDER BY course_enrolments.mark DESC NULLS LAST, courses.id ASC)
    FROM orgunits
        JOIN subjects ON (subjects.offeredBy = orgunits.id)
        JOIN courses ON (courses.subject = subjects.id)
        JOIN semesters ON (courses.semester = semesters.id)
        JOIN course_enrolments ON (course_enrolments.course = courses.id)
        JOIN students ON (students.id = course_enrolments.student)
        JOIN people ON (people.id = students.id)
    WHERE orgunits.id IN (
      SELECT DISTINCT all_org_id
      FROM Q3_0(org_id)
    )
  LOOP
    RETURN NEXT rawrecord;
  END LOOP;
  RETURN;
  END;
$$ language plpgsql;
-- this function is to join all necessary tables to select such information of course records
-- this function arranges row number, starts from highest mark to lowest, and then reset for another person


create or replace function Q3_2(org_id integer, num_courses integer, min_score integer)
  returns setof CourseRecord
as
$$
  DECLARE result CourseRecord;
  BEGIN
    FOR result IN
      SELECT unswid, student_name
      FROM Q3_1(org_id)
      GROUP BY unswid, student_name
      HAVING COUNT(subjects_code) > num_courses
      AND MAX(course_enrolments_mark) >= min_score
      -- why using max : if student max mark no less than min_score, it should be at least one course no less than min_score
      -- otherwise, if student max mark less than min_score, proving that ALL HIS/HER MARKS less than min_score
    LOOP
      RETURN NEXT result;
    END LOOP;
  RETURN;
  END;
$$ language plpgsql;
-- this function is to select persons who satisfy such conditions


create or replace function Q3(org_id integer, num_courses integer, min_score integer)
  returns setof CourseRecord
as 
$$
  DECLARE result CourseRecord;
  BEGIN
    IF org_id NOT IN(
        SELECT id
        FROM OrgUnits
      )
      THEN
      RAISE EXCEPTION 'INVALID ORGID';
      END IF;

    FOR result IN
      SELECT Q3_2.unswid, Q3_2.student_name, CONCAT(string_agg(Q3_1.subjects_code || ', ' || Q3_1.subjects_name || ', ' || Q3_1.semesters_name || ', ' ||
      Q3_1.orgunits_name || ', ' || Q3_1.course_enrolments_mark, E'\n' ORDER BY Q3_1.course_enrolments_mark DESC NULLS LAST, Q3_1.course_id ASC), E'\n')
      FROM Q3_1(org_id), Q3_2(org_id, num_courses, min_score)
      WHERE Q3_1.unswid = Q3_2.unswid 
      AND Q3_1.number_of_row <= 5
      GROUP BY Q3_2.unswid, Q3_2.student_name
    LOOP
      RETURN NEXT result;
    END LOOP;
  RETURN;
  END;

$$ language plpgsql;
-- this function outputs result, select only 5 rows of satisfied persons, the use string agg and concat to link the records