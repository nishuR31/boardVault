/**
 * Base Repository
 * Version: 1.0
 * Description: Generic repository with CRUD operations for data and image models
 * Last Updated: 2026-05-17
 */

import { dataPrisma, imagePrisma } from "../config/databaseConfig";
import {
  AppError,
  ConflictError,
  InternalServerError,
  NotFoundError,
} from "../utils/errors/error";

/**
 * Handle Prisma errors consistently across both clients
 */
function handlePrismaError(error: any, dataModelName: string, operation: string): never {
  // Log the full error for debugging
  console.error(`[PRISMA ERROR] ${operation} ${dataModelName}:`, {
    message: error?.message,
    code: error?.code,
    meta: error?.meta,
  });

  // Check for known Prisma error codes
  if (error?.code) {
    if (error.code === "P2025") {
      throw new NotFoundError(`${dataModelName} required for ${operation} not found.`, {
        original: { message: error.message, code: error.code, meta: error.meta },
      });
    }
    if (error.code === "P2002") {
      const field = error.meta?.target ? (error.meta.target as string[]).join(", ") : "";
      throw new ConflictError(
        `Conflict: A record with this unique field ${field} already exists.`,
        { original: { message: error.message, code: error.code, meta: error.meta } },
      );
    }
    if (error.code === "P2023") {
      throw new NotFoundError(`Invalid ID format supplied for ${dataModelName}`, {
        original: { message: error.message, code: error.code, meta: error.meta },
      });
    }
  }

  // Attach original error details for easier debugging while keeping message stable
  const message = `[Prisma Failure]: Failed ${operation} ${dataModelName} due to server error.`;
  const details = {
    original: {
      message: error?.message || String(error),
      code: error?.code,
      meta: error?.meta,
      stack: error?.stack,
    },
  };

  throw new InternalServerError(message, details);
}

export default class BaseRepository<T = any> {
  protected dataModelName: string;
  protected dataModel: any;
  protected imageModelName: string;
  protected imageModel: any;

  constructor(dataModelName: string, imageModelName: string) {
    if (!dataModelName || typeof dataModelName !== "string") {
      throw new AppError(
        `A ${dataModelName} model name(string) is required for BaseRepository.`,
      );
    }
    if (!imageModelName || typeof imageModelName !== "string") {
      throw new AppError(
        `A ${imageModelName} model name(string) is required for BaseRepository.`,
      );
    }

    this.dataModelName = dataModelName;
    this.dataModel = (dataPrisma as any)[dataModelName];
    this.imageModelName = imageModelName;
    this.imageModel = (imagePrisma as any)[imageModelName];

    if (!this.dataModel || typeof this.dataModel.findUnique !== "function") {
      throw new NotFoundError(
        `${dataModelName} not found or is invalid in Board Prisma Client.`,
      );
    }
    if (!this.imageModel || typeof this.imageModel.findUnique !== "function") {
      throw new NotFoundError(
        `${imageModelName} not found or is invalid in Image Prisma Client.`,
      );
    }
  }

  /**
   * Create a new record in the data model
   */
  async create(data: any, options: any = {}): Promise<T> {
    try {
      return await this.dataModel.create({ data, ...options });
    } catch (error) {
      handlePrismaError(error, this.dataModelName, "creation");
    }
  }

  /**
   * Upload image to image database
   */
  async upload(data: any, options: any = {}): Promise<any> {
    try {
      return await this.imageModel.create({ data, ...options });
    } catch (error) {
      handlePrismaError(error, this.imageModelName, "creation");
    }
  }

  /**
   * Find record by ID
   */
  async findById(userId: string, options: any = {}): Promise<T> {
    try {
      const record = await this.dataModel.findUnique({
        where: { id: userId },
        ...options,
      });
      if (!record) {
        throw new NotFoundError(`${this.dataModelName} with ID ${userId} not found`);
      }
      return record;
    } catch (error) {
      if (error instanceof NotFoundError) throw error;
      handlePrismaError(error, this.dataModelName, "fetching");
    }
  }

  /**
   * Find first record matching the condition
   */
  async findOne(where: any, options: any = {}): Promise<T | null> {
    try {
      return await this.dataModel.findFirst({ where, ...options });
    } catch (error) {
      handlePrismaError(error, this.dataModelName, "fetching one");
    }
  }

  /**
   * Find all records
   */
  async findAll(options: any = {}): Promise<T[]> {
    try {
      return await this.dataModel.findMany({ ...options });
    } catch (error) {
      handlePrismaError(error, this.dataModelName, "fetching all");
    }
  }

  /**
   * Update a record by ID
   */
  async update(id: string, data: any, options: any = {}): Promise<T> {
    try {
      return await this.dataModel.update({ where: { id }, data, ...options });
    } catch (error) {
      handlePrismaError(error, this.dataModelName, "updating");
    }
  }

  /**
   * Delete a record by ID
   */
  async deleteOne(id: string, options: any = {}): Promise<boolean> {
    try {
      await this.dataModel.delete({ where: { id }, ...options });
      return true;
    } catch (error) {
      handlePrismaError(error, this.dataModelName, "deleting");
    }
  }

  /**
   * Delete all records (use with caution; primarily for testing cleanup)
   */
  async deleteAll(): Promise<number> {
    try {
      const result = await this.dataModel.deleteMany({});
      return result.count;
    } catch (error) {
      handlePrismaError(error, this.dataModelName, "deleting all");
    }
  }
}
