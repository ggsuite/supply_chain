
rm -rf coverage
dart run coverage:test_with_coverage
# dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=./lib/src --report-on=./test
genhtml coverage/lcov.info -o coverage/html

if  !([ -z ${1+x} ])
then
  open coverage/html/src/index.html
fi
