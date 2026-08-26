import { Injectable, ServiceUnavailableException } from '@nestjs/common';

@Injectable()
export class EmailService {
  async send(to: string, subject: string, text: string) {
    const apiUrl = process.env.EMAIL_PROVIDER_API_URL;
    const apiKey = process.env.EMAIL_PROVIDER_API_KEY;
    const from = process.env.EMAIL_FROM ?? 'noreply@petrecord.local';

    if (!apiUrl || !apiKey) {
      if (process.env.NODE_ENV === 'production') {
        throw new ServiceUnavailableException('Email provider is not configured');
      }
      console.info(`[email-dev] to=${to} subject=${subject} text=${text}`);
      return { delivered: false, development: true };
    }

    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${apiKey}` },
      body: JSON.stringify({ from, to, subject, text }),
    });
    if (!response.ok) throw new ServiceUnavailableException('Email provider rejected the message');
    return { delivered: true };
  }
}
