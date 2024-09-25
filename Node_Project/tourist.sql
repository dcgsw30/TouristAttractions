DROP TABLE Locations CASCADE CONSTRAINTS;
DROP TABLE UserProfile CASCADE CONSTRAINTS;
DROP TABLE TouristAttractions1 CASCADE CONSTRAINTS;
DROP TABLE TouristAttractions2 CASCADE CONSTRAINTS;
DROP TABLE Transportation CASCADE CONSTRAINTS;
DROP TABLE ServicedBy CASCADE CONSTRAINTS;
DROP TABLE ExperienceOffered CASCADE CONSTRAINTS;
DROP TABLE Booking1 CASCADE CONSTRAINTS;
DROP TABLE Booking2 CASCADE CONSTRAINTS;
DROP TABLE Responses CASCADE CONSTRAINTS;
DROP TABLE Reviews CASCADE CONSTRAINTS;
DROP TABLE Comments CASCADE CONSTRAINTS;
DROP TABLE Photos CASCADE CONSTRAINTS;


CREATE TABLE Locations(
   province VARCHAR(2),
   city VARCHAR(20),
   PRIMARY KEY (province, city)
);


grant select on Locations to public;


CREATE TABLE UserProfile(
   userID number,
   userName varchar(20),
   PRIMARY KEY (userID)
);


grant select on UserProfile to public;


CREATE TABLE TouristAttractions1(
   latitude number(8, 5),
   longitude number(8, 5),
   province varchar(2),
   city varchar(20),
   PRIMARY KEY (latitude, longitude),
   FOREIGN KEY (province, city)
       REFERENCES Locations
       ON DELETE CASCADE
);


grant select on TouristAttractions1 to public;


CREATE TABLE TouristAttractions2(
   attractionID number GENERATED ALWAYS AS IDENTITY,
   attractionName varchar(50),
   attractionDesc varchar(1000),
   category varchar(20),
   openingHour varchar(5),
   closingHour varchar(5),
   latitude number(8, 5),
   longitude number(8, 5),
   PRIMARY KEY (attractionID),
   FOREIGN KEY (latitude, longitude)
       REFERENCES TouristAttractions1
       ON DELETE CASCADE
);


grant select on TouristAttractions2 to public;


CREATE TABLE Transportation(
   vehicleID number,
   type varchar(20),
   price number(9, 2),
   PRIMARY KEY (vehicleID)
);


grant select on Transportation to public;


CREATE TABLE ServicedBy(
   vehicleID number,
   attractionID number,
   PRIMARY KEY (vehicleID, attractionID),
   FOREIGN KEY (vehicleID)
       REFERENCES Transportation
       ON DELETE CASCADE,
   FOREIGN KEY (attractionID)
       REFERENCES TouristAttractions2
       ON DELETE CASCADE
);


grant select on ServicedBy to public;


CREATE TABLE ExperienceOffered(
   experienceID number,
   attractionID number,
   experienceName varchar(20),
   experienceDesc varchar(1000),
   company varchar(20),
   price number(9, 2),
   PRIMARY KEY (experienceID),
   FOREIGN KEY (attractionID)
       REFERENCES TouristAttractions2
       ON DELETE CASCADE
);


grant select on ExperienceOffered to public;


CREATE TABLE Booking1(
   experienceID number,
   userID number,
   startTime date,
   attractionID number,
   PRIMARY KEY (experienceID, userID, startTime),
   FOREIGN KEY (attractionID)
       REFERENCES TouristAttractions2
       ON DELETE CASCADE,
   FOREIGN KEY (userID)
       REFERENCES UserProfile
       ON DELETE CASCADE
);


grant select on Booking1 to public;


CREATE TABLE Booking2(
   bookingID number,
   experienceID number,
   userID number,
   startTime date,
   endTime date,
   numOfPersons number,
   PRIMARY KEY (bookingID),
   FOREIGN KEY (experienceID, userID, startTime)
       REFERENCES Booking1
       ON DELETE CASCADE
);


grant select on Booking2 to public;


