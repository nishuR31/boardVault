export type BoardType = "SBC" | "MC";

export type BoardBody = {
  name: string;
  slug: string;
  type: BoardType;
  category?: string[];
  bestFor?: string[];
  alternatives?: string[];
  description?: string;
  photoFrontId?: string;
  pinDiagramId?: string;
};

export type CreateBody = BoardBody & {
  password: string;
};

export type UpdateBody = Partial<BoardBody> & {
  password: string;
  id?: string;
};

export type DeleteBody = {
  id: string;
  password: string;
};

export type FindOneBody = {
  name?: string;
  id?: any;
};
