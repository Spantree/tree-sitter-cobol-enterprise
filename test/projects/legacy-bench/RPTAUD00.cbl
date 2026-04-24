       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTAUD00.
       AUTHOR. CLAUDE.
       DATE-WRITTEN. 2024-04-09.
      *****************************************************************
      * Audit Report Generator                                         *
      *                                                               *
      * Generates comprehensive audit report including:                *
      * - Security audit trails                                       *
      * - Process audit reporting                                     *
      * - Error summary reporting                                     *
      * - Control verification                                        *
      *****************************************************************
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT AUDIT-FILE ASSIGN TO AUDITLOG
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS AUD-KEY
               FILE STATUS IS WS-AUDIT-STATUS.

           SELECT ERROR-FILE ASSIGN TO ERRLOG
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS ERR-KEY
               FILE STATUS IS WS-ERROR-STATUS.

           SELECT REPORT-FILE ASSIGN TO RPTFILE
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-REPORT-STATUS.

       DATA DIVISION.
       FILE SECTION.
           COPY AUDITLOG.
           COPY ERRHAND.
           
       FD  REPORT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  REPORT-RECORD             PIC X(132).

       WORKING-STORAGE SECTION.
           COPY RTNCODE.

       01  WS-FILE-STATUS.
           05  WS-AUDIT-STATUS       PIC XX.
           05  WS-ERROR-STATUS       PIC XX.
           05  WS-REPORT-STATUS      PIC XX.

       01  WS-REPORT-HEADERS.
           05  WS-HEADER1.
               10  FILLER            PIC X(132) VALUE ALL '*'.
           05  WS-HEADER2.
               10  FILLER            PIC X(40) VALUE SPACES.
               10  FILLER            PIC X(52) 
                   VALUE 'SYSTEM AUDIT REPORT'.
               10  FILLER            PIC X(40) VALUE SPACES.
           05  WS-HEADER3.
               10  FILLER            PIC X(15) VALUE 'REPORT DATE:'.
               10  WS-REPORT-DATE    PIC X(10).
               10  FILLER            PIC X(107) VALUE SPACES.

       01  WS-AUDIT-DETAIL.
           05  WS-AUD-TIMESTAMP     PIC X(26).
           05  FILLER               PIC X(2) VALUE SPACES.
           05  WS-AUD-PROGRAM       PIC X(8).
           05  FILLER               PIC X(2) VALUE SPACES.
           05  WS-AUD-TYPE          PIC X(10).
           05  FILLER               PIC X(2) VALUE SPACES.
           05  WS-AUD-MESSAGE       PIC X(80).

       01  WS-ERROR-DETAIL.
           05  WS-ERR-TIMESTAMP     PIC X(26).
           05  FILLER               PIC X(2) VALUE SPACES.
           05  WS-ERR-PROGRAM       PIC X(8).
           05  FILLER               PIC X(2) VALUE SPACES.
           05  WS-ERR-CODE          PIC X(4).
           05  FILLER               PIC X(2) VALUE SPACES.
           05  WS-ERR-MESSAGE       PIC X(80).

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-REPORT
           PERFORM 3000-CLEANUP
           GOBACK.

       1000-INITIALIZE.
           PERFORM 1100-OPEN-FILES
           PERFORM 1200-WRITE-HEADERS.

       1100-OPEN-FILES.
           OPEN INPUT AUDIT-FILE
           IF WS-AUDIT-STATUS NOT = '00'
               MOVE 'ERROR OPENING AUDIT FILE'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF

           OPEN INPUT ERROR-FILE
           IF WS-ERROR-STATUS NOT = '00'
               MOVE 'ERROR OPENING ERROR FILE'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF

           OPEN OUTPUT REPORT-FILE
           IF WS-REPORT-STATUS NOT = '00'
               MOVE 'ERROR OPENING REPORT FILE'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF.

       1200-WRITE-HEADERS.
           ACCEPT WS-REPORT-DATE FROM DATE
           WRITE REPORT-RECORD FROM WS-HEADER1
           WRITE REPORT-RECORD FROM WS-HEADER2
           WRITE REPORT-RECORD FROM WS-HEADER3.

       2000-PROCESS-REPORT.
           PERFORM 2100-PROCESS-AUDIT-TRAIL
           PERFORM 2200-PROCESS-ERROR-LOG
           PERFORM 2300-WRITE-SUMMARY.

       2100-PROCESS-AUDIT-TRAIL.
           PERFORM 2110-READ-AUDIT-RECORDS
           PERFORM 2120-SUMMARIZE-AUDIT.

       2200-PROCESS-ERROR-LOG.
           PERFORM 2210-READ-ERROR-RECORDS
           PERFORM 2220-SUMMARIZE-ERRORS.

       2300-WRITE-SUMMARY.
           PERFORM 2310-WRITE-AUDIT-SUMMARY
           PERFORM 2320-WRITE-ERROR-SUMMARY
           PERFORM 2330-WRITE-CONTROL-SUMMARY.

       3000-CLEANUP.
           CLOSE AUDIT-FILE
                ERROR-FILE
                REPORT-FILE.

       9999-ERROR-HANDLER.
           DISPLAY WS-ERROR-MESSAGE
           MOVE 12 TO RETURN-CODE
           GOBACK.