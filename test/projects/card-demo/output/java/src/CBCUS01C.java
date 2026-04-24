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
// Note: COMP-3 / packed decimal fields → BigDecimal in real usage.
//       This translation uses String for all fields for readability.

import java.io.*;
import java.math.BigDecimal;
import java.nio.file.*;
import java.util.*;

public class CBCUS01C {

    // ─── Data Structures (from CVCUS01Y COPY book) ───────────────────────────

    /** CUSTOMER-RECORD — customer entity (RECLN 500) */
    static class CustomerRecord {
        String custId;               // PIC 9(09)
        String custFirstName;        // PIC X(25)
        String custMiddleName;       // PIC X(25)
        String custLastName;         // PIC X(25)
        String custAddrLine1;        // PIC X(50)
        String custAddrLine2;        // PIC X(50)
        String custAddrLine3;        // PIC X(50)
        String custAddrStateCd;      // PIC X(02)
        String custAddrCountryCd;    // PIC X(03)
        String custAddrZip;          // PIC X(10)
        String custPhoneNum1;        // PIC X(15)
        String custPhoneNum2;        // PIC X(15)
        String custSsn;              // PIC 9(09)
        String custGovtIssuedId;     // PIC X(20)
        String custDobYyyyMmDd;      // PIC X(10)
        String custEftAccountId;     // PIC X(10)
        String custPriCardHolderInd; // PIC X(01)
        String custFicoCreditScore;  // PIC 9(03)
        String filler;               // PIC X(168)

        @Override
        public String toString() {
            return "CustomerRecord{custId='" + custId + "', custFirstName='" + custFirstName
                + "', custLastName='" + custLastName + "', custAddrStateCd='" + custAddrStateCd
                + "', custAddrZip='" + custAddrZip + "', custFicoCreditScore='" + custFicoCreditScore + "'}";
        }
    }

    // ─── File Record (FILE SECTION) ──────────────────────────────────────────

    /** FD-CUSTFILE-REC — raw file record layout */
    static class FdCustfileRec {
        String fdCustId;    // PIC 9(09)
        String fdCustData;  // PIC X(491)
    }

    // ─── Working Storage ─────────────────────────────────────────────────────

    // CUSTFILE-STATUS  PIC X(02)
    private String custfileStatus = "  ";

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

    private CustomerRecord customerRecord = new CustomerRecord();

    // Simulated file state — replace with real VSAM/indexed file access
    private List<String> custfileLines = new ArrayList<>();
    private int custfilePos = 0;

    // ─── Paragraph: Z-DISPLAY-IO-STATUS ──────────────────────────────────────

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

    // ─── Paragraph: Z-ABEND-PROGRAM ──────────────────────────────────────────

    private void abendProgram() {
        System.out.println("ABENDING PROGRAM");
        timing = 0;
        abcode = 999;
        // TODO: CALL 'CEE3ABD' USING ABCODE, TIMING — z/OS LE abnormal termination stub
        System.exit(999);
    }

    // ─── Paragraph: 0000-CUSTFILE-OPEN ───────────────────────────────────────

    private void custfileOpen() {
        applResult = 8;
        // TODO: Replace with actual indexed VSAM KSDS open
        String path = System.getenv("CUSTFILE") != null ? System.getenv("CUSTFILE") : "CUSTFILE";
        try {
            custfileLines = Files.readAllLines(Paths.get(path));
            custfilePos = 0;
            custfileStatus = "00";
            applResult = 0;
        } catch (IOException e) {
            custfileStatus = "35"; // file not found
            applResult = 12;
        }

        if (applResult != 0) {
            System.out.println("ERROR OPENING CUSTFILE");
            ioStatus = custfileStatus;
            displayIoStatus();
            abendProgram();
        }
    }

    // ─── Paragraph: 1000-CUSTFILE-GET-NEXT ───────────────────────────────────

