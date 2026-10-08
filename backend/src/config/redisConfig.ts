import Redis from "ioredis";
import { REDIS_URL } from "./envConfig";

let isConnected = false;

const redis = new Redis(REDIS_URL || "redis://localhost:6379", {
  maxRetriesPerRequest: 1,
  enableOfflineQueue: false,
  lazyConnect: true,
  retryStrategy(times) {
    if (times > 2) {
      return null; // Stop reconnecting after 2 tries
    }
    return 500;
  },
});

redis.on("connect", () => {
  isConnected = true;
  console.info("✓ Redis connected");
});

redis.on("error", (err: any) => {
  isConnected = false;
  // Non-fatal, suppress unhandled error crash
});

redis.on("close", () => {
  isConnected = false;
});

export async function connectRedis(): Promise<void> {
  try {
    await redis.connect();
  } catch (err: any) {
    console.warn("⚠️  Redis connection failed (non-fatal, continuing without Redis):", err?.code || err?.message || "unreachable");
  }
}

export async function disconnectRedis(): Promise<void> {
  try {
    if (isConnected) {
      await redis.quit();
      console.info("Redis disconnected gracefully.");
    }
  } catch {}
}

export default redis;
