BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "faculty" ADD COLUMN "shiftPreference" text;
ALTER TABLE "faculty" ADD COLUMN "preferredHours" text;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "schedule" ADD COLUMN "loadType" text;
ALTER TABLE "schedule" ADD COLUMN "units" double precision;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "subject" ADD COLUMN "yearLevel" bigint;
ALTER TABLE "subject" ADD COLUMN "term" bigint;

--
-- MIGRATION VERSION FOR citesched
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('citesched', '20260216095929068', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260216095929068', "timestamp" = now();

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
