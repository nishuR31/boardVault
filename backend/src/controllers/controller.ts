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
    // collect multipart files (photoFront, photoBack, pinDiagram) if any
    const files: Record<string, any> = {};
    // folderId may come in body for Drive destination
    const { photoFront, pinDiagram, ...payload } = req.body as any;
    files[photoFront] = photoFront;
    files[pinDiagram] = pinDiagram;

    const result = await service.create(payload, files);
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

export const ping = asyncHandler(async (req: FastifyRequest, res: FastifyReply) => {
  sendSuccess(res, "pong", STATUS_CODES.OK, "pong");
});
