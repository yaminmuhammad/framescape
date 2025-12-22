/* eslint-disable @typescript-eslint/no-unused-vars */
/**
 * Cloud Functions for Photo AI App
 *
 * This function handles AI image generation using NanoBanana/Google Gemini API.
 * The API key is stored securely using Firebase Secrets.
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {setGlobalOptions} from "firebase-functions/v2";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import { GoogleGenAI } from "@google/genai";

// Initialize Firebase Admin
admin.initializeApp();

// Define secret for Gemini API Key
const geminiApiKey = defineSecret("GEMINI_API_KEY");

// Global options for all functions
setGlobalOptions({maxInstances: 10, region: "us-central1"});

// Get Firebase services
const storage = admin.storage();
const firestore = admin.firestore();

/**
 * generateImage - Callable Cloud Function
 *
 * Takes an original image from Storage and generates an AI variant.
 *
 * @param {string} imagePath - Path to the original image in Storage
 * @param {string} prompt - User's prompt for image generation
 * @returns {object} - Result with generated image URL and metadata
 */
export const generateImage = onCall(
  {
    secrets: [geminiApiKey],
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async (request) => {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "User must be authenticated to generate images."
      );
    }

    const uid = request.auth.uid;
    const {imagePath, category} = request.data;

    // Validate input
    if (!imagePath || typeof imagePath !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "imagePath is required and must be a string."
      );
    }

    if (!category || typeof category !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "category is required and must be a string."
      );
    }

    // Base photorealistic photography rules
    const photoRules = `Generate a single, cohesive, photorealistic image that looks like it was captured naturally on a modern smartphone camera.

The person and the environment must feel like they belong in the same scene, with consistent lighting direction, realistic shadows, natural color grading, and correct perspective.

Avoid any "cut-out", "pasted", or composited appearance. The subject should be naturally integrated into the environment, with soft edge transitions, accurate ambient lighting, and subtle light reflections on skin and clothing.

Use realistic mobile photography characteristics:
– natural daylight or indoor ambient light
– slight depth of field (smartphone portrait style, not studio)
– mild lens imperfections (very subtle noise, natural sharpness)
– authentic skin tones and realistic textures

The final result should look like a real photo taken on a phone, not an AI composite or background replacement.`;

    // Smart prompts for different categories with photorealistic rules
    const categoryPrompts: Record<string, string[]> = {
      beach: [
        `${photoRules}\n\nScene: Place this person naturally at a tropical beach paradise with golden sand, crystal blue water, and palm trees. Capture it as a candid vacation moment with warm natural sunlight.`,
        `${photoRules}\n\nScene: Show this person enjoying a sunset by the ocean, with warm orange and pink colors in the sky reflecting on the water. Natural golden hour lighting.`,
        `${photoRules}\n\nScene: Create a relaxed beach scene with turquoise water, white sand, and tropical vibes. The person should look naturally placed as if actually there.`,
      ],
      city: [
        `${photoRules}\n\nScene: Place this person in an urban cityscape with modern skyscrapers and vibrant city atmosphere. Natural daylight with building shadows.`,
        `${photoRules}\n\nScene: Show this person exploring a beautiful metropolitan area with iconic buildings. Street photography style with natural ambient lighting.`,
        `${photoRules}\n\nScene: Create a stylish coffee shop moment in a trendy urban neighborhood. Warm indoor lighting with city view through windows.`,
      ],
      roadtrip: [
        `${photoRules}\n\nScene: Place this person on a scenic highway surrounded by mountains and open skies. Natural outdoor lighting with adventure vibes.`,
        `${photoRules}\n\nScene: Show this person with a camper van on a beautiful mountain road. Golden hour lighting with travel exploration mood.`,
        `${photoRules}\n\nScene: Create a classic road trip scene with endless highways and dramatic landscapes. Natural sunlight and travel adventure atmosphere.`,
      ],
      mountain: [
        `${photoRules}\n\nScene: Place this person in a breathtaking mountain setting with snow-capped peaks and alpine scenery. Natural outdoor lighting.`,
        `${photoRules}\n\nScene: Show this person on a hiking trail with mountain vistas and pine forests. Natural daylight filtering through trees.`,
        `${photoRules}\n\nScene: Create a serene mountain lake scene with dramatic peaks in the background. Sunrise/sunset golden hour lighting.`,
      ],
      cafe: [
        `${photoRules}\n\nScene: Place this person at a cozy cafe with warm interior lighting, enjoying coffee. Natural indoor ambient light.`,
        `${photoRules}\n\nScene: Show this person at a Parisian-style outdoor cafe with elegant atmosphere. Natural daylight with soft shadows.`,
        `${photoRules}\n\nScene: Create a hygge-inspired coffee shop moment with books and warm lighting. Cozy indoor atmosphere with natural window light.`,
      ],
      sunset: [
        `${photoRules}\n\nScene: Place this person against a stunning golden hour sunset with dramatic orange and pink sky. Natural backlighting.`,
        `${photoRules}\n\nScene: Show this person at a beach during magical sunset with warm colors reflecting on water. Golden hour photography.`,
        `${photoRules}\n\nScene: Create a romantic sunset landscape scene with beautiful twilight colors. Natural evening ambient lighting.`,
      ],
      cyberpunk: [
        `${photoRules}\n\nScene: Place this person in a neon-lit cyberpunk city street at night with vibrant purple and blue lights. Night photography with neon reflections.`,
        `${photoRules}\n\nScene: Show this person in a futuristic urban environment with holographic signs and rain-slicked streets. Dramatic neon lighting.`,
        `${photoRules}\n\nScene: Create a dystopian city scene with towering buildings and neon advertisements. Moody night atmosphere with colorful artificial lighting.`,
      ],
      studio: [
        `${photoRules}\n\nScene: Place this person in a professional photography studio with clean white background. Soft studio lighting setup.`,
        `${photoRules}\n\nScene: Show this person with dramatic studio lighting and artistic shadows. Professional portrait photography setup.`,
        `${photoRules}\n\nScene: Create a fashion photography studio scene with colored gel lights and modern backdrop. Professional lighting arrangement.`,
      ],
      nature: [
        `${photoRules}\n\nScene: Place this person in a lush forest with sunlight filtering through the trees. Natural dappled lighting and green surroundings.`,
        `${photoRules}\n\nScene: Show this person in a flower field during spring with vibrant colors. Natural daylight and nature photography style.`,
        `${photoRules}\n\nScene: Create a peaceful lakeside scene with this person enjoying nature. Calm water reflections and natural outdoor lighting.`,
      ],
      retro: [
        `${photoRules}\n\nScene: Place this person in a vintage 1970s-style setting with retro decor and warm color grading. Film photography aesthetic.`,
        `${photoRules}\n\nScene: Show this person at a classic American diner with neon signs and vintage atmosphere. Nostalgic retro lighting.`,
        `${photoRules}\n\nScene: Create a vintage Polaroid-style scene with faded colors and retro environment. Classic film camera aesthetic.`,
      ],
    };

    // Get prompts for selected category
    const prompts = categoryPrompts[category] || categoryPrompts.beach;

    try {
      // Create unique ID for the generated result
      const generatedId = admin.firestore().collection("_").doc().id;

      // 1. Download original image from Storage
      const bucket = storage.bucket();
      const file = bucket.file(imagePath);

      const [exists] = await file.exists();
      if (!exists) {
        throw new HttpsError("not-found", "Original image not found.");
      }

      // 2. Download original image and prepare for AI processing
      const [imageBuffer] = await file.download();
      const base64Image = imageBuffer.toString("base64");

      // Get the mime type from the file metadata
      const [metadata] = await file.getMetadata();
      const mimeType = metadata.contentType || "image/jpeg";

      // Initialize Gemini AI client
      const ai = new GoogleGenAI({
        apiKey: geminiApiKey.value(),
      });

      // 3. Generate multiple images based on category prompts
      const generatedImageUrls: string[] = [];

      // For each prompt in the category, generate an image
      for (let i = 0; i < prompts.length; i++) {
        const prompt = prompts[i];

        try {
          // Call Gemini 2.5 Flash Image API
          const response = await ai.models.generateContent({
            model: "gemini-2.5-flash-image",
            contents: [
              {
                parts: [
                  {
                    inlineData: {
                      mimeType: mimeType,
                      data: base64Image,
                    },
                  },
                  {
                    text: prompt,
                  },
                ],
              },
            ],
          });

          // Extract image from response
          console.log(`Full response for prompt ${i + 1}:`, JSON.stringify(response, null, 2));

          const candidate = response.candidates?.[0];
          if (!candidate) {
            console.error(`No candidate found for prompt ${i + 1}`);
            continue;
          }

          const content = candidate.content;
          if (!content) {
            console.error(`No content found for prompt ${i + 1}`);
            continue;
          }

          const parts = content.parts;
          if (!parts) {
            console.error(`No parts found for prompt ${i + 1}`);
            continue;
          }

          let imageDataBase64 = "";

          for (const part of parts) {
            console.log(`Part ${i + 1}:`, JSON.stringify(part, null, 2));

            // Try different possible fields for image data
            if (part.inlineData && part.inlineData.data) {
              imageDataBase64 = part.inlineData.data;
              console.log(`Found image data in inlineData for prompt ${i + 1}`);
              break;
            } else if ((part as any).data) {
              imageDataBase64 = (part as any).data;
              console.log(`Found image data in data field for prompt ${i + 1}`);
              break;
            } else if ((part as any).fileData) {
              imageDataBase64 = (part as any).fileData;
              console.log(`Found image data in fileData for prompt ${i + 1}`);
              break;
            }
          }

          if (!imageDataBase64) {
            console.error(`No image data found for prompt ${i + 1}`);
            continue;
          }

          // Decode base64 and save to Firebase Storage
          const imageBuffer = Buffer.from(imageDataBase64, "base64");
          const imageId = `${generatedId}_${i}`;
          const storagePath = `users/${uid}/generated/${imageId}.jpg`;
          const fileRef = bucket.file(storagePath);

          await fileRef.save(imageBuffer, {
            metadata: {
              contentType: "image/jpeg",
              metadata: {
                originalPrompt: prompt,
                category: category,
                generatedAt: new Date().toISOString(),
              },
            },
            // Make file publicly readable
            preconditionOpts: {
              ifGenerationMatch: 0,
            },
          });

          // Make file public (if not already)
          await fileRef.makePublic();

          // Get public URL
          const publicUrl = `https://storage.googleapis.com/${bucket.name}/${storagePath}`;

          generatedImageUrls.push(publicUrl);
          console.log(`Generated image ${i + 1}/${prompts.length} for category: ${category}`);
        } catch (error) {
          console.error(`Error generating image ${i + 1}:`, error);
          // Continue with next image even if one fails
        }
      }

      // 4. Save metadata to Firestore
      const timestamp = admin.firestore.Timestamp.now();
      const imageDoc = {
        userId: uid,
        originalImagePath: imagePath,
        category: category,
        prompts: prompts,
        generatedImageUrls: generatedImageUrls,
        createdAt: timestamp,
        status: generatedImageUrls.length > 0 ? "completed" : "partial",
        generatedCount: generatedImageUrls.length,
      };

      await firestore
        .collection("images")
        .doc(generatedId)
        .set(imageDoc);

      // 5. Return success response
      return {
        success: true,
        generatedId: generatedId,
        generatedImageUrls: generatedImageUrls,
        createdAt: timestamp.toDate().toISOString(),
      };
    } catch (error) {
      console.error("Error generating image:", error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "Failed to generate image. Please try again later."
      );
    }
  }
);
