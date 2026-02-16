BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "student" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "email" text NOT NULL,
    "studentNumber" text NOT NULL,
    "course" text NOT NULL,
    "yearLevel" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "student_email_unique_idx" ON "student" USING btree ("email");
CREATE UNIQUE INDEX "student_number_unique_idx" ON "student" USING btree ("studentNumber");


--
-- MIGRATION VERSION FOR citesched
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('citesched', '20260214104205243', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260214104205243', "timestamp" = now();

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
