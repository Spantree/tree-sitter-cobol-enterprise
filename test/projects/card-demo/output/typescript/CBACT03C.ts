// Generated from CBACT03C.cbl — CardDemo reference translation. Not production code.
//
// Original program: CBACT03C.CBL
// Application: CardDemo
// Type: Batch COBOL Program
// Function: Read and print account cross-reference data file.
//
// COPY books expanded:
//   CVACT03Y → CardXrefRecord (card xref entity, RECLN 50)
//
// Note: COMP-3 / packed decimal fields are represented as number here.
// In production, use Decimal.js or similar for exact decimal arithmetic.

import * as fs from "fs";

// ─── Data Structures (from CVACT03Y COPY book) ───────────────────────────────

/** CARD-XREF-RECORD — card cross-reference entity (RECLN 50) */
interface CardXrefRecord {
  xrefCardNum: string;  // PIC X(16)
  xrefCustId: string;   // PIC 9(09)
  xrefAcctId: string;   // PIC 9(11)
  filler: string;       // PIC X(14)
}

// ─── File Record (FILE SECTION) ───────────────────────────────────────────────

/** FD-XREFFILE-REC — raw file record layout */
interface FdXreffileRec {
  fdXrefCardNum: string;  // PIC X(16)
  fdXrefData: string;     // PIC X(34)
}

// ─── Working Storage ──────────────────────────────────────────────────────────

let xreffileStatus: string = "00";  // XREFFILE-STATUS: PIC X(02)
let ioStatus: string = "00";        // IO-STATUS:       PIC X(02)
let applResult: number = 0;         // APPL-RESULT:     PIC S9(9) COMP
//   88 APPL-AOK VALUE 0
//   88 APPL-EOF VALUE 16
let endOfFile: string = "N";        // END-OF-FILE:     PIC X(01) VALUE 'N'
let abcode: number = 0;             // ABCODE:          PIC S9(9) BINARY
let timing: number = 0;             // TIMING:          PIC S9(9) BINARY

let cardXrefRecord: CardXrefRecord = {
  xrefCardNum: "",
  xrefCustId: "",
  xrefAcctId: "",
  filler: "",
};

// Simulated file state — wire to an actual indexed file reader in production
let xreffileLines: string[] = [];
let xreffilePos: number = 0;

// ─── Paragraph: 9910-DISPLAY-IO-STATUS ───────────────────────────────────────

function displayIoStatus(): void {
  const stat1 = ioStatus[0] ?? "";
  const stat2 = ioStatus[1] ?? "";
  if (!/^\d+$/.test(ioStatus) || stat1 === "9") {
    const twoBytesRight = stat2.charCodeAt(0);
    console.log(`FILE STATUS IS: NNNN${stat1}${String(twoBytesRight).padStart(3, "0")}`);
  } else {
    console.log(`FILE STATUS IS: NNNN00${ioStatus}`);
  }
}

// ─── Paragraph: 9999-ABEND-PROGRAM ───────────────────────────────────────────

function abendProgram(): never {
  console.log("ABENDING PROGRAM");
  timing = 0;
  abcode = 999;
  // TODO: CALL 'CEE3ABD' USING ABCODE, TIMING — z/OS LE abnormal termination stub
  process.exit(999);
}

// ─── Paragraph: 0000-XREFFILE-OPEN ───────────────────────────────────────────

function xreffileOpen(): void {
  applResult = 8;
  try {
    // TODO: Replace with actual indexed VSAM KSDS open
    const path = process.env["XREFFILE"] ?? "XREFFILE";
    xreffileLines = fs.readFileSync(path, "utf8").split("\n").filter(Boolean);
    xreffilePos = 0;
    xreffileStatus = "00";
    applResult = 0;
  } catch {
    xreffileStatus = "35";
    applResult = 12;
  }

  if (applResult !== 0) {
    console.log("ERROR OPENING XREFFILE");
    ioStatus = xreffileStatus;
    displayIoStatus();
    abendProgram();
  }
}

// ─── Paragraph: 1000-XREFFILE-GET-NEXT ───────────────────────────────────────

function xreffileGetNext(): void {
  if (xreffilePos >= xreffileLines.length) {
    xreffileStatus = "10"; // end of file
  } else {
    const raw = xreffileLines[xreffilePos++]!.padEnd(50, " ");
    xreffileStatus = "00";
    // Parse raw record into CARD-XREF-RECORD (mirrors READ … INTO CARD-XREF-RECORD)
    cardXrefRecord = {
      xrefCardNum: raw.substring(0, 16),
      xrefCustId:  raw.substring(16, 25),
      xrefAcctId:  raw.substring(25, 36),
      filler:      raw.substring(36, 50),
    };
    // In the COBOL source, 1000-XREFFILE-GET-NEXT DISPLAYs the record on every
    // successful read (note: the outer loop also DISPLAYs — matches source exactly)
    console.log(JSON.stringify(cardXrefRecord));
  }

  if (xreffileStatus === "00") {
    applResult = 0;
  } else if (xreffileStatus === "10") {
    applResult = 16; // APPL-EOF
  } else {
    applResult = 12;
  }

  if (applResult === 0) {
    // APPL-AOK: continue
  } else if (applResult === 16) {
    endOfFile = "Y";
  } else {
    console.log("ERROR READING XREFFILE");
    ioStatus = xreffileStatus;
    displayIoStatus();
    abendProgram();
  }
}

// ─── Paragraph: 9000-XREFFILE-CLOSE ──────────────────────────────────────────

function xreffileClose(): void {
  applResult = 8;
  try {
    // TODO: Close actual file handle
    xreffileLines = [];
    xreffileStatus = "00";
    applResult = 0;
  } catch {
    xreffileStatus = "90";
    applResult = 12;
  }

  if (applResult !== 0) {
    console.log("ERROR CLOSING XREFFILE");
    ioStatus = xreffileStatus;
    displayIoStatus();
    abendProgram();
  }
}

// ─── PROCEDURE DIVISION (main) ────────────────────────────────────────────────

function main(): void {
  console.log("START OF EXECUTION OF PROGRAM CBACT03C");

  xreffileOpen();

  // PERFORM UNTIL END-OF-FILE = 'Y'
  while (endOfFile !== "Y") {
    if (endOfFile === "N") {
      xreffileGetNext();
      if (endOfFile === "N") {
        // DISPLAY CARD-XREF-RECORD (outer loop display — inner paragraph also displays)
        console.log(JSON.stringify(cardXrefRecord));
      }
    }
  }

  xreffileClose();

  console.log("END OF EXECUTION OF PROGRAM CBACT03C");

  // GOBACK
  process.exit(0);
}

main();
