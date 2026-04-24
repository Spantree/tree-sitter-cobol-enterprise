       *****************************************************************
      * CHECKPOINT/RESTART CONTROL STRUCTURE
      * VERSION: 1.0
      * DATE: 2024
      *****************************************************************
       01  CHECKPOINT-CONTROL.
           05  CK-HEADER.
               10  CK-PROGRAM-ID       PIC X(8).
               10  CK-RUN-DATE         PIC X(8).
               10  CK-RUN-TIME         PIC X(6).
               10  CK-STATUS           PIC X(1).
                   88  CK-INITIAL      VALUE 'I'.
                   88  CK-ACTIVE       VALUE 'A'.
                   88  CK-COMPLETE     VALUE 'C'.
                   88  CK-FAILED       VALUE 'F'.
                   88  CK-RESTARTED    VALUE 'R'.
           
           05  CK-COUNTERS.
               10  CK-RECORDS-READ     PIC 9(9) COMP.
               10  CK-RECORDS-PROC     PIC 9(9) COMP.
               10  CK-RECORDS-ERROR    PIC 9(9) COMP.
               10  CK-RESTART-COUNT    PIC 9(2) COMP.
           
           05  CK-POSITION.
               10  CK-LAST-KEY         PIC X(50).
               10  CK-LAST-TIME        PIC X(26).
               10  CK-PHASE            PIC X(2).
                   88  CK-PHASE-INIT   VALUE '00'.
                   88  CK-PHASE-READ   VALUE '10'.
                   88  CK-PHASE-PROC   VALUE '20'.
                   88  CK-PHASE-UPDT   VALUE '30'.
                   88  CK-PHASE-TERM   VALUE '40'.
           
           05  CK-RESOURCES.
               10  CK-FILE-STATUS OCCURS 5 TIMES.
                   15  CK-FILE-NAME    PIC X(8).
                   15  CK-FILE-POS     PIC X(50).
                   15  CK-FILE-STATUS  PIC X(2).
           
           05  CK-CONTROL-INFO.
               10  CK-COMMIT-FREQ      PIC 9(5) COMP VALUE 1000.
               10  CK-MAX-ERRORS       PIC 9(3) COMP VALUE 100.
               10  CK-MAX-RESTARTS     PIC 9(2) COMP VALUE 3.
               10  CK-RESTART-MODE     PIC X(1).
                   88  CK-MODE-NORMAL  VALUE 'N'.
                   88  CK-MODE-RESTART VALUE 'R'.
                   88  CK-MODE-RECOVER VALUE 'C'.

      *****************************************************************
      * CHECKPOINT VSAM FILE RECORD
      *****************************************************************
       01  CHECKPOINT-RECORD.
           05  CKR-KEY.
               10  CKR-PROGRAM-ID      PIC X(8).
               10  CKR-RUN-DATE        PIC X(8).
           05  CKR-DATA                PIC X(400).
           
      *****************************************************************
      * STANDARD CHECKPOINT PROCESSING ROUTINES
      *****************************************************************
      * PROC-CHECKPOINT-INIT
      *     CALL 'CKPINIT' USING CHECKPOINT-CONTROL
      *                          RETURN-STATUS
      *
      * PROC-CHECKPOINT-TAKE
      *     CALL 'CKPTAKE' USING CHECKPOINT-CONTROL
      *                          RETURN-STATUS
      *
      * PROC-CHECKPOINT-COMMIT
      *     CALL 'CKPCMIT' USING CHECKPOINT-CONTROL
      *                          RETURN-STATUS
      *
      * PROC-CHECKPOINT-RESTART
      *     CALL 'CKPRSTR' USING CHECKPOINT-CONTROL
      *                          RETURN-STATUS
      *****************************************************************