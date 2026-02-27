const GEMINI_MODEL = 'gemini-1.5-flash';

function parseDataUrl(dataUrl) {
  const match = dataUrl.match(/^data:(.+);base64,(.+)$/);
  if (!match) {
    throw new Error('Invalid data URL');
  }
  return { mimeType: match[1], base64: match[2] };
}

function normalizeResult(raw) {
  const toInt = (v) => Math.max(0, Math.round(Number(v) || 0));
  const toFloat = (v) => Math.max(0, Math.min(1, Number(v) || 0));

  return {
    name: String(raw.name || 'Unknown'),
    calories: toInt(raw.calories),
    protein: toInt(raw.protein),
    carbs: toInt(raw.carbs),
    fats: toInt(raw.fats),
    health_score: toInt(raw.health_score),
    confidence: toFloat(raw.confidence),
    warnings: Array.isArray(raw.warnings)
      ? raw.warnings.map((w) => String(w))
      : [],
  };
}

async function callGemini({ base64, mimeType }) {
  const prompt =
    'You are a strict nutritionist API. Analyze the image and return ONLY valid JSON in the exact schema.';

  const schema = {
    type: 'OBJECT',
    properties: {
      name: { type: 'STRING' },
      calories: { type: 'INTEGER' },
      protein: { type: 'INTEGER' },
      carbs: { type: 'INTEGER' },
      fats: { type: 'INTEGER' },
      health_score: { type: 'INTEGER' },
      confidence: { type: 'NUMBER' },
      warnings: {
        type: 'ARRAY',
        items: { type: 'STRING' },
      },
    },
    required: [
      'name',
      'calories',
      'protein',
      'carbs',
      'fats',
      'health_score',
      'confidence',
      'warnings',
    ],
  };

  const body = {
    contents: [
      {
        parts: [
          {
            inline_data: {
              mime_type: mimeType,
              data: base64,
            },
          },
          { text: prompt },
        ],
      },
    ],
    generationConfig: {
      response_mime_type: 'application/json',
      response_schema: schema,
    },
  };

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': process.env.GEMINI_API_KEY || '',
      },
      body: JSON.stringify(body),
    }
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Gemini error: ${response.status} ${text}`);
  }

  const payload = await response.json();
  const textPart =
    payload?.candidates?.[0]?.content?.parts?.[0]?.text || '';
  if (!textPart) {
    throw new Error('Empty Gemini response');
  }

  try {
    return JSON.parse(textPart);
  } catch (error) {
    const start = textPart.indexOf('{');
    const end = textPart.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return JSON.parse(textPart.slice(start, end + 1));
    }
    throw error;
  }
}

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const secret = req.headers['x-app-secret'];
  if (!secret || secret !== process.env.APP_PROXY_SECRET) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  try {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    const imageBase64 = body?.image_base64;
    if (!imageBase64 || typeof imageBase64 !== 'string') {
      res.status(400).json({ error: 'image_base64 is required' });
      return;
    }

    const { mimeType, base64 } = parseDataUrl(imageBase64);
    const raw = await callGemini({ base64, mimeType });
    const normalized = normalizeResult(raw);
    res.status(200).json(normalized);
  } catch (error) {
    res.status(500).json({ error: error.message || 'Internal error' });
  }
};
