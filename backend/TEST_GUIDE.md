# API Documentation - BoardVault Backend

## Prerequisites

- Node.js or Bun installed
- Backend dependencies installed (`bun install` or `npm install`)
- PostgreSQL database configured (check `.env`)
- Backend server running

## Getting Started

### Start Backend Server

```bash
cd backend
bun dev
```

Expected output:

```
BoardVault started
   Environment : dev
   Port        : 3030
   Address     : http://localhost:3030
   API Base    : http://localhost:3030/api/v1
```

### Run Tests

In another terminal:

```bash
cd backend
bun run test-api.ts
```

This will:

- Test the ping endpoint
- Fetch all boards
- Create sample boards with images from `/boards` folder
- Find boards by name
- Display test results

## API Endpoints

### Ping the Server

```bash
curl http://localhost:3030/api/v1/ping
```

### Get All Boards

```bash
curl http://localhost:3030/api/v1/findOne
```

### Create a Board with Images

```bash
curl -X POST http://localhost:3030/api/v1/create \
  -F "name=Raspberry Pi 4" \
  -F "type=SBC" \
  -F "description=Powerful single board computer" \
  -F "password=nishu3126" \
  -F "photoFront=@/path/to/image.jpg" \
  -F "pinDiagram=@/path/to/diagram.jpg"
```

### Find Board by Name

```bash
curl http://localhost:3030/api/v1/find/Raspberry%20Pi%204
```

### Update Board

```bash
curl -X PUT http://localhost:3030/api/v1/update/{boardId} \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Updated description",
    "password": "nishu3126"
  }'
```

### Delete Board

```bash
curl -X DELETE http://localhost:3030/api/v1/delete/{boardId} \
  -H "Content-Type: application/json" \
  -d '{"password": "nishu3126"}'
```

## API Response Format

### Success Response

```json
{
  "status": "success",
  "statusCode": 200,
  "message": "Data found successful",
  "data": [
    {
      "id": "uuid",
      "name": "Board Name",
      "type": "SBC",
      "photoFront": "https://drive.google.com/...",
      "pinDiagram": "https://drive.google.com/...",
      "description": "Board description",
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

### Error Response

```json
{
  "status": "error",
  "statusCode": 400,
  "message": "Error message",
  "data": null
}
```

## Environment Configuration

Required `.env` variables:

- `PORT=3030` (or your preferred port)
- `DB_URL=postgresql://...` (PostgreSQL connection)
- `CRUD_PASSWORD=nishu3126`
- `DRIVE_CREDENTIALS_FILE=boardvault-3d538d2e7750.json`
- `NODE_ENV=dev`

## Troubleshooting

### Connection Refused

- Ensure backend is running: `bun dev`
- Verify PORT in `.env` matches the test URL
- Check port 3030 is not in use

### Database Connection Error

- Verify PostgreSQL is running
- Check `DB_URL` in `.env`
- Run Prisma migration: `bun run prisma`

### Google Drive Upload Issues

- Verify `DRIVE_CREDENTIALS_FILE` exists
- Check Drive API is enabled in Google Cloud
- Ensure service account has folder access

### Wrong Password Error

- Verify password matches `CRUD_PASSWORD` in `.env`
