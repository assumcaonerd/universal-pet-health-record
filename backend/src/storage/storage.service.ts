import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { GetObjectCommand, HeadObjectCommand, PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { randomUUID } from 'crypto';

@Injectable()
export class StorageService {
  private readonly bucket = process.env.S3_BUCKET;
  private readonly client = new S3Client({
    region: process.env.S3_REGION ?? 'us-east-1',
    endpoint: process.env.S3_ENDPOINT || undefined,
    forcePathStyle: process.env.S3_FORCE_PATH_STYLE === 'true',
    credentials:
      process.env.S3_ACCESS_KEY_ID && process.env.S3_SECRET_ACCESS_KEY
        ? {
            accessKeyId: process.env.S3_ACCESS_KEY_ID,
            secretAccessKey: process.env.S3_SECRET_ACCESS_KEY,
          }
        : undefined,
  });

  private requireBucket() {
    if (!this.bucket) throw new InternalServerErrorException('S3_BUCKET is not configured');
    return this.bucket;
  }

  async createPresignedUpload(petId: string, fileName: string, mimeType: string, sha256: string) {
    const bucket = this.requireBucket();
    const safeName = fileName.replace(/[^a-zA-Z0-9._-]/g, '_').slice(-120);
    const key = `pets/${petId}/clinical/${randomUUID()}-${safeName}`;
    const command = new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      ContentType: mimeType,
      Metadata: { sha256: sha256.toLowerCase() },
    });
    const uploadUrl = await getSignedUrl(this.client, command, { expiresIn: 300 });
    return { storageKey: key, uploadUrl, expiresInSeconds: 300 };
  }

  async createPresignedDownload(storageKey: string, fileName: string, mimeType: string) {
    const bucket = this.requireBucket();
    const safeName = fileName.replace(/["\\\r\n]/g, '_').slice(-180);
    const command = new GetObjectCommand({
      Bucket: bucket,
      Key: storageKey,
      ResponseContentType: mimeType,
      ResponseContentDisposition: `attachment; filename="${safeName}"`,
    });
    const downloadUrl = await getSignedUrl(this.client, command, { expiresIn: 120 });
    return { downloadUrl, expiresInSeconds: 120 };
  }

  async verifyObject(storageKey: string, expectedSha256: string, expectedSize: number) {
    const bucket = this.requireBucket();
    const head = await this.client.send(new HeadObjectCommand({ Bucket: bucket, Key: storageKey }));
    const storedHash = head.Metadata?.sha256?.toLowerCase();
    return {
      exists: true,
      hashMatches: storedHash === expectedSha256.toLowerCase(),
      sizeMatches: Number(head.ContentLength ?? -1) === expectedSize,
      contentType: head.ContentType,
    };
  }
}
