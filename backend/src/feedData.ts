/**
 * Feed Data Script
 * Reads boards.json and seeds board data into the database via API routes
 * Usage: bun src/feedData.ts
 * Stops on first error to prevent partial/duplicate seeding
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
  photo?: string;
  pinDiagram?: string;
}

interface BoardPayload {
  name: string;
  slug: string;
  type: "SBC" | "MC";
  category: string[];
  bestFor: string[];
  alternatives: string[];
  description: string;
  photoFrontId?: string;
  pinDiagramId?: string;
  password: string;
}

// Helper to generate URL-friendly slug from name
function generateSlug(name: string): string {
  return name
    .toLowerCase()
    .trim()
    .replace(/\s+/g, "-") // Replace spaces with hyphens
    .replace(/[^\w-]/g, "") // Remove non-word characters except hyphens
    .replace(/-+/g, "-") // Replace multiple hyphens with single hyphen
    .replace(/^-+|-+$/g, ""); // Remove leading/trailing hyphens
}

// Main feed function
async function feedData() {
  const boardsJsonPath = path.join(process.cwd(), "boards.json");
  const apiBase = process.env.BASE || "http://localhost:3030";
  const password = process.env.CRUD_PASSWORD || "";

  if (!password) {
    console.error("❌ Error: CRUD_PASSWORD env var is required");
    process.exit(1);
  }

  // Read boards.json
  if (!fs.existsSync(boardsJsonPath)) {
    console.error(`❌ Error: boards.json not found at ${boardsJsonPath}`);
    process.exit(1);
  }

  let boards: BoardData[] = [];
  try {
    const fileContent = fs.readFileSync(boardsJsonPath, "utf-8");
    boards = JSON.parse(fileContent);
    console.log(`✓ Loaded ${boards.length} boards from boards.json`);
  } catch (error) {
    console.error(`❌ Error reading boards.json:`, error);
    process.exit(1);
  }

  // Validate and transform data
  const payloads: BoardPayload[] = boards.map((board) => {
    const slug = generateSlug(board.name);
    return {
      name: board.name,
      slug,
      type: board.type,
      category: board.category || [],
      bestFor: board.bestFor || [],
      alternatives: board.alternatives || [],
      description: board.description || "",
      photoFrontId: board.photo ? `photo:${board.photo}` : undefined,
      pinDiagramId: board.pinDiagram ? `diagram:${board.pinDiagram}` : undefined,
      password,
    };
  });

  console.log(`\n Starting data feed to ${apiBase}/api/v1/boards...`);

  let successCount = 0;
  let failCount = 0;

  // Feed data one by one, stop on first error
  for (let i = 0; i < payloads.length; i++) {
    const payload = payloads[i];
    const boardName = payload.name;

    try {
      console.log(`\n[${i + 1}/${payloads.length}] Feeding: ${boardName}`);

      const response = await fetch(`${apiBase}/api/v1/boards`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      const result = await response.json();

      if (!response.ok || !result.success) {
        console.error(
          `❌ Failed to create board "${boardName}":`,
          result.message || response.statusText,
        );
        if (result.errors) {
          console.error("Details:", result.errors);
        }
        failCount++;
        console.log(
          `\n⛔ Stopping on first error. Partially seeded: ${successCount}/${payloads.length}`,
        );
        process.exit(1);
      }

      console.log(
        `✓ Created: ${boardName} (id: ${result.data.id || "N/A"}) - slug: ${result.data.slug || "N/A"}`,
      );
      successCount++;
    } catch (error) {
      console.error(`❌ Network error while feeding "${boardName}":`, error);
      failCount++;
      console.log(
        `\n⛔ Stopping on first error. Partially seeded: ${successCount}/${payloads.length}`,
      );
      process.exit(1);
    }
  }

  console.log(
    `\n✅ Data feed complete! Successfully seeded ${successCount}/${payloads.length} boards.`,
  );
  process.exit(0);
}

// Run the feed
feedData().catch((err) => {
  console.error("Unexpected error:", err);
  process.exit(1);
});
