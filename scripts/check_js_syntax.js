#!/usr/bin/env bun

import { readdirSync, readFileSync, statSync } from "node:fs"
import { extname, join } from "node:path"

const defaultRoots = ["templates/controllers"]
const roots = Bun.argv.slice(2)
const targets = roots.length > 0 ? roots : defaultRoots
const transpiler = new Bun.Transpiler({ loader: "js", target: "browser" })

function collectJsFiles(path, files = []) {
  const stat = statSync(path)
  if (stat.isFile()) {
    if (extname(path) === ".js") files.push(path)
    return files
  }

  readdirSync(path).forEach((entry) => {
    collectJsFiles(join(path, entry), files)
  })

  return files
}

let failed = 0
let total = 0

targets.forEach((target) => {
  const files = collectJsFiles(target)
  files.forEach((file) => {
    total += 1
    try {
      transpiler.transformSync(readFileSync(file, "utf8"))
    } catch (error) {
      failed += 1
      console.error(`\n[SYNTAX ERROR] ${file}`)
      console.error(error instanceof Error ? error.message : String(error))
    }
  })
})

if (failed > 0) {
  console.error(`\nSyntax check failed: ${failed}/${total} file(s) have errors.`)
  process.exit(1)
}

console.log(`Syntax check passed: ${total} file(s).`)
