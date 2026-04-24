       *================================================================*
      * Program Name: FILEHNDL
      * Description: Template for VSAM and Sequential file handling
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FILEHNDL.
       
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *----------------------------------------------------------------*
      * VSAM KSDS File
      *----------------------------------------------------------------*
           SELECT VSAM-FILE
               ASSIGN TO VSAMFILE
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS VSAM-RECORD-KEY
               FILE STATUS IS WS-VSAM-STATUS.
               
      *----------------------------------------------------------------*
      * Sequential Input File
      *----------------------------------------------------------------*
           SELECT INPUT-FILE
               ASSIGN TO INFILE
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-INPUT-STATUS.
               
      *----------------------------------------------------------------*
      * Sequential Output File
      *----------------------------------------------------------------*
           SELECT OUTPUT-FILE
               ASSIGN TO OUTFILE
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-OUTPUT-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
      *----------------------------------------------------------------*
      * VSAM file record definition
      *----------------------------------------------------------------*
       FD  VSAM-FILE
           RECORD CONTAINS 100 CHARACTERS.
       01  VSAM-RECORD.
           05  VSAM-RECORD-KEY          PIC X(10).
           05  VSAM-RECORD-DATA         PIC X(90).
           
      *----------------------------------------------------------------*
      * Sequential file record definitions
      *----------------------------------------------------------------*
       FD  INPUT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  INPUT-RECORD                 PIC X(80).
           
       FD  OUTPUT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  OUTPUT-RECORD                PIC X(80).
       
       WORKING-STORAGE SECTION.
      *----------------------------------------------------------------*
      * File status fields
      *----------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05  WS-VSAM-STATUS           PIC X(2).
               88  VSAM-SUCCESS         VALUE '00'.
               88  VSAM-EOF             VALUE '10'.
               88  VSAM-DUP-KEY         VALUE '22'.
               88  VSAM-NOT-FOUND       VALUE '23'.
           05  WS-INPUT-STATUS          PIC X(2).
               88  INPUT-SUCCESS        VALUE '00'.
               88  INPUT-EOF            VALUE '10'.
           05  WS-OUTPUT-STATUS         PIC X(2).
               88  OUTPUT-SUCCESS       VALUE '00'.
               
      *----------------------------------------------------------------*
      * VSAM operation work areas
      *----------------------------------------------------------------*
       01  WS-VSAM-WORK-AREAS.
           05  WS-VSAM-KEY             PIC X(10).
           
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS
           PERFORM 3000-TERMINATE
           GOBACK.
           
       1000-INITIALIZE.
      *----------------------------------------------------------------*
      * Open files and initialize work areas
      *----------------------------------------------------------------*
           INITIALIZE WS-FILE-STATUS
           
           OPEN INPUT  VSAM-FILE
           OPEN INPUT  INPUT-FILE
           OPEN OUTPUT OUTPUT-FILE
           
           PERFORM 9000-CHECK-FILE-STATUS
           .
           
       2000-PROCESS.
      *----------------------------------------------------------------*
      * Example VSAM READ operation
      *----------------------------------------------------------------*
       2100-READ-VSAM.
           MOVE LOW-VALUES TO VSAM-RECORD-KEY
           
           READ VSAM-FILE KEY IS VSAM-RECORD-KEY
               INVALID KEY
                   PERFORM 9100-VSAM-ERROR
           END-READ
           
           IF VSAM-SUCCESS
               PERFORM 2110-PROCESS-VSAM-RECORD
           END-IF
           .
           
      *----------------------------------------------------------------*
      * Example VSAM WRITE operation
      *----------------------------------------------------------------*
       2200-WRITE-VSAM.
           WRITE VSAM-RECORD
               INVALID KEY
                   PERFORM 9100-VSAM-ERROR
           END-WRITE
           .
           
      *----------------------------------------------------------------*
      * Example Sequential READ operation
      *----------------------------------------------------------------*
       2300-READ-SEQUENTIAL.
           READ INPUT-FILE
               AT END
                   SET INPUT-EOF TO TRUE
               NOT AT END
                   PERFORM 2310-PROCESS-INPUT-RECORD
           END-READ
           .
           
       3000-TERMINATE.
      *----------------------------------------------------------------*
      * Close files and perform cleanup
      *----------------------------------------------------------------*
           CLOSE VSAM-FILE
                 INPUT-FILE
                 OUTPUT-FILE
           
           PERFORM 9000-CHECK-FILE-STATUS
           .
           
      *----------------------------------------------------------------*
      * Error handling routines
      *----------------------------------------------------------------*
       9000-CHECK-FILE-STATUS.
           IF NOT VSAM-SUCCESS AND NOT VSAM-EOF
               PERFORM 9100-VSAM-ERROR
           END-IF
           
           IF NOT INPUT-SUCCESS AND NOT INPUT-EOF
               PERFORM 9200-SEQ-ERROR
           END-IF
           
           IF NOT OUTPUT-SUCCESS
               PERFORM 9200-SEQ-ERROR
           END-IF
           .
           
       9100-VSAM-ERROR.
           DISPLAY 'VSAM ERROR - FILE STATUS: ' WS-VSAM-STATUS
           MOVE 8 TO RETURN-CODE
           PERFORM 3000-TERMINATE
           GOBACK
           .
           
       9200-SEQ-ERROR.
           DISPLAY 'SEQUENTIAL FILE ERROR - STATUS: ' 
                   WS-INPUT-STATUS ' ' WS-OUTPUT-STATUS
           MOVE 8 TO RETURN-CODE
           PERFORM 3000-TERMINATE
           GOBACK
           .