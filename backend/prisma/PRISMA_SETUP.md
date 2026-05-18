# Prisma Database Configuration Documentation

## Version: 1.0

## Last Updated: 2026-05-17

---

## Overview

This document outlines the Prisma database setup for the BoardVault application with support for two separate PostgreSQL databases:

1. **Board Database** (`datadb`): Stores board-related data
2. **Image Database** (`imagedb`): Stores compressed images

---

## Architecture

### Database Separation Strategy

The application uses **two separate Prisma clients** to connect to two independent PostgreSQL databases:

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                         │
├─────────────────────────────────────────────────────────────┤
│  Controllers → Services → BoardRepository → BaseRepository   │
├─────────────────────────────────────────────────────────────┤
│         ↓                                    ↓                │
│   Board Prisma Client              Image Prisma Client       │
│   (board-client)                   (image-client)            │
├─────────────────────────────────────────────────────────────┤
│         ↓                                    ↓                │
│   Board Database (datadb)          Image Database (imagedb)  │
│   PostgreSQL                        PostgreSQL               │
└─────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
backend/
├── prisma/
│   ├── schema.prisma              # Deprecated - kept for reference
│   ├── board.schema.prisma        # Board database schema
│   ├── image.schema.prisma        # Image database schema
│   └── migrations/                # Database migrations
├── src/
│   ├── config/
│   │   ├── boardPrisma.ts         # Board Prisma client singleton
│   │   ├── imagePrisma.ts         # Image Prisma client singleton
│   │   ├── databaseConfig.ts      # Database initialization
│   │   └── envConfig.ts           # Environment variables
│   ├── generated/
│   │   ├── board-client/          # Generated Board Prisma client
│   │   └── image-client/          # Generated Image Prisma client
│   └── repositories/
│       ├── baseRepository.ts      # Base CRUD operations
│       └── boardRepository.ts     # Board-specific operations
├── .env                            # Environment variables
└── package.json
```

---

## Configuration Files

### 1. Environment Variables (`.env`)

```env
# Database URLs
DATABASE_URL=postgresql://user:password@host:port/database?sslmode=require
IMAGE_DATABASE_URL=postgresql://user:password@host:port/image_database?sslmode=require

# Application
PORT=3030
NODE_ENV=development
```

### 2. Board Schema (`prisma/board.schema.prisma`)

Defines the `Board` and `BoardType` models for the data database:

```prisma
model Board {
  id            String      @id @default(uuid())
  name          String      @unique
  type          BoardType
  description   String?     @default("Will be updated soon...")
  photoFrontId  String?
  pinDiagramId  String?
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt

  @@index([name])
  @@index([type])
  @@map("boards")
}

enum BoardType {
  SBC
  MC

  @@map("board_type")
}
```

### 3. Image Schema (`prisma/image.schema.prisma`)

Defines the `Image` model for the image database:

```prisma
model Image {
  id        String      @id @default(uuid())
  name      String      @unique
  data      Bytes
  createdAt DateTime    @default(now())
  updatedAt DateTime    @updatedAt

  @@index([name])
  @@index([createdAt])
  @@map("images")
}
```

---

## Client Initialization

### Board Prisma Client (`src/config/boardPrisma.ts`)

Singleton pattern for Board database:

```typescript
export const getBoardPrismaClient = (): BoardPrismaClient => {
  if (!boardPrismaInstance) {
    boardPrismaInstance = new BoardPrismaClient({
      log:
        process.env.NODE_ENV === "development"
          ? ["query", "info", "warn", "error"]
          : ["warn", "error"],
    });
  }
  return boardPrismaInstance;
};
```

### Image Prisma Client (`src/config/imagePrisma.ts`)

Singleton pattern for Image database:

```typescript
export const getImagePrismaClient = (): ImagePrismaClient => {
  if (!imagePrismaInstance) {
    imagePrismaInstance = new ImagePrismaClient({
      log:
        process.env.NODE_ENV === "development"
          ? ["query", "info", "warn", "error"]
          : ["warn", "error"],
    });
  }
  return imagePrismaInstance;
};
```

---

## Usage Examples

### In BoardRepository

```typescript
import BoardRepository from "./repositories/boardRepository";

const boardRepo = new BoardRepository();

// Create a board
const board = await boardRepo.create({
  name: "Arduino UNO",
  type: "SBC",
  description: "Arduino UNO Microcontroller Board",
});

// Find board by ID
const foundBoard = await boardRepo.findById(board.id);

// Upload image
const image = await boardRepo.upload({
  name: "arduino-uno-pinout.png",
  data: imageBuffer,
});

// Update board
const updated = await boardRepo.update(board.id, {
  photoFrontId: image.id,
});
```

---

## Commands

### Generate Prisma Clients

Generate both Board and Image clients:

```bash
# Generate Board client
npx prisma generate --schema=prisma/board.schema.prisma

# Generate Image client
npx prisma generate --schema=prisma/image.schema.prisma
```

### Run Migrations

```bash
# Migrate Board database
npx prisma migrate dev --schema=prisma/board.schema.prisma --name "add_boards_table"

# Migrate Image database
npx prisma migrate dev --schema=prisma/image.schema.prisma --name "add_images_table"
```

### View Database Data

```bash
# View Board database
npx prisma studio --schema=prisma/board.schema.prisma

# View Image database
npx prisma studio --schema=prisma/image.schema.prisma
```

---

## Error Handling

The `BaseRepository` provides centralized error handling for both databases:

- **P2025**: Record not found
- **P2002**: Unique constraint violation
- **P2023**: Invalid ID format

```typescript
async create(data: any, options: any = {}): Promise<T> {
  try {
    return await this.dataModel.create({ data, ...options });
  } catch (error) {
    handlePrismaError(error, this.dataModelName, "creation");
  }
}
```

---

## Best Practices

1. **Always use singleton pattern** for Prisma clients to avoid connection leaks
2. **Graceful shutdown** - Disconnect clients on SIGINT/SIGTERM
3. **Logging** - Enable query logging in development for debugging
4. **Migrations** - Keep migrations separate for each database
5. **Type safety** - Use generated types from both clients
6. **Error handling** - Use centralized error handler in BaseRepository

---

## Troubleshooting

### Multiple Datasources Error

If you see "You defined more than one datasource", ensure you're using separate schema files, not one schema.prisma with multiple datasources.

### Import Path Errors

Ensure generated clients are imported from:

- `../generated/board-client` (Board models)
- `../generated/image-client` (Image models)

### Connection Issues

Check that both DATABASE_URL and IMAGE_DATABASE_URL are:

- Valid PostgreSQL connection strings
- Pointing to accessible databases
- Include correct authentication credentials

---

## Version History

| Version | Date       | Changes                                  |
| ------- | ---------- | ---------------------------------------- |
| 1.0     | 2026-05-17 | Initial setup with separate schema files |
|         |            | Two Prisma clients implementation        |
|         |            | Comprehensive documentation              |

---

## Related Files

- [.env](.env) - Environment configuration
- [src/config/databaseConfig.ts](../src/config/databaseConfig.ts) - Database initialization
- [src/repositories/baseRepository.ts](../src/repositories/baseRepository.ts) - Base CRUD operations
- [src/repositories/boardRepository.ts](../src/repositories/boardRepository.ts) - Board operations
