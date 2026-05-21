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

export const create = asyncHandler(
  async (req: CreateRequest, res: FastifyReply): Promise<any> => {
    // Accept either JSON body with inline file objects or multipart uploads (best-effort).
    const rawBody = (req.body || {}) as any;

    // If request is multipart/form-data, try to parse parts (files + fields)
    let payload: any = {};
    const files: Record<string, any> = {};

    const contentType = (req.headers && (req.headers["content-type"] || "")).toString();
    if (contentType.includes("multipart/form-data") && (req as any).parts) {
      // consume parts async
      for await (const part of (req as any).parts()) {
        if (part.file) {
          // collect stream into buffer
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
      // fallback: extract potential file fields from JSON body
      payload = { ...rawBody };
      const fileFields = [
        "photoFront",
        "photoFrontId",
        "pinDiagram",
        "pinDiagramId",
        "photo",
      ];
      for (const f of fileFields) {
        if (payload[f]) {
          files[f] = payload[f];
          delete payload[f];
        }
      }

      // Map 'photo' to 'photoFrontId' if it exists in files
      if (files.photo && !files.photoFrontId) {
        files.photoFrontId = files.photo;
        delete files.photo;
      }
    }

    // Remove password from payload (middleware already validated it)
    const { password, ...rest } = payload;

    console.info(
      "[controller.create] received payload keys:",
      Object.keys(rest),
      "file keys:",
      Object.keys(files),
    );
    const result = await service.create(rest, files);
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
export const findAll = asyncHandler(async (req: FastifyRequest, res: FastifyReply) => {
  const result = await service.findAll();
  sendSuccess(res, "Data found successful", STATUS_CODES.OK, result);
});

export const update = asyncHandler(async (req: UpdateRequest, res: FastifyReply) => {
  const { id } = req.params;
  const result = await service.update(id, req.body);
  sendSuccess(res, "Data updated successfully", STATUS_CODES.OK, result);
});

export const deleteAll = asyncHandler(async (req: FastifyRequest, res: FastifyReply) => {
  const result = await service.deleteAll();
  sendSuccess(res, `Deleted ${result} boards`, STATUS_CODES.OK, { deleted: result });
});

export const ping = asyncHandler(async (req: FastifyRequest, res: FastifyReply) => {
  sendSuccess(res, "pong", STATUS_CODES.OK, "pong");
});
