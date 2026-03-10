const { GoogleGenAI, Type } = require('@google/genai');
const env = require('../config/env');
const fs = require('fs');
const path = require('path');

if (!env.geminiApiKey) {
  console.warn('⚠ GEMINI_API_KEY ayarlanmamış. AI özellikleri devre dışı.');
}

const ai = env.geminiApiKey ? new GoogleGenAI({ apiKey: env.geminiApiKey }) : null;
const MODEL = 'gemini-3-flash-preview';

const geminiService = {
  isAvailable() {
    return ai !== null;
  },

  /**
   * Kullanıcı konumuna yakın görevler üret
   */
  async generateQuests(lat, lng, existingTitles = []) {
    if (!ai) throw new Error('Gemini API yapılandırılmamış');

    const response = await ai.models.generateContent({
      model: MODEL,
      contents: `Koordinatlar: (${lat}, ${lng}) yakınında 3 adet benzersiz konum tabanlı görev üret.
Görevler eğlenceli dış mekan aktiviteleri olmalı.
Mevcut görev başlıkları (bunlardan farklı olmalı): ${existingTitles.join(', ') || 'yok'}.
Her görevi verilen koordinatlardan 200m-2km arasına yerleştir.
Görev tiplerini 'photo' ve 'question' olarak karıştır.
Fotoğraf görevleri için: kullanıcının ne fotoğrafı çekmesi gerektiğini açıkla.
Soru görevleri için: bölge/doğa/kültür hakkında bir soru ve cevabını ver.
Puanlar zorluk seviyesine göre 10-50 arasında olmalı.`,
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            quests: {
              type: Type.ARRAY,
              items: {
                type: Type.OBJECT,
                properties: {
                  title: { type: Type.STRING },
                  description: { type: Type.STRING },
                  type: { type: Type.STRING },
                  latitude: { type: Type.NUMBER },
                  longitude: { type: Type.NUMBER },
                  radius_meters: { type: Type.INTEGER },
                  points: { type: Type.INTEGER },
                  question: { type: Type.STRING, nullable: true },
                  answer: { type: Type.STRING, nullable: true },
                },
                required: ['title', 'description', 'type', 'latitude', 'longitude', 'radius_meters', 'points'],
              },
            },
          },
          required: ['quests'],
        },
        systemInstruction: 'Sen Geo-Quest adlı konum tabanlı macera oyunu için yaratıcı bir görev tasarımcısısın. Kullanıcıları çevreyi keşfetmeye teşvik eden eğlenceli, eğitici ve ilgi çekici görevler üret. Tüm metinler Türkçe olmalı. Görevler gerçekçi ve yapılabilir olmalı. Fotoğraf görevlerinde question ve answer null olmalı. Soru görevlerinde question soruyu, answer ise cevabı içermeli.',
      },
    });

    return JSON.parse(response.text);
  },

  /**
   * Fotoğraf gönderimini değerlendir
   */
  async evaluatePhoto(photoPath, questTitle, questDescription) {
    if (!ai) throw new Error('Gemini API yapılandırılmamış');

    const fullPath = path.join(__dirname, '../public', photoPath);
    const imageData = fs.readFileSync(fullPath);
    const base64 = imageData.toString('base64');
    const ext = path.extname(photoPath).toLowerCase();
    const mimeType = ext === '.png' ? 'image/png' : ext === '.webp' ? 'image/webp' : 'image/jpeg';

    const response = await ai.models.generateContent({
      model: MODEL,
      contents: [
        {
          role: 'user',
          parts: [
            {
              text: `Bu fotoğrafı değerlendir.
Görev başlığı: "${questTitle}"
Görev açıklaması: "${questDescription}"

Fotoğrafın görevle ne kadar ilgili olduğunu puanla (0-100).
- 70 ve üzeri: Görev başarıyla tamamlanmış sayılır
- 70 altı: Fotoğraf yetersiz veya ilgisiz

Değerlendirmeni Türkçe açıkla.`,
            },
            {
              inlineData: { mimeType, data: base64 },
            },
          ],
        },
      ],
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            score: { type: Type.INTEGER },
            evaluation: { type: Type.STRING },
            relevant: { type: Type.BOOLEAN },
          },
          required: ['score', 'evaluation', 'relevant'],
        },
      },
    });

    return JSON.parse(response.text);
  },

  /**
   * Görev için ipucu üret
   */
  async generateHint(quest) {
    if (!ai) throw new Error('Gemini API yapılandırılmamış');

    const typeInfo = quest.type === 'question'
      ? `Soru: "${quest.question}"`
      : quest.type === 'photo'
      ? 'Fotoğraf görevi'
      : 'QR kod görevi';

    const response = await ai.models.generateContent({
      model: MODEL,
      contents: `Görev: "${quest.title}"
Açıklama: "${quest.description}"
Tip: ${typeInfo}
Konum: (${quest.latitude}, ${quest.longitude})

Bu görev için kullanıcıya yardımcı olacak bir ipucu üret. İpucu cevabı doğrudan söylememeli, ama doğru yöne yönlendirmeli.`,
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            hint: { type: Type.STRING },
          },
          required: ['hint'],
        },
        systemInstruction: 'Sen bir görev ipucu asistanısın. Kullanıcılara nazik ve eğlenceli ipuçları ver. Cevabı doğrudan söyleme. Türkçe yanıt ver.',
      },
    });

    return JSON.parse(response.text);
  },

  /**
   * Kişiselleştirilmiş görev önerileri
   */
  async getRecommendations(completedQuests, availableQuests, userName) {
    if (!ai) throw new Error('Gemini API yapılandırılmamış');

    const completed = completedQuests.map(q => `- ${q.quest_title} (${q.quest_type})`).join('\n');
    const available = availableQuests.map(q => `- ID:${q.id} "${q.title}" (${q.type}, ${q.points} puan)`).join('\n');

    const response = await ai.models.generateContent({
      model: MODEL,
      contents: `Kullanıcı: ${userName}

Tamamlanan görevler:
${completed || 'Henüz tamamlanan görev yok'}

Mevcut görevler:
${available || 'Mevcut görev yok'}

Kullanıcının tamamladığı görevlere bakarak en uygun 3 görevi öner ve her biri için kısa bir sebep yaz.`,
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            recommendations: {
              type: Type.ARRAY,
              items: {
                type: Type.OBJECT,
                properties: {
                  quest_id: { type: Type.INTEGER },
                  reason: { type: Type.STRING },
                },
                required: ['quest_id', 'reason'],
              },
            },
          },
          required: ['recommendations'],
        },
        systemInstruction: 'Sen bir kişiselleştirilmiş görev öneri asistanısın. Kullanıcının geçmişine bakarak en uygun görevleri öner. Türkçe yanıt ver. Sadece mevcut görev listesindeki ID\'leri kullan.',
      },
    });

    return JSON.parse(response.text);
  },
};

module.exports = geminiService;
