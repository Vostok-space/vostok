Oberon-07
===========

Implementation details of Oberon-07 for Vostok missing from the language report:

| Type     |  Limits                     |
|----------|-----------------------------|
| INTEGER  | -2147483647 .. 2147483647   |
| REAL     | -1.8×10+308 .. 1,8×10+308   |
| SET      | \{} .. \{0 .. 31}           |
| CHAR     | 0X .. 0FFX                  |

| Expression | Value
|------------|------
| ORD(FALSE) | 0
| ORD(TRUE)  | 1

## Dynamic memory management

Available 3 implementations that guarantee data integrity and do not require
additional assumptions in the language:

 * Without freeing memory
 * Conservative garbage collector
 * Reference counting without automatic breaking of cycles

Considered as errors:

 * Source code, that can not be generated by syntax rules(syntax mistakes)
 * Arithmetic overflow and division by 0 for integers and fractions
 * Negative integer divisor
 * Assigning the BYTE variable a value outside of 0 .. 255
 * CHR(int), where int outside of 0 .. 255
 * Any usage out-of-bounds numbers(not in 0..31) with SET
 * ORD(set), if the condition (31 IN set) is met
 * Accessing an array at an out-of-bounds index
 * Assigning value ​​of open array or string to array of insufficient size
 * Reading an uninitialized variable
 * Dereference, variable selecting, type guard and type checking for pointers,
   which value is NIL
 * The presence of labels with overlapping values in the CASE-statement
 * No label containing the value from the input expression of the CASE-statement
 * Constant value of loop expression and eternal loops
 * FOR-loop with a step that does not match its limits
 * Accessing in the SYSTEM.GET,PUT,COPY by incorrect addresses

The desired reaction to errors is diagnostics.
List of possible diagnostics kinds in decreasing of preference order:

 * Report during pre-check (compilation).
 * Runtime notification with continuation of execution if an error occurred in
   auxiliary or useless code
 * Notification and emergency stop in runtime
 * Absence diagnostics, what allowed due to the difficulty in diagnosis or the
   need for efficiency
