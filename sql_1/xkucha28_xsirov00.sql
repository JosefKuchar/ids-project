-- 2. část - SQL skript pro vytvoření objektů schématu databáze
-- Josef Kuchař (xkucha28), Matej Sirovatka (xsirov00)

-- Projekt č.: 14
-- Název projektu: Poradna
-- Zadání:
-- Navrhněte IS poradny pro zájemce o studium na vysoké škole. Systém by měl poskytovat základní informace o různých
-- vysokých školách a fakultách,včetně údajů s dočasnou platností (termíny a podmínky přijímacích řízení atd.).

----------------------------------------
---- DROP TABLES (Can cause errors) ----
----------------------------------------
DROP TABLE "user" CASCADE CONSTRAINTS;
DROP TABLE "admin" CASCADE CONSTRAINTS;
DROP TABLE "school" CASCADE CONSTRAINTS;
DROP TABLE "faculty" CASCADE CONSTRAINTS;
DROP TABLE "message" CASCADE CONSTRAINTS;
DROP TABLE "edit" CASCADE CONSTRAINTS;
DROP TABLE "school_user" CASCADE CONSTRAINTS;
DROP TABLE "faculty_user" CASCADE CONSTRAINTS;

----------------------------------------
------------ CREATE TABLES -------------
----------------------------------------

-- Specialization is implemented as optional foreign key from user to admin
CREATE TABLE "admin" (
	"id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
	"permission_level" INT NOT NULL CHECK("permission_level" IN (0,1,2))
);

CREATE TABLE "user" (
	"id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
	"name" VARCHAR2(100) NOT NULL,
	-- Taken from https://www.dba-oracle.com/t_email_validation_regular_expressions.htm
	"email" VARCHAR2(100) NOT NULL, CHECK(REGEXP_LIKE("email", '^[A-Za-z]+[A-Za-z0-9.]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$')),
	"password" VARCHAR2(100) NOT NULL,
	"description" VARCHAR2(4000),
	"admin_id" INT DEFAULT NULL,
	CONSTRAINT "admin_id_fk" FOREIGN KEY ("admin_id") REFERENCES "admin" ("id") ON DELETE SET NULL
);

CREATE TABLE "school" (
	"id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
	"name" VARCHAR2(100) NOT NULL,
	"description" VARCHAR2(4000),
	"location" SDO_GEOMETRY
);

CREATE TABLE "faculty" (
	"id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
	"name" VARCHAR2(100) NOT NULL,
	"description" VARCHAR2(4000),
	"location" SDO_GEOMETRY,
	"school_id" INT NOT NULL,
	CONSTRAINT "school_id_fk" FOREIGN KEY ("school_id") REFERENCES "school" ("id") ON DELETE CASCADE
);

CREATE TABLE "message" (
	"id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
	"title" VARCHAR2(100) NOT NULL,
	"text" VARCHAR2(4000),
	"creation_date" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"valid_from" TIMESTAMP,
	"valid_to" TIMESTAMP,
	"school_id" INT,
	"faculty_id" INT,
	CONSTRAINT "school_id_fk2" FOREIGN KEY ("school_id") REFERENCES "school" ("id") ON DELETE CASCADE,
	CONSTRAINT "faculty_id_fk" FOREIGN KEY ("faculty_id") REFERENCES "faculty" ("id") ON DELETE CASCADE
);

CREATE TABLE "edit" (
	"id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
	"timestamp" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"changes" VARCHAR2(4000) NOT NULL,
	"message_id" INT NOT NULL,
	"admin_id" INT NOT NULL,
	CONSTRAINT "message_id_fk" FOREIGN KEY ("message_id") REFERENCES "message" ("id") ON DELETE CASCADE,
	CONSTRAINT "admin_id_fk2" FOREIGN KEY ("admin_id") REFERENCES "admin" ("id") ON DELETE CASCADE
);

-- school - user N:N
CREATE TABLE "school_user" (
	"id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
	"school_id" INT NOT NULL,
	"user_id" INT NOT NULL,
	CONSTRAINT "school_id_fk3" FOREIGN KEY ("school_id") REFERENCES "school" ("id") ON DELETE CASCADE,
	CONSTRAINT "user_id_fk" FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE
);

-- faculty - user N:N
CREATE TABLE "faculty_user" (
	"id" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
	"faculty_id" INT NOT NULL,
	"user_id" INT NOT NULL,
	CONSTRAINT "faculty_id_fk2" FOREIGN KEY ("faculty_id") REFERENCES "faculty" ("id") ON DELETE CASCADE,
	CONSTRAINT "user_id_fk2" FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE
);

