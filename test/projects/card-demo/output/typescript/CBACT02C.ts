// Generated from CBACT02C.cbl — CardDemo reference translation. Not production code.
//
// Original program: CBACT02C.CBL
// Application: CardDemo
// Type: Batch COBOL Program
// Function: Read and print card data file.
//
// COPY books expanded:
//   CVACT02Y → CardRecord (card entity, RECLN 150)
//
// Note: COMP-3 / packed decimal fields are represented as number here.
// In production, use Decimal.js or similar for exact decimal arithmetic.

import * as fs from "fs";

// ─── Data Structures (from CVACT02Y COPY book) ───────────────────────────────

/** CARD-RECORD — card entity (RECLN 150) */
interface CardRecord {
  cardNum: string;           // PIC X(16)
  cardAcctId: string;        // PIC 9(11)
  cardCvvCd: string;         // PIC 9(03)
  cardEmbossedName: string;  // PIC X(50)
  cardExpirationDate: string;// PIC X(10)
  cardActiveStatus: string;  // PIC X(01)
  filler: string;            // PIC X(59)
}

// ─── File Record (FILE SECTION) ───────────────────────────────────────────────

/** FD-CARDFILE-REC — raw file record layout */
interface FdCardfileRec {
  fdCardNum: string;   // PIC X(16)
  fdCardData: string;  // PIC X(134)
}

// ─── Working Storage ──────────────────────────────────────────────────────────

let cardfileStatus: string = "00";   // CARDFILE-STATUS: PIC X(02)
let ioStatus: string = "00";         // IO-STATUS:       PIC X(02)
let applResult: number = 0;          // APPL-RESULT:     PIC S9(9) COMP
//   88 APPL-AOK VALUE 0
//   88 APPL-EOF VALUE 16
let endOfFile: string = "N";         // END-OF-FILE:     PIC X(01) VALUE 'N'
let abcode: number = 0;              // ABCODE:          PIC S9(9) BINARY
let timing: number = 0;              // TIMING:          PIC S9(9) BINARY

let cardRecord: CardRecord = {
  cardNum: "",
  cardAcctId: "",
  cardCvvCd: "",
  cardEmbossedName: "",
  cardExpirationDate: "",
  cardActiveStatus: "",
  filler: "",
};

// Simulated file handle — in real usage, wire to an actual indexed file reader
let cardfileHandle: fs.ReadStream | null = null;
let cardfileLines: string[] = [];
let cardfilePos: number = 0;

// ─── Paragraph: 9910-DISPLAY-IO-STATUS ───────────────────────────────────────

function displayIoStatus(): void {
  // Mirrors COBOL logic: check if IO-STATUS is non-numeric or starts with '9'
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
  // TODO: CALL 'CEE3ABD' USING ABCODE, TIMING — z/OS LE abnormal termination
  // Stub: just exit with non-zero code
  process.exit(999);
}

// ─── Paragraph: 0000-CARDFILE-OPEN ───────────────────────────────────────────

function cardfileOpen(): void {
  applResult = 8;
  try {
    // TODO: Replace with actual indexed file open logic (VSAM KSDS equivalent)
    // Stub: read a flat file named CARDFILE line by line
    const path = process.env["CARDFILE"] ?? "CARDFILE";
    cardfileLines = fs.readFileSync(path, "utf8").split("\n").filter(Boolean);
    cardfilePos = 0;
    cardfileStatus = "00";
    applResult = 0;
  } catch {
    cardfileStatus = "35"; // file not found
    applResult = 12;
  }

  if (applResult !== 0) {
    console.log("ERROR OPENING CARDFILE");
    ioStatus = cardfileStatus;
    displayIoStatus();
    abendProgram();
  }
}

// ─── Paragraph: 1000-CARDFILE-GET-NEXT ───────────────────────────────────────

function cardfileGetNext(): void {
  if (cardfilePos >= cardfileLines.length) {
    // Simulate end-of-file (VSAM status '10')
    cardfileStatus = "10";
  } else {
    const raw = cardfileLines[cardfilePos++]!.padEnd(150, " ");
    cardfileStatus = "00";
    // Parse raw record into CARD-RECORD (mirrors READ … INTO CARD-RECORD)
    cardRecord = {
      cardNum:            raw.substring(0, 16),
      cardAcctId:         raw.substring(16, 27),
      cardCvvCd:          raw.substring(27, 30),
      cardEmbossedName:   raw.substring(30, 80),
      cardExpirationDate: raw.substring(80, 90),
      cardActiveStatus:   raw.substring(90, 91),
      filler:             raw.substring(91, 150),
    };
  }

  if (cardfileStatus === "00") {
    applResult = 0;
  } else if (cardfileStatus === "10") {
    applResult = 16; // APPL-EOF
  } else {
    applResult = 12;
  }

  if (applResult === 0) {
    // APPL-AOK: continue
  } else if (applResult === 16) {
    // APPL-EOF
    endOfFile = "Y";
  } else {
    console.log("ERROR READING CARDFILE");
    ioStatus = cardfileStatus;
    displayIoStatus();
    abendProgram();
  }
}

// ─── Paragraph: 9000-CARDFILE-CLOSE ──────────────────────────────────────────

function cardfileClose(): void {
  applResult = 8;
  try {
    // TODO: Close actual file handle
    cardfileLines = [];
    cardfileStatus = "00";
    applResult = 0;
  } catch {
    cardfileStatus = "90";
    applResult = 12;
  }

  if (applResult !== 0) {
    console.log("ERROR CLOSING CARDFILE");
    ioStatus = cardfileStatus;
    displayIoStatus();
    abendProgram();
  }
}

// ─── PROCEDURE DIVISION (main) ────────────────────────────────────────────────

function main(): void {
  console.log("START OF EXECUTION OF PROGRAM CBACT02C");

  cardfileOpen();

  // PERFORM UNTIL END-OF-FILE = 'Y'
  while (endOfFile !== "Y") {
    if (endOfFile === "N") {
      cardfileGetNext();
      if (endOfFile === "N") {
        // DISPLAY CARD-RECORD
        console.log(JSON.stringify(cardRecord));
      }
    }
  }

  cardfileClose();

  console.log("END OF EXECUTION OF PROGRAM CBACT02C");

  // GOBACK
  process.exit(0);
}

main();
