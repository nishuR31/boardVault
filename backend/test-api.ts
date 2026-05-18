#!/usr/bin/env bun
/**
 * BoardVault API Testing Script
 * Tests all endpoints and seeds sample board data
 */

import fs from "fs";
import path from "path";

const BASE_URL = "http://localhost:3030";
const API_V1 = `${BASE_URL}/api/v1`;
const CRUD_PASSWORD = process.env.CRUD_PASSWORD || "nishu3126";

interface TestResult {
  name: string;
  status: "PASS" | "FAIL";
  data?: any;
  error?: string;
}

const results: TestResult[] = [];

// Helper function to make requests
async function makeRequest(
  method: string,
  endpoint: string,
  body?: any,
  files?: Record<string, string>,
): Promise<any> {
  const url = `${API_V1}${endpoint}`;
  console.log(`\n📡 ${method} ${endpoint}`);

  try {
    if (files && method === "POST") {
      // Multipart form data
      const formData = new FormData();

      // Add regular fields
      if (body) {
        Object.entries(body).forEach(([key, value]) => {
          formData.append(key, String(value));
        });
      }

      // Add files
      Object.entries(files).forEach(([key, filePath]) => {
        const absolutePath = path.resolve(filePath);
        if (fs.existsSync(absolutePath)) {
          const fileBuffer = fs.readFileSync(absolutePath);
          formData.append(
            key,
            new Blob([fileBuffer], { type: "image/jpeg" }),
            path.basename(filePath),
          );
        } else {
          console.warn(`⚠️  File not found: ${absolutePath}`);
        }
      });

      const response = await fetch(url, {
        method,
        body: formData,
      });

      return {
        status: response.status,
        data: await response.json(),
      };
    } else {
      // JSON request
      const response = await fetch(url, {
        method,
        headers: {
          "Content-Type": "application/json",
        },
        body: body ? JSON.stringify(body) : undefined,
      });

      return {
        status: response.status,
        data: await response.json(),
      };
    }
  } catch (error: any) {
    throw new Error(error.message);
  }
}

// Test functions
async function testPing() {
  try {
    const response = await makeRequest("GET", "/ping");
    if (response.status === 200 && response.data.message === "pong") {
      results.push({ name: "Ping Endpoint", status: "PASS", data: response.data });
      console.log("✅ Ping successful");
    } else {
      throw new Error(`Unexpected response: ${JSON.stringify(response.data)}`);
    }
  } catch (error: any) {
    results.push({ name: "Ping Endpoint", status: "FAIL", error: error.message });
    console.log(`❌ Ping failed: ${error.message}`);
  }
}

async function testGetAllBoards() {
  try {
    const response = await makeRequest("GET", "/findOne");
    if (response.status === 200 && Array.isArray(response.data.data)) {
      results.push({ name: "Get All Boards", status: "PASS", data: response.data });
      console.log(`✅ Found ${response.data.data.length} boards`);
    } else {
      throw new Error(`Unexpected response: ${JSON.stringify(response.data)}`);
    }
  } catch (error: any) {
    results.push({ name: "Get All Boards", status: "FAIL", error: error.message });
    console.log(`❌ Failed: ${error.message}`);
  }
}

async function createBoard(boardData: any, files?: Record<string, string>) {
  try {
    const payload = {
      ...boardData,
      password: CRUD_PASSWORD,
    };

    const response = await makeRequest("POST", "/create", payload, files);

    if (response.status === 201 || response.status === 200) {
      results.push({
        name: `Create Board: ${boardData.name}`,
        status: "PASS",
        data: response.data,
      });
      console.log(`✅ Board created: ${boardData.name}`);
      return response.data.data;
    } else {
      throw new Error(`Unexpected status: ${response.status}`);
    }
  } catch (error: any) {
    results.push({
      name: `Create Board: ${boardData.name}`,
      status: "FAIL",
      error: error.message,
    });
    console.log(`❌ Failed to create board: ${error.message}`);
  }
}

async function findBoard(name: string) {
  try {
    const response = await makeRequest("GET", `/find/${encodeURIComponent(name)}`);

    if (response.status === 200) {
      results.push({
        name: `Find Board: ${name}`,
        status: "PASS",
        data: response.data,
      });
      console.log(`✅ Found board: ${name}`);
      return response.data.data;
    } else {
      throw new Error(`Unexpected status: ${response.status}`);
    }
  } catch (error: any) {
    results.push({
      name: `Find Board: ${name}`,
      status: "FAIL",
      error: error.message,
    });
    console.log(`❌ Failed to find board: ${error.message}`);
  }
}

