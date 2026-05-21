import { FastifyReply, FastifyRequest } from "fastify";

import Service from "../services/service";
import asyncHandler from "../utils/common/asyncHandler";
import { sendSuccess } from "../utils/common/response";
import { STATUS_CODES } from "../utils/common/constants";
import { CreateBody, DeleteBody, FindOneBody, UpdateBody } from "../types";

const service = new Service();

type CreateRequest = FastifyRequest<{
  Body: CreateBody;
}>;
type DeleteRequest = FastifyRequest<{
  Params: { id: string };
  Body: DeleteBody;
}>;
type FindOneRequest = FastifyRequest<{
  Params: FindOneBody;
}>;
type UpdateRequest = FastifyRequest<{
  Params: { id: string };
  Body: UpdateBody;
}>;

async function parseBoardPayload(req: FastifyRequest) {
  const rawBody = (req.body || {}) as any;
  let payload: any = {};
  const files: Record<string, any> = {};

  const contentType = (req.headers?.["content-type"] || "").toString();
  if (contentType.includes("multipart/form-data") && (req as any).parts) {
    for await (const part of (req as any).parts()) {
      if (part.file) {
        const chunks: Buffer[] = [];
        for await (const chunk of part.file) chunks.push(Buffer.from(chunk));
        files[part.fieldname] = {
          file: Buffer.concat(chunks),
          mimetype: part.mimetype,
          filename: part.filename,
        };
      } else {
        payload[part.fieldname] = part.value;
      }
    }
  } else {
    payload = { ...rawBody };
    const fileFields = [
      "photoFront",
      "photoFrontId",
      "pinDiagram",
      "pinDiagramId",
      "photo",
    ];
    for (const field of fileFields) {
      if (payload[field]) {
        files[field] = payload[field];
        delete payload[field];
      }
    }

    if (files.photo && !files.photoFrontId) {
      files.photoFrontId = files.photo;
      delete files.photo;
    }
  }

  const arrayFields = ["category", "bestFor", "alternatives"];
  for (const field of arrayFields) {
    if (typeof payload[field] === "string") {
      try {
        payload[field] = JSON.parse(payload[field]);
      } catch {
        if (payload[field].includes(",")) {
          payload[field] = payload[field].split(",").map((value: string) => value.trim());
        }
      }
    }
  }

  const fileFieldsFromPayload = ["photoFront", "pinDiagram", "photo"];
  for (const field of fileFieldsFromPayload) {
    if (payload[field]) {
      files[field] = payload[field];
      delete payload[field];
    }
  }

  const { password, ...rest } = payload;
  return { payload: rest, files };
}

export const create = asyncHandler(
  async (req: CreateRequest, res: FastifyReply): Promise<any> => {
    const { payload, files } = await parseBoardPayload(req);

    console.info(
      "[controller.create] received payload keys:",
      Object.keys(payload),
      "file keys:",
      Object.keys(files),
    );

    const result = await service.create(payload, files);
    console.info("[controller.create] service.create returned:", result && result.id);
    sendSuccess(res, "Data successfully added", STATUS_CODES.CREATED, result);
  },
);

export const deleteOne = asyncHandler(async (req: DeleteRequest, res: FastifyReply) => {
  const { id } = req.params;
  const result = await service.deleteOne(id);
  sendSuccess(res, "Deletion successful", STATUS_CODES.OK, result);
});

export const findOne = asyncHandler(async (req: FindOneRequest, res: FastifyReply) => {
  const { name } = req.params;
  const result = await service.findOne(name as string);
  sendSuccess(res, "Data found successful", STATUS_CODES.OK, result);
});

export const findById = asyncHandler(async (req: FindOneRequest, res: FastifyReply) => {
  const { id } = req.params;
  const result = await service.findById(id);
  sendSuccess(res, "Data found successful", STATUS_CODES.OK, result);
});

export const findAll = asyncHandler(async (_req: FastifyRequest, res: FastifyReply) => {
  const result = await service.findAll();
  sendSuccess(res, "Data found successful", STATUS_CODES.OK, result);
});

export const update = asyncHandler(async (req: UpdateRequest, res: FastifyReply) => {
  const { id } = req.params;
  const { payload, files } = await parseBoardPayload(req);
  const result = await service.update(id, payload as any, files);
  sendSuccess(res, "Data updated successfully", STATUS_CODES.OK, result);
});

export const deleteAll = asyncHandler(async (_req: FastifyRequest, res: FastifyReply) => {
  const result = await service.deleteAll();
  sendSuccess(res, `Deleted ${result} boards`, STATUS_CODES.OK, { deleted: result });
});

export const ping = asyncHandler(async (_req: FastifyRequest, res: FastifyReply) => {
  sendSuccess(res, "pong", STATUS_CODES.OK, "pong");
});
