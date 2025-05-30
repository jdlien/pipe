# cpanfile for pipe.pl project
# Production dependencies: NONE (by design)

# Development and testing dependencies
on 'develop' => sub {
    requires 'Test::More', '1.302183';  # Core testing framework
    requires 'Devel::Cover', '1.40';    # Code coverage analysis
    requires 'Devel::Cover::Report::Json_detailed'; # JSON coverage reports for AI
    requires 'JSON::MaybeXS';       # Required for JSON coverage reports
    requires 'Test::Pod', '1.52';       # POD syntax testing
    requires 'Test::Pod::Coverage', '1.10'; # POD coverage testing
    requires 'Perl::Critic', '1.140';   # Static code analysis/linting
    requires 'Perl::Tidy', '20220613';  # Code formatting
    requires 'Test::Perl::Critic', '1.04'; # Integrate Perl::Critic with tests
};

# Optional testing enhancements
on 'test' => sub {
    requires 'Test::More', '1.302183';
    requires 'Test::Exception', '0.43';  # Better exception testing
    requires 'Test::Warn', '0.36';       # Warning testing
    requires 'IO::String', '1.08';       # String I/O for testing
};