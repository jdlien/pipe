# Perl Unit Tests for Pipe.pl

This directory contains Perl unit tests using the Test::More framework.

## Structure

- `00-load.t` - Basic test to ensure testing infrastructure works
- `01-core.t` - Tests for Pipe::Core module (template)
- `02-context.t` - Tests for Pipe::Context module (template)
- `99-integration.t` - Integration tests for pipe.pl
- Additional test files will be added as modules are created

## Running Tests

### Run all tests:
```bash
prove -v t/
```

### Run specific test:
```bash
perl t/00-load.t
```

### Run with coverage (requires Devel::Cover):
```bash
cover -test
```

## Test Naming Convention

- `00-` - Infrastructure tests
- `01-09` - Core module tests
- `10-89` - Feature module tests  
- `90-98` - Integration tests
- `99` - Full system tests

## Writing Tests

Each test file should:
1. Use `Test::More`
2. Have a clear test count or use `done_testing()`
3. Use descriptive test names
4. Test edge cases
5. Be independent of other tests

## Example Test Structure

```perl
#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;
use lib 'lib';

BEGIN { use_ok('Module::Name') }

# Test functionality
is($result, $expected, 'descriptive test name');
ok($condition, 'another test');

# Edge cases
is(function(undef), '', 'handles undef');
```

## Current Status

Most tests are templates waiting for modules to be created during the modularization process. The integration test (`99-integration.t`) tests the current pipe.pl functionality.