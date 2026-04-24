      *================================================================*
      * Program Name: ERRPROC
      * Description: Standard Error Processing Subroutine
      * Author: [Author name]
      * Date Written: 2024-03-20
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ERRPROC.
       
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ERROR-LOG
               ASSIGN TO ERRLOG
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-LOG-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       FD  ERROR-LOG
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  ERROR-LOG-RECORD.
           05  LOG-DATA            PIC X(400).
       
       WORKING-STORAGE SECTION.
           COPY ERRHAND.
           
       01  WS-WORK-AREAS.
           05  WS-LOG-STATUS      PIC X(2).
           05  WS-FORMATTED-TIME  PIC X(26).
           
       LINKAGE SECTION.
       01  LS-ERROR-REQUEST.
           05  LS-PROGRAM-ID      PIC X(8).
           05  LS-CATEGORY        PIC X(2).
           05  LS-ERROR-CODE      PIC X(4).
           05  LS-SEVERITY        PIC S9(4) COMP.
           05  LS-ERROR-TEXT      PIC X(80).
           05  LS-ERROR-DETAILS   PIC X(256).
           05  LS-RETURN-CODE     PIC S9(4) COMP.
       
       PROCEDURE DIVISION USING LS-ERROR-REQUEST.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-ERROR
           PERFORM 3000-TERMINATE
           GOBACK
           .
           
       1000-INITIALIZE.
           INITIALIZE WS-WORK-AREAS
           ACCEPT WS-FORMATTED-TIME FROM TIME STAMP
           
           OPEN EXTEND ERROR-LOG
           IF WS-LOG-STATUS NOT = '00'
               DISPLAY 'Error opening log file: ' WS-LOG-STATUS
           END-IF
           .
           
       2000-PROCESS-ERROR.
      *----------------------------------------------------------------*
      * Build and write error message
      *----------------------------------------------------------------*
           MOVE WS-FORMATTED-TIME TO ERR-TIMESTAMP
           MOVE LS-PROGRAM-ID TO ERR-PROGRAM
           MOVE LS-CATEGORY TO ERR-CATEGORY
           MOVE LS-ERROR-CODE TO ERR-CODE
           MOVE LS-SEVERITY TO ERR-SEVERITY
           MOVE LS-ERROR-TEXT TO ERR-TEXT
           MOVE LS-ERROR-DETAILS TO ERR-DETAILS
           
           PERFORM 2100-WRITE-LOG
           PERFORM 2200-DISPLAY-ERROR
           
           MOVE LS-SEVERITY TO LS-RETURN-CODE
           .
           
       2100-WRITE-LOG.
           MOVE ERR-MESSAGE TO LOG-DATA
           
           WRITE ERROR-LOG-RECORD
           
           IF WS-LOG-STATUS NOT = '00'
               DISPLAY 'Error writing to log: ' WS-LOG-STATUS
           END-IF
           .
           
       2200-DISPLAY-ERROR.
           DISPLAY '===================================================='
           DISPLAY 'ERROR DETECTED: ' ERR-TIMESTAMP
           DISPLAY 'PROGRAM:       ' ERR-PROGRAM
           DISPLAY 'CATEGORY:      ' ERR-CATEGORY
           DISPLAY 'CODE:          ' ERR-CODE
           DISPLAY 'SEVERITY:      ' ERR-SEVERITY
           DISPLAY 'MESSAGE:       ' ERR-TEXT
           DISPLAY 'DETAILS:       ' ERR-DETAILS
           DISPLAY '===================================================='
           .
           
       3000-TERMINATE.
           CLOSE ERROR-LOG
           . 