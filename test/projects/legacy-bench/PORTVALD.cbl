      *================================================================*
      * Program Name: PORTVALD
      * Description: Portfolio Validation Subroutine
      *             Validates portfolio data elements
      * Author: [Author name]
      * Date Written: 2024-03-20
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PORTVALD.
       
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
           COPY PORTVAL.
           
       LINKAGE SECTION.
       01  LS-VALIDATION-REQUEST.
           05  LS-VALIDATE-TYPE    PIC X(1).
               88  LS-VAL-ID         VALUE 'I'.
               88  LS-VAL-ACCT       VALUE 'A'.
               88  LS-VAL-TYPE       VALUE 'T'.
               88  LS-VAL-AMT        VALUE 'M'.
           05  LS-INPUT-VALUE      PIC X(50).
           05  LS-RETURN-CODE      PIC S9(4) COMP.
           05  LS-ERROR-MSG        PIC X(50).
       
       PROCEDURE DIVISION USING LS-VALIDATION-REQUEST.
       0000-MAIN.
           INITIALIZE VAL-WORK-AREAS
           
           EVALUATE TRUE
               WHEN LS-VAL-ID
                   PERFORM 1000-VALIDATE-ID
               WHEN LS-VAL-ACCT
                   PERFORM 2000-VALIDATE-ACCOUNT
               WHEN LS-VAL-TYPE
                   PERFORM 3000-VALIDATE-TYPE
               WHEN LS-VAL-AMT
                   PERFORM 4000-VALIDATE-AMOUNT
               WHEN OTHER
                   MOVE VAL-INVALID-ID TO LS-RETURN-CODE
                   MOVE 'Invalid validation type' TO LS-ERROR-MSG
           END-EVALUATE
           
           GOBACK
           .
           
       1000-VALIDATE-ID.
      *----------------------------------------------------------------*
      * Portfolio ID must start with 'PORT' and have 4 numeric digits
      *----------------------------------------------------------------*
           IF LS-INPUT-VALUE(1:4) NOT = VAL-ID-PREFIX
               MOVE VAL-INVALID-ID TO LS-RETURN-CODE
               MOVE VAL-ERR-ID TO LS-ERROR-MSG
               EXIT PARAGRAPH
           END-IF
           
           MOVE LS-INPUT-VALUE(5:4) TO VAL-NUMERIC-CHECK
           IF VAL-NUMERIC-CHECK IS NOT NUMERIC
               MOVE VAL-INVALID-ID TO LS-RETURN-CODE
               MOVE VAL-ERR-ID TO LS-ERROR-MSG
               EXIT PARAGRAPH
           END-IF
           
           MOVE VAL-SUCCESS TO LS-RETURN-CODE
           MOVE SPACES TO LS-ERROR-MSG
           .
           
       2000-VALIDATE-ACCOUNT.
      *----------------------------------------------------------------*
      * Account number must be 10 numeric digits
      *----------------------------------------------------------------*
           IF LS-INPUT-VALUE IS NOT NUMERIC
           OR LS-INPUT-VALUE = ZEROS
               MOVE VAL-INVALID-ACCT TO LS-RETURN-CODE
               MOVE VAL-ERR-ACCT TO LS-ERROR-MSG
               EXIT PARAGRAPH
           END-IF
           
           MOVE VAL-SUCCESS TO LS-RETURN-CODE
           MOVE SPACES TO LS-ERROR-MSG
           .
           
       3000-VALIDATE-TYPE.
      *----------------------------------------------------------------*
      * Investment type must be valid value
      *----------------------------------------------------------------*
           IF LS-INPUT-VALUE NOT = 'STK'
              AND NOT = 'BND'
              AND NOT = 'MMF'
              AND NOT = 'ETF'
               MOVE VAL-INVALID-TYPE TO LS-RETURN-CODE
               MOVE VAL-ERR-TYPE TO LS-ERROR-MSG
               EXIT PARAGRAPH
           END-IF
           
           MOVE VAL-SUCCESS TO LS-RETURN-CODE
           MOVE SPACES TO LS-ERROR-MSG
           .
           
       4000-VALIDATE-AMOUNT.
      *----------------------------------------------------------------*
      * Amount must be within valid range
      *----------------------------------------------------------------*
           MOVE LS-INPUT-VALUE TO VAL-TEMP-NUM
           
           IF VAL-TEMP-NUM < VAL-MIN-AMOUNT
           OR VAL-TEMP-NUM > VAL-MAX-AMOUNT
               MOVE VAL-INVALID-AMT TO LS-RETURN-CODE
               MOVE VAL-ERR-AMT TO LS-ERROR-MSG
               EXIT PARAGRAPH
           END-IF
           
           MOVE VAL-SUCCESS TO LS-RETURN-CODE
           MOVE SPACES TO LS-ERROR-MSG
           . 