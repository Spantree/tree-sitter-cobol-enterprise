      *================================================================*
      * BATCH CONTROL FILE RECORD DEFINITION
      * Version: 1.0
      * Date: 2024
      * 
      * Purpose: Job-level control and process sequencing.
      * Works with: CKPRST.cpy for program-level checkpointing
      *================================================================*
       01  BATCH-CONTROL-RECORD.
           05  BCT-KEY.
               10  BCT-JOB-NAME      PIC X(8).
               10  BCT-PROCESS-DATE  PIC X(8).
               10  BCT-SEQUENCE-NO   PIC 9(4).
           05  BCT-DATA.
               10  BCT-STATUS        PIC X(1).
                   88  BCT-STATUS-READY    VALUE 'R'.
                   88  BCT-STATUS-ACTIVE   VALUE 'A'.
                   88  BCT-STATUS-WAITING  VALUE 'W'.
                   88  BCT-STATUS-DONE     VALUE 'D'.
                   88  BCT-STATUS-ERROR    VALUE 'E'.
               10  BCT-PROCESS-CONTROL.
                   15  BCT-STEP-NAME    PIC X(8).
                   15  BCT-PROGRAM-NAME PIC X(8).
                   15  BCT-START-TIME   PIC X(8).
                   15  BCT-END-TIME     PIC X(8).
               10  BCT-DEPENDENCIES.
                   15  BCT-PREREQ-COUNT PIC 9(2) COMP.
                   15  BCT-PREREQ-JOBS  OCCURS 10 TIMES.
                       20  BCT-PREREQ-NAME  PIC X(8).
                       20  BCT-PREREQ-SEQ   PIC 9(4).
                       20  BCT-PREREQ-RC    PIC S9(4) COMP.
               10  BCT-RETURN-INFO.
                   15  BCT-RETURN-CODE  PIC S9(4) COMP.
                   15  BCT-ERROR-DESC   PIC X(80).
           05  BCT-STATISTICS.
               10  BCT-RESTART-COUNT  PIC 9(2) COMP.
               10  BCT-ATTEMPT-TS     PIC X(26).
               10  BCT-COMPLETE-TS    PIC X(26).
           05  BCT-FILLER            PIC X(50).
      *================================================================*
      * This control file manages job-level sequencing and dependencies,
      * while CKPRST handles program-level checkpointing.
      *
      * Example usage:
      * 1. Job scheduler creates BCT record with READY status
      * 2. Job step checks prerequisites using BCT-PREREQ-JOBS
      * 3. Program uses CKPRST for checkpointing during execution
      * 4. Job completion updates BCT status and return info
      *================================================================* 