function test_phase1_smoke
%TEST_PHASE1_SMOKE Real-data smoke test for Phase 1 on a single subject.
%   Runs phase1_preprocess with SmokeSubjectCount=1 and asserts that:
%     - params.json and qa_channels.csv are produced
%     - exactly one checkpoint .set is written
%     - four PSD PNGs land in the figures directory
%     - the checkpoint loads, has srate 100 Hz, and non-empty data
%
%   No mocks. If the local BIDS dataset is missing, the test fails with
%   a clear message and must be run on a machine with the data available.

    bidsRoot = "/Volumes/S1/Datasets/HBN/L100/R3_L100_bdf";
    if ~isfolder(bidsRoot)
        error("test_phase1_smoke:no_data", ...
            "BIDS dataset not present at %s; cannot run a real-data test.", bidsRoot);
    end

    testOut = string(tempname);
    cleaner = onCleanup(@() rmdir_if_exists(testOut));

    paramsPath = phase1_preprocess( ...
        BidsRoot=bidsRoot, ...
        OutDir=testOut, ...
        SmokeSubjectCount=1);

    assert(isfile(paramsPath), "params.json missing at %s", paramsPath);
    assert(isfile(fullfile(testOut, "qa_channels.csv")), "qa_channels.csv missing");

    setFiles = dir(fullfile(testOut, "sub-*", "eeg", "*_desc-clean_eeg.set"));
    assert(numel(setFiles) == 1, ...
        "expected 1 .set file, got %d", numel(setFiles));

    pngFiles = dir(fullfile(testOut, "sub-*", "figures", "*_psd.png"));
    assert(numel(pngFiles) == 4, ...
        "expected 4 PSD PNGs (raw/hpf/cleanline/chanreject), got %d", numel(pngFiles));

    EEG = pop_loadset('filename', setFiles(1).name, 'filepath', setFiles(1).folder);
    assert(EEG.srate == 100, "srate mismatch: %d", EEG.srate);
    assert(EEG.nbchan > 0 && EEG.nbchan <= 129, "unexpected nbchan: %d", EEG.nbchan);
    assert(EEG.pnts > 0, "empty data");

    fprintf("test_phase1_smoke: OK\n");
end

function rmdir_if_exists(p)
    if isfolder(p)
        rmdir(p, 's');
    end
end
