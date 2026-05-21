import BoardRepository from "../repositories/boardRepository";
import { CreateBody, UpdateBody } from "../types";
import { NotFoundError } from "../utils/errors/error";
import { getOrSet, del, set } from "../utils/cache/cache";
import { compressImage, bufferToStream } from "../utils/imageCompress";

const boardRepo = new BoardRepository();

const ALL_BOARDS_KEY = "boards:all";
const BOARD_BY_NAME = (name: string) => `board:name:${name}`;
const BOARD_BY_ID = (id: string) => `board:id:${id}`;

// Helper to generate URL-friendly slug from name
function generateSlug(name: string): string {
  return name
    .toLowerCase()
    .trim()
    .replace(/\s+/g, "-") // Replace spaces with hyphens
    .replace(/[^\w-]/g, "") // Remove non-word characters except hyphens
    .replace(/-+/g, "-") // Replace multiple hyphens with single hyphen
    .replace(/^-+|-+$/g, ""); // Remove leading/trailing hyphens
}

export default class Service {
  async create(data: CreateBody, files?: Record<string, any>) {
    const { password, ...payload } = data;

    // Generate slug from name if not provided
    if (!payload.slug && payload.name) {
      payload.slug = generateSlug(payload.name);
    }

    // if files provided, upload them first and attach urls to payload
    try {
      if (files) {
        const uploadPics: Record<string, any> = {};
        for (const key of Object.keys(files)) {
          const file = files[key];
          const uploaded = await this.uploadPic(file);
          uploadPics[key] = uploaded;
          if (!uploadPics[key]) continue;
        }

        // map known keys to payload fields
        if (uploadPics.photoFront) payload.photoFrontId = uploadPics.photoFront;
        if (uploadPics.photoFrontId) payload.photoFrontId = uploadPics.photoFrontId;
        if (uploadPics.pinDiagram) payload.pinDiagramId = uploadPics.pinDiagram;
        if (uploadPics.pinDiagramId) payload.pinDiagramId = uploadPics.pinDiagramId;
      }
    } catch (e) {
      // don't fail cache logic; propagate after trying to create record
    }
    // invalidate list cache, set individual cache
    const created = await boardRepo.create(payload);
    void Promise.all([
      del(ALL_BOARDS_KEY),
      set(BOARD_BY_ID(created.id), created, 60 * 5),
      set(BOARD_BY_NAME(created.name), created, 60 * 5),
    ]).catch(() => {
      // ignore cache errors
    });
    return created;
  }

  async findAll() {
    return getOrSet(ALL_BOARDS_KEY, 60, async () => {
      return boardRepo.findAll({ orderBy: { createdAt: "desc" } });
    });
  }
  async findById(id: string) {
    return getOrSet(ALL_BOARDS_KEY, 60, async () => {
      return boardRepo.findById(id);
    });
  }

  async findOne(name: string) {
    const board = await getOrSet(BOARD_BY_NAME(name), 60, async () => {
      const b = await boardRepo.findOne({ name });
      if (!b) throw new NotFoundError(`Board with name ${name} not found`);
      return b;
    });

    if (!board) {
      throw new NotFoundError(`Board with name ${name} not found`);
    }

    return board;
  }

  async update(id: string, data: UpdateBody) {
    const { password: _password, ...payload } = data;
    const board = await boardRepo.findById(id);
    const updated = await boardRepo.update(board.id, payload);

    void Promise.all([
      del([ALL_BOARDS_KEY, BOARD_BY_ID(id), BOARD_BY_NAME(board.name)]),
      set(BOARD_BY_ID(updated.id), updated, 60 * 5),
      set(BOARD_BY_NAME(updated.name), updated, 60 * 5),
    ]).catch(() => {
      // ignore cache errors
    });

    return updated;
  }

  async deleteOne(id: string) {
    const board = await boardRepo.findById(id);
    const deleted = await boardRepo.deleteOne(board.id);
    void del([ALL_BOARDS_KEY, BOARD_BY_ID(id), BOARD_BY_NAME(board.name)]).catch(() => {
      // ignore cache errors
    });
    return deleted;
  }

  async deleteAll() {
    const deleted = await boardRepo.deleteAll();
    void del(ALL_BOARDS_KEY).catch(() => {
      // ignore cache errors
    });
    return deleted;
  }

  async uploadPic(file: any) {
    // Normalize many input formats: data URI string, { base64, mimetype, filename }, { file: Buffer|Stream, mimetype, filename }
    let name = file?.filename || file?.name || "upload";
    let mime = file?.mimetype || "image/jpeg";
    let inputBuffer: Buffer | null = null;

    // data URI
    if (typeof file === "string" && file.startsWith("data:")) {
      const m = file.match(/^data:([^;]+);base64,(.*)$/);
      if (m) {
        mime = m[1];
        inputBuffer = Buffer.from(m[2], "base64");
      }
    }

    // object with base64
    if (!inputBuffer && file && typeof file === "object" && file.base64) {
      mime = file.mimetype || mime;
      inputBuffer = Buffer.from(file.base64, "base64");
    }

    // file.file could be Buffer or stream
    if (!inputBuffer && file && typeof file === "object" && file.file) {
      if (Buffer.isBuffer(file.file)) {
        inputBuffer = file.file;
      } else if (file.file.readable) {
        // stream -> buffer
        inputBuffer = await new Promise<Buffer>((resolve, reject) => {
          const chunks: Buffer[] = [];
          file.file.on("data", (c: Buffer) => chunks.push(Buffer.from(c)));
          file.file.on("end", () => resolve(Buffer.concat(chunks)));
          file.file.on("error", (err: any) => reject(err));
        });
      }
    }

    // If we have a buffer, try to compress
    if (inputBuffer) {
      try {
        const compressed = await compressImage(inputBuffer, mime);
        inputBuffer = compressed;
        // normalize
        if (!/png/i.test(mime)) mime = "image/jpeg";
      } catch (e) {
        // ignore
      }
    }

    // Prepare prisma payload
    const data: any = { name };
    if (inputBuffer) data.data = inputBuffer;

    const { id } = await boardRepo.upload(data);
    return id;
  }
}