    private void custfileGetNext() {
        if (custfilePos >= custfileLines.size()) {
            custfileStatus = "10"; // end of file
        } else {
            // Pad or trim to exactly 500 chars (RECLN 500)
            String raw = String.format("%-500s", custfileLines.get(custfilePos++));
            custfileStatus = "00";
            // Parse raw record into CUSTOMER-RECORD (mirrors READ … INTO CUSTOMER-RECORD)
            // Offsets follow CVCUS01Y field layout (RECLN 500)
            customerRecord = new CustomerRecord();
            customerRecord.custId               = raw.substring(0, 9);     // PIC 9(09)
            customerRecord.custFirstName        = raw.substring(9, 34);    // PIC X(25)
            customerRecord.custMiddleName       = raw.substring(34, 59);   // PIC X(25)
            customerRecord.custLastName         = raw.substring(59, 84);   // PIC X(25)
            customerRecord.custAddrLine1        = raw.substring(84, 134);  // PIC X(50)
            customerRecord.custAddrLine2        = raw.substring(134, 184); // PIC X(50)
            customerRecord.custAddrLine3        = raw.substring(184, 234); // PIC X(50)
            customerRecord.custAddrStateCd      = raw.substring(234, 236); // PIC X(02)
            customerRecord.custAddrCountryCd    = raw.substring(236, 239); // PIC X(03)
            customerRecord.custAddrZip          = raw.substring(239, 249); // PIC X(10)
            customerRecord.custPhoneNum1        = raw.substring(249, 264); // PIC X(15)
            customerRecord.custPhoneNum2        = raw.substring(264, 279); // PIC X(15)
            customerRecord.custSsn              = raw.substring(279, 288); // PIC 9(09)
            customerRecord.custGovtIssuedId     = raw.substring(288, 308); // PIC X(20)
            customerRecord.custDobYyyyMmDd      = raw.substring(308, 318); // PIC X(10)
            customerRecord.custEftAccountId     = raw.substring(318, 328); // PIC X(10)
            customerRecord.custPriCardHolderInd = raw.substring(328, 329); // PIC X(01)
            customerRecord.custFicoCreditScore  = raw.substring(329, 332); // PIC 9(03)
            customerRecord.filler               = raw.substring(332, 500); // PIC X(168)
            // Note: inner paragraph DISPLAYs on success (matches COBOL source)
            System.out.println(customerRecord);
        }

        if ("00".equals(custfileStatus)) {
            applResult = 0;
        } else if ("10".equals(custfileStatus)) {
            applResult = 16; // APPL-EOF
        } else {
            applResult = 12;
        }

        if (applResult == 0) {
            // APPL-AOK: continue
        } else if (applResult == 16) {
            endOfFile = 'Y';
        } else {
            System.out.println("ERROR READING CUSTOMER FILE");
            ioStatus = custfileStatus;
            displayIoStatus();
            abendProgram();
        }
    }

    // ─── Paragraph: 9000-CUSTFILE-CLOSE ──────────────────────────────────────

    private void custfileClose() {
        applResult = 8;
        // TODO: Close actual file handle
        custfileLines.clear();
        custfileStatus = "00";
        applResult = 0;

        if (applResult != 0) {
            System.out.println("ERROR CLOSING CUSTOMER FILE");
            ioStatus = custfileStatus;
            displayIoStatus();
            abendProgram();
        }
    }

    // ─── PROCEDURE DIVISION ───────────────────────────────────────────────────

    public void run() {
        System.out.println("START OF EXECUTION OF PROGRAM CBCUS01C");

        custfileOpen();

        // PERFORM UNTIL END-OF-FILE = 'Y'
        while (endOfFile != 'Y') {
            if (endOfFile == 'N') {
                custfileGetNext();
                if (endOfFile == 'N') {
                    // DISPLAY CUSTOMER-RECORD (outer loop display)
                    System.out.println(customerRecord);
                }
            }
        }

        custfileClose();

        System.out.println("END OF EXECUTION OF PROGRAM CBCUS01C");

        // GOBACK
        System.exit(0);
    }

    public static void main(String[] args) {
        new CBCUS01C().run();
    }
}
