BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "room" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "room" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "capacity" bigint NOT NULL,
    "type" text NOT NULL,
    "program" text NOT NULL,
    "building" text NOT NULL,
    "isActive" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "room_name_unique_idx" ON "room" USING btree ("name");

--
-- ACTION DROP TABLE
--
DROP TABLE "subject" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "subject" (
    "id" bigserial PRIMARY KEY,
    "code" text NOT NULL,
    "name" text NOT NULL,
    "units" bigint NOT NULL,
    "yearLevel" bigint,
    "term" bigint,
    "type" text NOT NULL,
    "program" text NOT NULL,
    "studentsCount" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);


--
-- MIGRATION VERSION FOR citesched
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('citesched', '20260217141816761', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260217141816761', "timestamp" = now();

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
-- MIGRATION VERSION FOR serverpod_auth
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth', '20250825102351908-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250825102351908-v3-0-0', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20251208110412389-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110412389-v3-0-0', "timestamp" = now();


COMMIT;
