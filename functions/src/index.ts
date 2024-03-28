/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import axios from "axios";
import * as cors from "cors";
import { API_KEY } from './api_keys';

const corsHandler = cors({origin: true});

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

export const maps = onRequest((request, response) => {
  corsHandler(request, response, async () => {
    try {
      const mapsResponse = await axios.get("https://maps.googleapis.com/maps/api/js?key="+API_KEY+"&loading=async");
      response.send(mapsResponse.data);
    } catch (error) {
      logger.error("Error fetching Google Maps API", {structuredData: true});
      response.status(500).send(error);
    }
  });
});
