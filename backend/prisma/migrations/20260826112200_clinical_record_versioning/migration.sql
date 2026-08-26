CREATE TABLE "Organization" (
  "id" TEXT PRIMARY KEY,
  "name" TEXT NOT NULL,
  "registrationNumber" TEXT,
  "city" TEXT,
  "state" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL
);

ALTER TABLE "MedicalRecord"
ADD COLUMN "organizationId" TEXT,
ADD COLUMN "currentVersion" INTEGER NOT NULL DEFAULT 1;

ALTER TABLE "MedicalRecord"
ADD CONSTRAINT "MedicalRecord_veterinarianId_fkey"
FOREIGN KEY ("veterinarianId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "MedicalRecord"
ADD CONSTRAINT "MedicalRecord_organizationId_fkey"
FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE SET NULL ON UPDATE CASCADE;

CREATE TABLE "MedicalRecordVersion" (
  "id" TEXT PRIMARY KEY,
  "medicalRecordId" TEXT NOT NULL,
  "version" INTEGER NOT NULL,
  "diagnosis" TEXT,
  "treatment" TEXT,
  "notes" TEXT,
  "reason" TEXT,
  "authorId" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "MedicalRecordVersion_medicalRecordId_fkey" FOREIGN KEY ("medicalRecordId") REFERENCES "MedicalRecord"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "MedicalRecordVersion_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "MedicalRecordVersion_medicalRecordId_version_key"
ON "MedicalRecordVersion"("medicalRecordId", "version");
