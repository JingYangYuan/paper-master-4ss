arg News and Updates
======

# *arg* 0.2.1

* `arg_or()` now runs much faster when some conditions fail and others pass.

* Fixed bug in nested `arg_or()`/`arg_and()` introduced in previous version. Such errors render much more cleanly.

* Nested errors are formatted more cleanly when used with `when_not_null()` and `when_supplied()`.

* The multi-line errors produced by nested `arg_or()`/`arg_and()` now wrap at the console width, exactly as *cli* wraps a single-line error message, with continuation lines indented under the text they continue.

# *arg* 0.2.0

* Added `arg_color()` (and variants) to check whether an argument corresponds to a valid color specification.

* Added `arg_name()` and `arg_names()` to check whether an argument is a vector of valid names of elements of an object.

* Added `arg_ordered()` to check whether an argument is an ordered factor.

* `arg_index()` and `arg_indices()` now check names for arbitrary objects, not just matrices and data frames.

* `arg_counts()` and `arg_whole_numeric()` (and their scalar equivalents) now check whether a value is a whole number using `rlang::is_integerish()` instead of the criterion used by `all.equal()`.

* Fixed a bug where the message provided to `.msg` (if any) was not evaluated in the correct environment.

* Fixed several typos in the documentation and in some error messages.

* Fixed bugs in processing some complicated nested messages produced by `arg_and()` and `arg_or()`.

* Added a new logo.

* Added a testing suite.

# *arg* 0.1.1

* `err()`, `wrn()`, and `msg()` now pass arguments specified in `...` to `rlang::abort()`, `rlang::warn()`, and `rlang::inform()`, respectively.

* When an error is caused by a failure to process a given fixed argument (e.g., `bounds` in `arg_gt()` or `len` in `arg_length()`), that error is now thrown correctly in `arg_or()`, `arg_and()`, `when_supplied()`, and `when_not_null()`. Previously, it was bundled with the errors thrown to the ultimate user of the function `and_or()`, etc., was used in, which it made it confusing to diagnose.

* Fixed bugs with `arg_or()`, `arg_and()`, `when_supplied()`, and `when_not_null()`.

* Fixed a bug where an extra period might be added after an error message.

* When the empty string (`""`) is supplied to `err()`, etc., it is no longer appended with a period.

* Improved error messages for `arg_element()` and `arg_not_element()`.

* The `.msg` argument of `arg_*()` functions is now checked to ensure it is a string when not `NULL`.

# *arg* 0.1.0

* Initial CRAN submission.
