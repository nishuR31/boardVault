/**
 * Board Repository
 * Version: 1.0
 * Description: Repository for Board model with image support
 * Last Updated: 2026-05-17
 */

import { Board } from "../generated/board-client/client";
import { Image } from "../generated/image-client/client";
import BaseRepository from "./baseRepository";

export default class BoardRepository extends BaseRepository<Board | Image> {
  /**
   * Constructor
   * Initializes the repository with Board and Image models
   */
  constructor() {
    super("board", "image");
  }
}
