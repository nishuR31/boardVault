import Redis from "ioredis";
import { REDIS_URL } from "../../config/envConfig";

// In-memory fallback cache when Redis is unavailable or down
interface CacheEntry {
  val: string;
  expiresAt?: number;
}
const memoryCache = new Map<string, CacheEntry>();

let isRedisConnected = false;
let hasLoggedRedisWarning = false;

const redis = new Redis(REDIS_URL || "redis://localhost:6379", {
  lazyConnect: true,
  maxRetriesPerRequest: 1,
  enableOfflineQueue: false,
  connectTimeout: 3000,
  retryStrategy(times) {
    if (times > 3) {
      if (!hasLoggedRedisWarning) {
        console.warn(
          "[Cache] Redis host unreachable. Operating smoothly using in-memory cache fallback.",
        );
        hasLoggedRedisWarning = true;
      }
      return null; // Stop reconnecting after 3 failed attempts
    }
    return Math.min(times * 200, 1000);
  },
});

// CRITICAL: Prevent unhandled error events from crashing the process
redis.on("error", (err: any) => {
  isRedisConnected = false;
  if (!hasLoggedRedisWarning) {
    console.warn(
      `[Cache] Redis connection issue (${err?.code || err?.message || "unreachable"}). Using in-memory fallback.`,
    );
    hasLoggedRedisWarning = true;
  }
});

redis.on("connect", () => {
  isRedisConnected = true;
  hasLoggedRedisWarning = false;
  console.log("✓ [Cache] Redis connected successfully");
});

// Attempt lazy connection safely in the background
redis.connect().catch(() => {
  // Gracefully ignored, fallback handled
});

async function getRaw(key: string): Promise<string | null> {
  if (isRedisConnected) {
    try {
      return await redis.get(key);
    } catch {
      // Fallback to memory cache below
    }
  }

  // Memory fallback
  const entry = memoryCache.get(key);
  if (!entry) return null;
  if (entry.expiresAt && entry.expiresAt < Date.now()) {
    memoryCache.delete(key);
    return null;
  }
  return entry.val;
}

async function get<T = any>(key: string): Promise<T | null> {
  try {
    const raw = await getRaw(key);
    if (!raw) return null;
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

async function set(key: string, value: any, ttlSeconds?: number): Promise<void> {
  const raw = JSON.stringify(value);
  const expiresAt = ttlSeconds && ttlSeconds > 0 ? Date.now() + ttlSeconds * 1000 : undefined;

  // Always store in memory fallback
  memoryCache.set(key, { val: raw, expiresAt });

  if (isRedisConnected) {
    try {
      if (ttlSeconds && ttlSeconds > 0) {
        await redis.set(key, raw, "EX", ttlSeconds);
      } else {
        await redis.set(key, raw);
      }
    } catch {
      // Ignore Redis set failure, memory cache already updated
    }
  }
}

async function del(key: string | string[]): Promise<void> {
  const keys = Array.isArray(key) ? key : [key];
  for (const k of keys) {
    memoryCache.delete(k);
  }

  if (isRedisConnected && keys.length > 0) {
    try {
      await redis.del(...keys);
    } catch {
      // Ignore failure
    }
  }
}

async function getOrSet<T>(
  key: string,
  ttlSeconds: number,
  fetcher: () => Promise<T>,
): Promise<T> {
  try {
    const cached = await get<T>(key);
    if (cached !== null && cached !== undefined) return cached;
  } catch {
    // Continue to fetcher on cache error
  }

  const fresh = await fetcher();
  try {
    await set(key, fresh, ttlSeconds);
  } catch {
    // Ignore cache set error
  }
  return fresh;
}

export { redis, get, getOrSet, set, del };
