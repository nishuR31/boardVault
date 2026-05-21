import { FastifyReply, FastifyRequest } from "fastify";

import { CRUD_PASSWORD } from "../config/envConfig";
import { UnauthorizedError } from "../utils/errors/error";

type PasswordBody = {
  password: string;
};

export default async function requireCrudPassword(
  req: FastifyRequest<{ Body: PasswordBody }>,
  reply: FastifyReply,
) {
  // Try to get password from header first (most reliable for all content types)
  const headerPassword = (req.headers &&
    (req.headers["x-crud-password"] || req.headers["crud-password"])) as
    | string
    | undefined;

  if (headerPassword === CRUD_PASSWORD) {
    return; // Header auth passed
  }

  // Try to get from body if header not provided
  let bodyPassword: string | undefined;
  try {
    // Use req.body which is already parsed by Fastify
    const body = (req.body || {}) as any;
    bodyPassword = body?.password;
  } catch (e) {
    // Body parsing failed, continue with header-only auth
  }

  const effective = bodyPassword || headerPassword;

  if (effective !== CRUD_PASSWORD) {
    throw new UnauthorizedError("Invalid password");
  }
}