CREATE TABLE Responses (
   responseID int,
   userID int,
   attractionID int,
   responseDate DATE,
   body varchar(1000),
   PRIMARY KEY (responseID),
   FOREIGN KEY (userID)
       REFERENCES UserProfile
       ON DELETE CASCADE,
   FOREIGN KEY (attractionID)
       REFERENCES TouristAttractions2
       ON DELETE CASCADE
);


grant select on Responses to public;


CREATE TABLE Reviews (
   reviewID number,
   starRating number(1),
   PRIMARY KEY (reviewID),
   FOREIGN KEY (reviewID)
       REFERENCES Responses (responseID)
       ON DELETE CASCADE
);


grant select on Reviews to public;


CREATE TABLE Comments (
   commentID number,
   reviewID number,
   PRIMARY KEY (commentID),
   FOREIGN KEY (commentID)
       REFERENCES Responses (responseID)
       ON DELETE CASCADE,
   FOREIGN KEY (reviewID)
       REFERENCES reviews (reviewID)
       ON DELETE CASCADE
);


grant select on Comments to public;


CREATE TABLE Photos (
   photoID number,
   attractionID number,
   url varchar(2048),
   photoDescription varchar(1000),
   uploadDate date,
   PRIMARY KEY (photoID),
   FOREIGN KEY (attractionID)
       REFERENCES TouristAttractions2
       ON DELETE CASCADE
);

grant select on Photos to public;


insert into Locations
values('bc', 'vancouver');
insert into Locations
values('bc', 'victoria');
insert into Locations
values('ab', 'calgary');
insert into Locations
values('on', 'ottawa');
insert into Locations
values('on', 'toronto');


insert into UserProfile
values(0, 'test0');
insert into UserProfile
values(1, 'test1');
insert into UserProfile
values(2, 'test2');
insert into UserProfile
values(3, 'test3');
insert into UserProfile
values(4, 'test4');


insert into TouristAttractions1
values(49.30427, -123.14421, 'bc', 'vancouver');
insert into TouristAttractions1
values(48.42842, -123.36564, 'bc', 'victoria');
insert into TouristAttractions1
values(51.04427, -114.06310, 'ab', 'calgary');
insert into TouristAttractions1
values(45.42153, -75.69719, 'on', 'ottawa');
insert into TouristAttractions1
values(43.65107, -79.34702, 'on', 'toronto');
insert into TouristAttractions1
values (49.27124, -123.13487, 'bc', 'vancouver');
insert into TouristAttractions1
values (49.282446, -123.12071, 'bc', 'vancouver');



-- auto incrementing id 1
insert into TouristAttractions2 (attractionName, attractionDesc, category, openingHour, closingHour, latitude, longitude)
values('stanley park',
   q'[north america's third-largest park draws eight million visitors per year, many of whom may skate or walk past you on the seawall, a scenic, 5.5-mile path running along the water on the park's perimeter. It's just one of many trails among the park's 1,000 acres, which also house an aquarium, nature center and other recreational facilities.]',
   'park', null, null, 49.30427, -123.14421);

-- auto incrementing id 2
insert into TouristAttractions2 (attractionName, attractionDesc, category, openingHour, closingHour, latitude, longitude)
values('butchart gardens',
   q'[a group of floral display gardens in brentwood bay, british columbia, canada, near victoria on vancouver island. the gardens receive over a million visitors each year.]',
   'park', '9:00', '17:00', 48.42842, -123.36564);

-- auto incrementing id 3
insert into TouristAttractions2 (attractionName, attractionDesc, category, openingHour, closingHour, latitude, longitude)
values('calgary tower',
   q'[a 190.8-meter free standing observation tower in downtown calgary, alberta, canada.]',
   'landmarks', '8:00', '20:00', 51.04427, -114.06310);

-- auto incrementing id 4
insert into TouristAttractions2 (attractionName, attractionDesc, category, openingHour, closingHour, latitude, longitude)
values('parliament hill',
   q'[an area of crown land on the southern banks of the ottawa river in downtown ottawa, ontario. its gothic revival suite of buildings is the home of the parliament of canada.]',
   'historical site', '10:00', '18:00', 45.421530, -75.697191);

