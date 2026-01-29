// Gemini API limits endpoint for Vercel (serverless function)
import { VercelRequest, VercelResponse } from '@vercel/node';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // Gemini 2.0 Flash limits (free tier)
  const limits = {
    model: 'gemini-2.0-flash',
    requests_per_minute: 10,
    requests_per_day: 1500,
    tokens_per_minute: 1000000,
    tokens_per_day: 10000000
  };

  return res.status(200).json(limits);
}
