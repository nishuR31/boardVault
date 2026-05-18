import app from "./config/serverConfig";
import { PORT, NODE_ENV } from "./config/envConfig";
import redis, { disconnectRedis } from "./config/redisConfig";
import basePrisma from "./config/databaseConfig";

const startServer = async () => {
  try {
    const address = await app.listen({ port: PORT });
    console.info(`BoardVault started`);
    console.info(`   Environment : ${NODE_ENV}`);
    console.info(`   Port        : ${PORT}`);
    console.info(`   Address     : ${address}`);
    console.info(`   Health      : ${address}/health`);
    console.info(`   Date        : ${address}/date`);
    console.info(`   Ping        : ${address}/ping`);
    console.info(`   API Base    : ${address}/api/v1`);
  } catch (err: any) {
    console.error(err?.message || err);
    process.exit(1);
  }
};

// await basePrisma.$connect();
await startServer();
await redis.connect();

async function gracefulShutdown(signal: string) {
  console.info(`\n Received ${signal}. Shutting down gracefully…`);

  app.close(async () => {
    console.info("HTTP server closed.");

    try {
      await disconnectRedis();
    } catch (err) {
      console.error("Error dismounting RAM", { error: err });
    }

    console.info("All connections closed. Goodbye!");
    process.exit(0);
  });

  setTimeout(() => {
    console.error("Shutdown timed out. Forcing exit.");
    process.exit(1);
  }, 10_000);
}

process.on("SIGINT", () => gracefulShutdown("SIGINT"));
process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));

process.on("unhandledRejection", (reason: any) => {
  console.error("Unhandled Rejection", { error: reason?.message || reason });
});

process.on("uncaughtException", (error: Error) => {
  console.error("Uncaught Exception", {
    error: error.message,
    stack: error.stack,
  });
  process.exit(1);
});
