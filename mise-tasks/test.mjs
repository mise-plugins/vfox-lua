#!/usr/bin/env node
//MISE description="Run plugin tests - install and execute tool"
//MISE tools={node="latest"}

import { execSync, spawnSync } from "node:child_process";

function run(cmd, opts = {}) {
  const result = execSync(cmd, {
    encoding: "utf-8",
    stdio: opts.silent ? "pipe" : "inherit",
    timeout: 300000,
    ...opts,
  });
  return result?.trim() ?? "";
}

function test(name, fn) {
  process.stdout.write(`  ${name}... `);
  try {
    fn();
    console.log("✓");
  } catch (e) {
    console.log("✗");
    console.log(`    ${e.message}`);
    process.exit(1);
  }
}

const LUA_VERSION = process.env.LUA_TEST_VERSION || "5.4.7";

run("mise plugin link --force lua .");
run("mise cache clear");
run(`mise uninstall lua@${LUA_VERSION}`);
run(`mise install lua@${LUA_VERSION}`);

test("lua binary reports correct version", () => {
  const out = run(`mise exec lua@${LUA_VERSION} -- lua -v 2>&1`, {
    stdio: "pipe",
  });
  if (!out.includes(LUA_VERSION)) {
    throw new Error(`expected ${LUA_VERSION} in output:\n${out}`);
  }
});

test("luarocks is available", () => {
  const out = run(`mise exec lua@${LUA_VERSION} -- luarocks --version`, {
    stdio: "pipe",
  });
  if (!out.toLowerCase().includes("luarocks")) {
    throw new Error(`luarocks not found:\n${out}`);
  }
});

console.log("\n✓ All tests passed");
