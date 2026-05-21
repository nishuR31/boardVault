/**
 * Feed Data Script
 * Reads boards.json and seeds board data into the database via API routes
 * Uploads associated images from boards/ directory
 * Usage: bun src/feedData.ts
 */

import fs from "node:fs";
import path from "node:path";
import dotenv from "dotenv";
dotenv.config();

interface BoardData {
  name: string;
  type: "SBC" | "MC";
  category: string[];
  bestFor: string[];
  alternatives: string[];
  description: string;
}

interface BoardPayload {
  name: string;
  slug: string;
  type: "SBC" | "MC";
  category: string[];
  bestFor: string[];
  alternatives: string[];
  description: string;
}

function generateSlug(name: string): string {
  return name
    .toLowerCase()
    .trim()
    .replace(/\s+/g, "-")
    .replace(/[^\w-]/g, "")
    .replace(/-+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function findImageFiles(
  boardName: string,
  imagesDir: string,
): { photoFront?: string; pinDiagram?: string } {
  const files = fs.readdirSync(imagesDir);
  const normalize = (value: string) =>
    value
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, " ")
      .replace(/\s+/g, " ")
      .trim();

  const tokens = normalize(boardName).split(" ").filter(Boolean);
  const ignore = new Set(["rev", "r", "r3", "model", "v1", "dev", "kit"]);
  const usefulTokens = tokens.filter((token) => !ignore.has(token));

  let bestPhoto: { file?: string; score: number } = { score: 0 };
  let bestPin: { file?: string; score: number } = { score: 0 };

  for (const file of files) {
    const lower = file.toLowerCase();
    const base = lower.replace(/\.(jpg|jpeg|png|gif)$/i, "");

    let score = 0;
    for (const token of usefulTokens) {
      if (base.includes(token)) score += 1;
    }

    const isPin = base.includes("pin");
    if (isPin) {
      if (score > bestPin.score) bestPin = { file, score };
    } else if (score > bestPhoto.score) {
      bestPhoto = { file, score };
    }
  }

  return {
    photoFront: bestPhoto.file ? path.join(imagesDir, bestPhoto.file) : undefined,
    pinDiagram: bestPin.file ? path.join(imagesDir, bestPin.file) : undefined,
  };
}

function buildForm(payload: BoardPayload, boardName: string, boardsImageDir: string) {
  const form = new FormData();
  form.append("name", payload.name);
  form.append("slug", payload.slug);
  form.append("type", payload.type);
  form.append("category", JSON.stringify(payload.category));
  form.append("bestFor", JSON.stringify(payload.bestFor));
  form.append("alternatives", JSON.stringify(payload.alternatives));
  form.append("description", payload.description);

  const { photoFront, pinDiagram } = findImageFiles(boardName, boardsImageDir);

  const toBlob = (filePath: string) => {
    const bytes = fs.readFileSync(filePath);
    const ext = path.extname(filePath).toLowerCase();
    const mimeType = ext === ".png" ? "image/png" : "image/jpeg";
    return new Blob([bytes], { type: mimeType });
  };

  if (photoFront && fs.existsSync(photoFront)) {
    console.log(`  📷 Attaching photo: ${path.basename(photoFront)}`);
    form.append("photoFront", toBlob(photoFront), path.basename(photoFront));
  } else {
    console.log(`  ⚠️  Photo not found for: ${boardName}`);
  }

  if (pinDiagram && fs.existsSync(pinDiagram)) {
    console.log(`  📋 Attaching pin diagram: ${path.basename(pinDiagram)}`);
    form.append("pinDiagram", toBlob(pinDiagram), path.basename(pinDiagram));
  } else {
    console.log(`  ⚠️  Pin diagram not found for: ${boardName}`);
  }

  return form;
}

async function readJsonResponse(response: Response) {
  try {
    return await response.json();
  } catch {
    return null;
  }
}

async function feedData() {
  const boardsJsonPath = path.join(process.cwd(), "boards.json");
  const boardsImageDir = path.join(process.cwd(), "..", "boards");
  const apiBase = process.env.BACKEND || "http://localhost:3030";
  const password = process.env.CRUD_PASSWORD || "";

  if (!password) {
    console.error("❌ Error: CRUD_PASSWORD env var is required");
    process.exit(1);
  }

  if (!fs.existsSync(boardsJsonPath)) {
    console.error(`❌ Error: boards.json not found at ${boardsJsonPath}`);
    process.exit(1);
  }

  let boards: BoardData[] = [];
  try {
    boards = JSON.parse(fs.readFileSync(boardsJsonPath, "utf-8"));
    console.log(`✓ Loaded ${boards.length} boards from boards.json`);
  } catch (error) {
    console.error("❌ Error reading boards.json:", error);
    process.exit(1);
  }

  console.log(`\n Starting data feed to ${apiBase}/api/v1/boards...`);

  let successCount = 0;

  for (let i = 0; i < boards.length; i++) {
    const board = boards[i];
    const boardName = board.name;

    try {
      console.log(`\n[${i + 1}/${boards.length}] Feeding: ${boardName}`);

      const payload: BoardPayload = {
        name: board.name,
        slug: generateSlug(board.name),
        type: board.type,
        category: board.category || [],
        bestFor: board.bestFor || [],
        alternatives: board.alternatives || [],
        description: board.description || "",
      };

      const existingResponse = await fetch(
        `${apiBase}/api/v1/boards/name/${encodeURIComponent(boardName)}`,
        { headers: { "x-crud-password": password } },
      );
      const existingResult = await readJsonResponse(existingResponse);
      const existingBoardId = existingResult?.data?.id as string | undefined;

      const form = buildForm(payload, boardName, boardsImageDir);
      const headers: Record<string, string> = { "x-crud-password": password };

      const response = await fetch(
        existingBoardId
          ? `${apiBase}/api/v1/boards/${existingBoardId}`
          : `${apiBase}/api/v1/boards`,
        {
          method: existingBoardId ? "PUT" : "POST",
          headers,
          body: form as any,
        },
      );

      const result = await readJsonResponse(response);
      if (!response.ok || !result?.success) {
        const message = result?.message || response.statusText;
        console.error(
          existingBoardId
            ? `❌ Failed to update board "${boardName}": ${message}`
            : `❌ Failed to create board "${boardName}": ${message}`,
        );
        if (result?.errors) {
          console.error("Details:", result.errors);
        }
        process.exit(1);
      }

      console.log(
        existingBoardId
          ? `✓ Updated: ${boardName} (id: ${result.data.id || existingBoardId})`
          : `✓ Created: ${boardName} (id: ${result.data.id || "N/A"})`,
      );
      if (result.data.photoFrontId) {
        console.log(`  └─ Photo ID: ${result.data.photoFrontId}`);
      }
      if (result.data.pinDiagramId) {
        console.log(`  └─ Pin Diagram ID: ${result.data.pinDiagramId}`);
      }

      successCount += 1;
    } catch (error) {
      console.error(`❌ Network error while feeding "${boardName}":`, error);
      console.log(
        `\n⛔ Stopping on first error. Partially seeded: ${successCount}/${boards.length}`,
      );
      process.exit(1);
    }
  }

  console.log(
    `\n✅ Data feed complete! Successfully seeded ${successCount}/${boards.length} boards.`,
  );
  process.exit(0);
}

feedData().catch((error) => {
  console.error("Unexpected error:", error);
  process.exit(1);
});
