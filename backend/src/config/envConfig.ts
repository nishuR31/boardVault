import dotenv from "dotenv";

dotenv.config();

export const PORT = Number(process.env.PORT) || 3001;
export const BACKEND =
  process.env.BACKEND || `http://127.0.0.1:${Number(process.env.PORT) || 3001}`;

export const DATABASE_URL = process.env.DB_URL;
export const IMAGE_DATABASE_URL = process.env.IMG_URL;
export const NODE_ENV = process.env.NODE_ENV || "development";
export const CRUD_PASSWORD = process.env.CRUD_PASSWORD || "---";
export const RATE_LIMIT_MAX_REQUESTS = Number(process.env.RATE_LIMIT_MAX_REQUESTS);
export const RATE_LIMIT_WINDOW_SECONDS = Number(process.env.RATE_LIMIT_WINDOW_SECONDS);
export const REDIS_URL = process.env.REDIS_URL || "redis://localhost:6379";
