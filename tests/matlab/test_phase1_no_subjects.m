function test_phase1_no_subjects
%TEST_PHASE1_NO_SUBJECTS Confirm the empty-eligible error branch fires.
%   Calls phase1_preprocess with a Subjects list that cannot intersect
%   the real cohort. Asserts hbn:phase1:no_subjects is raised before any
%   pop_importbids work is attempted.

    bidsRoot = "/Volumes/S1/Datasets/HBN/L100/R3_L100_bdf";
    if ~isfolder(bidsRoot)
        error("test_phase1_no_subjects:no_data", ...
            "BIDS dataset not present at %s; cannot run a real-data test.", bidsRoot);
    end

    testOut = string(tempname);
    cleaner = onCleanup(@() rmdir_if_exists(testOut)); %#ok<NASGU>

    threw = false;
    try
        phase1_preprocess( ...
            BidsRoot=bidsRoot, ...
            OutDir=testOut, ...
            Subjects="sub-DOES-NOT-EXIST");
    catch ME
        threw = string(ME.identifier) == "hbn:phase1:no_subjects";
    end
    assert(threw, "expected hbn:phase1:no_subjects");

    fprintf("test_phase1_no_subjects: OK\n");
end

function rmdir_if_exists(p)
    if isfolder(p)
        rmdir(p, 's');
    end
end
