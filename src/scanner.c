#include "tree_sitter/parser.h"

enum TokenType {
  COMMENT,
  PIC_STRING,
  COMMENT_ENTRY,
  SKIP_AREA,
  STRING_LITERAL,
};

void *tree_sitter_cobol_external_scanner_create() { return NULL; }
void tree_sitter_cobol_external_scanner_destroy(void *payload) {}
unsigned tree_sitter_cobol_external_scanner_serialize(void *payload,
                                                      char *buffer) {
  return 0;
}
void tree_sitter_cobol_external_scanner_deserialize(void *payload,
                                                    const char *buffer,
                                                    unsigned length) {}

static void advance(TSLexer *lexer) { lexer->advance(lexer, false); }
static void skip_char(TSLexer *lexer) { lexer->advance(lexer, true); }

static bool is_eol(int32_t c) { return c == '\n' || c == '\r'; }

static void consume_to_eol(TSLexer *lexer) {
  while (!lexer->eof(lexer) && !is_eol(lexer->lookahead)) {
    advance(lexer);
  }
}

bool tree_sitter_cobol_external_scanner_scan(void *payload, TSLexer *lexer,
                                             const bool *valid_symbols) {

  uint32_t col = lexer->get_column(lexer);

  /* Error recovery: all external tokens valid simultaneously. */
  bool error_recovery = valid_symbols[COMMENT] && valid_symbols[PIC_STRING] &&
                        valid_symbols[COMMENT_ENTRY] && valid_symbols[SKIP_AREA] &&
                        valid_symbols[STRING_LITERAL];

  /* --- PIC STRING ---
   * Opaque PIC value after PIC/PICTURE keyword. */
  if (valid_symbols[PIC_STRING] && !error_recovery) {
    while (lexer->lookahead == ' ' || lexer->lookahead == '\t') {
      skip_char(lexer);
    }
    if (lexer->eof(lexer) || is_eol(lexer->lookahead)) return false;

    bool has_content = false;
    lexer->result_symbol = PIC_STRING;

    while (!lexer->eof(lexer) && !is_eol(lexer->lookahead)) {
      col = lexer->get_column(lexer);
      int32_t c = lexer->lookahead;
      if (col >= 72) {
        if (has_content) lexer->mark_end(lexer);
        return has_content;
      }
      if (c == '.') {
        lexer->mark_end(lexer);
        advance(lexer);
        if (lexer->eof(lexer) || is_eol(lexer->lookahead) ||
            lexer->lookahead == ' ' || lexer->lookahead == '\t') {
          return has_content;
        }
        has_content = true;
        continue;
      }
      if (c == ' ' || c == '\t') {
        lexer->mark_end(lexer);
        return has_content;
      }
      advance(lexer);
      has_content = true;
    }
    if (has_content) lexer->mark_end(lexer);
    return has_content;
  }

  /* --- COMMENT ENTRY ---
   * Free-form text after AUTHOR., DATE-WRITTEN., etc. */
  if (valid_symbols[COMMENT_ENTRY] && !error_recovery) {
    while (lexer->lookahead == ' ' || lexer->lookahead == '\t') {
      skip_char(lexer);
    }
    bool found = false;
    lexer->result_symbol = COMMENT_ENTRY;
    while (!lexer->eof(lexer) && !is_eol(lexer->lookahead)) {
      col = lexer->get_column(lexer);
      if (col >= 72) break;
      advance(lexer);
      found = true;
    }
    if (found) {
      lexer->mark_end(lexer);
      return true;
    }
    /* No content found — fall through to extras handlers so that
     * SKIP_AREA can consume ID-area numbers, newlines, etc.
     * Refresh col since skip_char may have advanced position. */
    col = lexer->get_column(lexer);
  }

  /* --- STRING LITERAL ---
   * Handles quoted strings with continuation line support.
   * When a string reaches col 72 without closing, the scanner
   * consumes through the ID area, newline, seq area, and continuation
   * indicator '-' on the next line, then continues the string. */
  if (valid_symbols[STRING_LITERAL] && !error_recovery) {
    int32_t quote = lexer->lookahead;
    if (quote == '\'' || quote == '"') {
      col = lexer->get_column(lexer);
      if (col >= 7 && col < 72) {
        advance(lexer); /* consume opening quote */
        bool closed = false;
        while (!lexer->eof(lexer)) {
          col = lexer->get_column(lexer);
          int32_t c = lexer->lookahead;
          if (c == quote) {
            advance(lexer); /* consume closing quote */
            /* Check for doubled quote (escape): '' inside string */
            if (!lexer->eof(lexer) && lexer->lookahead == quote) {
              advance(lexer); /* consume second quote, continue string */
              continue;
            }
            closed = true;
            break;
          }
          if (is_eol(c) || col >= 72) {
            /* Unclosed string at end of source area — look for continuation.
             * Consume: rest of line (ID area), newline, seq area, indicator.*/
            while (!lexer->eof(lexer) && !is_eol(lexer->lookahead)) {
              advance(lexer);
            }
            /* Consume newline */
            if (!lexer->eof(lexer)) {
              if (lexer->lookahead == '\r') {
                advance(lexer);
                if (!lexer->eof(lexer) && lexer->lookahead == '\n')
                  advance(lexer);
              } else {
                advance(lexer);
              }
            }
            /* Consume sequence area (cols 0-5) */
            for (int i = 0; i < 6 && !lexer->eof(lexer) && !is_eol(lexer->lookahead); i++) {
              advance(lexer);
            }
            /* Check indicator at col 6 */
            if (lexer->eof(lexer) || is_eol(lexer->lookahead)) {
              break; /* no continuation indicator */
            }
            int32_t indicator = lexer->lookahead;
            if (indicator != '-') {
              break; /* not a continuation line */
            }
            advance(lexer); /* consume '-' indicator */
            /* Skip spaces until opening quote on continuation line */
            while (!lexer->eof(lexer) && !is_eol(lexer->lookahead)) {
              col = lexer->get_column(lexer);
              if (col >= 72) break;
              if (lexer->lookahead == quote) {
                advance(lexer); /* consume opening quote of continuation */
                break;
              }
              advance(lexer);
            }
            continue; /* continue scanning string content */
          }
          advance(lexer);
        }
        lexer->mark_end(lexer);
        lexer->result_symbol = STRING_LITERAL;
        return true;
      }
    }
  }

  /* =================================================================
   * EXTRAS: Column management and whitespace
   *
   * CRITICAL: The scanner handles ALL whitespace (spaces, tabs,
   * newlines, separators). No regex extras exist. This ensures the
   * scanner stays in control across line boundaries, properly
   * handling fixed-form COBOL column positions.
   *
   * COBOL fixed-form layout (0-indexed columns):
   *   Cols 0-5:  Sequence area (skip)
   *   Col 6:     Indicator (* / D d = comment, - = continuation)
   *   Cols 7-71: Source area (parsed by grammar)
   *   Cols 72+:  Identification area (skip)
   * ================================================================= */

  if (lexer->eof(lexer)) return false;

  /* Newlines: consume FIRST regardless of column position.
   * This must be above column-based handlers so newlines at col 72+
   * (e.g., after an 80-char line) are consumed instead of rejected. */
  if (is_eol(lexer->lookahead) && valid_symbols[SKIP_AREA]) {
    lexer->result_symbol = SKIP_AREA;
    if (lexer->lookahead == '\r') {
      advance(lexer);
      if (!lexer->eof(lexer) && lexer->lookahead == '\n') {
        advance(lexer);
      }
    } else {
      advance(lexer);
    }
    lexer->mark_end(lexer);
    return true;
  }

  /* Identification area: col 72+ */
  if (col >= 72 && valid_symbols[SKIP_AREA]) {
    lexer->result_symbol = SKIP_AREA;
    consume_to_eol(lexer);
    lexer->mark_end(lexer);
    return true;
  }

  /* Sequence area: cols 0-5 */
  if (col < 6 && (valid_symbols[SKIP_AREA] || valid_symbols[COMMENT])) {
    /* Consume sequence area (cols 0-5) */
    while (col < 6) {
      if (lexer->eof(lexer) || is_eol(lexer->lookahead)) {
        lexer->result_symbol = SKIP_AREA;
        lexer->mark_end(lexer);
        return true;
      }
      advance(lexer);
      col++;
    }

    /* Now at col 6: indicator */
    if (lexer->eof(lexer) || is_eol(lexer->lookahead)) {
      lexer->result_symbol = SKIP_AREA;
      lexer->mark_end(lexer);
      return true;
    }

    int32_t indicator = lexer->lookahead;
    advance(lexer); /* consume indicator */

    if (indicator == '*' || indicator == '/' ||
        indicator == 'D' || indicator == 'd') {
      if (valid_symbols[COMMENT]) {
        lexer->result_symbol = COMMENT;
      } else {
        lexer->result_symbol = SKIP_AREA;
      }
      consume_to_eol(lexer);
      lexer->mark_end(lexer);
      return true;
    }

    /* Regular line or continuation — seq area + indicator consumed */
    lexer->result_symbol = SKIP_AREA;
    lexer->mark_end(lexer);
    return true;
  }

  /* Indicator at col 6 (direct arrival, e.g. after tab) */
  if (col == 6 && (valid_symbols[COMMENT] || valid_symbols[SKIP_AREA])) {
    int32_t c = lexer->lookahead;

    if (c == '*' || c == '/' || c == 'D' || c == 'd') {
      if (valid_symbols[COMMENT]) {
        lexer->result_symbol = COMMENT;
      } else {
        lexer->result_symbol = SKIP_AREA;
      }
      advance(lexer);
      consume_to_eol(lexer);
      lexer->mark_end(lexer);
      return true;
    }

    if (c == '-') {
      /* Continuation indicator */
      if (valid_symbols[SKIP_AREA]) {
        lexer->result_symbol = SKIP_AREA;
        advance(lexer);
        lexer->mark_end(lexer);
        return true;
      }
    }

    if (c == ' ' || c == '\t') {
      /* Regular line indicator (space) */
      if (valid_symbols[SKIP_AREA]) {
        lexer->result_symbol = SKIP_AREA;
        advance(lexer);
        lexer->mark_end(lexer);
        return true;
      }
    }
  }

  /* Source area whitespace and separators (cols 7-71)
   * Note: commas are NOT consumed here — they're grammar tokens
   * used in subscripts, function args, etc. Semicolons are
   * optional COBOL separators treated as whitespace. */
  if (col >= 7 && col < 72 && valid_symbols[SKIP_AREA]) {
    int32_t c = lexer->lookahead;
    if (c == ' ' || c == '\t' || c == ';') {
      lexer->result_symbol = SKIP_AREA;
      while (!lexer->eof(lexer) && !is_eol(lexer->lookahead)) {
        c = lexer->lookahead;
        if (c != ' ' && c != '\t' && c != ';') break;
        col = lexer->get_column(lexer);
        if (col >= 72) break;
        advance(lexer);
      }
      lexer->mark_end(lexer);
      return true;
    }
  }

  return false;
}
