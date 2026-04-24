      *================================================================*
      * Copybook Name: PORTVAL
      * Description: Portfolio Validation Rules and Error Messages
      * Author: [Author name]
      * Date Written: 2024-03-20
      *================================================================*
      
      *----------------------------------------------------------------*
      * Validation Return Codes
      *----------------------------------------------------------------*
       01  VAL-RETURN-CODES.
           05  VAL-SUCCESS         PIC S9(4) VALUE +0.
           05  VAL-INVALID-ID      PIC S9(4) VALUE +1.
           05  VAL-INVALID-ACCT    PIC S9(4) VALUE +2.
           05  VAL-INVALID-TYPE    PIC S9(4) VALUE +3.
           05  VAL-INVALID-AMT     PIC S9(4) VALUE +4.
           
      *----------------------------------------------------------------*
      * Validation Error Messages
      *----------------------------------------------------------------*
       01  VAL-ERROR-MESSAGES.
           05  VAL-ERR-ID         PIC X(50) VALUE
               'Invalid Portfolio ID format'.
           05  VAL-ERR-ACCT       PIC X(50) VALUE
               'Invalid Account Number format'.
           05  VAL-ERR-TYPE       PIC X(50) VALUE
               'Invalid Investment Type'.
           05  VAL-ERR-AMT        PIC X(50) VALUE
               'Amount outside valid range'.
           
      *----------------------------------------------------------------*
      * Validation Constants
      *----------------------------------------------------------------*
       01  VAL-CONSTANTS.
           05  VAL-MIN-AMOUNT     PIC S9(13)V99 VALUE -9999999999999.99.
           05  VAL-MAX-AMOUNT     PIC S9(13)V99 VALUE +9999999999999.99.
           05  VAL-ID-PREFIX      PIC X(4)      VALUE 'PORT'.
           
      *----------------------------------------------------------------*
      * Validation Working Storage
      *----------------------------------------------------------------*
       01  VAL-WORK-AREAS.
           05  VAL-NUMERIC-CHECK  PIC X(10).
           05  VAL-TEMP-NUM       PIC S9(13)V99.
           05  VAL-ERROR-CODE     PIC S9(4).
           05  VAL-ERROR-MSG      PIC X(50). 