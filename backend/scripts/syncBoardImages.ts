import fs from "fs";
import path from "path";

function normalizeName(s: string) {
  return s
    .toLowerCase()
    .replace(/[^a-z0-9\s.-]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function tokens(s: string) {
  return normalizeName(s).split(" ").filter(Boolean);
}

function bestMatch(files: string[], boardName: string) {
  const t = tokens(boardName);
  let best = { file: null as string | null, score: 0 };
  for (const f of files) {
    const base = f.toLowerCase().replace(/\.(jpg|jpeg|png|gif)$/i, "");
    let score = 0;
    for (const tok of t) if (base.includes(tok)) score++;
    if (score > best.score) best = { file: f, score };
  }
  return best.file;
}

(async () => {
  const repoRoot = path.join(process.cwd(), ".."); // backend/ is cwd
  const boardsJson = path.join(process.cwd(), "boards.json");
  const imagesDir = path.join(process.cwd(), "..", "boards");

  if (!fs.existsSync(boardsJson)) {
    console.error("boards.json not found at", boardsJson);
    process.exit(1);
  }
  if (!fs.existsSync(imagesDir)) {
    console.error("boards/ directory not found at", imagesDir);
    process.exit(1);
  }

  const boards = JSON.parse(fs.readFileSync(boardsJson, "utf8"));
  const files = fs.readdirSync(imagesDir);

  for (const board of boards) {
    const name = board.name;
    const targetBase = normalizeName(name);
    // photo
    const photoSrc = bestMatch(
      files.filter((f) => !/pin/i.test(f)),
      name,
    );
    if (photoSrc) {
      const ext = path.extname(photoSrc) || ".jpg";
      const target = `${targetBase}${ext}`;
      const srcPath = path.join(imagesDir, photoSrc);
      const targetPath = path.join(imagesDir, target);
      if (srcPath !== targetPath) {
        if (fs.existsSync(targetPath)) {
          console.warn("Target exists, skipping:", target);
        } else {
          fs.renameSync(srcPath, targetPath);
          console.log("Renamed photo:", photoSrc, "->", target);
          // update files list
          const idx = files.indexOf(photoSrc);
          if (idx >= 0) files[idx] = target;
        }
      }
    } else {
      console.log("No photo match for", name);
    }

    // pin diagram
    const pinSrc = bestMatch(
      files.filter((f) => /pin/i.test(f)),
      name,
    );
    if (pinSrc) {
      const ext = path.extname(pinSrc) || ".jpg";
      const target = `${targetBase} pin${ext}`;
      const srcPath = path.join(imagesDir, pinSrc);
      const targetPath = path.join(imagesDir, target);
      if (srcPath !== targetPath) {
        if (fs.existsSync(targetPath)) {
          console.warn("Target exists, skipping:", target);
        } else {
          fs.renameSync(srcPath, targetPath);
          console.log("Renamed pin diagram:", pinSrc, "->", target);
          const idx = files.indexOf(pinSrc);
          if (idx >= 0) files[idx] = target;
        }
      }
    } else {
      console.log("No pin match for", name);
    }
  }

  console.log("Done.");
})();
