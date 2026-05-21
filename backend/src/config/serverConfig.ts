import fastify from "fastify";
import { FastifyReply, FastifyRequest } from "fastify";
import cors from "@fastify/cors";
import multipart from "@fastify/multipart";

import { STATUS_CODES } from "../utils/common/constants";
import apiRouter from "../routes/apiRoutes";
import { sendError } from "../utils/common/response";

import errorHandler from "../middlewares/errorHandlerMiddleware";
import { TooManyRequestsError } from "../utils/errors/error";
import {
  RATE_LIMIT_MAX_REQUESTS,
  RATE_LIMIT_WINDOW_SECONDS,
  NODE_ENV,
  PORT,
  BACKEND,
  FRONTEND,
} from "./envConfig";

let fastifyApp = fastify({ logger: true, exposeHeadRoutes: true });

const allowedOrigins = new Set<string>([
  "http://localhost:3000",
  "http://localhost:3001",
  "http://localhost:3030",
  "http://127.0.0.1:3000",
  "http://127.0.0.1:3001",
  "http://127.0.0.1:3030",
]);

if (FRONTEND) {
  FRONTEND.split(",")
    .map((origin) => origin.trim())
    .filter(Boolean)
    .forEach((origin) => allowedOrigins.add(origin));
}

if (BACKEND) {
  try {
    const backendUrl = new URL(BACKEND);
    allowedOrigins.add(`${backendUrl.protocol}//${backendUrl.host}`);
  } catch {
    // ignore invalid backend URLs
  }
}

fastifyApp.register(cors, {
  origin: (origin, cb) => {
    if (!origin) {
      cb(null, true);
      return;
    }

    if (allowedOrigins.has(origin)) {
      cb(null, true);
      return;
    }

    cb(new Error(`CORS blocked for origin: ${origin}`), false);
  },
  credentials: true,
});
// Allow larger multipart uploads (5 MB per file) for image uploads
fastifyApp.register(multipart, { limits: { fileSize: 5 * 1024 * 1024 } });
const rateLimitWindow = RATE_LIMIT_WINDOW_SECONDS;
const rateLimitReq = RATE_LIMIT_MAX_REQUESTS;

type RateLimitEntry = {
  count: number;
  resetAt: number;
};

const rateLimitStore = new Map<string, RateLimitEntry>();

fastifyApp.addHook("onRequest", async (req: FastifyRequest, reply: FastifyReply) => {
  if (
    req.url === "/" ||
    req.url === "/ping" ||
    req.url === "/health" ||
    req.url === "/date"
  ) {
    return;
  }

  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
  const key = `ratelimit:${ip}:${req.method}:${req.url}`;

  const now = Date.now();
  const currentEntry = rateLimitStore.get(key);

  if (!currentEntry || currentEntry.resetAt <= now) {
    rateLimitStore.set(key, {
      count: 1,
      resetAt: now + rateLimitWindow * 1000,
    });
    return;
  }

  currentEntry.count += 1;

  if (currentEntry.count > rateLimitReq) {
    const retryAfterSeconds = Math.max(1, Math.ceil((currentEntry.resetAt - now) / 1000));
    reply.header("Retry-After", String(retryAfterSeconds));
    throw new TooManyRequestsError("Too many requests. Please try again later.", {
      limit: rateLimitReq,
      windowSeconds: rateLimitWindow,
      retryAfterSeconds,
    });
  }
});

fastifyApp.get("/", (req: FastifyRequest, res: FastifyReply) => {
  res.code(200).send({ message: "Server fired up" });
});
fastifyApp.register(apiRouter);

fastifyApp.get("/health", (req: FastifyRequest, res: FastifyReply) => {
  res.status(STATUS_CODES.OK).send({
    success: true,
    message: "API is healthy and is running",
    timestamp: new Date().toLocaleString(),
    uptime: process.uptime(),
  });
});
fastifyApp.get("/ping", (req: FastifyRequest, res: FastifyReply) => {
  res.status(STATUS_CODES.OK).send({ pong: "pong" });
});
fastifyApp.get("/help", (req: FastifyRequest, res: FastifyReply) => {
  let data: object = {
    Environment: NODE_ENV,
    Port: `${PORT}`,
    Address: `${BACKEND}`,
    Health: `${BACKEND}/health`,
    Date: `${BACKEND}/date`,
    Ping: `${BACKEND}/ping`,
    "API Base": `${BACKEND}/api/v1`,
  };
  res.status(STATUS_CODES.OK).send(data);
});

fastifyApp.get("/today", (req: FastifyRequest, res: FastifyReply) => {
  res.code(200).send({
    date: new Date().toLocaleString("en-IN", {
      hour: "2-digit",
      hour12: true,
      year: "numeric",
      month: "long",
      weekday: "long",
      day: "numeric",
      minute: "2-digit",
      second: "2-digit",
    }),
  });
});

fastifyApp.setNotFoundHandler((req: FastifyRequest, res: FastifyReply) => {
  sendError(res, "Route not found", STATUS_CODES.NOT_FOUND);
});
fastifyApp.setErrorHandler(errorHandler);

export default fastifyApp;
