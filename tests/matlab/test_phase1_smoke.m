function test_phase1_smoke
%TEST_PHASE1_SMOKE Real-data smoke test for Phase 1 on a single subject.
%   Runs phase1_preprocess with SmokeSubjectCount=1 and asserts that:
%     - params.json and qa_channels.csv are produced and carry expected fields
%     - exactly one checkpoint .set is written
%     - four PSD PNGs land in the figures directory
%     - the checkpoint loads and round-trips with matching channel count
%       and srate against the QA CSV
%
%   No mocks. If the local BIDS dataset is missing, the test fails with
%   a clear message and must be run on a machine with the data available.

    bidsRoot = "/Volumes/S1/Datasets/HBN/L100/R3_L100_bdf";
    if ~isfolder(bidsRoot)
        error("test_phase1_smoke:no_data", ...
            "BIDS dataset not present at %s; cannot run a real-data test.", bidsRoot);
    end

    testOut = string(tempname);
    cleaner = onCleanup(@() rmdir_if_exists(testOut)); %#ok<NASGU>

    paramsPath = phase1_preprocess( ...
        BidsRoot=bidsRoot, ...
        OutDir=testOut, ...
        SmokeSubjectCount=1);

    % Artifact existence
    assert(isfile(paramsPath), "params.json missing at %s", paramsPath);
    qaPath = fullfile(testOut, "qa_channels.csv");
    assert(isfile(qaPath), "qa_channels.csv missing");

    setFiles = dir(fullfile(testOut, "sub-*", "eeg", "*_desc-clean_eeg.set"));
    assert(numel(setFiles) == 1, ...
        "expected 1 .set file, got %d", numel(setFiles));

    pngFiles = dir(fullfile(testOut, "sub-*", "figures", "*_psd.png"));
    assert(numel(pngFiles) == 4, ...
        "expected 4 PSD PNGs (raw/hpf/cleanline/chanreject), got %d", numel(pngFiles));

    % params.json schema
    params = jsondecode(fileread(paramsPath));
    assert(params.HpfHz == 1, "HpfHz=%g expected 1", params.HpfHz);
    assert(islogical(params.RunCleanline) && ~params.RunCleanline, ...
        "RunCleanline should default to false");
    assert(params.n_subjects_ok == 1, "n_subjects_ok=%d expected 1", params.n_subjects_ok);
    assert(params.n_subjects_failed == 0, "n_subjects_failed=%d expected 0", params.n_subjects_failed);
    assert(params.SmokeSubjectCount == 1, "SmokeSubjectCount mismatch");
    assert(strlength(string(params.git_sha)) > 0, "git_sha should be populated or 'unknown'");

    % qa_channels.csv content
    qa = readtable(qaPath, "TextType","string", "VariableNamingRule","preserve");
    assert(height(qa) == 1, "qa_channels.csv should have 1 row, has %d", height(qa));
    assert(qa.status(1) == "ok", "qa row status=%s expected ok", qa.status(1));
    assert(qa.cleanline_status(1) == "skipped_nyquist", ...
        "cleanline_status=%s expected skipped_nyquist at 100 Hz", qa.cleanline_status(1));
    assert(qa.srate(1) > 0, "srate in QA CSV should be positive");

    % Checkpoint round-trip and consistency
    EEG = pop_loadset('filename', setFiles(1).name, 'filepath', setFiles(1).folder);
    assert(EEG.srate == qa.srate(1), ...
        "set srate=%g disagrees with QA srate=%g", EEG.srate, qa.srate(1));
    assert(EEG.nbchan == qa.n_channels_after(1), ...
        "set nbchan=%d disagrees with QA n_channels_after=%d", ...
        EEG.nbchan, qa.n_channels_after(1));
    assert(EEG.nbchan > 0, "checkpoint has zero channels");
    assert(EEG.pnts > 0, "checkpoint has empty data");

    fprintf("test_phase1_smoke: OK\n");
end

function rmdir_if_exists(p)
    if isfolder(p)
        rmdir(p, 's');
    end
end
