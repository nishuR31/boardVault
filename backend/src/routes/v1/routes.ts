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

  // Read one by id
  app.get("/boards/:id", findById);
  // Read one by name (distinct path to avoid route conflict)
  app.get("/boards/name/:name", findOne);

  // Update
  app.put("/boards/:id", { preHandler: requireCrudPassword }, update);

  // Delete
  app.delete("/boards/:id", { preHandler: requireCrudPassword }, deleteOne);
};

export default routes;
