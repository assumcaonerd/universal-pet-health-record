CREATE TYPE "AllergySeverity" AS ENUM ('MILD', 'MODERATE', 'SEVERE', 'LIFE_THREATENING');

ALTER TABLE "Vaccination" ADD COLUMN "veterinarianId" TEXT;
ALTER TABLE "Vaccination" ADD COLUMN "organizationId" TEXT;
UPDATE "Vaccination" SET "veterinarianId" = "administeredBy" WHERE "veterinarianId" IS NULL;
ALTER TABLE "Vaccination" ALTER COLUMN "veterinarianId" SET NOT NULL;
ALTER TABLE "Vaccination" DROP COLUMN "administeredBy";
ALTER TABLE "Vaccination" ADD CONSTRAINT "Vaccination_veterinarianId_fkey" FOREIGN KEY ("veterinarianId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Vaccination" ADD CONSTRAINT "Vaccination_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE SET NULL ON UPDATE CASCADE;

CREATE TABLE "Prescription" (
  "id" TEXT PRIMARY KEY,
  "petId" TEXT NOT NULL,
  "medicalRecordId" TEXT,
  "veterinarianId" TEXT NOT NULL,
  "organizationId" TEXT,
  "medication" TEXT NOT NULL,
  "dosage" TEXT NOT NULL,
  "frequency" TEXT NOT NULL,
  "duration" TEXT,
  "instructions" TEXT,
  "prescribedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Prescription_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Prescription_medicalRecordId_fkey" FOREIGN KEY ("medicalRecordId") REFERENCES "MedicalRecord"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT "Prescription_veterinarianId_fkey" FOREIGN KEY ("veterinarianId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT "Prescription_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE "Allergy" (
  "id" TEXT PRIMARY KEY,
  "petId" TEXT NOT NULL,
  "allergen" TEXT NOT NULL,
  "reaction" TEXT,
  "severity" "AllergySeverity" NOT NULL DEFAULT 'MODERATE',
  "active" BOOLEAN NOT NULL DEFAULT true,
  "authorId" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Allergy_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Allergy_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE "ClinicalAttachment" (
  "id" TEXT PRIMARY KEY,
  "petId" TEXT NOT NULL,
  "medicalRecordId" TEXT,
  "authorId" TEXT,
  "fileName" TEXT NOT NULL,
  "mimeType" TEXT NOT NULL,
  "storageKey" TEXT NOT NULL UNIQUE,
  "sha256" TEXT NOT NULL,
  "sizeBytes" INTEGER NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "ClinicalAttachment_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "ClinicalAttachment_medicalRecordId_fkey" FOREIGN KEY ("medicalRecordId") REFERENCES "MedicalRecord"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT "ClinicalAttachment_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE
);