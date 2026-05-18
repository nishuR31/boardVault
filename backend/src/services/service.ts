import BoardRepository from "../repositories/boardRepository";
import { CreateBody, UpdateBody } from "../types";
import { NotFoundError } from "../utils/errors/error";
import { getOrSet, del, set } from "../utils/cache/cache";
import { compressImage, bufferToStream } from "../utils/imageCompress";

const boardRepo = new BoardRepository();

const ALL_BOARDS_KEY = "boards:all";
const BOARD_BY_NAME = (name: string) => `board:name:${name}`;
const BOARD_BY_ID = (id: string) => `board:id:${id}`;

export default class Service {
  async create(data: CreateBody, files?: Record<string, any>) {
    const { password, ...payload } = data;
    // if files provided, upload them first and attach urls to payload
    try {
      if (files) {
        const uploadPics: Record<string, any> = {};
        for (const key in Object.keys(files)) {
          const uploaded = await this.uploadPic(files[key]);
          uploadPics[key] = uploaded;
          if (!uploadPics[key]) continue;
        }

        // map known keys to payload fields
        if (uploadPics.photoFront) payload.photoFront = uploadPics.photoFront;
        if (uploadPics.pinDiagram) payload.pinDiagram = uploadPics.pinDiagram;
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

  async uploadPic(file: any) {
    try {
      if (
        file &&
        file.mimetype &&
        typeof file.mimetype === "string" &&
        file.mimetype.startsWith("image/")
      ) {
        // compress image stream or buffer
        const compressed = await compressImage(file.file, file.mimetype);
        file.file = bufferToStream(compressed);
        // normalize to jpeg for lossy compression when appropriate
        if (!/png/i.test(file.mimetype)) {
          file.mimetype = "image/jpeg";
        }
      }
    } catch (e) {
      // if compression fails, proceed with original file
    }

    const { id, name, data } = await boardRepo.upload(file);
    return {
      id,
      name,
      data,
    };
  }
}
