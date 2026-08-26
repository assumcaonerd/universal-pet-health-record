CREATE TABLE "TotpConfiguration" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "secretCiphertext" TEXT NOT NULL,
  "iv" TEXT NOT NULL,
  "authTag" TEXT NOT NULL,
  "enabledAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "TotpConfiguration_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "TotpConfiguration_userId_key" ON "TotpConfiguration"("userId");

ALTER TABLE "TotpConfiguration"
ADD CONSTRAINT "TotpConfiguration_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
