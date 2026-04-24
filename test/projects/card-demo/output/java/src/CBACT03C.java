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
// Note: COMP-3 / packed decimal fields → BigDecimal in real usage.
//       This translation uses String for all fields for readability.

import java.io.*;
import java.math.BigDecimal;
import java.nio.file.*;
import java.util.*;

public class CBACT03C {

    // ─── Data Structures (from CVACT03Y COPY book) ───────────────────────────

    /** CARD-XREF-RECORD — card cross-reference entity (RECLN 50) */
    static class CardXrefRecord {
        String xrefCardNum;  // PIC X(16)
        String xrefCustId;   // PIC 9(09)
        String xrefAcctId;   // PIC 9(11)
        String filler;       // PIC X(14)

        @Override
        public String toString() {
            return "CardXrefRecord{xrefCardNum='" + xrefCardNum + "', xrefCustId='"
                + xrefCustId + "', xrefAcctId='" + xrefAcctId + "'}";
        }
    }

    // ─── File Record (FILE SECTION) ──────────────────────────────────────────

    /** FD-XREFFILE-REC — raw file record layout */
    static class FdXreffileRec {
        String fdXrefCardNum;  // PIC X(16)
        String fdXrefData;     // PIC X(34)
    }

    // ─── Working Storage ─────────────────────────────────────────────────────

    // XREFFILE-STATUS  PIC X(02)
    private String xreffileStatus = "  ";

    // IO-STATUS  PIC X(02)
    private String ioStatus = "  ";

    // TWO-BYTES-BINARY  PIC 9(4) BINARY
    private int twoBytesBinary = 0;

    // APPL-RESULT  PIC S9(9) COMP
    //   88 APPL-AOK VALUE 0
    //   88 APPL-EOF VALUE 16
    private int applResult = 0;

    // END-OF-FILE  PIC X(01) VALUE 'N'
    private char endOfFile = 'N';

    // ABCODE  PIC S9(9) BINARY
    private int abcode = 0;

    // TIMING  PIC S9(9) BINARY
    private int timing = 0;

    private CardXrefRecord cardXrefRecord = new CardXrefRecord();

    // Simulated file state — replace with real VSAM/indexed file access
    private List<String> xreffileLines = new ArrayList<>();
    private int xreffilePos = 0;

    // ─── Paragraph: 9910-DISPLAY-IO-STATUS ───────────────────────────────────

    private void displayIoStatus() {
        String stat1 = ioStatus.length() > 0 ? String.valueOf(ioStatus.charAt(0)) : "";
        String stat2 = ioStatus.length() > 1 ? String.valueOf(ioStatus.charAt(1)) : "";
        boolean isNonNumeric = !ioStatus.trim().matches("\\d+");
        if (isNonNumeric || "9".equals(stat1)) {
            int twoBytesRight = stat2.length() > 0 ? (int) stat2.charAt(0) : 0;
            System.out.printf("FILE STATUS IS: NNNN%s%03d%n", stat1, twoBytesRight);
        } else {
            System.out.printf("FILE STATUS IS: NNNN00%s%n", ioStatus);
        }
    }

    // ─── Paragraph: 9999-ABEND-PROGRAM ───────────────────────────────────────

    private void abendProgram() {
        System.out.println("ABENDING PROGRAM");
        timing = 0;
        abcode = 999;
        // TODO: CALL 'CEE3ABD' USING ABCODE, TIMING — z/OS LE abnormal termination stub
        System.exit(999);
    }

    // ─── Paragraph: 0000-XREFFILE-OPEN ───────────────────────────────────────

    private void xreffileOpen() {
        applResult = 8;
        // TODO: Replace with actual indexed VSAM KSDS open
        String path = System.getenv("XREFFILE") != null ? System.getenv("XREFFILE") : "XREFFILE";
        try {
            xreffileLines = Files.readAllLines(Paths.get(path));
            xreffilePos = 0;
            xreffileStatus = "00";
            applResult = 0;
        } catch (IOException e) {
            xreffileStatus = "35"; // file not found
            applResult = 12;
        }

        if (applResult != 0) {
            System.out.println("ERROR OPENING XREFFILE");
            ioStatus = xreffileStatus;
            displayIoStatus();
            abendProgram();
        }
    }

    // ─── Paragraph: 1000-XREFFILE-GET-NEXT ───────────────────────────────────

    private void xreffileGetNext() {
        if (xreffilePos >= xreffileLines.size()) {
            xreffileStatus = "10"; // end of file
        } else {
            // Pad or trim to exactly 50 chars (RECLN 50)
            String raw = String.format("%-50s", xreffileLines.get(xreffilePos++));
            xreffileStatus = "00";
            // Parse raw record into CARD-XREF-RECORD (mirrors READ … INTO CARD-XREF-RECORD)
            cardXrefRecord = new CardXrefRecord();
            cardXrefRecord.xrefCardNum = raw.substring(0, 16);
            cardXrefRecord.xrefCustId  = raw.substring(16, 25);
            cardXrefRecord.xrefAcctId  = raw.substring(25, 36);
            cardXrefRecord.filler      = raw.substring(36, 50);
            // Note: inner paragraph also DISPLAYs on success (matches COBOL source)
            System.out.println(cardXrefRecord);
        }

        if ("00".equals(xreffileStatus)) {
            applResult = 0;
        } else if ("10".equals(xreffileStatus)) {
            applResult = 16; // APPL-EOF
        } else {
            applResult = 12;
        }

        if (applResult == 0) {
            // APPL-AOK: continue
        } else if (applResult == 16) {
            endOfFile = 'Y';
        } else {
            System.out.println("ERROR READING XREFFILE");
            ioStatus = xreffileStatus;
            displayIoStatus();
            abendProgram();
        }
    }

    // ─── Paragraph: 9000-XREFFILE-CLOSE ──────────────────────────────────────

    private void xreffileClose() {
        applResult = 8;
        // TODO: Close actual file handle
        xreffileLines.clear();
        xreffileStatus = "00";
        applResult = 0;

        if (applResult != 0) {
            System.out.println("ERROR CLOSING XREFFILE");
            ioStatus = xreffileStatus;
            displayIoStatus();
            abendProgram();
        }
    }

    // ─── PROCEDURE DIVISION ───────────────────────────────────────────────────

    public void run() {
        System.out.println("START OF EXECUTION OF PROGRAM CBACT03C");

        xreffileOpen();

        // PERFORM UNTIL END-OF-FILE = 'Y'
        while (endOfFile != 'Y') {
            if (endOfFile == 'N') {
                xreffileGetNext();
                if (endOfFile == 'N') {
                    // DISPLAY CARD-XREF-RECORD (outer loop display)
                    System.out.println(cardXrefRecord);
                }
            }
        }

        xreffileClose();

        System.out.println("END OF EXECUTION OF PROGRAM CBACT03C");

        // GOBACK
        System.exit(0);
    }

    public static void main(String[] args) {
        new CBACT03C().run();
    }
}
