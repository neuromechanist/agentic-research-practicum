function results = run_all_tests
%RUN_ALL_TESTS Execute every Phase 1 test in sequence, collecting results.
%   results = run_all_tests returns a table of name / passed / message.
%   Intended to be invoked from the MATLAB MCP shell or CI entrypoint.

    tests = { ...
        @test_list_eligible_subjects, ...
        @test_write_qa_channels_csv, ...
        @test_phase1_no_subjects, ...
        @test_phase1_smoke};

    names = strings(numel(tests),1);
    passed = false(numel(tests),1);
    messages = strings(numel(tests),1);

    for k = 1:numel(tests)
        names(k) = string(func2str(tests{k}));
        try
            tests{k}();
            passed(k) = true;
        catch ME
            passed(k) = false;
            messages(k) = ME.message;
            fprintf(2, "[FAIL] %s: %s\n", names(k), ME.message);
        end
    end

    results = table(names, passed, messages, ...
        'VariableNames', {'name','passed','message'});
    nOk = sum(passed);
    fprintf("run_all_tests: %d/%d passed\n", nOk, numel(tests));
    if nOk < numel(tests)
        error("run_all_tests:failures", "%d test(s) failed", numel(tests) - nOk);
    end
end
