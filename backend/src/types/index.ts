export type BoardType = "SBC" | "MC";

export type BoardBody = {
  name: string;
  type: BoardType;
  photoFront?: string;
  photoBack?: string;
  description?: string;
  pinDiagram?: string;
};

export type CreateBody = BoardBody & {
  password: string;
};

export type UpdateBody = Partial<BoardBody> & {
  password: string;
  id: string;
};

export type DeleteBody = {
  id: string;
  password: string;
};

export type FindOneBody = {
  name?: string;
  id?: any;
};
