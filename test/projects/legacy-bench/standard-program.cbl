      *================================================================*
      * Program Name: PROGNAME
      * Description: [Description of program purpose]
      * Author: [Author name]
      * Date Written: [Date]
      * Maintenance Log:
      * Date       Author        Description
      * ---------- ------------- -------------------------------------
      * [Date]     [Author]      Initial Creation
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROGNAME.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           *> File control entries will go here
       
       DATA DIVISION.
       FILE SECTION.
           *> File descriptions will go here
       
       WORKING-STORAGE SECTION.
      *----------------------------------------------------------------*
      * Constants and switches
      *----------------------------------------------------------------*
       01  WS-CONSTANTS.
           05  WS-PROGRAM-NAME          PIC X(08) VALUE 'PROGNAME '.
           05  WS-SUCCESS               PIC S9(4) VALUE +0.
           05  WS-ERROR                 PIC S9(4) VALUE +8.
           
       01  WS-SWITCHES.
           05  WS-END-OF-FILE-SW        PIC X     VALUE 'N'.
               88  END-OF-FILE                    VALUE 'Y'.
               88  NOT-END-OF-FILE                VALUE 'N'.
           
      *----------------------------------------------------------------*
      * Work areas
      *----------------------------------------------------------------*
       01  WS-WORK-AREAS.
           05  WS-RETURN-CODE           PIC S9(4) VALUE +0.
           
       LINKAGE SECTION.
           *> Parameters passed to program will go here
       
       PROCEDURE DIVISION.
      *----------------------------------------------------------------*
      * Main process
      *----------------------------------------------------------------*
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           
           PERFORM 2000-PROCESS
              UNTIL END-OF-FILE
           
           PERFORM 3000-TERMINATE
           
           GOBACK.
           
      *----------------------------------------------------------------*
      * Initialization
      *----------------------------------------------------------------*
       1000-INITIALIZE.
           INITIALIZE WS-WORK-AREAS
           .
           
      *----------------------------------------------------------------*
      * Main processing
      *----------------------------------------------------------------*
       2000-PROCESS.
           *> Main processing logic will go here
           SET END-OF-FILE TO TRUE
           .
           
      *----------------------------------------------------------------*
      * Termination
      *----------------------------------------------------------------*
       3000-TERMINATE.
           MOVE WS-RETURN-CODE TO RETURN-CODE
           .
      *----------------------------------------------------------------*
      * Error handling routines
      *----------------------------------------------------------------*
       9000-HANDLE-ERROR.
           *> Error handling logic will go here
           MOVE WS-ERROR TO WS-RETURN-CODE
           . 