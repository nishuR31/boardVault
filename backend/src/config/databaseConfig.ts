/**
 * Database Configuration
 * Version: 1.0
 * Description: Manages connections to Board and Image databases
 * Last Updated: 2026-05-17
 */

import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient as BoardPrismaClient } from "../generated/board-client/client";
import { PrismaClient as ImagePrismaClient } from "../generated/image-client/client";
import { DATABASE_URL, IMAGE_DATABASE_URL, NODE_ENV } from "./envConfig";

// Board Database Client
const dataPrisma = new BoardPrismaClient({
  log: NODE_ENV === "development" ? ["error", "query", "warn"] : ["warn", "error"],
});

// Image Database Client
const imagePrisma = new ImagePrismaClient({
  log: NODE_ENV === "development" ? ["error", "query", "warn"] : ["warn", "error"],
});

/**
 * Shutdown handler for graceful disconnection
 */
function shutDownHandler(signal: string) {
  return async () => {
    console.log(`${signal} received, shutting down gracefully...`);
    try {
      await dataPrisma.$disconnect();
      console.log("Board database disconnected");
      await imagePrisma.$disconnect();
      console.log("Image database disconnected");
    } catch (error) {
      console.error("Error during shutdown:", error);
    }
    process.exit(0);
  };
}

// Handle termination signals
process.on("SIGINT", shutDownHandler("SIGINT"));
process.on("SIGTERM", shutDownHandler("SIGTERM"));

export { dataPrisma, imagePrisma };
