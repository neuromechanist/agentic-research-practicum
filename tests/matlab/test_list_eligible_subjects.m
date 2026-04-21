function test_list_eligible_subjects
%TEST_LIST_ELIGIBLE_SUBJECTS Unit test for the participants.tsv filter.
%   Writes a real minimal BIDS-root fixture (no mocks, just a real TSV on
%   disk) with one row for each availability value and asserts only the
%   "available" rows are returned. Also covers the error branches
%   (missing participants.tsv and missing task column).

    root = string(tempname);
    cleaner = onCleanup(@() rmdir_if_exists(root)); %#ok<NASGU>
    mkdir(root);

    % Missing participants.tsv error
    threw = false;
    try
        hbn.list_eligible_subjects(root, "ThePresent");
    catch ME
        threw = string(ME.identifier) == "hbn:list_eligible_subjects:missing_tsv";
    end
    assert(threw, "expected hbn:list_eligible_subjects:missing_tsv");

    % Happy path: four rows, one of each status
    tsv = fullfile(root, "participants.tsv");
    fid = fopen(tsv, "w");
    c = onCleanup(@() fclose(fid));
    fprintf(fid, "participant_id\tage\tThePresent\n");
    fprintf(fid, "sub-001\t10\tavailable\n");
    fprintf(fid, "sub-002\t11\tcaution\n");
    fprintf(fid, "sub-003\t12\tunavailable\n");
    fprintf(fid, "sub-004\t13\tavailable\n");
    clear c;

    subjects = hbn.list_eligible_subjects(root, "ThePresent");
    assert(numel(subjects) == 2, "expected 2 available subjects, got %d", numel(subjects));
    assert(all(ismember(["sub-001","sub-004"], subjects)), ...
        "expected sub-001 and sub-004 to be selected");
    assert(~any(ismember(["sub-002","sub-003"], subjects)), ...
        "caution/unavailable rows should be excluded");

    % Missing task column error
    threw = false;
    try
        hbn.list_eligible_subjects(root, "NotATask");
    catch ME
        threw = string(ME.identifier) == "hbn:list_eligible_subjects:missing_task_col";
    end
    assert(threw, "expected hbn:list_eligible_subjects:missing_task_col");

    fprintf("test_list_eligible_subjects: OK\n");
end

function rmdir_if_exists(p)
    if isfolder(p)
        rmdir(p, 's');
    end
end
