const fs = require("fs");
const path = require("path");

const ROOT_DIR = process.cwd();
const SEARCH = "gemini-2.5-flash-native-audio-preview";

// Папки, которые игнорируем
const IGNORE_DIRS = new Set([
  "node_modules",
  ".git",
  ".next",
  "dist",
  "build",
  "coverage"
]);

// Расширения бинарных файлов, которые пропускаем
const IGNORE_EXT = new Set([
  ".png", ".jpg", ".jpeg", ".gif", ".webp",
  ".exe", ".dll", ".so", ".zip", ".tar", ".gz",
  ".mp4", ".mp3", ".pdf"
]);

function searchInFile(filePath) {
  try {
    const ext = path.extname(filePath).toLowerCase();
    if (IGNORE_EXT.has(ext)) return false;

    const content = fs.readFileSync(filePath, "utf8");
    return content.includes(SEARCH);
  } catch {
    return false; // если не текстовый или нет доступа
  }
}

function walk(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      if (!IGNORE_DIRS.has(entry.name)) {
        walk(fullPath);
      }
    } else if (entry.isFile()) {
      if (searchInFile(fullPath)) {
        console.log(fullPath);
      }
    }
  }
}

console.log(`Searching for "${SEARCH}" in: ${ROOT_DIR}`);
console.log("--------------------------------------");

walk(ROOT_DIR);

console.log("--------------------------------------");
console.log("Done.");
