       IDENTIFICATION DIVISION.
       PROGRAM-ID. CKPRST.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CHECKPOINT-FILE
           ASSIGN TO CKPTFILE
           ORGANIZATION IS INDEXED
           ACCESS MODE IS DYNAMIC
           RECORD KEY IS CKR-KEY
           FILE STATUS IS WS-FILE-STATUS.
           
       DATA DIVISION.
       FILE SECTION.
       FD  CHECKPOINT-FILE.
       COPY CKPRST.
       
       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS             PIC X(2).
       
       LINKAGE SECTION.
       COPY CKPRST.
       COPY RETHND.
       
       PROCEDURE DIVISION USING CHECKPOINT-CONTROL
                              RETURN-STATUS.
           
           EVALUATE TRUE
               WHEN ENTRY-POINT-INIT
                   PERFORM PROC-INIT
               WHEN ENTRY-POINT-TAKE
                   PERFORM PROC-TAKE-CHECKPOINT
               WHEN ENTRY-POINT-COMMIT
                   PERFORM PROC-COMMIT-CHECKPOINT
               WHEN ENTRY-POINT-RESTART
                   PERFORM PROC-RESTART
           END-EVALUATE
           
           GOBACK
           .
      
       PROC-INIT.
           * Initialize checkpoint processing
           .
       
       PROC-TAKE-CHECKPOINT.
           * Take a checkpoint
           .
       
       PROC-COMMIT-CHECKPOINT.
           * Commit checkpoint
           .
       
       PROC-RESTART.
           * Handle restart processing
           . 