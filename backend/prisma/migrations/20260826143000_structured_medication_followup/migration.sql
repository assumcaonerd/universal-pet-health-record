ALTER TABLE "MedicalRecord"
ADD COLUMN "followUpAt" TIMESTAMP(3);

ALTER TABLE "Prescription"
ADD COLUMN "startsAt" TIMESTAMP(3),
ADD COLUMN "endsAt" TIMESTAMP(3),
ADD COLUMN "intervalMinutes" INTEGER;

ALTER TABLE "Prescription"
ADD CONSTRAINT "Prescription_intervalMinutes_positive" CHECK ("intervalMinutes" IS NULL OR "intervalMinutes" > 0);

ALTER TABLE "Prescription"
ADD CONSTRAINT "Prescription_end_after_start" CHECK ("startsAt" IS NULL OR "endsAt" IS NULL OR "endsAt" >= "startsAt");
