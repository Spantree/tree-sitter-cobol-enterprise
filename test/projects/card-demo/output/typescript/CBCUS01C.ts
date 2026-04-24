// Generated from CBCUS01C.cbl — CardDemo reference translation. Not production code.
//
// Original program: CBCUS01C.CBL
// Application: CardDemo
// Type: Batch COBOL Program
// Function: Read and print customer data file.
//
// COPY books expanded:
//   CVCUS01Y → CustomerRecord (customer entity, RECLN 500)
//
// Note: COMP-3 / packed decimal fields are represented as number here.
// In production, use Decimal.js or similar for exact decimal arithmetic.

import * as fs from "fs";

// ─── Data Structures (from CVCUS01Y COPY book) ───────────────────────────────

/** CUSTOMER-RECORD — customer entity (RECLN 500) */
interface CustomerRecord {
  custId: string;              // PIC 9(09)
  custFirstName: string;       // PIC X(25)
  custMiddleName: string;      // PIC X(25)
  custLastName: string;        // PIC X(25)
  custAddrLine1: string;       // PIC X(50)
  custAddrLine2: string;       // PIC X(50)
  custAddrLine3: string;       // PIC X(50)
  custAddrStateCd: string;     // PIC X(02)
  custAddrCountryCd: string;   // PIC X(03)
  custAddrZip: string;         // PIC X(10)
  custPhoneNum1: string;       // PIC X(15)
  custPhoneNum2: string;       // PIC X(15)
  custSsn: string;             // PIC 9(09)
  custGovtIssuedId: string;    // PIC X(20)
  custDobYyyyMmDd: string;     // PIC X(10)
  custEftAccountId: string;    // PIC X(10)
  custPriCardHolderInd: string;// PIC X(01)
  custFicoCreditScore: string; // PIC 9(03)
  filler: string;              // PIC X(168)
}

// ─── File Record (FILE SECTION) ───────────────────────────────────────────────

/** FD-CUSTFILE-REC — raw file record layout */
interface FdCustfileRec {
  fdCustId: string;    // PIC 9(09)
  fdCustData: string;  // PIC X(491)
}

// ─── Working Storage ──────────────────────────────────────────────────────────

let custfileStatus: string = "00";  // CUSTFILE-STATUS: PIC X(02)
let ioStatus: string = "00";        // IO-STATUS:       PIC X(02)
let applResult: number = 0;         // APPL-RESULT:     PIC S9(9) COMP
//   88 APPL-AOK VALUE 0
//   88 APPL-EOF VALUE 16
let endOfFile: string = "N";        // END-OF-FILE:     PIC X(01) VALUE 'N'
let abcode: number = 0;             // ABCODE:          PIC S9(9) BINARY
let timing: number = 0;             // TIMING:          PIC S9(9) BINARY

let customerRecord: CustomerRecord = {
  custId: "",
  custFirstName: "",
  custMiddleName: "",
  custLastName: "",
  custAddrLine1: "",
  custAddrLine2: "",
  custAddrLine3: "",
  custAddrStateCd: "",
  custAddrCountryCd: "",
  custAddrZip: "",
  custPhoneNum1: "",
  custPhoneNum2: "",
  custSsn: "",
  custGovtIssuedId: "",
  custDobYyyyMmDd: "",
  custEftAccountId: "",
  custPriCardHolderInd: "",
  custFicoCreditScore: "",
  filler: "",
};

// Simulated file state — wire to an actual indexed file reader in production
let custfileLines: string[] = [];
let custfilePos: number = 0;

// ─── Paragraph: Z-DISPLAY-IO-STATUS ──────────────────────────────────────────

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

// ─── Paragraph: Z-ABEND-PROGRAM ──────────────────────────────────────────────

function abendProgram(): never {
  console.log("ABENDING PROGRAM");
  timing = 0;
  abcode = 999;
  // TODO: CALL 'CEE3ABD' USING ABCODE, TIMING — z/OS LE abnormal termination stub
  process.exit(999);
}

// ─── Paragraph: 0000-CUSTFILE-OPEN ───────────────────────────────────────────

