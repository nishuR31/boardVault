/**
 * Feed Data Script
 * Seeds & syncs 100+ curated microcontrollers and single-board computers
 * directly into the PostgreSQL database using Prisma upsert operations.
 *
 * Guarantees:
 * - Zero duplicates (upserts matching by unique name and slug)
 * - Preserves existing custom board images
 * - Does not require backend HTTP server or passwords to run
 *
 * Usage:
 *   bun run feed
 *   or: bun run seed
 */

import dotenv from "dotenv";
dotenv.config();

import { PrismaClient } from "./generated/board-client";
import { CURATED_BOARDS, SeedBoard } from "./data/boardsData";

const prisma = new PrismaClient();

async function feedData() {
  console.log("🌱 ========================================================");
  console.log("🚀 Feeding Curated Board Data to Database");
  console.log("🌱 ========================================================\n");

  const mcCount = CURATED_BOARDS.filter((b) => b.type === "MC").length;
  const sbcCount = CURATED_BOARDS.filter((b) => b.type === "SBC").length;
  console.log(`📦 Curated dataset: ${CURATED_BOARDS.length} boards`);
  console.log(`   ├─ Microcontrollers (MC)        : ${mcCount}`);
  console.log(`   └─ Single Board Computers (SBC) : ${sbcCount}\n`);

  let createdCount = 0;
  let updatedCount = 0;
  let errorCount = 0;

  for (let i = 0; i < CURATED_BOARDS.length; i++) {
    const board: SeedBoard = CURATED_BOARDS[i];
    const prefix = `[${(i + 1).toString().padStart(3, " ")}/${CURATED_BOARDS.length}]`;

    try {
      // Find existing record by unique name or slug to prevent duplicate violations
      const existing = await prisma.board.findFirst({
        where: {
          OR: [{ name: board.name }, { slug: board.slug }],
        },
      });

      if (existing) {
        await prisma.board.update({
          where: { id: existing.id },
          data: {
            name: board.name,
            slug: board.slug,
            type: board.type,
            description: board.description,
            category: board.category,
            bestFor: board.bestFor,
            alternatives: board.alternatives,
            photoFrontId: existing.photoFrontId || board.photoFrontId || null,
            pinDiagramId: existing.pinDiagramId || board.pinDiagramId || null,
          },
        });
        updatedCount++;
        console.log(`${prefix} 🔄 Updated: ${board.name} (${board.type})`);
      } else {
        await prisma.board.create({
          data: {
            name: board.name,
            slug: board.slug,
            type: board.type,
            description: board.description,
            category: board.category,
            bestFor: board.bestFor,
            alternatives: board.alternatives,
            photoFrontId: board.photoFrontId ?? null,
            pinDiagramId: board.pinDiagramId ?? null,
          },
        });
        createdCount++;
        console.log(`${prefix} ✨ Created: ${board.name} (${board.type})`);
      }
    } catch (err: any) {
      errorCount++;
      console.error(`${prefix} ❌ Error processing ${board.name}:`, err?.message || err);
    }
  }

  const finalTotal = await prisma.board.count();

  console.log("\n========================================================");
  console.log("✅ Feed Complete!");
  console.log(`   ├─ Boards Created : ${createdCount}`);
  console.log(`   ├─ Boards Updated : ${updatedCount}`);
  console.log(`   ├─ Errors         : ${errorCount}`);
  console.log(`   └─ Total in DB    : ${finalTotal} boards`);
  console.log("========================================================\n");
}

feedData()
  .catch((err) => {
    console.error("Fatal error during feedData:", err);
  })
  .finally(async () => {
    try {
      await prisma.$disconnect();
    } catch {}
    process.exit(0);
  });
