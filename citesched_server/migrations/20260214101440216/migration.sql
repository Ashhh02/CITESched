BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "faculty" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "email" text NOT NULL,
    "department" text NOT NULL,
    "maxLoad" bigint NOT NULL,
    "employmentStatus" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "faculty_email_unique_idx" ON "faculty" USING btree ("email");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "room" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "capacity" bigint NOT NULL,
    "type" text NOT NULL,
    "building" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "schedule" (
    "id" bigserial PRIMARY KEY,
    "subjectId" bigint NOT NULL,
    "facultyId" bigint NOT NULL,
    "roomId" bigint NOT NULL,
    "timeslotId" bigint NOT NULL,
    "section" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "subject" (
    "id" bigserial PRIMARY KEY,
    "code" text NOT NULL,
    "name" text NOT NULL,
    "units" bigint NOT NULL,
    "type" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "timeslot" (
    "id" bigserial PRIMARY KEY,
    "day" text NOT NULL,
    "startTime" text NOT NULL,
    "endTime" text NOT NULL,
    "label" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "schedule"
    ADD CONSTRAINT "schedule_fk_0"
    FOREIGN KEY("subjectId")
    REFERENCES "subject"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "schedule"
    ADD CONSTRAINT "schedule_fk_1"
    FOREIGN KEY("facultyId")
    REFERENCES "faculty"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "schedule"
    ADD CONSTRAINT "schedule_fk_2"
    FOREIGN KEY("roomId")
    REFERENCES "room"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "schedule"
    ADD CONSTRAINT "schedule_fk_3"
    FOREIGN KEY("timeslotId")
    REFERENCES "timeslot"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR citesched
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('citesched', '20260214101440216', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260214101440216', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260109031533194', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260109031533194', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20251208110412389-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110412389-v3-0-0', "timestamp" = now();


COMMIT;
