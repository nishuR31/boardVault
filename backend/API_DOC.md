# API Reference - BoardVault

## Endpoints Summary

| Method | Endpoint                          | Purpose            | Auth |
| ------ | --------------------------------- | ------------------ | ---- |
| GET    | `/api/v1/ping`                    | Health check       | No   |
| POST   | `/api/v1/boards`                  | Create a new board | Yes  |
| GET    | `/api/v1/boards`                  | List all boards    | No   |
| GET    | `/api/v1/boards/:id`              | Get board by id    | No   |
| GET    | `/api/v1/boards/:name` (see note) | Get board by name  | No   |
| PUT    | `/api/v1/boards/:id`              | Update board by id | Yes  |
| DELETE | `/api/v1/boards/:id`              | Delete board by id | Yes  |

NOTE: The code currently registers `/boards/:id` then `/boards/:name`. Because both use a single path param, the first matching route (`:id`) will capture requests and the `:name` route will not be reached. Recommended fix: change the name route to `/boards/name/:name` or register the `name` route before `:id`.

## Response format

All successful responses use the following wrapper (see `sendSuccess` helper):

```json
{
  "success": true,
  "message": "Human readable message",
  "data": ...
}
```

Errors use `sendError` and look like:

```json
{
  "success": false,
  "message": "Error message",
  "errors": {
    /* optional */
  }
}
```

## Common Commands

Start backend:

```bash
cd boardvault/backend
bun dev
```

Run tests (if available):

```bash
cd boardvault/backend
bun run test-api.ts
```

Ping API (example):

```bash
curl http://localhost:3030/api/v1/ping
```

Get all boards:

```bash
curl http://localhost:3030/api/v1/boards
```

Get board by id:

```bash
curl http://localhost:3030/api/v1/boards/<id>
```

Get board by name (recommended path):

```bash
curl http://localhost:3030/api/v1/boards/name/Raspberry%20Pi%204%20Model%20B
```

Create board (JSON body; requires `password` field for auth check):

```bash
curl -X POST http://localhost:3030/api/v1/boards \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Arduino Uno R3",
    "slug": "arduino-uno-r3",
    "type": "MC",
    "category": ["Education", "Robotics", "Embedded"],
    "bestFor": ["Beginners", "Students", "DIY Projects"],
    "alternatives": ["Arduino Nano", "Arduino Mega", "ESP32"],
    "description": "Arduino Uno R3 is one of the most beginner-friendly microcontroller boards...",
    "photoFrontId": "Arduino Uno R3 board image",
    "pinDiagramId": "Arduino Uno R3 pin diagram labeled",
    "password": "<crud-password>"
  }'
```

Update board (provide `id` in URL and `password` in body):

```bash
curl -X PUT http://localhost:3030/api/v1/boards/<id> \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated","password":"<crud-password>"}'
```

Delete board (provide `password` in body):

```bash
curl -X DELETE http://localhost:3030/api/v1/boards/<id> \
  -H "Content-Type: application/json" \
  -d '{"password":"<crud-password>"}'
```

## Board Data Structure (inside `data` of success response)

```json
{
  "id": "uuid",
  "name": "Raspberry Pi 4 Model B",
  "slug": "raspberry-pi-4-model-b",
  "type": "SBC",
  "category": ["Linux", "Robotics", "Edge Computing"],
  "bestFor": ["Linux Projects", "Robotics", "Home Servers"],
  "alternatives": ["Orange Pi", "Jetson Nano", "ODROID"],
  "description": "Full board description and key details...",
  "photoFrontId": "<drive-id-or-url-or-descriptive-text>",
  "pinDiagramId": "<drive-id-or-url-or-descriptive-text>",
  "createdAt": "ISO-8601 timestamp",
  "updatedAt": "ISO-8601 timestamp"
}
```

## Test Checklist (updated)

- Backend runs on `http://localhost:3030`
- GET `/api/v1/ping` returns a success wrapper with `data: "pong"`
- GET `/api/v1/boards` returns a success wrapper with `data` being an array of boards
- POST `/api/v1/boards` creates a board and returns the created board in `data` (requires `password`)
- GET `/api/v1/boards/:id` returns the board object in `data` for a valid id
- GET by name: consider switching to `/boards/name/:name` to reliably fetch by name
- PUT `/api/v1/boards/:id` updates and returns updated board in `data` (requires `password`)
- DELETE `/api/v1/boards/:id` deletes and returns deletion result in `data` (requires `password`)

## Getting Started

### Start Backend:

```bash
cd boardvault/backend
bun dev
```

### Seed Database with boards.json:

Before running this, ensure:

1. Backend is running (`bun dev`)
2. `.env` has `CRUD_PASSWORD` set
3. PostgreSQL databases are reachable (check DB_URL and IMG_URL)

Then run the feed script:

```bash
cd boardvault/backend
BASE=http://localhost:3030 CRUD_PASSWORD=<your-password> bun src/feedData.ts
```

The script will:

- Read `boards.json`
- Generate URL-friendly slugs from board names
- POST each board to `/api/v1/boards`
- Stop on the first error (prevents partial/duplicate seeding)
- Report success/failure for each board

### Run Tests:

```bash
cd boardvault/backend
bun run test
```

### Verify API:

```bash
GET http://localhost:3030/api/v1/boards
```

## Troubleshooting

| Issue              | Solution                                 |
| ------------------ | ---------------------------------------- |
| Connection refused | Verify backend is running with `bun dev` |
| Port 3030 in use   | Change `PORT` in `.env` or kill process  |
| Database error     | Check DB connection and `DATABASE_URL`   |
| No images          | Verify uploaded files and Drive upload   |

## Configuration

- Backend URL: `http://localhost:3030`
- API Base: `http://localhost:3030/api/v1`
- Port: 3030 (from `.env`)

## Notes / Recommendations

- The current route ordering (`/boards/:id` before `/boards/:name`) causes the name-based route to be unreachable; change to `/boards/name/:name` or register the name route first.
- All endpoints return the `{ success, message, data }` wrapper — update any consumers (Flutter app, tests) to parse `data` instead of assuming a raw object or string.
