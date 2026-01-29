// IcoAtlas API proxy for Vercel (serverless function)
declare const process: any;

type VercelRequest = {
  method: string;
  query: { ico?: string };
  url: string;
  headers: Record<string, string>;
  body: any;
  cookies: Record<string, string>;
};

type VercelResponse = {
  status(code: number): VercelResponse;
  json(data: any): void;
};

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const ico = req.query.ico;

  if (!ico) {
    return res.status(400).json({ error: 'Missing IČO parameter' });
  }

  // Pad ICO to 8 digits if numeric
  const paddedIco = ico.padStart(8, '0');

  // Get API key from environment
  const apiKey = process.env.ICOATLAS_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ error: 'Server configuration error' });
  }

  try {
    const response = await fetch(`https://icoatlas.sk/api/company/${paddedIco}`, {
      headers: {
        'X-Api-Key': apiKey,
        'Content-Type': 'application/json'
      }
    });

    if (response.status === 404) {
      return res.status(404).json({ error: 'Company not found' });
    }

    if (response.status === 401 || response.status === 403) {
      return res.status(500).json({ error: 'Authentication error' });
    }

    if (!response.ok) {
      return res.status(response.status).json({ error: 'External API error' });
    }

    const data = await response.json();

    // Transform to match our expected format
    const result = {
      name: data.name || '',
      ico: data.ico || ico,
      dic: data.dic || '',
      icDph: data.ic_dph || '',
      address: data.address || ''
    };

    return res.status(200).json(result);
  } catch (error) {
    console.error('IcoAtlas proxy error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
