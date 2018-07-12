-- COMP9311 18s1 Project 1 Check
--
-- MyMyUNSW Check

create or replace function
	proj1_table_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='r';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	proj1_view_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='v';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	proj1_function_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_proc
	where proname=tname;
	return (_check > 0);
end;
$$ language plpgsql;

-- proj1_check_result:
-- * determines appropriate message, based on count of
--   excess and missing tuples in user output vs expected output

create or replace function
	proj1_check_result(nexcess integer, nmissing integer) returns text
as $$
begin
	if (nexcess = 0 and nmissing = 0) then
		return 'correct';
	elsif (nexcess > 0 and nmissing = 0) then
		return 'too many result tuples';
	elsif (nexcess = 0 and nmissing > 0) then
		return 'missing result tuples';
	elsif (nexcess > 0 and nmissing > 0) then
		return 'incorrect result tuples';
	end if;
end;
$$ language plpgsql;

-- proj1_check:
-- * compares output of user view/function against expected output
-- * returns string (text message) containing analysis of results

create or replace function
	proj1_check(_type text, _name text, _res text, _query text) returns text
as $$
declare
	nexcess integer;
	nmissing integer;
	excessQ text;
	missingQ text;
begin
	if (_type = 'view' and not proj1_view_exists(_name)) then
		return 'No '||_name||' view; did it load correctly?';
	elsif (_type = 'function' and not proj1_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (not proj1_table_exists(_res)) then
		return _res||': No expected results!';
	else
		excessQ := 'select count(*) '||
			   'from (('||_query||') except '||
			   '(select * from '||_res||')) as X';
		-- raise notice 'Q: %',excessQ;
		execute excessQ into nexcess;
		missingQ := 'select count(*) '||
			    'from ((select * from '||_res||') '||
			    'except ('||_query||')) as X';
		-- raise notice 'Q: %',missingQ;
		execute missingQ into nmissing;
		return proj1_check_result(nexcess,nmissing);
	end if;
	return '???';
end;
$$ language plpgsql;

-- proj1_rescheck:
-- * compares output of user function against expected result
-- * returns string (text message) containing analysis of results

create or replace function
	proj1_rescheck(_type text, _name text, _res text, _query text) returns text
as $$
declare
	_sql text;
	_chk boolean;
begin
	if (_type = 'function' and not proj1_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (_res is null) then
		_sql := 'select ('||_query||') is null';
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	else
		_sql := 'select ('||_query||') = '||quote_literal(_res);
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	end if;
	if (_chk) then
		return 'correct';
	else
		return 'incorrect result';
	end if;
end;
$$ language plpgsql;

-- check_all:
-- * run all of the checks and return a table of results

drop type if exists TestingResult cascade;
create type TestingResult as (test text, result text);

create or replace function
	check_all() returns setof TestingResult
as $$
declare
	i int;
	testQ text;
	result text;
	out TestingResult;
	tests text[] := array['q1', 'q2', 'q3', 'q4', 'q5a', 'q5b', 'q6','q7','q8','q9','q10'];
begin
	for i in array_lower(tests,1) .. array_upper(tests,1)
	loop
		testQ := 'select check_'||tests[i]||'()';
		execute testQ into result;
		out := (tests[i],result);
		return next out;
	end loop;
	return;
end;
$$ language plpgsql;


--
-- Check functions for specific test-cases in Project 1
--

create or replace function check_q1() returns text
as $chk$
select proj1_check('view','q1','q1_expected',
                   $$select * from q1$$)
$chk$ language sql;

create or replace function check_q2() returns text
as $chk$
select proj1_check('view','q2','q2_expected',
                   $$select * from q2$$)
$chk$ language sql;

create or replace function check_q3() returns text
as $chk$
select proj1_check('view','q3','q3_expected',
                   $$select * from q3$$)
$chk$ language sql;

create or replace function check_q4() returns text
as $chk$
select proj1_check('view','q4','q4_expected',
                   $$select * from q4$$)
$chk$ language sql;

create or replace function check_q5a() returns text
as $chk$
select proj1_check('view','q5a','q5a_expected',
                   $$select * from q5a$$)
$chk$ language sql;

create or replace function check_q5b() returns text
as $chk$
select proj1_check('view','q5b','q5b_expected',
                   $$select * from q5b$$)
$chk$ language sql;

create or replace function check_q6() returns text
as $chk$
select proj1_check('function','q6','q6_expected',
                   $$select * from q6('COMP9311')$$)
$chk$ language sql;

create or replace function check_q7() returns text
as $chk$
select proj1_check('view','q7','q7_expected',
                   $$select * from q7$$)
$chk$ language sql;

create or replace function check_q8() returns text
as $chk$
select proj1_check('view','q8','q8_expected',
                   $$select * from q8$$)
$chk$ language sql;

create or replace function check_q9() returns text
as $chk$
select proj1_check('view','q9','q9_expected',
                   $$select * from q9$$)
$chk$ language sql;

create or replace function check_q10() returns text
as $chk$
select proj1_check('view','q10','q10_expected',
                   $$select * from q10$$)
$chk$ language sql;

--
-- Tables of expected results for test cases
--

drop table if exists q1_expected;
create table q1_expected (
     unswid bigint,
     name LongName
);

drop table if exists q2_expected;
create table q2_expected (
	unswid ShortString,
	name LongName
);

drop table if exists q3_expected;
create table q3_expected (
	unswid integer,
	name LongName
);

drop table if exists q4_expected;
create table q4_expected (
	unswid integer,
	name LongName
);

drop table if exists q5a_expected;
create table q5a_expected (
    num bigint
);
drop table if exists q5b_expected;
create table q5b_expected (
    num bigint
);

drop table if exists q6_expected;
create table q6_expected (
    cname text
);

drop table if exists q7_expected;
create table q7_expected (
    code char(4),
	name LongName
);

drop table if exists q8_expected;
create table q8_expected (
    code char(8),
	name MediumName,
	semester ShortName
);

drop table if exists q9_expected;
create table q9_expected (
    name LongName,
    school LongString,
    email text,
    starting date,
    num_subjects bigint
);

drop table if exists q10_expected;
create table q10_expected (
    code text,
    name LongName,
    year text,
    s1_HD_rate numeric(4,2),
    s2_HD_rate numeric(4,2)
);


COPY q1_expected (unswid, name) FROM stdin;
3286795	Richelle Matteo
3170224	Sisheng Yee
3094797	Vincent Cinelli
3255964	Janaki Ritchie
3235617	Tek Cadden
3135264	Jason Gilkeson
\.

COPY q2_expected (unswid, name) FROM stdin;
K-K17-621	Seminar Room
K-K17-113	CSE Meeting Room
\.

COPY q3_expected (unswid, name) FROM stdin;
9456812	Alan Hodgkinson
9711919	Roslyn Poulos
3192298	Niamh Stephenson
3058407	Husna Razee
3115479	Anne Bunde-Birouste
3320037	Casimir MacGregor
3208037	Anura Jayasuriya
3068974	Tun Shwe
\.

COPY q4_expected (unswid, name) FROM stdin;
3040773	Tonny Andrewartha
3058056	Wayne Salway
3028145	Ione Chew
3168474	Kim King
3172526	Janet Sutcliffe
3044547	Prashanti Oldham
3032240	Sarah Bitar
3045150	Mayuran Marzook
3144015	Ayako Kao
3092780	Monika Lilian
3095265	Graeme Lepre
3177192	Gavin Ngan
3157092	Nahm Rachel Nahye
3012907	Jordan Sayed
3012907	Jordan Sayed
3100291	Sylvie Ricci
3107434	Josephine Vial
3118604	Katie Moore
3075924	Natasha Arneman
3062680	David Lines
3062680	David Lines
3171814	Linn Szeto
3148169	Ka Kim
3131729	Yilu Zhang Ying
3173265	Michael Maclachlan
3127217	Thomas Odekerken
3171855	Maria Okuda
3103918	Heidi Kopac
3195695	Pui Mirl
3156701	Willie Nur
3165795	Carla Kamal
3188787	Priscilla Swaffield
3171566	Brigid Macks
3166740	Terence Wheate
3137680	Benny Mok
3137680	Benny Mok
3137680	Benny Mok
3173772	Fouad Moreira
3139456	Minna Henry-May
3139774	Catherine Borzycki
3124015	Shudo Suzuki Cheung
3119903	Syarief Skurnik
3197893	Indhuja Thieviasingham
3127022	Charles Longhitano
3187681	Hai Jugueta
3108938	Mazhar Aliani
3108938	Mazhar Aliani
3122796	Kenneth Mow
3194736	Ilana Wainer
3171666	Kedkanok Sivakriskul
3198807	Ralph Vitek
3128290	Nathan Asplet
3109365	Rachael Meguerditchian
3191768	Alastair Thackray
3192680	Luke De Luca
3192680	Luke De Luca
3192680	Luke De Luca
3152664	Alan Yang Bing
3129900	Veronica Kirkhope
3112493	James Kwan
3112493	James Kwan
3121108	Gaby Abery
3115451	Wainer Yashpal
3134196	Samara Eslake
3126962	Fang Ye
3167164	Masao Chin
3154824	Geoffrey Verbeek-Martin
3166948	Zara Israel
3279369	Huiyu Deng Jing
3278476	Lynelle Bargon
3279180	Samah Sathanapally
3248314	Beini Or
3239253	Manorat Phongpool
3221574	Ryan Blagg
3238680	Stacey Acosta
3207781	Ngai Ou Yang
3299389	Simon Lao
3274927	Colin Kiss
3217643	Fleur Touzell
3205879	Oliver Raghav
3210209	Hal Wehr
3221026	Patrick Gahan
3237661	Arul Raizada
3282610	Elisa Labrador
3285781	Nicole Datta
3219452	Gary Karakaidos
3254882	Archana Dickison
3212703	Iskandar Suthanaya
3268383	Farida Polamerasetti
3234315	Ta Kong
3253302	Andrew Champness
3265660	John Raynsford
3255084	Yoke Tan Mustafa
3202405	Kristina Sade
3204779	Shahzeb Sajjad
3242345	Vanessa Geale
3202875	Glen Ozanne
3283571	Wayne Lo
3281562	Kevin Becker
3284948	Seng Ahmad Zaidi
3284948	Seng Ahmad Zaidi
3275343	Wee Foo
3206628	Steffi Petznick
3284350	Erik Treccase
3233164	Noel Taylor
3280943	Tee Abdul Hamid
3203653	Gary Apostle
3200931	Susanne Jabour
3234228	Glen Mounjed
3254031	Hong Nguyen Van
3250242	Nga To
3279389	Kyung-Chuel Sun
3239830	Mile Ralph
3215509	Sehyun Moy
3250244	Aamon Govinden
3208768	Mi Feng Xiaohong
3298588	Faith Linz
3247722	Catherine Biggs
3292187	Yui Sim
3201057	Hiu Ouyang
3224643	Yueming Chow
3202725	Sally Kirkhope
3202725	Sally Kirkhope
3296302	Nirutchara Lothienpratan
3234937	Louisa Bajric
3214758	Shuyuan Bin
3278837	Zhen You Lixin
3233283	Kirsty Everest
3210808	Philip Chua
3230042	Fiona Ogden
3220744	Karn Sitthiosoth
3203412	Karen Pithers
3231598	Sarah-Jane Quick
3231598	Sarah-Jane Quick
3210782	Peter Dibianco
3259108	Stanley Klement
3250224	Michael Silva
3257694	Nicholas Woerner
3243180	Michael Kemper
3261580	Tarryn Edmonstone
3261145	Monica Scott
3242505	Elizabeth Petty
3216120	Matthew Preswick
3218107	Cathy Calligeris
3254643	Brenton Levee
3293636	Ruvan Towns
3262901	James Guild
3208494	Raena Bellamy
3226665	Xin Loh
3285717	Izumi Yamaka
3210563	Michael Eddy
3229678	Chelsea Rahal
3274852	Fergus Nettlefold
3290193	Simon Mesa
3295382	Roy Solano
3201489	Marco Murr
3272701	Ann Upton
3232156	Kyle Sese
3214627	Shabnah Kumaran
3284662	William Ellwood
3220741	Kathleen Meere
3251266	Kelsi Majumdar
3270049	Brooke Kwai
3209070	Anthony Amos
3260028	Duc Bradd
3295438	Wan Lowe
3282682	Chennu Chen Jing
3201915	Kim Psathas
3227815	Claudia Frigerio
3281646	Lara Shum
3211634	Immelda Indriawati
3207247	Terri Hackett
3243054	Lian Moh
3252201	Christopher Kretschmer
3216011	Daniel Natan
3378028	Ulrich Guo
3219354	Jonathan Cordova
3200368	Joel Murray-Quist
3309123	Sophia Gabagat
3353934	Ellen Goncales
3313062	Ryan Cannon-Brookes
3391466	One Zhou
3380834	Bae Dae Soon
3380834	Bae Dae Soon
3305763	Ziauddin Zaunders
3220904	Carly-Maree Toumazou
3218715	Kuei Chuang
3391048	Antonina Govindasamy
3227471	Jeffrey Luck
3367897	Ian Cliff
3250934	Sweet Hannah Soo-Hyun
3318711	Chee Kuruneru
3363270	Wadih Polon
3306980	David Yaw
3343820	Owen Koppler
3347113	Sujata Massing
3329968	Grace Shu
3394553	Meagan Du Brule
3329123	Samareh Vatanpour
3352879	Zhong Phooi
3351736	Anthony Arkapaw
3325081	Valerie Deck
3310106	Pritham Azhar
3392978	Atsumi Konda
3354501	Christopher Gabbedy
3324041	Quang Kouck
3337393	William Hellenpach
3363921	Timothy Cappie-Wood
3317938	Gabriel France
3354517	Lynne Hills
3376747	Ling Chiu
3397556	Monique Cheong
3329763	Michael D'Agostino
3339142	Huaying Lou
3324243	Hilary Ashley
3364227	Ho Nodjoumi
3364227	Ho Nodjoumi
3316342	Rachel Shaltry
3301742	Nattallee Kakwani
3318076	Peter Giammaria
3336604	Sanip Chitrakar
3336604	Sanip Chitrakar
3329892	Yudishtiran Vivekanandarajah
3362832	Saurabh Gomez
3381748	Linda Supratiknjo
3369208	Christine Farhart
3345867	Tung-Ching Tu
3380320	Jeffrey Favero
3380320	Jeffrey Favero
3375688	Courtney Ogilvie-Robertson
3320447	Susannah Jones
3390315	Pasquale Button
3383255	Sharon Lechowicz
3395395	Vivian Lofaro
3390293	Nguyen Nguyen-Tran
3341618	Ky Huan
3378806	Sally Maunsell
3373065	Stephan Yaghlejian
3344408	Zhi Tao Yi
3338080	Nongnuch Leelalertwong
3354560	Miranda Delshad
3337324	Alice Dix
3315198	Robert Budnik
3384317	Hiroe Takizawa
3386070	Bai Gu Yun
3303985	Yuecen Sa
3303985	Yuecen Sa
3397737	Roy Andoyo
3436225	Kar-Kent Mohamad Ayob
3376609	Allan Tisdell
3401745	Yuchen Zan
\.

COPY q5a_expected (num) FROM stdin;
76
\.

COPY q5b_expected (num) FROM stdin;
213
\.


-- select * from q6(COMP9311);
COPY q6_expected (cname) FROM stdin;
COMP9311 Database Systems 6
\.

COPY q7_expected (code, name) FROM stdin;
2805	Paediatrics
2460	Biochem & Molecular Genetics
3040	Chemical Engineering
1297	Criminology
2651	Civil Engineering
1545	Actuarial Studies
8415	Professional Accounting (Ext)
8350	Business Administration
1550	Marketing
6394	Computer Science and Engineering
8291	Public Relations & Advertising
8229	Arts (Extension)
9304	Design
1001	Cotutelle
2010	Chemical Engineering
8161	Financial Mathematics
1082	Oceanography
1743	Doctor Information Technology
8039	Biopharmaceuticals
1999	PhD Research (Science)
3640	Electrical Engineering
2655	Photovoltaic Engineering
2265	Art Theory
8655	Petroleum Engineering
3045	Petroleum Engineering
1010	Chemical Engineering
3644	Photonic Engineering
8417	Commerce (Extension)
8417	Commerce (Extension)
3040	Chemical Engineering
8132	Sustainable Development
8411	Actuarial Studies
8684	Information Technology
1860	Optometry
3045	Petroleum Engineering
8404	Commerce
5448	Telecommunications
6001	Study Abroad Program
8033	Food Science and Technology
8682	Computing and Information Tech
1631	Civil Engineering
2180	Mining Engineering
1655	Photovoltaic Engineering
8124	Const Project Mgt in Prof Prac
1321	International & Pol. Studies
9046	Public Health (Extn)
8715	Engineering Materials
1535	Taxation and Business Law
5020	Food Technology
9305	Design
2691	Mechanical Engineering
8034	Food Science & Tech (Extn)
8680	Computer Science
7341	Petroleum Engineering
1665	Safety Science
2036	Biotechnology
1681	Surveying & Spatial Info Sys
2655	Photovoltaic Engineering
1208	Linguistics
3563	Psychology
8404	Commerce
2150	Chemical Engineering
3642	Photovoltaics & Solar Energy
3625	Environmental Engineering
8129	Building Construction Mgt Prog
8665	Biomedical Engineering
1203	Southeast Asian Social Inquiry
1532	Strategy and Entrepreneurship
8425	Accounting/Business Info Tech
8409	Professional Accounting
8142	Architecture
7312	Forensic Mental Health
8508	Information Science
9308	Digital Media
2485	Biological Science
8652	Spatial Information
6555	Foundation Studies
8416	Actuarial Studies (Extension)
4058	Economics / Education
8007	Technology & Innovation Mgmt
8760	Graduate Optometry
1541	Economics and Management
3135	Materials Science and Eng
3065	Food Science
2692	Mechanical & Manufacturing Eng
2354	Education
3625	Environmental Engineering
8501	Electrical Engineering
1885	Computer Science
3643	Telecommunications
8902	Health Management (Ext)
8503	Telecommunications
2910	Chemistry
1017	Petroleum Engineering
1050	Mining Engineering
8125	Construction Management
1655	Photovoltaic Engineering
1812	Surgery (St George Clin Schl)
5523	Optometry
8539	Engineering Science (Ext)
3640	Electrical Engineering
1661	Mechanical Engineering
3642	Photovoltaics & Solar Energy
8708	Chemical Analysis & Lab Mngt
8425	Accounting/Business Info Tech
1643	Electrical Engineering
2675	Biomedical Engineering
8224	Combined Arts/Social Sciences
9311	Design
8761	Community Eye Health
2925	Computer Science
8660	Biomedical Engineering
1871	Chemistry
8607	Engineering
8224	Combined Arts/Social Sciences
1799	PhD Research (Law)
8941	Health Services Management
5665	Optometry
2875	Surgery (POW Clinical School)
8131	Urban Development and Design
1031	Food Science and Technology
2031	Food Science and Technology
8543	Information Technology
6007	Practicum Exchange Program
1299	PhD Research (Arts & Soc Sc)
2663	Electrical Engineering
2900	Optometry
8751	Biostatistics
4916	Commerce / Int Studies
8718	Mathematics
5452	Computer Science
7311	Design
1870	Chemistry
8621	Engineering
8538	Engineering Science
2721	Surveying & Spatial Info Sys
\.

COPY q8_expected (code, name, semester) FROM stdin;
PHYS2030	Laboratory A	Sem1 2011
\.

COPY q9_expected (name, school, email, starting, num_subjects) FROM stdin;
Robert Burford	School of Chemical Engineering	r.burford@unsw.edu.au	2001-01-01	18
David Lovell	School of Humanities and Social Sciences (ADFA)	d.lovell@adfa.edu.au	2010-03-19	97
Christopher Rizos	School of Surveying and Spatial Information Systems	c.rizos@UNSW.EDU.AU	2001-01-01	13
Roger Read	School of Risk & Safety Science	r.read@UNSW.EDU.AU	2001-01-01	7
Philip Mitchell	School of Psychiatry	phil.mitchell@unsw.edu.au	2010-03-05	1
Stephen Foster	School of Civil and Environmental Engineering	S.Foster@unsw.edu.au	2013-05-08	13
Sylvia Ross	School of Art - COFA	Sylvia.Ross@unsw.edu.au	2001-01-01	6
Richard Corkish	School of Photovoltaic and Renewable Engineering	r.corkish@UNSW.EDU.AU	2010-03-05	2
Richard Newbury	School of Physics	r.newbury@unsw.edu.au	2001-01-01	22
Bruce Henry	School of Mathematics & Statistics	b.henry@UNSW.EDU.AU	2013-04-10	7
Warrick Lawson	School of Physical, Environmental and Mathematical Sciences (ADFA)	w.lawson@adfa.edu.au	2011-09-06	11
Kim Snepvangers	School of Art History & Art Education - COFA	k.snepvangers@unsw.edu.au	2010-03-05	20
Fiona Stapleton	School of Optometry and Vision Science	f.stapleton@unsw.edu.au	2001-01-01	6
Maurice Pagnucco	School of Computer Science and Engineering	morri@cse.unsw.edu.au	2010-07-15	8
Barbara Messerle	School of Chemistry	b.messerle@unsw.edu.au	2010-03-05	9
Anne Simmons	School of Mechanical and Manufacturing Engineering	a.simmons@unsw.edu.au	2011-10-10	11
Eliathamby Ambikairajah	School of Electrical Engineering & Telecommunications	ambi@ee.unsw.edu.au	2001-01-01	10
Denise Doiron	School of Economics	D.Doiron@unsw.edu.au	2013-02-25	9
Jerry Parwada	School of Banking and Finance	j.parwada@unsw.edu.au	2011-09-19	7
Elanor Huntington	School of Engineering and Information Technology (ADFA)	e.huntington@adfa.edu.au	2011-02-28	7
John Whitelock	Graduate School of Biomedical Engineering	j.whitelock@unsw.edu.au	2011-10-10	8
Johann Murmann	School of Strategy and Entrepreneurship	peter.murmann@agsm.edu.au	2001-01-01	1
Chandini MacIntyre	School of Public Health & Community Medicine	r.macintyre@unsw.edu.au	2001-01-01	2
Christine Davison	School of Education	c.davison@unsw.edu.au	2001-01-01	8
Andrew Schultz	School of the Arts and Media	a.schultz@unsw.edu.au	2010-03-05	3
Patrick Finnegan	School of Information Systems, Technology and Management	p.finnegan@unsw.edu.au	2011-09-27	4
Simon Killcross	School of Psychology	s.killcross@unsw.edu.au	2001-01-01	4
James Lee	School of International Studies	z3134548@unsw.edu.au	2013-03-18	8
Val Pinczewski	School of Petroleum Engineering	v.pinczewski@unsw.edu.au	2010-03-05	14
Peter Roebuck	School of Accounting	z8500014@unsw.edu.au	2011-03-07	2
Christopher Taylor	Australian School of Taxation and Business Law	c.taylor@unsw.edu.au	2011-03-07	10
Bruce Hebblewhite	School of Mining Engineering	b.hebblewhite@unsw.edu.au	2010-03-05	12
David Cohen	School of Biological, Earth and Environmental Sciences	d.cohen@unsw.edu.au	2010-03-05	13
Caleb Kelly	School of Media Arts	caleb.kelly@unsw.edu.au	2013-04-15	1
\.

COPY q10_expected (code,name,year,s1_HD_rate,s2_HD_rate) FROM stdin;
COMP9311	Database Systems	03	0.44	0.38
COMP9311	Database Systems	04	0.33	0.11
COMP9311	Database Systems	05	0.00	0.00
COMP9311	Database Systems	06	0.17	0.22
COMP9311	Database Systems	07	0.14	0.33
COMP9311	Database Systems	08	0.13	0.15
COMP9311	Database Systems	09	0.32	0.05
COMP9311	Database Systems	10	0.09	0.26
COMP9311	Database Systems	11	0.11	0.06
COMP9311	Database Systems	12	0.06	0.11
COMP9331	Computer Networks&Applications	03	0.20	0.17
COMP9331	Computer Networks&Applications	04	0.00	0.29
COMP9331	Computer Networks&Applications	05	0.00	0.00
COMP9331	Computer Networks&Applications	06	0.00	0.00
COMP9331	Computer Networks&Applications	07	0.00	0.14
COMP9331	Computer Networks&Applications	08	0.00	0.17
COMP9331	Computer Networks&Applications	09	0.20	0.15
COMP9331	Computer Networks&Applications	10	0.00	0.05
COMP9331	Computer Networks&Applications	11	0.00	0.25
COMP9331	Computer Networks&Applications	12	0.04	0.04
\.
