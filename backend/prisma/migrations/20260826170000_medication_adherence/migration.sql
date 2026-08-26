CREATE TYPE "MedicationAdherenceStatus" AS ENUM ('TAKEN', 'SKIPPED');

CREATE TABLE "MedicationAdherenceEvent" (
  "id" TEXT NOT NULL,
  "petId" TEXT NOT NULL,
  "prescriptionId" TEXT NOT NULL,
  "recorderId" TEXT NOT NULL,
  "scheduledAt" TIMESTAMP(3) NOT NULL,
  "administeredAt" TIMESTAMP(3),
  "status" "MedicationAdherenceStatus" NOT NULL,
  "note" TEXT,
  "clientEventId" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "MedicationAdherenceEvent_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "MedicationAdherenceEvent_clientEventId_key" ON "MedicationAdherenceEvent"("clientEventId");
CREATE UNIQUE INDEX "MedicationAdherenceEvent_prescriptionId_scheduledAt_key" ON "MedicationAdherenceEvent"("prescriptionId", "scheduledAt");
CREATE INDEX "MedicationAdherenceEvent_petId_scheduledAt_idx" ON "MedicationAdherenceEvent"("petId", "scheduledAt");
ALTER TABLE "MedicationAdherenceEvent" ADD CONSTRAINT "MedicationAdherenceEvent_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "MedicationAdherenceEvent" ADD CONSTRAINT "MedicationAdherenceEvent_prescriptionId_fkey" FOREIGN KEY ("prescriptionId") REFERENCES "Prescription"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "MedicationAdherenceEvent" ADD CONSTRAINT "MedicationAdherenceEvent_recorderId_fkey" FOREIGN KEY ("recorderId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
