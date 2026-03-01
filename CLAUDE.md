# CLAUDE.md — tree-sitter-cobol-enterprise

You are building a tree-sitter grammar for IBM Enterprise COBOL that handles
EXEC CICS and EXEC SQL as first-class citizens with typed AST nodes.

## Project Context

This grammar exists to fix a critical gap: the existing `tree-sitter-cobol`
(yutaro-sakamoto/phodal on npm) treats EXEC CICS/SQL blocks as opaque word
sequences, causing ERROR nodes in 25 of 44 CardDemo COBOL programs. This
grammar parses them properly.

**Target dialect:** IBM Enterprise COBOL for z/OS (fixed-form, columns 1-80)
**Primary test corpus:** AWS CardDemo at `~/src/gatx/carddemo-source/`
**Consumer:** `mainframe-modernization-plugin` at `~/src/gatx/mainframe-modernization-plugin/`

## Architecture

```
grammar.js              # Main grammar — all rules defined here
src/scanner.c           # External scanner — column-position, comments, continuations
src/parser.c            # AUTO-GENERATED — do not edit
src/grammar.json        # AUTO-GENERATED — do not edit
bindings/node/          # Node.js native binding (nan-based, tree-sitter 0.20.x)
test/corpus/            # tree-sitter test cases (one .txt per concern)
examples/               # Sample .cbl files for manual testing
```

## Build Commands

```bash
npm install                   # Install deps (nan, tree-sitter-cli)
npx tree-sitter generate      # Generate parser from grammar.js
npm run build                  # Compile native module (node-gyp rebuild)
npx tree-sitter test           # Run test corpus
node scripts/validate.js       # Parse all CardDemo files, count ERROR nodes
```

## Grammar Design Rules

### Keywords Are Case-Insensitive
COBOL keywords can be upper, lower, or mixed case. Define them as regex:
```javascript
_MOVE: $ => /[Mm][Oo][Vv][Ee]/,
```
Or use `alias()` with a helper function for case-insensitive matching.

### EXEC CICS Commands Have Typed Options
Each CICS command gets its own rule with `field()` names for options:
```javascript
cics_read: $ => seq($._READ, repeat(choice(
  field('dataset', seq($._DATASET, '(', $._cics_arg, ')')),
  field('into', seq($._INTO, '(', $._cics_arg, ')')),
  // ...
  $.cics_option,  // fallback for unknown options
))),
```

### EXEC SQL Uses Statement Classification
SQL is parsed at type level (SELECT/INSERT/UPDATE/DELETE) with host variable
recognition (`:var`), NOT deep SQL syntax:
```javascript
sql_select: $ => seq($._SELECT, repeat($._sql_token)),
sql_host_variable: $ => seq(':', $.WORD),
```

### The External Scanner Handles Column Position
Fixed-form COBOL has column-sensitive semantics:
- Cols 1-6: sequence area (skip)
- Col 7: indicator (`*`=comment, `-`=continuation)
- Cols 8-72: source code
- Cols 73-80: identification area (skip)

The scanner uses `lexer->get_column()` (tree-sitter 0.20+) to determine position.

## Key Files in CardDemo (Test Reference)

### CICS Programs (must produce typed exec_cics_statement nodes)
- `COSGN00C.cbl` — Signon screen, SEND MAP, RECEIVE MAP, RETURN, READ, XCTL
- `COACTUPC.cbl` — Account update, 17 EXEC CICS, HANDLE ABEND, GO TO spaghetti
- `COUSR00C.cbl` — User list, STARTBR/READNEXT/ENDBR browse pattern
- `COCRDLIC.cbl` — Card list, complex EVALUATE with CICS calls

### Batch Programs (should continue to work as before)
- `CBACT01C.cbl` — Account batch, PERFORM/READ/WRITE patterns
- `CBTRN01C.cbl` — Transaction batch, SORT with I/O PROCEDURE

### SQL Programs (must produce typed exec_sql_statement nodes)
- `COTRTLIC.cbl` — CICS+DB2, DECLARE CURSOR/OPEN/FETCH/CLOSE
- `COBTUPDT.cbl` — Batch DB2, INSERT with host variables
- `COBTUPDW.cbl` — Batch DB2, UPDATE with WHERE

### Copybooks (should parse data descriptions)
- `CVACT01Y.cpy` — 13 PIC clauses (good PIC test)
- `COCOM01Y.cpy` — Nested groups, OCCURS, REDEFINES

## GitHub Issues

The implementation plan is tracked in GitHub issues:
- #1 — Epic (overview, sub-issue checklist)
- #2 — Project scaffold
- #3 — External scanner
- #4 — DATA DIVISION grammar
- #5 — PROCEDURE DIVISION grammar
- #6 — EXEC CICS grammar (22 commands)
- #7 — EXEC SQL grammar
- #8 — Test corpus & validation
- #9 — Integration with mainframe-modernization-plugin

Read the issue comments for detailed design notes, code examples, and
CardDemo-specific patterns.

## Multi-Agent Team Strategy

This project can be parallelized with a team:

| Agent | Issues | Description |
|-------|--------|-------------|
| **Lead** | #1 | Orchestrate, review, integrate |
| **Scanner Agent** | #2, #3 | Scaffold + external scanner |
| **Grammar Agent 1** | #4 | DATA DIVISION rules |
| **Grammar Agent 2** | #5 | PROCEDURE DIVISION rules |
| **CICS Agent** | #6 | All 22 EXEC CICS command rules |
| **SQL Agent** | #7 | EXEC SQL rules |
| **Test Agent** | #8 | Write test corpus, validate |

Dependencies: #2 blocks all others. #3 blocks #4/#5/#6/#7. #4+#5+#6+#7 block #8.
#8 blocks #9.

In practice, agents working on #4-#7 can work in parallel on separate sections of
`grammar.js`, then the lead merges. The grammar file is the single source of truth.

## Conventions

- tree-sitter 0.20.x compatibility (matches mainframe-modernization-plugin)
- nan-based Node.js bindings (not node-addon-api)
- External function name: `tree_sitter_cobol` (for `parser.setLanguage()` compat)
- Test names: descriptive, using real CardDemo patterns where possible
- Commits: conventional commits, one logical change per commit
