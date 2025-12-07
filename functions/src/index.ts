/**
 * Cloud Functions for Photo AI App
 *
 * This function handles AI image generation using Google Gemini API.
 * The API key is stored securely using Firebase Secrets.
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {setGlobalOptions} from "firebase-functions/v2";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import {GoogleGenerativeAI} from "@google/generative-ai";

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
    const {imagePath, prompt} = request.data;

    // Validate input
    if (!imagePath || typeof imagePath !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "imagePath is required and must be a string."
      );
    }

    if (!prompt || typeof prompt !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "prompt is required and must be a string."
      );
    }

    try {
      // 1. Download original image from Storage
      const bucket = storage.bucket();
      const file = bucket.file(imagePath);

      const [exists] = await file.exists();
      if (!exists) {
        throw new HttpsError("not-found", "Original image not found.");
      }

      const [imageBuffer] = await file.download();
      const base64Image = imageBuffer.toString("base64");

      // Get the mime type from the file metadata
      const [metadata] = await file.getMetadata();
      const mimeType = metadata.contentType || "image/jpeg";

      // 2. Call Google Gemini API for image generation
      const genAI = new GoogleGenerativeAI(geminiApiKey.value());
      const model = genAI.getGenerativeModel({model: "gemini-1.5-flash-001"});

      const result = await model.generateContent([
        {
          inlineData: {
            mimeType: mimeType,
            data: base64Image,
          },
        },
        {
          text: prompt,
        },
      ]);

      const response = result.response;
      const generatedText = response.text();

      // 3. Create unique ID for the generated result
      const generatedId = admin.firestore().collection("_").doc().id;
      const timestamp = admin.firestore.Timestamp.now();

      // 4. Save metadata to Firestore
      const imageDoc = {
        userId: uid,
        originalImagePath: imagePath,
        prompt: prompt,
        generatedText: generatedText,
        createdAt: timestamp,
        status: "completed",
      };

      await firestore
        .collection("images")
        .doc(generatedId)
        .set(imageDoc);

      // 5. Return success response
      return {
        success: true,
        generatedId: generatedId,
        generatedText: generatedText,
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
