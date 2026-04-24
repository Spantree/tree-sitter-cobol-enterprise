      *================================================================*
      * Process Sequence Definitions
      * Version: 1.0
      * Date: 2024
      *================================================================*
       01  PROCESS-SEQUENCE-RECORD.
           05  PSR-KEY.
               10  PSR-PROCESS-ID    PIC X(8).
               10  PSR-VERSION       PIC 9(2).
           05  PSR-DATA.
               10  PSR-DESCRIPTION   PIC X(30).
               10  PSR-TYPE         PIC X(3).
                   88  PSR-TYPE-INIT    VALUE 'INI'.
                   88  PSR-TYPE-PROC    VALUE 'PRC'.
                   88  PSR-TYPE-RPT     VALUE 'RPT'.
                   88  PSR-TYPE-TERM    VALUE 'TRM'.
               10  PSR-TIMING.
                   15  PSR-FREQ        PIC X(1).
                       88  PSR-DAILY      VALUE 'D'.
                       88  PSR-WEEKLY     VALUE 'W'.
                       88  PSR-MONTHLY    VALUE 'M'.
                   15  PSR-START-TIME  PIC 9(4).
                   15  PSR-MAX-TIME    PIC 9(4).
               10  PSR-DEPENDENCIES.
                   15  PSR-DEP-COUNT   PIC 9(2) COMP.
                   15  PSR-DEP-ENTRY OCCURS 10 TIMES.
                       20  PSR-DEP-ID    PIC X(8).
                       20  PSR-DEP-TYPE  PIC X(1).
                           88  PSR-DEP-HARD  VALUE 'H'.
                           88  PSR-DEP-SOFT  VALUE 'S'.
                       20  PSR-DEP-RC    PIC S9(4) COMP.
               10  PSR-CONTROL.
                   15  PSR-PROGRAM     PIC X(8).
                   15  PSR-PARM        PIC X(50).
                   15  PSR-MAX-RC      PIC S9(4) COMP.
                   15  PSR-RESTART     PIC X(1).
                       88  PSR-RESTARTABLE  VALUE 'Y'.
                       88  PSR-NO-RESTART   VALUE 'N'.
           05  PSR-SCHEDULE.
               10  PSR-ACTIVE-DAYS    PIC X(7).
                   88  PSR-WEEKDAY      VALUE 'YYYYYNN'.
                   88  PSR-WEEKEND      VALUE 'NNNNNYY'.
                   88  PSR-ALL-DAYS     VALUE 'YYYYYYY'.
               10  PSR-MONTH-END      PIC X(1).
                   88  PSR-LAST-DAY     VALUE 'Y'.
               10  PSR-HOLIDAY-RUN    PIC X(1).
                   88  PSR-SKIP-HOL     VALUE 'N'.
                   88  PSR-RUN-HOL      VALUE 'Y'.
           05  PSR-RECOVERY.
               10  PSR-RECOVERY-PGM   PIC X(8).
               10  PSR-RECOVERY-PARM  PIC X(50).
               10  PSR-ERROR-LIMIT    PIC 9(4) COMP.
           05  PSR-AUDIT.
               10  PSR-CREATE-DATE    PIC X(10).
               10  PSR-CREATE-USER    PIC X(8).
               10  PSR-UPDATE-DATE    PIC X(10).
               10  PSR-UPDATE-USER    PIC X(8).
           05  PSR-FILLER            PIC X(50).

      *================================================================*
      * Standard Process Sequences
      *================================================================*
       01  STANDARD-SEQUENCES.
           05  SEQ-START-OF-DAY.
               10  FILLER            PIC X(8) VALUE 'INITDAY '.
               10  FILLER            PIC X(8) VALUE 'CKPCLR  '.
               10  FILLER            PIC X(8) VALUE 'DATEVAL '.
           05  SEQ-MAIN-PROCESS.
               10  FILLER            PIC X(8) VALUE 'TRNVAL00'.
               10  FILLER            PIC X(8) VALUE 'POSUPD00'.
               10  FILLER            PIC X(8) VALUE 'HISTLD00'.
           05  SEQ-END-OF-DAY.
               10  FILLER            PIC X(8) VALUE 'RPTGEN00'.
               10  FILLER            PIC X(8) VALUE 'BCKLOD00'.
               10  FILLER            PIC X(8) VALUE 'ENDDAY  '. 