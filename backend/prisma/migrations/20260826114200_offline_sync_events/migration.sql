CREATE TABLE "SyncEvent" (
  "id" TEXT NOT NULL,
  "clientEventId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "deviceId" TEXT NOT NULL,
  "entityType" TEXT NOT NULL,
  "entityId" TEXT NOT NULL,
  "operation" TEXT NOT NULL,
  "version" INTEGER,
  "payload" JSONB,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "SyncEvent_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "SyncEvent_clientEventId_key" ON "SyncEvent"("clientEventId");
CREATE INDEX "SyncEvent_userId_createdAt_idx" ON "SyncEvent"("userId", "createdAt");
CREATE INDEX "SyncEvent_entityType_entityId_idx" ON "SyncEvent"("entityType", "entityId");

ALTER TABLE "SyncEvent"
  ADD CONSTRAINT "SyncEvent_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
