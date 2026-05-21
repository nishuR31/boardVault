import { FastifyReply, FastifyRequest } from "fastify";

import { imagePrisma } from "../config/databaseConfig";
import { STATUS_CODES } from "../utils/common/constants";
import { NotFoundError } from "../utils/errors/error";

function getImageMimeType(name?: string) {
  const lower = (name || "").toLowerCase();
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".webp")) return "image/webp";
  if (lower.endsWith(".gif")) return "image/gif";
  if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
  return "application/octet-stream";
}

export async function getImageById(
  req: FastifyRequest<{ Params: { id: string } }>,
  res: FastifyReply,
) {
  const { id } = req.params;
  const image = await imagePrisma.image.findUnique({ where: { id } });

  if (!image) {
    throw new NotFoundError(`Image with id ${id} not found`);
  }

  const mimeType = getImageMimeType(image.name);
  res.code(STATUS_CODES.OK).type(mimeType).send(Buffer.from(image.data));
}
