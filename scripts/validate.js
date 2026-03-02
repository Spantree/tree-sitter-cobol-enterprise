#!/usr/bin/env node
/**
 * validate.js — Parse all CardDemo COBOL files and report ERROR nodes.
 *
 * Usage: node scripts/validate.js
 *
 * Requires: npm run build (native module must be compiled)
 */

const fs = require('fs');
const path = require('path');
const Parser = require('tree-sitter');
const Cobol = require('..');

const parser = new Parser();
parser.setLanguage(Cobol);

const testDir = path.join(__dirname, '..', 'test', 'projects', 'carddemo');
const cblDir = path.join(testDir, 'cbl');
const cpyDir = path.join(testDir, 'cpy');

function countNodes(node, type) {
  let count = 0;
  if (node.type === type) count++;
  for (let i = 0; i < node.childCount; i++) {
    count += countNodes(node.child(i), type);
  }
  return count;
}

function parseFiles(dir, ext) {
  const results = [];
  if (!fs.existsSync(dir)) return results;
  const files = fs.readdirSync(dir).filter(f =>
    f.toLowerCase().endsWith(ext)
  );
  for (const file of files.sort()) {
    const filePath = path.join(dir, file);
    const source = fs.readFileSync(filePath, 'utf8');
    const tree = parser.parse(source);
    const errors = countNodes(tree.rootNode, 'ERROR');
    const cics = countNodes(tree.rootNode, 'exec_cics_statement');
    const sql = countNodes(tree.rootNode, 'exec_sql_statement');
    const hostVars = countNodes(tree.rootNode, 'sql_host_variable');
    results.push({ file, errors, cics, sql, hostVars });
  }
  return results;
}

console.log('Parsing CardDemo COBOL files...\n');

const cblResults = parseFiles(cblDir, '.cbl');
const cpyResults = parseFiles(cpyDir, '.cpy');

let totalErrors = 0;
let totalFiles = 0;

console.log('=== CBL Files ===');
for (const r of cblResults) {
  totalFiles++;
  totalErrors += r.errors;
  const status = r.errors === 0 ? '  OK' : 'FAIL';
  const extras = [];
  if (r.cics > 0) extras.push(`CICS:${r.cics}`);
  if (r.sql > 0) extras.push(`SQL:${r.sql}`);
  if (r.hostVars > 0) extras.push(`host-vars:${r.hostVars}`);
  const detail = extras.length > 0 ? `  [${extras.join(', ')}]` : '';
  console.log(`  ${status}  ${r.file}${r.errors > 0 ? ` (${r.errors} errors)` : ''}${detail}`);
}

console.log('\n=== CPY Files ===');
for (const r of cpyResults) {
  totalFiles++;
  totalErrors += r.errors;
  const status = r.errors === 0 ? '  OK' : 'FAIL';
  console.log(`  ${status}  ${r.file}${r.errors > 0 ? ` (${r.errors} errors)` : ''}`);
}

console.log(`\n--- Summary ---`);
console.log(`Total files: ${totalFiles}`);
console.log(`Files with errors: ${cblResults.filter(r => r.errors > 0).length + cpyResults.filter(r => r.errors > 0).length}`);
console.log(`Total ERROR nodes: ${totalErrors}`);

// CSSETATY.cpy is a COPY REPLACING template with substitution variables — expected errors
const unexpectedErrors = [...cblResults, ...cpyResults].filter(
  r => r.errors > 0 && r.file !== 'CSSETATY.cpy'
);

if (unexpectedErrors.length > 0) {
  process.exit(1);
}
