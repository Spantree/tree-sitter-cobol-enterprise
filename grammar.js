// tree-sitter-cobol-enterprise grammar
// IBM Enterprise COBOL for z/OS — fixed-form, EXEC CICS/SQL first-class
//
// Case-insensitive keyword helper
function ci(keyword) {
  return new RegExp(
    keyword
      .split('')
      .map(c => {
        if (/[a-zA-Z]/.test(c)) return `[${c.toLowerCase()}${c.toUpperCase()}]`;
        if (/[0-9]/.test(c)) return c;
        if (c === '-') return '-';
        return '\\' + c;
      })
      .join('')
  );
}

module.exports = grammar({
  name: 'cobol',

  word: $ => $.WORD,

  externals: $ => [$.comment, $.pic_string, $.comment_entry, $._skip_area, $._string_literal_ext],

  // ALL whitespace handled by the external scanner to maintain column
  // control across line boundaries. No regex extras — the scanner
  // handles spaces, tabs, newlines, and separators (;,).
  extras: $ => [$.comment, $._skip_area],

  conflicts: $ => [
    [$.qualified_identifier, $.identifier],
    [$._expression, $._condition],
    [$._comparison_condition, $._class_condition],
    [$._statement, $.paragraph],
    [$.data_description],
    [$.perform_statement, $.perform_inline],
    [$.io_handler],
    [$.read_statement],
    [$.rewrite_statement],
    [$.search_statement],
    [$.return_statement],
    [$._parenthesized_expression, $.subscript],
    [$._parenthesized_expression, $._simple_condition],
    [$.identifier],
    [$.copybook_definition, $._statement],
  ],

  rules: {
    // ========================================================================
    // TOP LEVEL
    // ========================================================================
    source_file: $ =>
      choice($.program_definition, $.copybook_definition),

    program_definition: $ =>
      seq(
        $.identification_division,
        optional($.environment_division),
        optional($.data_division),
        optional($.procedure_division),
        optional(seq(ci('END'), ci('PROGRAM'), $._name_word, optional('.'))),
      ),

    // Copybooks: just data descriptions, no divisions required
    copybook_definition: $ =>
      repeat1(choice(
        $.data_description, $.copy_statement, seq($.exec_sql_statement, optional('.')),
        $.section, $.paragraph, $.sentence,
      )),

    // ========================================================================
    // IDENTIFICATION DIVISION
    // ========================================================================
    identification_division: $ =>
      seq(
        ci('IDENTIFICATION'),
        ci('DIVISION'),
        '.',
        $.program_id_paragraph,
        repeat(
          choice(
            $.author_paragraph,
            $.date_written_paragraph,
            $.date_compiled_paragraph,
            $.installation_paragraph,
            $.security_paragraph,
            $.remarks_paragraph,
          ),
        ),
      ),

    program_id_paragraph: $ =>
      seq(ci('PROGRAM-ID'), optional('.'), $._name_word, optional('.')),

    author_paragraph: $ =>
      seq(ci('AUTHOR'), '.', optional($.comment_entry)),

    date_written_paragraph: $ =>
      seq(ci('DATE-WRITTEN'), '.', optional($.comment_entry)),

    date_compiled_paragraph: $ =>
      seq(ci('DATE-COMPILED'), '.', optional($.comment_entry)),

    installation_paragraph: $ =>
      seq(ci('INSTALLATION'), '.', optional($.comment_entry)),

    security_paragraph: $ =>
      seq(ci('SECURITY'), '.', optional($.comment_entry)),

    remarks_paragraph: $ =>
      seq(ci('REMARKS'), '.', optional($.comment_entry)),

    // ========================================================================
    // ENVIRONMENT DIVISION
    // ========================================================================
    environment_division: $ =>
      seq(
        ci('ENVIRONMENT'),
        ci('DIVISION'),
        '.',
        optional($.configuration_section),
        optional($.input_output_section),
      ),

    configuration_section: $ =>
      seq(
        ci('CONFIGURATION'),
        ci('SECTION'),
        '.',
        repeat(choice(
          $.source_computer_paragraph,
          $.object_computer_paragraph,
          $.special_names_paragraph,
          $.repository_paragraph,
        )),
      ),

    source_computer_paragraph: $ =>
      seq(ci('SOURCE-COMPUTER'), '.', repeat($._env_word), optional('.')),

    object_computer_paragraph: $ =>
      seq(ci('OBJECT-COMPUTER'), '.', repeat($._env_word), optional('.')),

    special_names_paragraph: $ =>
      seq(ci('SPECIAL-NAMES'), '.', repeat($._env_word), optional('.')),

    repository_paragraph: $ =>
      seq(ci('REPOSITORY'), '.', repeat($._env_word), optional('.')),

    _env_word: $ =>
      choice($.WORD, $.number_literal, $.string_literal),

    input_output_section: $ =>
      seq(
        ci('INPUT-OUTPUT'),
        ci('SECTION'),
        '.',
        optional($.file_control_paragraph),
        optional($.io_control_paragraph),
      ),

    file_control_paragraph: $ =>
      seq(ci('FILE-CONTROL'), '.', repeat($.select_statement)),

    io_control_paragraph: $ =>
      seq(ci('I-O-CONTROL'), '.', repeat($._env_word), optional('.')),

    select_statement: $ =>
      seq(
        ci('SELECT'),
        optional(ci('OPTIONAL')),
        $._name_word,
        ci('ASSIGN'),
        optional(ci('TO')),
        $._name_word,
        repeat(choice(
          seq(ci('ORGANIZATION'), optional(ci('IS')),
            choice(ci('INDEXED'), ci('SEQUENTIAL'), ci('RELATIVE'), seq(ci('LINE'), ci('SEQUENTIAL')))),
          seq(ci('ACCESS'), optional(ci('MODE')), optional(ci('IS')),
            choice(ci('SEQUENTIAL'), ci('RANDOM'), ci('DYNAMIC'))),
          seq(ci('RECORD'), optional(ci('KEY')), optional(ci('IS')), $._name_word),
          seq(ci('ALTERNATE'), ci('RECORD'), optional(ci('KEY')), optional(ci('IS')),
            $._name_word, optional(seq(ci('WITH'), ci('DUPLICATES')))),
          seq(ci('FILE'), ci('STATUS'), optional(ci('IS')), $._name_word),
          seq(ci('RELATIVE'), optional(ci('KEY')), optional(ci('IS')), $._name_word),
        )),
        '.',
      ),

    // ========================================================================
    // DATA DIVISION
    // ========================================================================
    data_division: $ =>
      seq(
        ci('DATA'),
        ci('DIVISION'),
        '.',
        repeat(choice(
          $.file_section,
          $.working_storage_section,
          $.linkage_section,
          $.local_storage_section,
        )),
      ),

    file_section: $ =>
      seq(
        ci('FILE'),
        ci('SECTION'),
        '.',
        repeat(choice($.fd_entry, $.data_description, $.copy_statement, seq($.exec_sql_statement, optional('.')))),
      ),

    working_storage_section: $ =>
      seq(
        ci('WORKING-STORAGE'),
        ci('SECTION'),
        '.',
        repeat(choice($.data_description, $.copy_statement, seq($.exec_sql_statement, optional('.')))),
      ),

    linkage_section: $ =>
      seq(
        ci('LINKAGE'),
        ci('SECTION'),
        '.',
        repeat(choice($.data_description, $.copy_statement, seq($.exec_sql_statement, optional('.')))),
      ),

    local_storage_section: $ =>
      seq(
        ci('LOCAL-STORAGE'),
        ci('SECTION'),
        '.',
        repeat(choice($.data_description, $.copy_statement, seq($.exec_sql_statement, optional('.')))),
      ),

    fd_entry: $ =>
      seq(
        choice(ci('FD'), ci('SD')),
        $._name_word,
        repeat(choice(
          seq(ci('RECORDING'), optional(ci('MODE')), optional(ci('IS')),
            choice(ci('F'), ci('V'), ci('U'), ci('S'))),
          seq(ci('RECORD'), choice(
            seq(optional(ci('IS')), optional(ci('VARYING')),
              optional(seq(ci('IN'), ci('SIZE'))),
              optional(seq(ci('FROM'), $.number_literal, optional(seq(ci('TO'), $.number_literal)))),
              optional(seq(ci('DEPENDING'), optional(ci('ON')), $._name_word))),
            seq(ci('CONTAINS'), $.number_literal,
              optional(seq(ci('TO'), $.number_literal)),
              optional(ci('CHARACTERS'))),
          )),
          seq(ci('BLOCK'), optional(ci('CONTAINS')), $.number_literal,
            optional(seq(ci('TO'), $.number_literal)),
            optional(choice(ci('RECORDS'), ci('CHARACTERS')))),
          seq(ci('LABEL'), choice(ci('RECORD'), ci('RECORDS')),
            optional(choice(ci('IS'), ci('ARE'))),
            choice(ci('STANDARD'), ci('OMITTED'))),
          seq(ci('DATA'), choice(ci('RECORD'), ci('RECORDS')),
            optional(choice(ci('IS'), ci('ARE'))),
            repeat1($._name_word)),
          seq(ci('EXTERNAL')),
          seq(ci('GLOBAL')),
        )),
        '.',
      ),

    // --- Data Description Entry ---
    data_description: $ =>
      seq(
        $.level_number,
        optional($.entry_name),
        repeat($._data_clause),
        '.',
      ),

    level_number: $ => /[0-9]{1,2}/,

    entry_name: $ => choice($._name_word, ci('FILLER')),

    _data_clause: $ =>
      choice(
        $.picture_clause,
        $.usage_clause,
        $.value_clause,
        $.redefines_clause,
        $.occurs_clause,
        $.sign_clause,
        $.justified_clause,
        $.blank_when_zero_clause,
        $.synchronized_clause,
        $.renames_clause,
        $.external_clause,
        $.global_clause,
      ),

    picture_clause: $ =>
      seq(choice(ci('PIC'), ci('PICTURE')), optional(ci('IS')), $.pic_string),

    usage_clause: $ =>
      seq(
        optional(seq(ci('USAGE'), optional(ci('IS')))),
        choice(
          ci('BINARY'),
          ci('COMP'), ci('COMP-1'), ci('COMP-2'), ci('COMP-3'), ci('COMP-4'), ci('COMP-5'),
          ci('COMPUTATIONAL'), ci('COMPUTATIONAL-1'), ci('COMPUTATIONAL-2'),
          ci('COMPUTATIONAL-3'), ci('COMPUTATIONAL-4'), ci('COMPUTATIONAL-5'),
          ci('DISPLAY'), ci('DISPLAY-1'),
          ci('INDEX'), ci('NATIONAL'),
          ci('PACKED-DECIMAL'), ci('POINTER'),
          ci('PROCEDURE-POINTER'), ci('FUNCTION-POINTER'),
        ),
      ),

    value_clause: $ =>
      seq(
        choice(ci('VALUE'), ci('VALUES')),
        optional(ci('IS')),
        optional(ci('ARE')),
        $._value_item,
        repeat(seq(optional(','), optional(choice(ci('THRU'), ci('THROUGH'))), $._value_item)),
      ),

    _value_item: $ =>
      choice(
        $._literal,
        $._figurative_constant,
        seq(ci('ALL'), $._literal),
      ),

    redefines_clause: $ => seq(ci('REDEFINES'), $._name_word),

    occurs_clause: $ =>
      seq(
        ci('OCCURS'),
        $.number_literal,
        optional(seq(ci('TO'), $.number_literal)),
        optional(ci('TIMES')),
        optional(seq(ci('DEPENDING'), optional(ci('ON')), $.identifier)),
        optional(seq(ci('INDEXED'), optional(ci('BY')), repeat1($._name_word))),
      ),

    sign_clause: $ =>
      seq(
        optional(ci('SIGN')),
        optional(ci('IS')),
        choice(ci('LEADING'), ci('TRAILING')),
        optional(seq(ci('SEPARATE'), optional(ci('CHARACTER')))),
      ),

    justified_clause: $ =>
      seq(choice(ci('JUSTIFIED'), ci('JUST')), optional(ci('RIGHT'))),

    blank_when_zero_clause: $ =>
      seq(ci('BLANK'), optional(ci('WHEN')),
        choice(ci('ZERO'), ci('ZEROS'), ci('ZEROES'))),

    synchronized_clause: $ =>
      seq(choice(ci('SYNCHRONIZED'), ci('SYNC')),
        optional(choice(ci('LEFT'), ci('RIGHT')))),

    renames_clause: $ =>
      seq(ci('RENAMES'), $._name_word,
        optional(seq(choice(ci('THRU'), ci('THROUGH')), $._name_word))),

    external_clause: $ =>
      seq(ci('EXTERNAL'), optional(seq(ci('AS'), $.string_literal))),

    global_clause: $ => ci('GLOBAL'),

    // ========================================================================
    // COPY STATEMENT
    // ========================================================================
    copy_statement: $ =>
      seq(
        ci('COPY'),
        choice($._name_word, $.string_literal),
        optional(seq(ci('OF'), choice($._name_word, $.string_literal))),
        optional(seq(ci('IN'), choice($._name_word, $.string_literal))),
        optional($.replacing_clause),
        '.',
      ),

    replacing_clause: $ =>
      seq(
        ci('REPLACING'),
        repeat1(seq($._replacing_operand, ci('BY'), $._replacing_operand)),
      ),

    _replacing_operand: $ =>
      choice($.pseudo_text, $._name_word, $._literal),

    pseudo_text: $ =>
      seq('==', repeat(choice($.WORD, /[^=]+/)), '=='),

    // ========================================================================
    // PROCEDURE DIVISION
    // ========================================================================
    procedure_division: $ =>
      seq(
        ci('PROCEDURE'),
        ci('DIVISION'),
        optional($.using_clause),
        optional($.returning_clause),
        '.',
        repeat(choice($.section, $.paragraph, $.sentence)),
      ),

    using_clause: $ =>
      seq(
        ci('USING'),
        repeat1(seq(
          optional(choice(
            seq(ci('BY'), ci('REFERENCE')),
            seq(ci('BY'), ci('CONTENT')),
            seq(ci('BY'), ci('VALUE')),
          )),
          $._name_word,
          optional(','),
        )),
      ),

    returning_clause: $ => seq(ci('RETURNING'), $._name_word),

    section: $ =>
      prec.left(seq($._name_word, ci('SECTION'), optional($.number_literal), '.',
        repeat(choice($.paragraph, $.sentence)))),

    paragraph: $ =>
      prec.left(seq($._name_word, '.', repeat($.sentence))),

    sentence: $ => seq(repeat1($._statement), '.'),

    // ========================================================================
    // STATEMENTS
    // ========================================================================
    _statement: $ =>
      choice(
        // Control flow
        $.if_statement,
        $.evaluate_statement,
        $.perform_statement,
        $.perform_inline,
        $.go_to_statement,
        $.goback_statement,
        $.stop_statement,
        $.exit_statement,
        $.continue_statement,
        $.next_sentence_statement,

        // Data movement
        $.move_statement,
        $.initialize_statement,
        $.set_statement,
        $.compute_statement,
        $.add_statement,
        $.subtract_statement,
        $.multiply_statement,
        $.divide_statement,

        // I/O
        $.display_statement,
        $.accept_statement,
        $.open_statement,
        $.close_statement,
        $.read_statement,
        $.write_statement,
        $.rewrite_statement,
        $.delete_statement,

        // String
        $.string_statement,
        $.unstring_statement,
        $.inspect_statement,

        // Table
        $.search_statement,
        $.sort_statement,
        $.merge_statement,
        $.release_statement,
        $.return_statement,

        // Program flow
        $.call_statement,
        $.alter_statement,

        // EXEC
        $.exec_cics_statement,
        $.exec_sql_statement,

        // COPY in procedure division
        $.copy_statement,
      ),

    // --- IF / EVALUATE: self-terminating with END-xxx ---
    if_statement: $ =>
      seq(
        ci('IF'),
        $._condition,
        optional(ci('THEN')),
        repeat($._statement),
        optional(seq(ci('ELSE'), repeat($._statement))),
        ci('END-IF'),
      ),

    evaluate_statement: $ =>
      seq(
        ci('EVALUATE'),
        $._evaluate_subject,
        repeat(seq(ci('ALSO'), $._evaluate_subject)),
        repeat1($.when_clause),
        optional(seq(ci('WHEN'), ci('OTHER'), repeat($._statement))),
        ci('END-EVALUATE'),
      ),

    _evaluate_subject: $ =>
      choice(ci('TRUE'), ci('FALSE'), $._expression),

    when_clause: $ =>
      prec.left(seq(
        ci('WHEN'),
        $._when_condition,
        repeat(seq(ci('ALSO'), $._when_condition)),
        repeat($._statement),
      )),

    _when_condition: $ =>
      choice(
        ci('ANY'),
        $._condition,
        seq($._expression, choice(ci('THRU'), ci('THROUGH')), $._expression),
      ),

    perform_statement: $ =>
      prec.left(seq(
        ci('PERFORM'),
        $._name_word,
        optional(seq(choice(ci('THRU'), ci('THROUGH')), $._name_word)),
        optional(choice(
          seq($._expression, ci('TIMES')),
          seq(optional(seq(optional(ci('WITH')), ci('TEST'),
            choice(ci('BEFORE'), ci('AFTER')))),
            ci('UNTIL'), $._condition),
          seq(ci('VARYING'), $._name_word, ci('FROM'), $._expression,
            ci('BY'), $._expression, ci('UNTIL'), $._condition),
        )),
      )),

    perform_inline: $ =>
      seq(
        ci('PERFORM'),
        choice(
          seq($._expression, ci('TIMES')),
          seq(optional(seq(optional(ci('WITH')), ci('TEST'),
            choice(ci('BEFORE'), ci('AFTER')))),
            ci('UNTIL'), $._condition),
          seq(ci('VARYING'), $._name_word, ci('FROM'), $._expression,
            ci('BY'), $._expression, ci('UNTIL'), $._condition),
        ),
        repeat($._statement),
        ci('END-PERFORM'),
      ),

    go_to_statement: $ =>
      prec.left(seq(ci('GO'), optional(ci('TO')), optional($._name_word))),

    goback_statement: $ => ci('GOBACK'),

    stop_statement: $ =>
      prec.left(seq(ci('STOP'), choice(ci('RUN'), $._literal))),

    exit_statement: $ =>
      prec.left(seq(ci('EXIT'), optional(choice(
        ci('PROGRAM'), ci('PARAGRAPH'), ci('SECTION'), ci('PERFORM'), ci('CYCLE'))))),

    continue_statement: $ => ci('CONTINUE'),

    next_sentence_statement: $ => seq(ci('NEXT'), ci('SENTENCE')),

    // --- Data Movement ---
    move_statement: $ =>
      prec.left(seq(
        ci('MOVE'),
        optional(ci('CORRESPONDING')),
        $._expression,
        ci('TO'),
        repeat1($._expression),
      )),

    initialize_statement: $ =>
      prec.left(seq(
        ci('INITIALIZE'),
        repeat1($._expression),
        optional(seq(ci('REPLACING'),
          repeat1(seq(
            choice(ci('ALPHABETIC'), ci('ALPHANUMERIC'), ci('NUMERIC'),
              ci('ALPHANUMERIC-EDITED'), ci('NUMERIC-EDITED')),
            optional(ci('DATA')),
            ci('BY'), $._expression,
          )),
        )),
      )),

    set_statement: $ =>
      prec.left(seq(
        ci('SET'),
        choice(
          seq(repeat1($._expression), ci('TO'), $._expression),
          seq($._expression, choice(ci('UP'), ci('DOWN')), ci('BY'), $._expression),
          seq(ci('ADDRESS'), ci('OF'), $._expression, ci('TO'), $._expression),
        ),
      )),

    compute_statement: $ =>
      seq(
        ci('COMPUTE'),
        repeat1(seq($._expression, optional(ci('ROUNDED')))),
        '=',
        $._expression,
        optional(ci('END-COMPUTE')),
      ),

    add_statement: $ =>
      prec.left(seq(
        ci('ADD'),
        optional(ci('CORRESPONDING')),
        repeat1($._expression),
        ci('TO'),
        repeat1(seq($._expression, optional(ci('ROUNDED')))),
        optional(seq(ci('GIVING'), repeat1(seq($._expression, optional(ci('ROUNDED')))))),
        optional(ci('END-ADD')),
      )),

    subtract_statement: $ =>
      prec.left(seq(
        ci('SUBTRACT'),
        optional(ci('CORRESPONDING')),
        repeat1($._expression),
        ci('FROM'),
        repeat1(seq($._expression, optional(ci('ROUNDED')))),
        optional(seq(ci('GIVING'), repeat1(seq($._expression, optional(ci('ROUNDED')))))),
        optional(ci('END-SUBTRACT')),
      )),

    multiply_statement: $ =>
      prec.left(seq(
        ci('MULTIPLY'),
        $._expression,
        ci('BY'),
        repeat1(seq($._expression, optional(ci('ROUNDED')))),
        optional(seq(ci('GIVING'), repeat1(seq($._expression, optional(ci('ROUNDED')))))),
        optional(ci('END-MULTIPLY')),
      )),

    divide_statement: $ =>
      prec.left(seq(
        ci('DIVIDE'),
        $._expression,
        choice(ci('INTO'), ci('BY')),
        repeat1(seq($._expression, optional(ci('ROUNDED')))),
        optional(seq(ci('GIVING'), repeat1(seq($._expression, optional(ci('ROUNDED')))))),
        optional(seq(ci('REMAINDER'), $._expression)),
        optional(ci('END-DIVIDE')),
      )),

    // --- I/O ---
    display_statement: $ =>
      prec.left(seq(
        ci('DISPLAY'),
        repeat1($._expression),
        optional(seq(ci('UPON'), $._name_word)),
        optional(seq(ci('WITH'), ci('NO'), ci('ADVANCING'))),
      )),

    accept_statement: $ =>
      prec.left(seq(
        ci('ACCEPT'),
        $._expression,
        optional(seq(ci('FROM'),
          choice(
            seq(ci('DATE'), optional(ci('YYYYMMDD'))),
            seq(ci('DAY'), optional(ci('YYYYDDD'))),
            ci('DAY-OF-WEEK'), ci('TIME'),
            ci('CONSOLE'), $._name_word))),
      )),

    open_statement: $ =>
      prec.left(seq(
        ci('OPEN'),
        repeat1(seq(
          choice(ci('INPUT'), ci('OUTPUT'), ci('I-O'), ci('EXTEND')),
          repeat1($._name_word),
        )),
      )),

    close_statement: $ =>
      prec.left(seq(ci('CLOSE'), repeat1($._name_word))),

    read_statement: $ =>
      seq(
        ci('READ'),
        $._name_word,
        optional(ci('NEXT')),
        optional(ci('RECORD')),
        optional(seq(ci('INTO'), $._expression)),
        optional(seq(ci('KEY'), optional(ci('IS')), $._name_word)),
        repeat($.io_handler),
        optional(ci('END-READ')),
      ),

    io_handler: $ =>
      choice(
        seq(optional(ci('AT')), ci('END'), repeat1($._statement)),
        seq(ci('NOT'), optional(ci('AT')), ci('END'), repeat1($._statement)),
        seq(ci('INVALID'), ci('KEY'), repeat1($._statement)),
        seq(ci('NOT'), ci('INVALID'), ci('KEY'), repeat1($._statement)),
      ),

    write_statement: $ =>
      seq(
        ci('WRITE'),
        $._expression,
        optional(seq(ci('FROM'), $._expression)),
        optional(ci('END-WRITE')),
      ),

    rewrite_statement: $ =>
      seq(
        ci('REWRITE'),
        $._expression,
        optional(seq(ci('FROM'), $._expression)),
        repeat($.io_handler),
        optional(ci('END-REWRITE')),
      ),

    delete_statement: $ =>
      seq(
        ci('DELETE'),
        $._name_word,
        optional(ci('RECORD')),
        optional(ci('END-DELETE')),
      ),

    // --- String ---
    string_statement: $ =>
      seq(
        ci('STRING'),
        repeat1(seq(repeat1(seq($._expression, optional(','))),
          ci('DELIMITED'), optional(ci('BY')),
          choice(ci('SIZE'), $._expression))),
        ci('INTO'),
        $._expression,
        optional(seq(optional(ci('WITH')), ci('POINTER'), $._expression)),
        optional(ci('END-STRING')),
      ),

    unstring_statement: $ =>
      seq(
        ci('UNSTRING'),
        $._expression,
        optional(seq(ci('DELIMITED'), optional(ci('BY')), optional(ci('ALL')),
          $._expression,
          repeat(seq(ci('OR'), optional(ci('ALL')), $._expression)))),
        ci('INTO'),
        repeat1($._expression),
        optional(seq(ci('TALLYING'), optional(ci('IN')), $._expression)),
        optional(ci('END-UNSTRING')),
      ),

    inspect_statement: $ =>
      prec.left(seq(
        ci('INSPECT'),
        $._expression,
        choice(
          seq(ci('TALLYING'), repeat1($.inspect_tallying_phrase)),
          seq(ci('REPLACING'), repeat1($.inspect_replacing_phrase)),
          seq(ci('CONVERTING'), $._expression, ci('TO'), $._expression,
            repeat($.inspect_before_after)),
        ),
      )),

    inspect_tallying_phrase: $ =>
      prec.right(seq(
        $._expression,
        ci('FOR'),
        repeat1(choice(
          seq(ci('CHARACTERS'), repeat($.inspect_before_after)),
          seq(optional(choice(ci('ALL'), ci('LEADING'))),
            $._expression, repeat($.inspect_before_after)),
        )),
      )),

    inspect_replacing_phrase: $ =>
      prec.left(choice(
        seq(ci('CHARACTERS'), ci('BY'), $._expression, repeat($.inspect_before_after)),
        seq(choice(ci('ALL'), ci('LEADING'), ci('FIRST')), $._expression,
          ci('BY'), $._expression, repeat($.inspect_before_after)),
      )),

    inspect_before_after: $ =>
      seq(choice(ci('BEFORE'), ci('AFTER')), optional(ci('INITIAL')), $._expression),

    // --- Table ---
    search_statement: $ =>
      seq(
        ci('SEARCH'),
        optional(ci('ALL')),
        $._expression,
        optional(seq(ci('VARYING'), $._expression)),
        optional(seq(optional(ci('AT')), ci('END'), repeat1($._statement))),
        repeat1(seq(ci('WHEN'), $._condition, repeat($._statement))),
        optional(ci('END-SEARCH')),
      ),

    sort_statement: $ =>
      prec.left(seq(
        ci('SORT'),
        $._name_word,
        optional(seq(optional(ci('ON')),
          choice(ci('ASCENDING'), ci('DESCENDING')),
          optional(ci('KEY')), repeat1($._name_word))),
        choice(
          seq(ci('USING'), repeat1($._name_word)),
          seq(ci('INPUT'), ci('PROCEDURE'), optional(ci('IS')), $._name_word,
            optional(seq(choice(ci('THRU'), ci('THROUGH')), $._name_word))),
        ),
        choice(
          seq(ci('GIVING'), repeat1($._name_word)),
          seq(ci('OUTPUT'), ci('PROCEDURE'), optional(ci('IS')), $._name_word,
            optional(seq(choice(ci('THRU'), ci('THROUGH')), $._name_word))),
        ),
      )),

    merge_statement: $ =>
      prec.left(seq(
        ci('MERGE'),
        $._name_word,
        optional(seq(optional(ci('ON')),
          choice(ci('ASCENDING'), ci('DESCENDING')),
          optional(ci('KEY')), repeat1($._name_word))),
        ci('USING'), repeat1($._name_word),
        choice(
          seq(ci('GIVING'), repeat1($._name_word)),
          seq(ci('OUTPUT'), ci('PROCEDURE'), optional(ci('IS')), $._name_word),
        ),
      )),

    release_statement: $ =>
      prec.left(seq(ci('RELEASE'), $._expression, optional(seq(ci('FROM'), $._expression)))),

    return_statement: $ =>
      seq(
        ci('RETURN'),
        $._name_word,
        optional(ci('RECORD')),
        optional(seq(ci('INTO'), $._expression)),
        seq(optional(ci('AT')), ci('END'), repeat1($._statement)),
        optional(ci('END-RETURN')),
      ),

    // --- Program Flow ---
    call_statement: $ =>
      seq(
        ci('CALL'),
        $._expression,
        optional(seq(ci('USING'),
          repeat1(seq(
            optional(choice(
              seq(ci('BY'), ci('REFERENCE')),
              seq(ci('BY'), ci('CONTENT')),
              seq(ci('BY'), ci('VALUE')),
            )),
            $._expression,
            optional(','),
          )),
        )),
        optional(seq(ci('RETURNING'), $._expression)),
        optional(ci('END-CALL')),
      ),

    alter_statement: $ =>
      prec.left(seq(
        ci('ALTER'),
        repeat1(seq($._name_word, ci('TO'), optional(seq(ci('PROCEED'), ci('TO'))), $._name_word)),
      )),

    // ========================================================================
    // EXEC CICS
    // ========================================================================
    exec_cics_statement: $ =>
      seq(ci('EXEC'), ci('CICS'), $._cics_command, ci('END-EXEC')),

    _cics_command: $ =>
      choice(
        $.cics_send,
        $.cics_send_text,
        $.cics_receive,
        $.cics_return,
        $.cics_read,
        $.cics_write,
        $.cics_rewrite,
        $.cics_delete,
        $.cics_startbr,
        $.cics_readnext,
        $.cics_readprev,
        $.cics_endbr,
        $.cics_resetbr,
        $.cics_xctl,
        $.cics_link,
        $.cics_assign,
        $.cics_handle_abend,
        $.cics_handle_condition,
        $.cics_handle_aid,
        $.cics_abend,
        $.cics_syncpoint,
        $.cics_asktime,
        $.cics_formattime,
        $.cics_retrieve,
        $.cics_writeq,
        $.cics_readq,
        $.cics_deleteq,
        $.cics_getmain,
        $.cics_freemain,
        $.cics_generic,
      ),

    cics_send: $ =>
      seq(ci('SEND'), repeat1($.cics_option)),

    cics_send_text: $ =>
      seq(ci('SEND'), ci('TEXT'), repeat($.cics_option)),

    cics_receive: $ =>
      seq(ci('RECEIVE'), repeat($.cics_option)),

    cics_return: $ =>
      seq(ci('RETURN'), repeat($.cics_option)),

    cics_read: $ =>
      seq(ci('READ'), repeat1($.cics_option)),

    cics_write: $ =>
      seq(ci('WRITE'), repeat1($.cics_option)),

    cics_rewrite: $ =>
      seq(ci('REWRITE'), repeat1($.cics_option)),

    cics_delete: $ =>
      seq(ci('DELETE'), repeat1($.cics_option)),

    cics_startbr: $ =>
      seq(ci('STARTBR'), repeat($.cics_option)),

    cics_readnext: $ =>
      seq(ci('READNEXT'), repeat($.cics_option)),

    cics_readprev: $ =>
      seq(ci('READPREV'), repeat($.cics_option)),

    cics_endbr: $ =>
      seq(ci('ENDBR'), repeat($.cics_option)),

    cics_resetbr: $ =>
      seq(ci('RESETBR'), repeat($.cics_option)),

    cics_xctl: $ =>
      seq(ci('XCTL'), repeat($.cics_option)),

    cics_link: $ =>
      seq(ci('LINK'), repeat($.cics_option)),

    cics_assign: $ =>
      seq(ci('ASSIGN'), repeat1($.cics_option)),

    cics_handle_abend: $ =>
      seq(ci('HANDLE'), ci('ABEND'), repeat($.cics_option)),

    cics_handle_condition: $ =>
      seq(ci('HANDLE'), ci('CONDITION'), repeat($.cics_option)),

    cics_handle_aid: $ =>
      seq(ci('HANDLE'), ci('AID'), repeat($.cics_option)),

    cics_abend: $ =>
      seq(ci('ABEND'), repeat($.cics_option)),

    cics_syncpoint: $ =>
      seq(ci('SYNCPOINT'), repeat($.cics_option)),

    cics_asktime: $ =>
      seq(ci('ASKTIME'), repeat($.cics_option)),

    cics_formattime: $ =>
      seq(ci('FORMATTIME'), repeat($.cics_option)),

    cics_retrieve: $ =>
      seq(ci('RETRIEVE'), repeat($.cics_option)),

    cics_writeq: $ =>
      seq(ci('WRITEQ'), repeat($.cics_option)),

    cics_readq: $ =>
      seq(ci('READQ'), repeat($.cics_option)),

    cics_deleteq: $ =>
      seq(ci('DELETEQ'), repeat($.cics_option)),

    cics_getmain: $ =>
      seq(ci('GETMAIN'), repeat($.cics_option)),

    cics_freemain: $ =>
      seq(ci('FREEMAIN'), repeat($.cics_option)),

    // Fallback for unrecognized CICS commands
    cics_generic: $ =>
      seq($.WORD, repeat($.cics_option)),

    cics_option: $ =>
      choice(
        seq($.WORD, '(', $._cics_value, ')'),
        $.WORD,
      ),

    _cics_value: $ =>
      repeat1(choice(
        $.WORD,
        $.numeric_name,
        $.string_literal,
        $.number_literal,
        $.length_of_expression,
        seq('(', $._cics_value, ')'),
        '+', '-',
      )),

    length_of_expression: $ =>
      seq(ci('LENGTH'), ci('OF'), $.WORD),

    // ========================================================================
    // EXEC SQL
    // ========================================================================
    exec_sql_statement: $ =>
      seq(ci('EXEC'), ci('SQL'), $._sql_body, ci('END-EXEC')),

    _sql_body: $ =>
      choice(
        $.sql_include,
        $.sql_declare_cursor,
        $.sql_select,
        $.sql_insert,
        $.sql_update,
        $.sql_delete_sql,
        $.sql_open,
        $.sql_close,
        $.sql_fetch,
        $.sql_whenever,
        $.sql_generic,
      ),

    sql_include: $ =>
      seq(ci('INCLUDE'), repeat1($._sql_token)),

    sql_declare_cursor: $ =>
      seq(ci('DECLARE'), repeat1($._sql_token)),

    sql_select: $ =>
      seq(ci('SELECT'), repeat1($._sql_token)),

    sql_insert: $ =>
      seq(ci('INSERT'), repeat1($._sql_token)),

    sql_update: $ =>
      seq(ci('UPDATE'), repeat1($._sql_token)),

    sql_delete_sql: $ =>
      seq(ci('DELETE'), repeat1($._sql_token)),

    sql_open: $ =>
      seq(ci('OPEN'), repeat1($._sql_token)),

    sql_close: $ =>
      seq(ci('CLOSE'), repeat1($._sql_token)),

    sql_fetch: $ =>
      seq(ci('FETCH'), repeat1($._sql_token)),

    sql_whenever: $ =>
      seq(ci('WHENEVER'), repeat1($._sql_token)),

    sql_generic: $ =>
      repeat1($._sql_token),

    _sql_token: $ =>
      choice(
        $.sql_host_variable,
        $.WORD,
        $.numeric_name,
        $.string_literal,
        $.number_literal,
        '(', ')', '.', ',', '=', '<', '>', '<=', '>=', '<>',
        '+', '-', '*', '/',
      ),

    sql_host_variable: $ =>
      seq(':', $.WORD),

    // ========================================================================
    // EXPRESSIONS & CONDITIONS
    // ========================================================================
    _expression: $ =>
      choice(
        $.identifier,
        $._literal,
        $._figurative_constant,
        $.function_call,
        $.address_of,
        $.length_of,
        $._parenthesized_expression,
        $._arithmetic_expression,
      ),

    _parenthesized_expression: $ =>
      seq('(', $._expression, ')'),

    _arithmetic_expression: $ =>
      choice(
        prec.left(3, seq($._expression, '**', $._expression)),
        prec.left(2, seq($._expression, choice('*', '/'), $._expression)),
        prec.left(1, seq($._expression, choice('+', '-'), $._expression)),
      ),

    address_of: $ =>
      prec(5, seq(ci('ADDRESS'), ci('OF'), $._name_word)),

    length_of: $ =>
      prec(5, seq(ci('LENGTH'), ci('OF'), $._expression)),

    identifier: $ =>
      prec.right(choice(
        seq($.qualified_identifier, $.subscript, $.subscript),
        seq($._name_word, $.subscript, $.subscript),
        seq($.qualified_identifier, $.subscript),
        seq($._name_word, $.subscript),
        $.qualified_identifier,
        $._name_word,
      )),

    qualified_identifier: $ =>
      prec.left(seq(
        $._name_word,
        repeat1(seq(choice(ci('OF'), ci('IN')), $._name_word)),
      )),

    // Unified subscript/reference-modification rule.
    // (a) or (a, b) = subscript; (a:b) or (a:) = reference modification.
    subscript: $ =>
      seq('(', $._expression,
        optional(choice(
          repeat1(seq(',', $._expression)),  // multi-subscript: (a, b, ...)
          seq(':', optional($._expression)), // reference modification: (a:b)
        )),
      ')'),

    function_call: $ =>
      prec.left(5, seq(
        ci('FUNCTION'),
        $.WORD,
        optional(choice(
          seq('(', $._expression, ':', optional($._expression), ')'),
          seq('(', optional(seq($._expression, repeat(seq(',', $._expression)))), ')'),
        )),
      )),

    _condition: $ =>
      choice(
        $._simple_condition,
        prec.left(1, seq($._condition, ci('AND'), $._condition)),
        prec.left(0, seq($._condition, ci('OR'), $._condition)),
        prec(2, seq(ci('NOT'), $._condition)),
        prec(3, seq('(', $._condition, ')')),
      ),

    _simple_condition: $ =>
      choice($._comparison_condition, $._class_condition, $._expression),

    _comparison_condition: $ =>
      prec.left(3, seq(
        $._expression,
        optional(ci('IS')),
        optional(ci('NOT')),
        choice(
          '=', '<', '>', '<=', '>=', '<>',
          seq(ci('EQUAL'), optional(ci('TO'))),
          seq(ci('GREATER'), optional(ci('THAN'))),
          seq(ci('LESS'), optional(ci('THAN'))),
          seq(ci('GREATER'), optional(ci('THAN')), ci('OR'), ci('EQUAL'), optional(ci('TO'))),
          seq(ci('LESS'), optional(ci('THAN')), ci('OR'), ci('EQUAL'), optional(ci('TO'))),
        ),
        $._expression,
        // Abbreviated combined conditions: X = A OR B, X NOT = A AND B
        repeat(seq(choice(ci('OR'), ci('AND')), $._expression)),
      )),

    _class_condition: $ =>
      prec.left(3, seq(
        $._expression,
        optional(ci('IS')),
        optional(ci('NOT')),
        choice(
          ci('NUMERIC'), ci('ALPHABETIC'), ci('ALPHABETIC-LOWER'),
          ci('ALPHABETIC-UPPER'), ci('POSITIVE'), ci('NEGATIVE'),
          ci('ZERO'), ci('ZEROS'), ci('ZEROES'),
        ),
      )),

    // ========================================================================
    // LITERALS & NAMES
    // ========================================================================
    _literal: $ =>
      choice($.string_literal, $.number_literal),

    string_literal: $ =>
      choice(
        $._string_literal_ext,
        /[Xx]'[0-9A-Fa-f]*'/,
        /[Xx]"[0-9A-Fa-f]*"/,
        /[Nn]'[^']*'/,
        /[Nn]"[^"]*"/,
      ),

    number_literal: $ =>
      /[+-]?[0-9]+(\.[0-9]+)?/,

    _figurative_constant: $ =>
      choice(
        ci('SPACES'), ci('SPACE'),
        ci('ZEROS'), ci('ZEROES'), ci('ZERO'),
        ci('LOW-VALUES'), ci('LOW-VALUE'),
        ci('HIGH-VALUES'), ci('HIGH-VALUE'),
        ci('QUOTES'), ci('QUOTE'),
        ci('NULLS'), ci('NULL'),
      ),

    _name_word: $ => choice($.WORD, $.numeric_name),

    WORD: $ => /[a-zA-Z][a-zA-Z0-9_-]*/,

    // COBOL names that start with digits (e.g., 0000-ACCTFILE-OPEN, 1000-GET-NEXT)
    // Must contain at least one letter or hyphen to distinguish from number_literal.
    numeric_name: $ => /[0-9]+[a-zA-Z_-][a-zA-Z0-9_-]*/,
  },
});
