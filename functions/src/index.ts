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

    // Smart prompts for different categories
    const categoryPrompts: Record<string, string[]> = {
      beach: [
        "Transform this photo into a tropical beach paradise scene with golden sand, crystal blue water, and palm trees. Make it look like a perfect Instagram beach vacation moment.",
        "Create a dreamy beach getaway scene with this person enjoying the sunset by the ocean, with warm orange and pink colors in the sky.",
        "Turn this into a luxurious beach resort scene with turquoise water, white sand, and tropical vibes perfect media.",
      ],
      city: [
        "Transform this into an urban cityscape scene with modern skyscrapers, busy streets, and vibrant city lights. Make it look like a trendy city break.",
        "Create a stylish city adventure scene with this person exploring a beautiful metropolitan area with iconic buildings and street art.",
        "Turn this into a cosmopolitan lifestyle scene with urban landscapes, coffee shops, and city exploration vibes.",
      ],
      roadtrip: [
        "Create an epic road trip adventure scene with this person on a scenic highway surrounded by mountains, forests, and open skies.",
        "Transform this into a van life moment with a camper van on a beautiful mountain road, perfect for travel enthusiasts.",
        "Turn this into a classic American road trip scene with endless highways, rest stops, and adventure on the open road.",
      ],
      mountain: [
        "Create a breathtaking mountain adventure scene with snow-capped peaks, alpine lakes, and this person enjoying the majestic wilderness.",
        "Transform this into a hiking adventure scene with mountain trails, pine forests, and panoramic views from the summit.",
        "Turn this into a serene mountain retreat with dramatic peaks, sunrise views, and peaceful nature vibes.",
      ],
      cafe: [
        "Create a cozy cafe culture scene with this person enjoying coffee at a trendy urban coffee shop with warm lighting and aesthetic vibes.",
        "Transform this into a Parisian-style cafe moment with outdoor seating, croissants, and elegant coffee culture.",
        "Turn this into a hygge-inspired cafe scene with warm lighting, books, coffee, and cozy interior design.",
      ],
      sunset: [
        "Create a stunning golden hour sunset scene with this person silhouetted against a dramatic orange and pink sky.",
        "Transform this into a magical sunset beach scene with warm colors reflecting on the water and a perfect evening atmosphere.",
        "Turn this into a romantic sunset landscape with this person enjoying the beautiful colors of twilight.",
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
