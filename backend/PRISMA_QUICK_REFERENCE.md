# Prisma Quick Reference Guide

## Version: 1.0

## Updated: 2026-05-17

---

## Quick Setup

```bash
# 1. Install dependencies
npm install

# 2. Configure environment
cp .env.example .env
# Edit .env with your database URLs

# 3. Generate Prisma clients
npm run prisma:generate

# 4. Run migrations
npm run prisma:migrate
```

---

## Common Commands

### Client Generation

```bash
# Generate both clients
npm run prisma:generate

# Generate specific client
npx prisma generate --schema=prisma/board.schema.prisma
npx prisma generate --schema=prisma/image.schema.prisma
```

### Database Migrations

```bash
# Create new migration
npx prisma migrate dev --schema=prisma/board.schema.prisma --name "migration_name"
npx prisma migrate dev --schema=prisma/image.schema.prisma --name "migration_name"

# Apply migrations
npm run prisma:migrate

# Reset database (⚠️ deletes all data)
npx prisma migrate reset --schema=prisma/board.schema.prisma
```

### Database Studio

```bash
# View Board database
npx prisma studio --schema=prisma/board.schema.prisma

# View Image database
npx prisma studio --schema=prisma/image.schema.prisma
```

---

## Usage in Code

### Import Models

```typescript
// Board models and client
import { Board, BoardType } from "../generated/board-client";
import { dataPrisma } from "../config/databaseConfig";

// Image models and client
import { Image } from "../generated/image-client";
import { imagePrisma } from "../config/databaseConfig";
```

### Using Repository

```typescript
import BoardRepository from "./repositories/boardRepository";

const boardRepo = new BoardRepository();

// Create
const board = await boardRepo.create({
  name: "Arduino UNO",
  type: "SBC",
  description: "Arduino Board",
});

// Read
const foundBoard = await boardRepo.findById(board.id);
const allBoards = await boardRepo.findAll();

// Update
await boardRepo.update(board.id, {
  description: "Updated description",
});

// Delete
await boardRepo.deleteOne(board.id);

// Upload Image
const image = await boardRepo.upload({
  name: "pinout.png",
  data: imageBuffer,
});
```

### Direct Client Usage

```typescript
import { dataPrisma, imagePrisma } from "../config/databaseConfig";

// Board operations
const boards = await dataPrisma.board.findMany();
const board = await dataPrisma.board.create({
  data: { name: "New Board", type: "SBC" },
});

// Image operations
const images = await imagePrisma.image.findMany();
const image = await imagePrisma.image.create({
  data: { name: "image.png", data: buffer },
});
```

---

## Error Handling

```typescript
import { NotFoundError, ConflictError } from "../utils/errors/error";

try {
  await boardRepo.findById(invalidId);
} catch (error) {
  if (error instanceof NotFoundError) {
    console.log("Board not found");
  } else if (error instanceof ConflictError) {
    console.log("Unique constraint violated");
  }
}
```

---

## Environment Variables

```env
# Required
DATABASE_URL=postgresql://user:password@host/database?sslmode=require
IMAGE_DATABASE_URL=postgresql://user:password@host/image_database?sslmode=require

# Optional
NODE_ENV=development|production
PORT=3030
```

---

## Schema Reference

### Board Model

```prisma
model Board {
  id            String      @id @default(uuid())
  name          String      @unique
  type          BoardType   // SBC | MC
  description   String?
  photoFrontId  String?
  pinDiagramId  String?
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt
}
```

### Image Model

```prisma
model Image {
  id        String      @id @default(uuid())
  name      String      @unique
  data      Bytes
  createdAt DateTime    @default(now())
  updatedAt DateTime    @updatedAt
}
```

---

## Troubleshooting

### "Cannot find module" Error

```bash
# Regenerate clients
npm run prisma:generate
```

### Database Connection Error

- Verify DATABASE_URL and IMAGE_DATABASE_URL in .env
- Ensure PostgreSQL databases are running
- Check network connectivity

### Migration Failed

```bash
# Reset and re-migrate
npx prisma migrate reset --schema=prisma/board.schema.prisma
npx prisma migrate reset --schema=prisma/image.schema.prisma
```

### Type Safety Issues

```bash
# Regenerate and check types
npm run prisma:generate
npm run type-check
```

---

## Best Practices

✅ **DO:**

- Use repositories for CRUD operations
- Handle errors with try-catch
- Use transactions for related operations
- Disconnect clients on shutdown
- Use indexes for frequently queried fields

❌ **DON'T:**

- Bypass repositories for direct client access
- Use sync operations in async code
- Leave connections open without cleanup
- Mix Board and Image operations in same transaction
- Ignore migration errors

---

## Performance Tips

1. **Use select** to fetch only needed fields

   ```typescript
   await dataPrisma.board.findMany({
     select: { id: true, name: true },
   });
   ```

2. **Batch operations**

   ```typescript
   await dataPrisma.board.createMany({
     data: boardsArray,
   });
   ```

3. **Use pagination**

   ```typescript
   await dataPrisma.board.findMany({
     skip: 0,
     take: 10,
   });
   ```

4. **Add database indexes** (already included in schema)
   ```prisma
   @@index([name])
   @@index([type])
   ```

---

## Additional Resources

- [Prisma Documentation](https://www.prisma.io/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Setup Guide](./PRISMA_SETUP.md)
- [Version Notes](../VERSION.md)

---

**Need Help?** Check PRISMA_SETUP.md for detailed documentation or version history at VERSION.md.
