       *================================================================*
      * Program Name: PRCSEQ00
      * Description: Process Sequence Manager
      * Version: 1.0
      * Date: 2024
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PRCSEQ00.
       
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PROCESS-SEQ-FILE
               ASSIGN TO PRCSEQ
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS PSR-KEY
               FILE STATUS IS WS-PSR-STATUS.
               
           SELECT BATCH-CONTROL-FILE
               ASSIGN TO BCHCTL
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS BCT-KEY
               FILE STATUS IS WS-BCT-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       FD  PROCESS-SEQ-FILE.
           COPY PRCSEQ.
       
       FD  BATCH-CONTROL-FILE.
           COPY BCHCTL.
       
       WORKING-STORAGE SECTION.
           COPY BCHCON.
           COPY ERRHAND.
           
       01  WS-FILE-STATUS.
           05  WS-PSR-STATUS         PIC X(2).
           05  WS-BCT-STATUS         PIC X(2).
           
       01  WS-WORK-AREAS.
           05  WS-CURRENT-TIME       PIC X(26).
           05  WS-SEQUENCE-IX        PIC 9(4) COMP.
           05  WS-PROCESS-COUNT      PIC 9(4) COMP.
           05  WS-ACTIVE-COUNT       PIC 9(4) COMP.
           05  WS-ERROR-COUNT        PIC 9(4) COMP.
           
       01  WS-PROCESS-TABLE.
           05  WS-PROC-ENTRY OCCURS 100 TIMES
                            INDEXED BY WS-PROC-IX.
               10  WS-PROC-ID        PIC X(8).
               10  WS-PROC-SEQ       PIC 9(4) COMP.
               10  WS-PROC-STATUS    PIC X(1).
               10  WS-PROC-RC        PIC S9(4) COMP.
       
       LINKAGE SECTION.
       01  LS-SEQUENCE-REQUEST.
           05  LS-FUNCTION          PIC X(4).
               88  FUNC-INIT          VALUE 'INIT'.
               88  FUNC-NEXT          VALUE 'NEXT'.
               88  FUNC-STAT          VALUE 'STAT'.
               88  FUNC-TERM          VALUE 'TERM'.
           05  LS-PROCESS-DATE     PIC X(8).
           05  LS-SEQUENCE-TYPE    PIC X(3).
           05  LS-NEXT-PROCESS     PIC X(8).
           05  LS-RETURN-CODE      PIC S9(4) COMP.
       
       PROCEDURE DIVISION USING LS-SEQUENCE-REQUEST.
       0000-MAIN.
           EVALUATE TRUE
               WHEN FUNC-INIT
                   PERFORM 1000-INITIALIZE-SEQUENCE
               WHEN FUNC-NEXT
                   PERFORM 2000-GET-NEXT-PROCESS
               WHEN FUNC-STAT
                   PERFORM 3000-CHECK-STATUS
               WHEN FUNC-TERM
                   PERFORM 4000-TERMINATE-SEQUENCE
               WHEN OTHER
                   MOVE 'Invalid function code' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-EVALUATE
           
           MOVE LS-RETURN-CODE TO RETURN-CODE
           GOBACK
           .
           
       1000-INITIALIZE-SEQUENCE.
           PERFORM 1100-OPEN-FILES
           PERFORM 1200-BUILD-SEQUENCE
           PERFORM 1300-CREATE-CONTROL-RECORDS
           .
           
       2000-GET-NEXT-PROCESS.
           PERFORM 2100-FIND-NEXT-READY
           PERFORM 2200-CHECK-DEPENDENCIES
           IF LS-RETURN-CODE = ZERO
               PERFORM 2300-UPDATE-PROCESS-STATUS
           END-IF
           .
           
       3000-CHECK-STATUS.
           PERFORM 3100-READ-CONTROL-STATUS
           PERFORM 3200-UPDATE-SEQUENCE-TABLE
           PERFORM 3300-CHECK-COMPLETION
           .
           
       4000-TERMINATE-SEQUENCE.
           PERFORM 4100-CHECK-FINAL-STATUS
           PERFORM 4200-CLOSE-FILES
           .
           
       9000-ERROR-ROUTINE.
           MOVE 'PRCSEQ00' TO ERR-PROGRAM
           MOVE BCT-RC-ERROR TO LS-RETURN-CODE
           CALL 'ERRPROC' USING ERR-MESSAGE
           .
      *================================================================*
      * Detailed procedures to be implemented:
      * 1100-OPEN-FILES
      * 1200-BUILD-SEQUENCE
      * 1300-CREATE-CONTROL-RECORDS
      * 2100-FIND-NEXT-READY
      * 2200-CHECK-DEPENDENCIES
      * 2300-UPDATE-PROCESS-STATUS
      * 3100-READ-CONTROL-STATUS
      * 3200-UPDATE-SEQUENCE-TABLE
      * 3300-CHECK-COMPLETION
      * 4100-CHECK-FINAL-STATUS
      * 4200-CLOSE-FILES
      *================================================================*
      *----------------------------------------------------------------*
      * File and initialization procedures
      *----------------------------------------------------------------*
       1100-OPEN-FILES.
           OPEN I-O PROCESS-SEQ-FILE
           IF WS-PSR-STATUS NOT = '00'
               MOVE 'Error opening sequence file' TO ERR-TEXT
               PERFORM 9000-ERROR-ROUTINE
           END-IF
           
           OPEN I-O BATCH-CONTROL-FILE
           IF WS-BCT-STATUS NOT = '00'
               MOVE 'Error opening control file' TO ERR-TEXT
               PERFORM 9000-ERROR-ROUTINE
           END-IF
           .
           
       1200-BUILD-SEQUENCE.
           INITIALIZE WS-PROCESS-TABLE
                      WS-PROCESS-COUNT
           SET WS-PROC-IX TO 1
           
           MOVE LS-PROCESS-DATE TO PSR-KEY
           
           START PROCESS-SEQ-FILE KEY >= PSR-KEY
               INVALID KEY
                   MOVE 'No sequence found for date' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-START
           
           PERFORM UNTIL WS-PSR-STATUS = '10'
               READ PROCESS-SEQ-FILE NEXT RECORD
                   AT END
                       MOVE '10' TO WS-PSR-STATUS
                   NOT AT END
                       IF PSR-TYPE = LS-SEQUENCE-TYPE
                           PERFORM 1210-ADD-TO-SEQUENCE
                       END-IF
               END-READ
           END-PERFORM
           .
           
       1210-ADD-TO-SEQUENCE.
           ADD 1 TO WS-PROCESS-COUNT
           MOVE PSR-PROCESS-ID TO WS-PROC-ID(WS-PROC-IX)
           MOVE WS-PROCESS-COUNT TO WS-PROC-SEQ(WS-PROC-IX)
           MOVE BCT-STAT-READY TO WS-PROC-STATUS(WS-PROC-IX)
           SET WS-PROC-IX UP BY 1
           .
           
       1300-CREATE-CONTROL-RECORDS.
           PERFORM VARYING WS-SEQUENCE-IX FROM 1 BY 1
                   UNTIL WS-SEQUENCE-IX > WS-PROCESS-COUNT
               
               INITIALIZE BATCH-CONTROL-RECORD
               MOVE WS-PROC-ID(WS-SEQUENCE-IX) TO BCT-JOB-NAME
               MOVE LS-PROCESS-DATE TO BCT-PROCESS-DATE
               MOVE WS-PROC-SEQ(WS-SEQUENCE-IX) TO BCT-SEQUENCE-NO
               MOVE BCT-STAT-READY TO BCT-STATUS
               
               WRITE BATCH-CONTROL-RECORD
                   INVALID KEY
                       MOVE 'Error creating control record' TO ERR-TEXT
                       PERFORM 9000-ERROR-ROUTINE
               END-WRITE
           END-PERFORM
           .
           
       2100-FIND-NEXT-READY.
           PERFORM VARYING WS-SEQUENCE-IX FROM 1 BY 1
                   UNTIL WS-SEQUENCE-IX > WS-PROCESS-COUNT
               IF WS-PROC-STATUS(WS-SEQUENCE-IX) = BCT-STAT-READY
                   MOVE WS-PROC-ID(WS-SEQUENCE-IX) 
                     TO LS-NEXT-PROCESS
                   EXIT PERFORM
               END-IF
           END-PERFORM
           
           IF WS-SEQUENCE-IX > WS-PROCESS-COUNT
               MOVE SPACES TO LS-NEXT-PROCESS
           END-IF
           .
           
       2200-CHECK-DEPENDENCIES.
           MOVE LS-NEXT-PROCESS TO PSR-PROCESS-ID
           
           READ PROCESS-SEQ-FILE
               INVALID KEY
                   MOVE 'Process definition not found' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-READ
           
           PERFORM VARYING WS-SUB FROM 1 BY 1
                   UNTIL WS-SUB > PSR-DEP-COUNT
               PERFORM 2210-CHECK-DEP-STATUS
               IF LS-RETURN-CODE NOT = ZERO
                   EXIT PERFORM
               END-IF
           END-PERFORM
           .
           
       2210-CHECK-DEP-STATUS.
           MOVE PSR-DEP-ID(WS-SUB) TO BCT-JOB-NAME
           MOVE LS-PROCESS-DATE TO BCT-PROCESS-DATE
           
           READ BATCH-CONTROL-FILE
               INVALID KEY
                   MOVE 'Dependency record not found' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-READ
           
           IF NOT BCT-STATUS-DONE
               IF PSR-DEP-HARD(WS-SUB)
                   MOVE BCT-RC-WARNING TO LS-RETURN-CODE
               END-IF
           ELSE
               IF BCT-RETURN-CODE > PSR-DEP-RC(WS-SUB)
                   MOVE BCT-RC-ERROR TO LS-RETURN-CODE
               END-IF
           END-IF
           .
           
       2300-UPDATE-PROCESS-STATUS.
           MOVE LS-NEXT-PROCESS TO BCT-JOB-NAME
           MOVE LS-PROCESS-DATE TO BCT-PROCESS-DATE
           
           READ BATCH-CONTROL-FILE
               INVALID KEY
                   MOVE 'Process record not found' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-READ
           
           MOVE BCT-STAT-ACTIVE TO BCT-STATUS
           ACCEPT WS-CURRENT-TIME FROM TIME STAMP
           MOVE WS-CURRENT-TIME TO BCT-START-TIME
           
           REWRITE BATCH-CONTROL-RECORD
               INVALID KEY
                   MOVE 'Error updating control record' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-REWRITE
           .
           
       3100-READ-CONTROL-STATUS.
           MOVE LS-NEXT-PROCESS TO BCT-JOB-NAME
           MOVE LS-PROCESS-DATE TO BCT-PROCESS-DATE
           
           READ BATCH-CONTROL-FILE
               INVALID KEY
                   MOVE 'Process record not found' TO ERR-TEXT
                   PERFORM 9000-ERROR-ROUTINE
           END-READ
           .
           
       3200-UPDATE-SEQUENCE-TABLE.
           PERFORM VARYING WS-SEQUENCE-IX FROM 1 BY 1
                   UNTIL WS-SEQUENCE-IX > WS-PROCESS-COUNT
               IF WS-PROC-ID(WS-SEQUENCE-IX) = BCT-JOB-NAME
                   MOVE BCT-STATUS TO 
                        WS-PROC-STATUS(WS-SEQUENCE-IX)
                   MOVE BCT-RETURN-CODE TO 
                        WS-PROC-RC(WS-SEQUENCE-IX)
                   EXIT PERFORM
               END-IF
           END-PERFORM
           .
           
       3300-CHECK-COMPLETION.
           MOVE ZERO TO WS-ACTIVE-COUNT
                       WS-ERROR-COUNT
           
           PERFORM VARYING WS-SEQUENCE-IX FROM 1 BY 1
                   UNTIL WS-SEQUENCE-IX > WS-PROCESS-COUNT
               
               IF WS-PROC-STATUS(WS-SEQUENCE-IX) = BCT-STAT-ACTIVE
                   ADD 1 TO WS-ACTIVE-COUNT
               END-IF
               
               IF WS-PROC-STATUS(WS-SEQUENCE-IX) = BCT-STAT-ERROR
                   ADD 1 TO WS-ERROR-COUNT
               END-IF
           END-PERFORM
           .
           
       4100-CHECK-FINAL-STATUS.
           PERFORM 3300-CHECK-COMPLETION
           
           IF WS-ERROR-COUNT > ZERO
               MOVE BCT-RC-ERROR TO LS-RETURN-CODE
           ELSE
               IF WS-ACTIVE-COUNT > ZERO
                   MOVE BCT-RC-WARNING TO LS-RETURN-CODE
               ELSE
                   MOVE BCT-RC-SUCCESS TO LS-RETURN-CODE
               END-IF
           END-IF
           .
           
       4200-CLOSE-FILES.
           CLOSE PROCESS-SEQ-FILE
                 BATCH-CONTROL-FILE
           
           IF WS-PSR-STATUS NOT = '00' OR 
              WS-BCT-STATUS NOT = '00'
               MOVE 'Error closing files' TO ERR-TEXT
               PERFORM 9000-ERROR-ROUTINE
           END-IF
           .