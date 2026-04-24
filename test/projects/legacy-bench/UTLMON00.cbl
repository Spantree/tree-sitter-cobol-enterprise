       IDENTIFICATION DIVISION.
       PROGRAM-ID. UTLMON00.
       AUTHOR. CLAUDE.
       DATE-WRITTEN. 2024-04-09.
      *****************************************************************
      * System Monitoring Utility                                      *
      *                                                               *
      * Monitors system health and performance:                       *
      * - Resource utilization tracking                              *
      * - Performance metrics collection                             *
      * - Threshold monitoring                                       *
      * - Alert generation                                           *
      *****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           CONSOLE IS CONS.
           
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT MONITOR-CONFIG ASSIGN TO MONCFG
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-CFG-STATUS.

           SELECT MONITOR-LOG ASSIGN TO MONLOG
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-LOG-STATUS.

           SELECT ALERT-FILE ASSIGN TO ALERTS
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-ALERT-STATUS.

           SELECT DB2-STATS ASSIGN TO DB2STATS
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS STAT-KEY
               FILE STATUS IS WS-DB2-STATUS.

       DATA DIVISION.
       FILE SECTION.
           COPY DB2STAT.
           
       FD  MONITOR-CONFIG
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  CONFIG-RECORD.
           05  CFG-RESOURCE-TYPE    PIC X(10).
           05  CFG-THRESHOLD-TYPE   PIC X(10).
           05  CFG-THRESHOLD-VALUE  PIC 9(9)V99.
           05  CFG-ALERT-LEVEL      PIC X(10).
           05  CFG-ALERT-ACTION     PIC X(50).

       FD  MONITOR-LOG
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  LOG-RECORD.
           05  LOG-TIMESTAMP        PIC X(26).
           05  LOG-RESOURCE-TYPE    PIC X(10).
           05  LOG-METRIC-NAME      PIC X(20).
           05  LOG-METRIC-VALUE     PIC 9(9)V99.
           05  LOG-STATUS           PIC X(10).

       FD  ALERT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  ALERT-RECORD.
           05  ALERT-TIMESTAMP      PIC X(26).
           05  ALERT-LEVEL          PIC X(10).
           05  ALERT-RESOURCE       PIC X(10).
           05  ALERT-MESSAGE        PIC X(80).

       WORKING-STORAGE SECTION.
           COPY RTNCODE.
           COPY ERRHAND.

       01  WS-FILE-STATUS.
           05  WS-CFG-STATUS        PIC XX.
           05  WS-LOG-STATUS        PIC XX.
           05  WS-ALERT-STATUS      PIC XX.
           05  WS-DB2-STATUS        PIC XX.

       01  WS-RESOURCE-TYPES.
           05  WS-CPU               PIC X(10) VALUE 'CPU'.
           05  WS-MEMORY            PIC X(10) VALUE 'MEMORY'.
           05  WS-DASD              PIC X(10) VALUE 'DASD'.
           05  WS-DB2               PIC X(10) VALUE 'DB2'.

       01  WS-THRESHOLD-TYPES.
           05  WS-UTILIZATION       PIC X(10) VALUE 'UTIL'.
           05  WS-RESPONSE          PIC X(10) VALUE 'RESPONSE'.
           05  WS-QUEUE             PIC X(10) VALUE 'QUEUE'.
           05  WS-ERROR             PIC X(10) VALUE 'ERROR'.

       01  WS-ALERT-LEVELS.
           05  WS-INFO              PIC X(10) VALUE 'INFO'.
           05  WS-WARNING           PIC X(10) VALUE 'WARNING'.
           05  WS-CRITICAL          PIC X(10) VALUE 'CRITICAL'.

       01  WS-PROCESSING-FLAGS.
           05  WS-END-OF-CONFIG     PIC X VALUE 'N'.
               88  END-OF-CONFIG    VALUE 'Y'.
           05  WS-THRESHOLD-MET     PIC X VALUE 'N'.
               88  THRESHOLD-MET    VALUE 'Y'.

       01  WS-CURRENT-METRICS.
           05  WS-CPU-UTIL          PIC 9(3)V99.
           05  WS-MEMORY-UTIL       PIC 9(3)V99.
           05  WS-DASD-UTIL         PIC 9(3)V99.
           05  WS-DB2-UTIL          PIC 9(3)V99.
           05  WS-DB2-RESP          PIC 9(5)V99.
           05  WS-DB2-QUEUE         PIC 9(5).
           05  WS-DB2-ERRORS        PIC 9(5).

       01  WS-TIMESTAMP.
           05  WS-DATE.
               10  WS-YEAR          PIC 9(4).
               10  WS-MONTH         PIC 9(2).
               10  WS-DAY           PIC 9(2).
           05  WS-TIME.
               10  WS-HOUR          PIC 9(2).
               10  WS-MINUTE        PIC 9(2).
               10  WS-SECOND        PIC 9(2).
               10  WS-HUNDREDTH     PIC 9(2).

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS UNTIL WS-HOUR = 23
           PERFORM 3000-CLEANUP
           GOBACK.

       1000-INITIALIZE.
           PERFORM 1100-OPEN-FILES
           PERFORM 1200-INIT-PROCESSING
           PERFORM 1300-READ-CONFIG.

       1100-OPEN-FILES.
           OPEN INPUT MONITOR-CONFIG
           IF WS-CFG-STATUS NOT = '00'
               MOVE 'ERROR OPENING CONFIG FILE'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF

           OPEN OUTPUT MONITOR-LOG
           IF WS-LOG-STATUS NOT = '00'
               MOVE 'ERROR OPENING MONITOR LOG'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF

           OPEN OUTPUT ALERT-FILE
           IF WS-ALERT-STATUS NOT = '00'
               MOVE 'ERROR OPENING ALERT FILE'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF

           OPEN INPUT DB2-STATS
           IF WS-DB2-STATUS NOT = '00'
               MOVE 'ERROR OPENING DB2 STATS'
                 TO WS-ERROR-MESSAGE
               PERFORM 9999-ERROR-HANDLER
           END-IF.

       1200-INIT-PROCESSING.
           ACCEPT WS-TIMESTAMP FROM TIME.

       1300-READ-CONFIG.
           PERFORM UNTIL END-OF-CONFIG
               READ MONITOR-CONFIG
                   AT END
                       SET END-OF-CONFIG TO TRUE
                   NOT AT END
                       PERFORM 1310-STORE-CONFIG
               END-READ
           END-PERFORM.

       2000-PROCESS.
           PERFORM 2100-COLLECT-METRICS
           PERFORM 2200-CHECK-THRESHOLDS
           PERFORM 2300-LOG-STATUS
           PERFORM 2400-GENERATE-ALERTS
           CALL 'ILBOABN0' USING WS-MINUTE
           PERFORM 1200-INIT-PROCESSING.

       2100-COLLECT-METRICS.
           PERFORM 2110-GET-CPU-METRICS
           PERFORM 2120-GET-MEMORY-METRICS
           PERFORM 2130-GET-DASD-METRICS
           PERFORM 2140-GET-DB2-METRICS.

       2200-CHECK-THRESHOLDS.
           PERFORM 2210-CHECK-UTILIZATION
           PERFORM 2220-CHECK-RESPONSE
           PERFORM 2230-CHECK-QUEUES
           PERFORM 2240-CHECK-ERRORS.

       2300-LOG-STATUS.
           MOVE WS-TIMESTAMP TO LOG-TIMESTAMP
           PERFORM 2310-LOG-RESOURCES
           PERFORM 2320-LOG-PERFORMANCE.

       2400-GENERATE-ALERTS.
           IF THRESHOLD-MET
               PERFORM 2410-FORMAT-ALERT
               PERFORM 2420-WRITE-ALERT
           END-IF.

       3000-CLEANUP.
           CLOSE MONITOR-CONFIG
                MONITOR-LOG
                ALERT-FILE
                DB2-STATS.

       9999-ERROR-HANDLER.
           DISPLAY WS-ERROR-MESSAGE UPON CONS
           MOVE 12 TO RETURN-CODE
           GOBACK. 