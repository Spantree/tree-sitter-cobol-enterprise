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
// Note: COMP-3 / packed decimal fields → BigDecimal in real usage.
//       This translation uses String for all fields for readability.

import java.io.*;
import java.math.BigDecimal;
import java.nio.file.*;
import java.util.*;

public class CBACT02C {

    // ─── Data Structures (from CVACT02Y COPY book) ───────────────────────────

    /** CARD-RECORD — card entity (RECLN 150) */
    static class CardRecord {
        String cardNum;            // PIC X(16)
        String cardAcctId;         // PIC 9(11)
        String cardCvvCd;          // PIC 9(03)
        String cardEmbossedName;   // PIC X(50)
        String cardExpirationDate; // PIC X(10)
        String cardActiveStatus;   // PIC X(01)
        String filler;             // PIC X(59)

        @Override
        public String toString() {
            return "CardRecord{cardNum='" + cardNum + "', cardAcctId='" + cardAcctId
                + "', cardCvvCd='" + cardCvvCd + "', cardEmbossedName='" + cardEmbossedName
                + "', cardExpirationDate='" + cardExpirationDate
                + "', cardActiveStatus='" + cardActiveStatus + "'}";
        }
    }

    // ─── File Record (FILE SECTION) ──────────────────────────────────────────

    /** FD-CARDFILE-REC — raw file record layout */
    static class FdCardfileRec {
        String fdCardNum;   // PIC X(16)
        String fdCardData;  // PIC X(134)
    }

    // ─── Working Storage ─────────────────────────────────────────────────────

    // CARDFILE-STATUS  PIC X(02)
    private String cardfileStatus = "  ";

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

    private CardRecord cardRecord = new CardRecord();

    // Simulated file state — replace with real VSAM/indexed file access
    private List<String> cardfileLines = new ArrayList<>();
    private int cardfilePos = 0;

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

    // ─── Paragraph: 0000-CARDFILE-OPEN ───────────────────────────────────────

    private void cardfileOpen() {
        applResult = 8;
        // TODO: Replace with actual indexed VSAM KSDS open
        String path = System.getenv("CARDFILE") != null ? System.getenv("CARDFILE") : "CARDFILE";
        try {
            cardfileLines = Files.readAllLines(Paths.get(path));
            cardfilePos = 0;
            cardfileStatus = "00";
            applResult = 0;
        } catch (IOException e) {
            cardfileStatus = "35"; // file not found
            applResult = 12;
        }

        if (applResult != 0) {
            System.out.println("ERROR OPENING CARDFILE");
            ioStatus = cardfileStatus;
            displayIoStatus();
            abendProgram();
        }
    }

    // ─── Paragraph: 1000-CARDFILE-GET-NEXT ───────────────────────────────────

    private void cardfileGetNext() {
        if (cardfilePos >= cardfileLines.size()) {
            cardfileStatus = "10"; // end of file
        } else {
            // Pad or trim to exactly 150 chars (RECLN 150)
            String raw = String.format("%-150s", cardfileLines.get(cardfilePos++));
            cardfileStatus = "00";
            // Parse raw record into CARD-RECORD (mirrors READ … INTO CARD-RECORD)
            cardRecord = new CardRecord();
            cardRecord.cardNum            = raw.substring(0, 16);
            cardRecord.cardAcctId         = raw.substring(16, 27);
            cardRecord.cardCvvCd          = raw.substring(27, 30);
            cardRecord.cardEmbossedName   = raw.substring(30, 80);
            cardRecord.cardExpirationDate = raw.substring(80, 90);
            cardRecord.cardActiveStatus   = raw.substring(90, 91);
            cardRecord.filler             = raw.substring(91, 150);
        }

        if ("00".equals(cardfileStatus)) {
            applResult = 0;
        } else if ("10".equals(cardfileStatus)) {
            applResult = 16; // APPL-EOF
        } else {
            applResult = 12;
        }

        if (applResult == 0) {
            // APPL-AOK: continue
        } else if (applResult == 16) {
            endOfFile = 'Y';
        } else {
            System.out.println("ERROR READING CARDFILE");
            ioStatus = cardfileStatus;
            displayIoStatus();
            abendProgram();
        }
    }

    // ─── Paragraph: 9000-CARDFILE-CLOSE ──────────────────────────────────────

    private void cardfileClose() {
        applResult = 8;
        // TODO: Close actual file handle
        cardfileLines.clear();
        cardfileStatus = "00";
        applResult = 0;

        if (applResult != 0) {
            System.out.println("ERROR CLOSING CARDFILE");
            ioStatus = cardfileStatus;
            displayIoStatus();
            abendProgram();
        }
    }

    // ─── PROCEDURE DIVISION ───────────────────────────────────────────────────

    public void run() {
        System.out.println("START OF EXECUTION OF PROGRAM CBACT02C");

        cardfileOpen();

        // PERFORM UNTIL END-OF-FILE = 'Y'
        while (endOfFile != 'Y') {
            if (endOfFile == 'N') {
                cardfileGetNext();
                if (endOfFile == 'N') {
                    // DISPLAY CARD-RECORD
                    System.out.println(cardRecord);
                }
            }
        }

        cardfileClose();

        System.out.println("END OF EXECUTION OF PROGRAM CBACT02C");

        // GOBACK
        System.exit(0);
    }

    public static void main(String[] args) {
        new CBACT02C().run();
    }
}
