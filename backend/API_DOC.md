# API Reference - BoardVault

## Endpoints Summary

| Method | Endpoint               | Purpose             | Auth |
| ------ | ---------------------- | ------------------- | ---- |
| GET    | `/api/v1/ping`         | Health check        | No   |
| POST   | `/api/v1/boards`       | Create a new board  | Yes  |
| GET    | `/api/v1/boards`       | Find all boards     | No   |
| GET    | `/api/v1/boards/:id`   | Find boards by id   | No   |
| GET    | `/api/v1/boards/:name` | Find boards by name | No   |
| PUT    | `/api/v1/boards/:id`   | Update board by id  | Yes  |
| DELETE | `/api/v1/boards/:id`   | Delete board by id  | Yes  |

## Common Commands

Start backend:

```bash
cd boardvault/backend && bun dev
```

Run tests (new terminal):

```bash
cd boardvault/backend && bun run test-api.ts
```

Ping API:

```bash
curl http://localhost:3030/api/v1/ping
```

Get all boards:

```bash
curl http://localhost:3030/api/v1/findOne
```

Find board by name:

```bash
curl "http://localhost:3030/api/v1/find/Raspberry%20Pi%204%20Model%20B"
```

Create simple board (no images):

```bash
curl -X POST http://localhost:3030/api/v1/create \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","type":"SBC","description":"Test board","password":"nishu3126"}'
```

Delete board:

```bash
curl -X DELETE http://localhost:3030/api/v1/delete/{id} \
  -H "Content-Type: application/json" \
  -d '{"password":"nishu3126"}'
```

## Board Data Structure

```json
{
  "id": "uuid",
  "name": "Raspberry Pi 4 Model B",
  "type": "SBC",
  "photoFront": "https://drive.google.com/...",
  "pinDiagram": "https://drive.google.com/...",
  "description": "Board description",
  "createdAt": "ISO-8601 timestamp",
  "updatedAt": "ISO-8601 timestamp"
}
```

## Test Checklist

- Backend runs on http://localhost:3030
- GET /api/v1/ping returns "pong"
- GET /api/v1/findOne returns boards array
- Create sample boards with images
- GET /api/v1/find/[name] returns specific board
- Flutter app fetches and displays boards
- Image carousel cycles every 3 seconds

## Getting Started

Start Backend:

```bash
cd boardvault/backend
bun dev
```

Run Tests:

```bash
cd boardvault/backend
bun run test-api.ts
```

Verify API:

```
GET http://localhost:3030/api/v1/findOne
```

Run Flutter App:

```bash
flutter run --dart-define=BACKEND_URL=http://localhost:3030
```

## Troubleshooting

| Issue              | Solution                                 |
| ------------------ | ---------------------------------------- |
| Connection refused | Verify backend is running with `bun dev` |
| Port 3030 in use   | Change PORT in `.env` or kill process    |
| Database error     | Check PostgreSQL connection and DB_URL   |
| No images          | Verify Google Drive credentials setup    |

## Configuration

- Password: `nishu3126`
- Backend URL: `http://localhost:3030`
- API Base: `http://localhost:3030/api/v1`
- Port: 3030 (from .env)

## Tips

View full request/response:

```bash
curl -v http://localhost:3030/api/v1/findOne
```

Pretty-print JSON:

```bash
curl http://localhost:3030/api/v1/findOne | jq .
```

Save response to file:

```bash
curl http://localhost:3030/api/v1/findOne > response.json
```
