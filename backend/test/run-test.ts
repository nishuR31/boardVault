#!/usr/bin/env bun
/*
 TypeScript smoke test for BoardVault backend
 Usage:
  - Ensure server is running
  - Set env: BASE, CRUD_PASSWORD if needed
  - Run: `bun run test/run-test.ts` or `bun test/run-test.ts`
*/

import fs from "fs";
import path from "path";

const BASE = process.env.BASE || process.env.BACKEND || "http://127.0.0.1:3001";
const TIMEOUT = Number(process.env.TEST_TIMEOUT) || 5000;
const CRUD_PASSWORD = process.env.CRUD_PASSWORD || "---";

type SimpleTest = { name: string; path: string; expectStatus: number };

const simpleTests: SimpleTest[] = [
  { name: "root /", path: "/", expectStatus: 200 },
  { name: "/health", path: "/health", expectStatus: 200 },
  { name: "/ping (root)", path: "/ping", expectStatus: 200 },
  { name: "/help", path: "/help", expectStatus: 200 },
  { name: "/today", path: "/today", expectStatus: 200 },
  { name: "/api/v1/ping", path: "/api/v1/ping", expectStatus: 200 },
  { name: "/api/v1/boards (list)", path: "/api/v1/boards", expectStatus: 200 },
];

async function runSimpleTest(t: SimpleTest): Promise<boolean> {
  const url = new URL(t.path, BASE).href;
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), TIMEOUT);
    const res = await fetch(url, { signal: controller.signal });
    clearTimeout(timeout);
    let body: any = null;
    try {
      body = await res.json();
    } catch (e) {
      body = await res.text().catch(() => null);
    }
    const ok = res.status === t.expectStatus;
    if (ok) {
      console.log(`✅ PASS: ${t.name} -> ${url}`);
      return true;
    }
    console.error(`❌ FAIL: ${t.name} -> ${url}`);
    console.error("  status:", res.status);
    console.error("  body:", body);
    return false;
  } catch (err: any) {
    console.error(`❌ ERROR: ${t.name} -> ${url}`);
    console.error("  error:", err?.message || err);
    return false;
  }
}

function loadBoards(): any[] {
  // boards.txt is expected at backend root (one level above test/)
  const boardsPath = path.resolve(process.cwd(), "boards.txt");
  if (!fs.existsSync(boardsPath)) {
    console.error(`boards.txt not found at ${boardsPath}. Create it with sample data.`);
    return [];
  }
  try {
    const raw = fs.readFileSync(boardsPath, "utf-8");
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) {
      console.error("boards.txt must contain a JSON array of board objects");
      return [];
    }
    return parsed;
  } catch (e: any) {
    console.error("Failed to read/parse boards.txt:", e?.message || e);
    return [];
  }
}

async function runDbFlowForBoard(sample: any): Promise<boolean> {
  const baseApi = `${BASE}/api/v1`;
  let created: any = null;

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), TIMEOUT);
    const res = await fetch(`${baseApi}/boards`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ ...sample, password: CRUD_PASSWORD }),
      signal: controller.signal,
    });
    clearTimeout(timeout);
    const body = await res.json().catch(() => null);
    if (res.status !== 201) {
      console.error("❌ FAIL: create board -> status", res.status, "body", body);
      return false;
    }
    created = body?.data || body;
    if (!created || !created.id) {
      console.error("❌ FAIL: create board -> response missing id", body);
      return false;
    }
    console.log(`✅ Created board id=${created.id} name=${created.name}`);
  } catch (e: any) {
    console.error("❌ ERROR: creating board:", e?.message || e);
    return false;
  }

  // list check
  try {
    const res = await fetch(`${baseApi}/boards`);
    const body = await res.json().catch(() => null);
    if (res.status !== 200) {
      console.error("❌ FAIL: list boards -> status", res.status, body);
      return false;
    }
    const found = Array.isArray(body?.data)
      ? body.data.find((b) => b.id === created.id)
      : null;
    if (!found) {
      console.error("❌ FAIL: created board not found in list", body);
      return false;
    }
    console.log("✅ Found created board in list");
  } catch (e: any) {
    console.error("❌ ERROR: listing boards:", e?.message || e);
    return false;
  }

  // get by id
  try {
    const res = await fetch(`${baseApi}/boards/${created.id}`);
    const body = await res.json().catch(() => null);
    if (res.status !== 200) {
      console.error("❌ FAIL: get by id -> status", res.status, body);
      return false;
    }
    console.log("✅ Get by id OK");
  } catch (e: any) {
    console.error("❌ ERROR: get by id:", e?.message || e);
    return false;
  }

  // get by name
  try {
    const res = await fetch(`${baseApi}/boards/name/${encodeURIComponent(sample.name)}`);
    const body = await res.json().catch(() => null);
    if (res.status !== 200) {
      console.error("❌ FAIL: get by name -> status", res.status, body);
      return false;
    }
    console.log("✅ Get by name OK");
  } catch (e: any) {
    console.error("❌ ERROR: get by name:", e?.message || e);
    return false;
  }

  // update
  try {
    const res = await fetch(`${baseApi}/boards/${created.id}`, {
      method: "PUT",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        description: "Updated by smoke test",
        password: CRUD_PASSWORD,
      }),
    });
    const body = await res.json().catch(() => null);
    if (res.status !== 200) {
      console.error("❌ FAIL: update -> status", res.status, body);
      return false;
    }
    console.log("✅ Update OK");
  } catch (e: any) {
    console.error("❌ ERROR: update:", e?.message || e);
    return false;
  }

  // delete
  try {
    const res = await fetch(`${baseApi}/boards/${created.id}`, {
      method: "DELETE",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ password: CRUD_PASSWORD }),
    });
    const body = await res.json().catch(() => null);
    if (res.status !== 200) {
      console.error("❌ FAIL: delete -> status", res.status, body);
      return false;
    }
    console.log("✅ Delete OK");
  } catch (e: any) {
    console.error("❌ ERROR: delete:", e?.message || e);
    return false;
  }

  return true;
}

async function ping(): Promise<boolean> {
  try {
    const res = await fetch(BASE, { method: "GET" });
    return res.ok;
  } catch {
    return false;
  }
}

(async () => {
  console.log("Running smoke tests against", BASE);
  console.warn("\nchecking for server: ");
  const up = await ping();
  if (!up) {
    console.error("Server not reachable at", BASE);
    process.exit(1);
  }

  let all = true;
  for (const t of simpleTests) {
    const ok = await runSimpleTest(t);
    all = all && ok;
  }

  if (all) {
    const boards = loadBoards();
    if (boards.length === 0) {
      console.warn("No boards to test from boards.txt; skipping DB flow.");
    } else {
      console.log("\nRunning DB flow tests for boards defined in boards.txt...");
      for (const b of boards) {
        console.log(`\n-- Testing board: ${b.name}`);
        const ok = await runDbFlowForBoard(b);
        all = all && ok;
      }
    }
  }

  if (all) {
    console.log("\nAll tests passed.");
    process.exit(0);
  } else {
    console.error("\nSome tests failed.");
    process.exit(1);
  }
})();