----------------------------------------
--------- CREATE EXAMPLE DATA ----------
----------------------------------------
-- Note: Passwords are hashed with bcrypt 12 rounds (https://bcrypt-generator.com/)

-- Create admins
INSERT INTO "admin" ("permission_level") VALUES (0);
INSERT INTO "admin" ("permission_level") VALUES (2);
-- Create schools
INSERT INTO "school" ("name", "description", "location")
VALUES ('Vysoké učení technické v Brně', 'Nečekejte na budoucnost, tvořte ji s námi.', SDO_GEOMETRY(2001,8307,SDO_POINT_TYPE(-73.935242, 40.730610, NULL),NULL,NULL));
INSERT INTO "school" ("name", "description", "location")
VALUES ('Masarykova univerzita', 'Myslíme a jednáme udržitelně', SDO_GEOMETRY(2001,8307,SDO_POINT_TYPE(-74.006, 40.7128, NULL),NULL,NULL));
-- Create school faculties
INSERT INTO "faculty" ("name", "description", "location", "school_id")
VALUES ('FIT', 'Fakulta informačních technologií je moderním mezinárodně uznávaným vysokoškolským pracovištěm a centrem špičkového výzkumu v nejrůznějších oblastech.', SDO_GEOMETRY(2001,8307,SDO_POINT_TYPE(-73.935242, 40.730610, NULL),NULL,NULL), 1);
INSERT INTO "faculty" ("name", "description", "location", "school_id")
VALUES ('FEKT', 'Fakulta elektrotechniky a komunikačních technologií je třetí největší fakultou Vysokého učení technického v Brně a největší elektrofakultou v Česku.', SDO_GEOMETRY(2001,8307,SDO_POINT_TYPE(-73.935242, 40.730610, NULL),NULL,NULL), 1);
INSERT INTO "faculty" ("name", "description", "location", "school_id")
VALUES ('FI MU', 'Fakulta informatiky Masarykovy univerzity je fakulta Masarykovy univerzity, která rozvíjí vzdělávací, vědeckou a doplňkovou činnost v oblasti informatiky jako disciplíny věnované metodám, modelům a nástrojům zpracování informací, zejména pak pomocí počítačů.', SDO_GEOMETRY(2001,8307,SDO_POINT_TYPE(-74.006, 40.7128, NULL),NULL,NULL), 2);
-- Create users
INSERT INTO "user" ("name", "email", "password", "description", "admin_id")
VALUES ('Josef Kuchař', 'xkucha28@stud.fit.vutbr.cz', '$2a$12$zaid9XfIao25reQ0J7ZdEueb3O.rta97am9HYenTAkumsD1qkRrra', 'Student 2. ročníku', NULL);
INSERT INTO "user" ("name", "email", "password", "description", "admin_id")
VALUES ('Matej Sirovatka', 'xsirov00@stud.fit.vutbr.cz', '$2a$12$CqKCD0CwaCnyKUm8SsoiwunJNj3AnZTUCpmtMiiQN9l1eILBLH9f6', 'Student 1. ročníku', NULL);
INSERT INTO "user" ("name", "email", "password", "description", "admin_id")
VALUES ('Moderátor Janek', 'moderator@example.com', '$2a$12$HN1dNSiRgHwYMtQmCjyXCOdmYVJjSihPTjBjJJM1m.F1.A4IQ4POW', 'Základní moderátor', 1);
INSERT INTO "user" ("name", "email", "password", "description", "admin_id")
VALUES ('Master admin', 'masteradmin@example.com', '$2a$12$HN1dNSiRgHwYMtQmCjyXCOdmYVJjSihPTjBjJJM1m.F1.A4IQ4POW', 'Hlavní administrátor', 2);
-- Create messages
INSERT INTO "message" ("title", "text", "valid_from", "valid_to", "school_id", "faculty_id")
VALUES ('Uvítací zpráva', 'vítejte na naší škole!', TO_TIMESTAMP('2023-03-24 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 1, NULL);
INSERT INTO "message" ("title", "text", "valid_from", "valid_to", "school_id", "faculty_id")
VALUES ('Důležitá zpráva', 'Přednášky v D105 se ruší.', TO_TIMESTAMP('2023-03-25 07:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2023-03-25 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), NULL, 1);
-- Create edits
INSERT INTO "edit" ("changes", "message_id", "admin_id")
VALUES ('Odstraněna typografická chyba.', 2, 1);
-- Create follow bondings
INSERT INTO "school_user" ("school_id", "user_id")
VALUES (1, 1);
INSERT INTO "school_user" ("school_id", "user_id")
VALUES (2, 2);
INSERT INTO "faculty_user" ("faculty_id", "user_id")
VALUES (1, 1);