-- auto incrementing id 5
insert into TouristAttractions2 (attractionName, attractionDesc, category, openingHour, closingHour, latitude, longitude)
values('cn tower',
   q'[a 553.3 m-high concrete communications and observation tower located in downtown toronto, ontario.]',
   'landmark', null, null, 43.65107, -79.34702);

-- auto incrementing id 6
insert into TouristAttractions2 (attractionName, attractionDesc, category, openingHour, closingHour, latitude, longitude)
values('granville island',
   q'[this large sandbar and former industrial site is now a posh, artsy neighborhood filled with quaint shops, eateries, breweries, and year-round arts and cultural festivals]',
   'landmark', null, null, 49.27124, -123.13487);

-- auto incrementing id 7
insert into TouristAttractions2 (attractionName, attractionDesc, category, openingHour, closingHour, latitude, longitude)
values('vancouver art gallery',
   q'[one of north americas most exciting and innovative visual arts institutions.]', 'museum', '10:00', '20:00', 49.282446, -123.12071);


insert into Transportation
values(0, 'translink', 3.00);

insert into Transportation
values(1, 'mobi bicycles', 10.00);

insert into Transportation
values(2, 'yellow cab ottawa', 30.00);

insert into Transportation
values(3, 'enterprise calgary', 100.00);

insert into Transportation
values(4, 'toronto subway', 4.00);


insert into ServicedBy
values(0, 1);

insert into ServicedBy
values(0, 2);

insert into ServicedBy
values(3, 3);

insert into ServicedBy
values(3, 4);

insert into ServicedBy
values(4, 5);


insert into ExperienceOffered
values(0, 1, 'seawall walk', 'a scenic walk along the seawall in stanley park.', 'walking company', 30.00);

insert into ExperienceOffered 
values(1, 2, 'garden Tour', 'a guided tour of the butchart gardens.', 'butchart inc.', 20.00 ); 

insert into ExperienceOffered 
values(2, 3, 'tower observation', 'an observation experience at the top of calgary tower.', 'city of calgary', 25.00 ); 

insert into ExperienceOffered 
values(3, 4, 'historical tour', 'a guided historical tour of parliament hill.', 'canada', 15.00 ); 

insert into ExperienceOffered 
values(4, 5, 'skyline view', 'an observation experience at the top of the cn tower.', 'canada lands company', 35.00 );

insert into ExperienceOffered
values(5, 1, 'bicycle park tour', 'with miles of car-free paths and lots to see, vancouvers stanley park is perfect for exploring by bicycle.', 'city of vancouver', 50.00);

insert into ExperienceOffered
values(6, 5, '360 restaurant', 'surround your guests with the finest of canadian dining—and the finest of canadian views—at 360 the restaurant at the cn tower. 360 completes a full rotation every 72 minutes, giving every guest a fresh perspective on the city below.',
'cn tower', 100.00);


INSERT INTO Booking1 VALUES (0, 0, TO_DATE('2024-07-20 12:30', 'YYYY-MM-DD HH24:MI'), 1); 

INSERT INTO Booking1 VALUES (1, 1, TO_DATE('2024-07-21 13:30', 'YYYY-MM-DD HH24:MI'), 2); 

INSERT INTO Booking1 VALUES (2, 2, TO_DATE('2024-07-22 15:40', 'YYYY-MM-DD HH24:MI'), 3); 

INSERT INTO Booking1 VALUES (3, 3, TO_DATE('2024-07-23 17:20', 'YYYY-MM-DD HH24:MI'), 4); 

INSERT INTO Booking1 VALUES (4, 4, TO_DATE('2024-07-24 8:30', 'YYYY-MM-DD HH24:MI'), 5);

INSERT INTO Booking1 VALUES (5, 0, TO_DATE('2024-08-01 11:00', 'YYYY-MM-DD HH24:MI'), 1);

INSERT INTO Booking1 VALUES (6, 1, TO_DATE('2024-08-01 11:00', 'YYYY-MM-DD HH24:MI'), 5);



INSERT INTO Booking2
VALUES (0, 0, 0, TO_DATE('2024-07-20 12:30', 'YYYY-MM-DD HH24:MI'), TO_DATE('2024-07-20 13:30', 'YYYY-MM-DD HH24:MI'), 2);

