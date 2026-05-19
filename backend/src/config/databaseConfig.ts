/**
 * Database Configuration
 * Version: 1.0
 * Description: Manages connections to Board and Image databases
 * Last Updated: 2026-05-17
 */

import { PrismaClient as BoardPrismaClient } from "../generated/board-client/client";
import { PrismaClient as ImagePrismaClient } from "../generated/image-client/client";
import { DATABASE_URL, IMAGE_DATABASE_URL, NODE_ENV } from "./envConfig";

function createPrismaClient(Client: any, datasourceUrl?: string) {
  if (
    !datasourceUrl ||
    typeof datasourceUrl !== "string" ||
    datasourceUrl.trim() === ""
  ) {
    throw new Error(
      `Missing Prisma datasource URL for ${Client?.name || "PrismaClient"}. Set the matching env var in .env.`,
    );
  }

  return new Client({
    datasourceUrl,
    log: NODE_ENV === "development" ? ["error", "query", "warn"] : ["warn", "error"],
  });
}

// Board Database Client
const dataPrisma = createPrismaClient(BoardPrismaClient, DATABASE_URL);

// Image Database Client
const imagePrisma = createPrismaClient(ImagePrismaClient, IMAGE_DATABASE_URL);

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
