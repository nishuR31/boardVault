import { FastifyPluginAsync } from "fastify";

import {
  create,
  deleteOne,
  findOne,
  findById,
  findAll,
  update,
  ping,
} from "../../controllers/controller";

import requireCrudPassword from "../../middlewares/auth";

const routes: FastifyPluginAsync = async (app) => {
  // Health check
  app.get("/ping", ping);

  // Create
  app.post("/boards", { preHandler: requireCrudPassword }, create);

  // Read all
  app.get("/boards", findAll);

  // Read one
  app.get("/boards/:id", findById);
  app.get("/boards/:name", findOne);

  // Update
  app.put("/boards/:id", { preHandler: requireCrudPassword }, update);

  // Delete
  app.delete("/boards/:id", { preHandler: requireCrudPassword }, deleteOne);
};

export default routes;
