       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTSTA00.
       AUTHOR. CLAUDE.
       DATE-WRITTEN. 2024-04-09.
      *****************************************************************
      * System Statistics Report Generator                             *
      *                                                               *
      * Generates system performance and statistics report including:  *
      * - Processing statistics                                       *
      * - Performance metrics                                         *
      * - Resource utilization                                        *
      * - Trend analysis                                             *
      *****************************************************************
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT DB2-STATS ASSIGN TO DB2STATS
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS STAT-KEY
               FILE STATUS IS WS-DB2-STATUS.

           SELECT BATCH-STATS ASSIGN TO BCHSTATS
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS BCH-KEY
               FILE STATUS IS WS-BCH-STATUS.

           SELECT REPORT-FILE ASSIGN TO RPTFILE
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-REPORT-STATUS.

       DATA DIVISION.
       FILE SECTION.
           COPY DB2STAT.
           COPY BCHCTL.
           
       FD  REPORT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  REPORT-RECORD             PIC X(132).

       WORKING-STORAGE SECTION.
           COPY RTNCODE.
           COPY ERRHAND.

       01  WS-FILE-STATUS.
           05  WS-DB2-STATUS         PIC XX.
           05  WS-BCH-STATUS         PIC XX.
           05  WS-REPORT-STATUS      PIC XX.

       01  WS-REPORT-HEADERS.
           05  WS-HEADER1.
               10  FILLER            PIC X(132) VALUE ALL '*'.
           05  WS-HEADER2.
               10  FILLER            PIC X(35) VALUE SPACES.
               10  FILLER            PIC X(62) 
                   VALUE 'SYSTEM STATISTICS AND PERFORMANCE REPORT'.
               10  FILLER            PIC X(35) VALUE SPACES.
           05  WS-HEADER3.
               10  FILLER            PIC X(15) VALUE 'REPORT DATE:'.
               10  WS-REPORT-DATE    PIC X(10).
               10  FILLER            PIC X(107) VALUE SPACES.

       01  WS-PERFORMANCE-METRICS.
           05  WS-DB2-METRICS.
               10  WS-DB2-CALLS         PIC 9(9).
               10  WS-DB2-ELAPSED       PIC 9(9)V99.
               10  WS-DB2-CPU           PIC 9(9)V99.
               10  WS-DB2-WAIT          PIC 9(9)V99.
           05  WS-BATCH-METRICS.
               10  WS-BATCH-JOBS        PIC 9(9).
               10  WS-BATCH-SUCCESS     PIC 9(9).
               10  WS-BATCH-FAILED      PIC 9(9).
               10  WS-BATCH-ELAPSED     PIC 9(9)V99.

       01  WS-DETAIL-LINES.
           05  WS-DB2-DETAIL.
               10  FILLER               PIC X(20) VALUE 'DB2 CALLS:'.
               10  WS-DB2-CALLS-OUT     PIC ZZZ,ZZZ,ZZ9.
               10  FILLER               PIC X(20) VALUE SPACES.
               10  FILLER               PIC X(20) VALUE 'AVG RESPONSE:'.
               10  WS-DB2-AVG-RESP      PIC ZZ,ZZ9.999.
               10  FILLER               PIC X(40) VALUE SPACES.

           05  WS-BATCH-DETAIL.
               10  FILLER               PIC X(20) VALUE 'BATCH JOBS:'.
               10  WS-BATCH-TOTAL       PIC ZZZ,ZZ9.
               10  FILLER               PIC X(10) VALUE SPACES.
               10  FILLER               PIC X(20) VALUE 'SUCCESS RATE:'.
               10  WS-SUCCESS-RATE      PIC ZZ9.99.
               10  FILLER               PIC X(05) VALUE '%'.
               10  FILLER               PIC X(40) VALUE SPACES.

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-REPORT
           PERFORM 3000-CLEANUP
           GOBACK.

       1000-INITIALIZE.
           PERFORM 1100-OPEN-FILES
           PERFORM 1200-WRITE-HEADERS
           PERFORM 1300-INIT-ACCUMULATORS.

       1100-OPEN-FILES.
           OPEN INPUT DB2-STATS
           IF WS-DB2-STATUS NOT = '00'
               MOVE 'ERROR OPENING DB2 STATS'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF

           OPEN INPUT BATCH-STATS
           IF WS-BCH-STATUS NOT = '00'
               MOVE 'ERROR OPENING BATCH STATS'
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

       1300-INIT-ACCUMULATORS.
           INITIALIZE WS-PERFORMANCE-METRICS.

       2000-PROCESS-REPORT.
           PERFORM 2100-PROCESS-DB2-STATS
           PERFORM 2200-PROCESS-BATCH-STATS
           PERFORM 2300-CALCULATE-METRICS
           PERFORM 2400-WRITE-REPORT.

       2100-PROCESS-DB2-STATS.
           READ DB2-STATS
               AT END SET END-OF-DB2-STATS TO TRUE
           END-READ
           
           PERFORM UNTIL END-OF-DB2-STATS
               PERFORM 2110-ACCUMULATE-DB2-STATS
               READ DB2-STATS
                   AT END SET END-OF-DB2-STATS TO TRUE
               END-READ
           END-PERFORM.

       2200-PROCESS-BATCH-STATS.
           READ BATCH-STATS
               AT END SET END-OF-BATCH-STATS TO TRUE
           END-READ
           
           PERFORM UNTIL END-OF-BATCH-STATS
               PERFORM 2210-ACCUMULATE-BATCH-STATS
               READ BATCH-STATS
                   AT END SET END-OF-BATCH-STATS TO TRUE
               END-READ
           END-PERFORM.

       2300-CALCULATE-METRICS.
           PERFORM 2310-CALC-DB2-METRICS
           PERFORM 2320-CALC-BATCH-METRICS.

       2400-WRITE-REPORT.
           PERFORM 2410-WRITE-DB2-SECTION
           PERFORM 2420-WRITE-BATCH-SECTION
           PERFORM 2430-WRITE-TREND-ANALYSIS.

       3000-CLEANUP.
           CLOSE DB2-STATS
                BATCH-STATS
                REPORT-FILE.

       9999-ERROR-HANDLER.
           DISPLAY WS-ERROR-MESSAGE
           MOVE 12 TO RETURN-CODE
           GOBACK.