INSERT INTO Booking2
VALUES (1, 1, 1, TO_DATE('2024-07-21 13:30', 'YYYY-MM-DD HH24:MI'), TO_DATE('2024-07-21 15:40', 'YYYY-MM-DD HH24:MI'), 3);

INSERT INTO Booking2
VALUES (2, 2, 2, TO_DATE('2024-07-22 15:40', 'YYYY-MM-DD HH24:MI'), TO_DATE('2024-07-22 17:20', 'YYYY-MM-DD HH24:MI'), 4);

INSERT INTO Booking2
VALUES (3, 3, 3, TO_DATE('2024-07-23 17:20', 'YYYY-MM-DD HH24:MI'), TO_DATE('2024-07-23 18:00', 'YYYY-MM-DD HH24:MI'), 2);

INSERT INTO Booking2
VALUES (4, 4, 4, TO_DATE('2024-07-24 8:30', 'YYYY-MM-DD HH24:MI'), TO_DATE('2024-07-24 9:30', 'YYYY-MM-DD HH24:MI'), 1);

INSERT INTO Booking2
VALUES (5, 5, 0, TO_DATE('2024-08-01 11:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2024-08-01 12:30', 'YYYY-MM-DD HH24:MI'), 1);

INSERT INTO Booking2
VALUES (6, 6, 1, TO_DATE('2024-08-01 11:00', 'YYYY-MM-DD HH24:MI'), TO_DATE('2024-08-01 12:30', 'YYYY-MM-DD HH24:MI'), 1);

INSERT INTO Responses VALUES (1, 0, 1, TO_DATE('2024-07-20', 'YYYY-MM-DD'), 'amazing experience at stanley park!'); 

INSERT INTO Responses VALUES (2, 1, 2, TO_DATE('2024-07-21', 'YYYY-MM-DD'), 'the butchart gardens were beautiful.'); 

INSERT INTO Responses VALUES (3, 2, 3, TO_DATE('2024-07-22', 'YYYY-MM-DD'), 'great view from the calgary tower.'); 

INSERT INTO Responses VALUES (4, 3, 4, TO_DATE('2024-07-23', 'YYYY-MM-DD'), 'very informative tour at parliament hill.'); 

INSERT INTO Responses VALUES (5, 4, 5, TO_DATE('2024-07-24', 'YYYY-MM-DD'), 'stunning skyline view from the cn tower.');


INSERT INTO Reviews VALUES (1, 5); 

INSERT INTO Reviews VALUES (2, 4); 

INSERT INTO Reviews VALUES (3, 5); 

INSERT INTO Reviews VALUES (4, 4);

INSERT INTO Reviews VALUES (5, 5);


INSERT INTO Comments VALUES (1, 1); 

INSERT INTO Comments VALUES (2, 2); 

INSERT INTO Comments VALUES (3, 3); 

INSERT INTO Comments VALUES (4, 4); 

INSERT INTO Comments VALUES (5, 5);


INSERT INTO Photos VALUES (1, 1, 'https://example.com/stanley_park.jpg', 'a beautiful view of stanley park.', TO_DATE('2024-07-20', 'YYYY-MM-DD')); 

INSERT INTO Photos VALUES (2, 2, 'https://example.com/butchart_gardens.jpg', 'stunning flowers at butchart gardens.', TO_DATE('2024-07-21', 'YYYY-MM-DD')); 

INSERT INTO Photos VALUES (3, 3, 'https://example.com/calgary_tower.jpg', 'a view from calgary tower.', TO_DATE('2024-07-22', 'YYYY-MM-DD')); 

INSERT INTO Photos VALUES (4, 4, 'https://example.com/parliament_hill.jpg', 'parliament hill in ottawa.', TO_DATE('2024-07-23', 'YYYY-MM-DD')); 

INSERT INTO Photos VALUES (5, 5, 'https://example.com/cn_tower.jpg', 'the cn tower in toronto.', TO_DATE('2024-07-24', 'YYYY-MM-DD'));

COMMIT;