function custfileOpen(): void {
  applResult = 8;
  try {
    // TODO: Replace with actual indexed VSAM KSDS open
    const path = process.env["CUSTFILE"] ?? "CUSTFILE";
    custfileLines = fs.readFileSync(path, "utf8").split("\n").filter(Boolean);
    custfilePos = 0;
    custfileStatus = "00";
    applResult = 0;
  } catch {
    custfileStatus = "35";
    applResult = 12;
  }

  if (applResult !== 0) {
    console.log("ERROR OPENING CUSTFILE");
    ioStatus = custfileStatus;
    displayIoStatus();
    abendProgram();
  }
}

// ─── Paragraph: 1000-CUSTFILE-GET-NEXT ───────────────────────────────────────

function custfileGetNext(): void {
  if (custfilePos >= custfileLines.length) {
    custfileStatus = "10"; // end of file
  } else {
    const raw = custfileLines[custfilePos++]!.padEnd(500, " ");
    custfileStatus = "00";
    // Parse raw record into CUSTOMER-RECORD (mirrors READ … INTO CUSTOMER-RECORD)
    // Offsets follow CVCUS01Y field layout (RECLN 500)
    customerRecord = {
      custId:               raw.substring(0, 9),    // PIC 9(09)
      custFirstName:        raw.substring(9, 34),   // PIC X(25)
      custMiddleName:       raw.substring(34, 59),  // PIC X(25)
      custLastName:         raw.substring(59, 84),  // PIC X(25)
      custAddrLine1:        raw.substring(84, 134), // PIC X(50)
      custAddrLine2:        raw.substring(134, 184),// PIC X(50)
      custAddrLine3:        raw.substring(184, 234),// PIC X(50)
      custAddrStateCd:      raw.substring(234, 236),// PIC X(02)
      custAddrCountryCd:    raw.substring(236, 239),// PIC X(03)
      custAddrZip:          raw.substring(239, 249),// PIC X(10)
      custPhoneNum1:        raw.substring(249, 264),// PIC X(15)
      custPhoneNum2:        raw.substring(264, 279),// PIC X(15)
      custSsn:              raw.substring(279, 288),// PIC 9(09)
      custGovtIssuedId:     raw.substring(288, 308),// PIC X(20)
      custDobYyyyMmDd:      raw.substring(308, 318),// PIC X(10)
      custEftAccountId:     raw.substring(318, 328),// PIC X(10)
      custPriCardHolderInd: raw.substring(328, 329),// PIC X(01)
      custFicoCreditScore:  raw.substring(329, 332),// PIC 9(03)
      filler:               raw.substring(332, 500),// PIC X(168)
    };
    // Note: COBOL source DISPLAYs on every successful read inside this paragraph
    console.log(JSON.stringify(customerRecord));
  }

  if (custfileStatus === "00") {
    applResult = 0;
  } else if (custfileStatus === "10") {
    applResult = 16; // APPL-EOF
  } else {
    applResult = 12;
  }

  if (applResult === 0) {
    // APPL-AOK: continue
  } else if (applResult === 16) {
    endOfFile = "Y";
  } else {
    console.log("ERROR READING CUSTOMER FILE");
    ioStatus = custfileStatus;
    displayIoStatus();
    abendProgram();
  }
}

// ─── Paragraph: 9000-CUSTFILE-CLOSE ──────────────────────────────────────────

function custfileClose(): void {
  applResult = 8;
  try {
    // TODO: Close actual file handle
    custfileLines = [];
    custfileStatus = "00";
    applResult = 0;
  } catch {
    custfileStatus = "90";
    applResult = 12;
  }

  if (applResult !== 0) {
    console.log("ERROR CLOSING CUSTOMER FILE");
    ioStatus = custfileStatus;
    displayIoStatus();
    abendProgram();
  }
}

// ─── PROCEDURE DIVISION (main) ────────────────────────────────────────────────

function main(): void {
  console.log("START OF EXECUTION OF PROGRAM CBCUS01C");

  custfileOpen();

  // PERFORM UNTIL END-OF-FILE = 'Y'
  while (endOfFile !== "Y") {
    if (endOfFile === "N") {
      custfileGetNext();
      if (endOfFile === "N") {
        // DISPLAY CUSTOMER-RECORD (outer loop display — inner paragraph also displays)
        console.log(JSON.stringify(customerRecord));
      }
    }
  }

  custfileClose();

  console.log("END OF EXECUTION OF PROGRAM CBCUS01C");

  // GOBACK
  process.exit(0);
}

main();