async function updateBoard(id: string, updates: any) {
  try {
    const payload = {
      ...updates,
      password: CRUD_PASSWORD,
    };

    const response = await makeRequest("PUT", `/update/${id}`, payload);

    if (response.status === 200) {
      results.push({
        name: `Update Board: ${id}`,
        status: "PASS",
        data: response.data,
      });
      console.log(`✅ Board updated: ${id}`);
    } else {
      throw new Error(`Unexpected status: ${response.status}`);
    }
  } catch (error: any) {
    results.push({
      name: `Update Board: ${id}`,
      status: "FAIL",
      error: error.message,
    });
    console.log(`❌ Failed to update board: ${error.message}`);
  }
}

async function deleteBoard(id: string) {
  try {
    const payload = { password: CRUD_PASSWORD };
    const response = await makeRequest("DELETE", `/delete/${id}`, payload);

    if (response.status === 200) {
      results.push({
        name: `Delete Board: ${id}`,
        status: "PASS",
      });
      console.log(`✅ Board deleted: ${id}`);
    } else {
      throw new Error(`Unexpected status: ${response.status}`);
    }
  } catch (error: any) {
    results.push({
      name: `Delete Board: ${id}`,
      status: "FAIL",
      error: error.message,
    });
    console.log(`❌ Failed to delete board: ${error.message}`);
  }
}

// Main test sequence
async function runTests() {
  console.log("🚀 BoardVault API Testing Suite\n");
  console.log(`Base URL: ${BASE_URL}`);
  console.log(`API Base: ${API_V1}\n`);
  console.log("========================================\n");

  // Test 1: Ping
  console.log("1️⃣  Testing Ping Endpoint...");
  await testPing();

  // Test 2: Get all boards
  console.log("\n2️⃣  Testing Get All Boards...");
  await testGetAllBoards();

  // Test 3: Create sample boards
  console.log("\n3️⃣  Creating Sample Boards...");

  const boardsDir = path.resolve(__dirname, "../../../boards");

  const sampleBoards = [
    {
      name: "Raspberry Pi 4 Model B",
      type: "SBC",
      description:
        "Powerful single board computer with 4GB RAM, perfect for media centers and servers",
      imagePattern: "raspberry pi4 modelb",
    },
    {
      name: "Arduino Uno",
      type: "MC",
      description:
        "Classic microcontroller board, ideal for beginners and embedded projects",
      imagePattern: "ATmega328p",
    },
    {
      name: "ESP32 DevKit V1",
      type: "MC",
      description: "WiFi and Bluetooth enabled microcontroller, great for IoT projects",
      imagePattern: "esp32 devkit v1",
    },
    {
      name: "BeagleBone Black",
      type: "SBC",
      description: "High-performance SBC with real-time IO and industrial applications",
      imagePattern: "beaglebone black rev c",
    },
  ];

  const createdBoards: any[] = [];

  for (const board of sampleBoards) {
    // Find matching images
    const files: Record<string, string> = {};

    const photoMatch = fs
      .readdirSync(boardsDir)
      .find(
        (f) =>
          f.toLowerCase().includes(board.imagePattern.toLowerCase()) &&
          !f.includes("pin"),
      );

    const pinMatch = fs
      .readdirSync(boardsDir)
      .find(
        (f) =>
          f.toLowerCase().includes(board.imagePattern.toLowerCase()) && f.includes("pin"),
      );

    if (photoMatch) {
      files.photoFront = path.join(boardsDir, photoMatch);
    }
    if (pinMatch) {
      files.pinDiagram = path.join(boardsDir, pinMatch);
    }

    const result = await createBoard(
      board,
      Object.keys(files).length > 0 ? files : undefined,
    );
    if (result) {
      createdBoards.push(result);
    }
  }

  // Test 4: Find specific board
  if (createdBoards.length > 0) {
    console.log("\n4️⃣  Testing Find Board...");
    await findBoard(sampleBoards[0].name);
  }

  // Test 5: Get all boards again
  console.log("\n5️⃣  Fetching All Boards (After Creation)...");
  await testGetAllBoards();

  // Print summary
  console.log("\n\n========================================");
  console.log("📊 Test Summary\n");

  const passed = results.filter((r) => r.status === "PASS").length;
  const failed = results.filter((r) => r.status === "FAIL").length;

  results.forEach((result) => {
    const icon = result.status === "PASS" ? "✅" : "❌";
    console.log(`${icon} ${result.name}: ${result.status}`);
    if (result.error) {
      console.log(`   Error: ${result.error}`);
    }
  });

  console.log(`\nTotal: ${results.length} | Passed: ${passed} | Failed: ${failed}`);
  console.log("========================================\n");
}

// Run tests
await runTests();
