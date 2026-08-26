-- Initial versioned schema for Universal Pet Health Record
CREATE TYPE "UserRole" AS ENUM ('OWNER', 'VETERINARIAN', 'STAFF', 'ADMIN');
CREATE TYPE "PetSpecies" AS ENUM ('DOG', 'CAT', 'BIRD', 'RABBIT', 'OTHER');
CREATE TYPE "AccessLevel" AS ENUM ('READ', 'WRITE');

CREATE TABLE "User" (
  "id" TEXT PRIMARY KEY,
  "email" TEXT NOT NULL UNIQUE,
  "name" TEXT NOT NULL,
  "passwordHash" TEXT NOT NULL,
  "role" "UserRole" NOT NULL DEFAULT 'OWNER',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL
);

CREATE TABLE "Pet" (
  "id" TEXT PRIMARY KEY,
  "name" TEXT NOT NULL,
  "species" "PetSpecies" NOT NULL,
  "breed" TEXT,
  "birthDate" TIMESTAMP(3),
  "microchip" TEXT UNIQUE,
  "primaryOwnerId" TEXT NOT NULL,
  "version" INTEGER NOT NULL DEFAULT 1,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Pet_primaryOwnerId_fkey" FOREIGN KEY ("primaryOwnerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE "MedicalRecord" (
  "id" TEXT PRIMARY KEY,
  "petId" TEXT NOT NULL,
  "veterinarianId" TEXT NOT NULL,
  "type" TEXT NOT NULL,
  "diagnosis" TEXT,
  "treatment" TEXT,
  "notes" TEXT,
  "occurredAt" TIMESTAMP(3) NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "MedicalRecord_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE "Vaccination" (
  "id" TEXT PRIMARY KEY,
  "petId" TEXT NOT NULL,
  "vaccineName" TEXT NOT NULL,
  "manufacturer" TEXT,
  "batchNumber" TEXT,
  "dateAdministered" TIMESTAMP(3) NOT NULL,
  "nextDueDate" TIMESTAMP(3),
  "administeredBy" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Vaccination_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE "AccessGrant" (
  "id" TEXT PRIMARY KEY,
  "tokenHash" TEXT NOT NULL UNIQUE,
  "petId" TEXT NOT NULL,
  "level" "AccessLevel" NOT NULL DEFAULT 'READ',
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "maxUses" INTEGER NOT NULL DEFAULT 1,
  "uses" INTEGER NOT NULL DEFAULT 0,
  "revokedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "AccessGrant_petId_fkey" FOREIGN KEY ("petId") REFERENCES "Pet"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE "AuditEvent" (
  "id" TEXT PRIMARY KEY,
  "actorId" TEXT,
  "action" TEXT NOT NULL,
  "entityType" TEXT NOT NULL,
  "entityId" TEXT NOT NULL,
  "metadata" JSONB,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
