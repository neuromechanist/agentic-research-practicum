function paramsPath = phase1_preprocess(opts)
%PHASE1_PREPROCESS Channel-level preprocessing for HBN R3 "ThePresent".
%   paramsPath = phase1_preprocess() runs the full eligible cohort.
%   paramsPath = phase1_preprocess(Name=Value,...) overrides defaults.
%
%   Pipeline per subject:
%     stage 00 raw PSD  ->  1 Hz high-pass  ->  stage 01 PSD
%       ->  conditional cleanline (skipped unless srate>=500 or
%           RunCleanline=true)                 ->  stage 02 PSD
%       ->  pop_clean_rawdata channels-only    ->  stage 03 PSD
%       ->  save checkpoint + QA row
%
%   Per-subject failures are caught, logged, and recorded in the QA CSV
%   with status="failed_<stage>" so a single bad file never aborts the
%   cohort. Missing-from-import subjects (in `eligible` but not returned
%   by pop_importbids) are flagged as status="missing_from_import".
%
%   Outputs (rooted at opts.OutDir, default "derivatives/preproc"):
%     params.json                                         # phase config
%     qa_channels.csv                                     # one row / subject
%     sub-<ID>/eeg/sub-<ID>_task-<Task>_desc-clean_eeg.set
%     sub-<ID>/figures/sub-<ID>_stage-<NN>-<name>_psd.png (x4)
%
%   Name-value arguments:
%     BidsRoot           (1,1) string   default "/Volumes/S1/Datasets/HBN/L100/R3_L100_bdf"
%     Task               (1,1) string   default "ThePresent"
%     OutDir             (1,1) string   default "derivatives/preproc"
%     Subjects           (1,:) string   default string.empty  (empty = all eligible)
%     HpfHz              (1,1) double   default 1
%     RunCleanline       (1,1) logical  default false  (auto-true if srate>=500)
%     LineNoiseHz        (1,:) double   default [60 120 180]
%     ChannelCriterion   (1,1) double   default 0.8
%     LineNoiseCriterion (1,1) double   default 5
%     SmokeSubjectCount  (1,1) double   default 0      (>0 limits to first N)

    arguments
        opts.BidsRoot (1,1) string = "/Volumes/S1/Datasets/HBN/L100/R3_L100_bdf"
        opts.Task (1,1) string = "ThePresent"
        opts.OutDir (1,1) string = "derivatives/preproc"
        opts.Subjects (1,:) string = string.empty
        opts.HpfHz (1,1) double {mustBePositive} = 1
        opts.RunCleanline (1,1) logical = false
        opts.LineNoiseHz (1,:) double = [60 120 180]
        opts.ChannelCriterion (1,1) double = 0.8
        opts.LineNoiseCriterion (1,1) double = 5
        opts.SmokeSubjectCount (1,1) double {mustBeNonnegative, mustBeInteger} = 0
    end

    if ~isfolder(opts.OutDir); mkdir(opts.OutDir); end

    eligible = hbn.list_eligible_subjects(opts.BidsRoot, opts.Task);
    if ~isempty(opts.Subjects)
        eligible = intersect(eligible, opts.Subjects, 'stable');
    end
    if opts.SmokeSubjectCount > 0 && numel(eligible) > opts.SmokeSubjectCount
        eligible = eligible(1:opts.SmokeSubjectCount);
    end
    if isempty(eligible)
        error("hbn:phase1:no_subjects", ...
            "No eligible subjects after filtering (BidsRoot=%s Task=%s)", ...
            opts.BidsRoot, opts.Task);
    end
    fprintf("[phase1] %d eligible subject(s)\n", numel(eligible));

    importDir = fullfile(opts.OutDir, "_bids_import_scratch");
    [STUDY, ALLEEG] = hbn.import_bids_study(opts.BidsRoot, opts.Task, importDir); %#ok<ASGLU>
    % Always filter to the requested eligible set so the STUDY / ALLEEG
    % ordering matches the filter exactly, regardless of pop_importbids
    % return order.
    [STUDY, ALLEEG] = hbn.filter_study_subjects(STUDY, ALLEEG, eligible); %#ok<ASGLU>

    imported = string({ALLEEG.subject});
    missing = setdiff(eligible, imported, 'stable');
    for m = 1:numel(missing)
        warning("hbn:phase1:missing_from_import", ...
            "subject %s in eligible list but not returned by pop_importbids", missing(m));
        hbn.write_qa_channels_csv(opts.OutDir, struct( ...
            'participant_id', missing(m), ...
            'status', "missing_from_import", ...
            'n_channels_before', NaN, ...
            'n_channels_after', NaN, ...
            'rejected_channels', "", ...
            'srate', NaN, ...
            'cleanline_status', "", ...
            'duration_s', NaN, ...
            'error_message', "not returned by pop_importbids"));
    end

    nOk = 0;
    nFailed = 0;
    for i = 1:numel(ALLEEG)
        EEG = ALLEEG(i);
        subjId = string(EEG.subject);
        if subjId == ""; subjId = string(EEG.setname); end
        fprintf("[phase1] (%d/%d) %s ...\n", i, numel(ALLEEG), subjId);
        tStart = tic;
        try
            [EEG, qaRow] = process_one_subject(EEG, opts);
            qaRow.participant_id = subjId;
            qaRow.status = "ok";
            qaRow.duration_s = toc(tStart);
            qaRow.error_message = "";
            hbn.save_subject_checkpoint(EEG, opts.OutDir, opts.Task);
            hbn.write_qa_channels_csv(opts.OutDir, qaRow);
            nOk = nOk + 1;
        catch ME
            nFailed = nFailed + 1;
            stage = extract_stage_from_error(ME);
            warning("hbn:phase1:subject_failed", ...
                "subject %s failed at stage %s: %s", subjId, stage, ME.message);
            hbn.write_qa_channels_csv(opts.OutDir, struct( ...
                'participant_id', subjId, ...
                'status', sprintf("failed_%s", stage), ...
                'n_channels_before', get_nbchan_safe(ALLEEG(i)), ...
                'n_channels_after', get_nbchan_safe(EEG), ...
                'rejected_channels', "", ...
                'srate', ALLEEG(i).srate, ...
                'cleanline_status', "", ...
                'duration_s', toc(tStart), ...
                'error_message', ME.message));
        end
    end

    paramsPath = hbn.write_params_json(opts.OutDir, opts, struct( ...
        'n_subjects_eligible', numel(eligible), ...
        'n_subjects_ok', nOk, ...
        'n_subjects_failed', nFailed, ...
        'n_subjects_missing_from_import', numel(missing), ...
        'bids_import_scratch', importDir));
    fprintf("[phase1] done. ok=%d failed=%d missing=%d. params at %s\n", ...
        nOk, nFailed, numel(missing), paramsPath);
end

function [EEG, qaRow] = process_one_subject(EEG, opts)
    nBefore = EEG.nbchan;
    hbn.save_psd_figure(EEG, opts.OutDir, "stage-00-raw");

    EEG = hbn.highpass_filter(EEG, opts.HpfHz);
    hbn.save_psd_figure(EEG, opts.OutDir, "stage-01-hpf");

    [EEG, cleanlineStatus] = hbn.conditional_cleanline(EEG, opts);
    if cleanlineStatus == "skipped_nyquist"
        hbn.save_psd_figure(EEG, opts.OutDir, "stage-02-cleanline", ...
            "SKIPPED (Nyquist)");
    else
        hbn.save_psd_figure(EEG, opts.OutDir, "stage-02-cleanline");
    end

    [EEG, rejected] = hbn.reject_bad_channels(EEG, opts);
    hbn.save_psd_figure(EEG, opts.OutDir, "stage-03-chanreject");

    qaRow = struct( ...
        'n_channels_before', nBefore, ...
        'n_channels_after', EEG.nbchan, ...
        'rejected_channels', rejected, ...
        'srate', EEG.srate, ...
        'cleanline_status', cleanlineStatus);
end

function stage = extract_stage_from_error(ME)
    id = string(ME.identifier);
    if startsWith(id, "hbn:save_psd_figure")
        stage = "psd";
    elseif startsWith(id, "hbn:reject_bad_channels")
        stage = "chanreject";
    else
        % Fall back to walking the stack for the first +hbn/phase1 frame
        stage = "unknown";
        for k = 1:numel(ME.stack)
            f = string(ME.stack(k).name);
            if contains(f, "highpass_filter"); stage = "hpf"; return;
            elseif contains(f, "conditional_cleanline"); stage = "cleanline"; return;
            elseif contains(f, "reject_bad_channels"); stage = "chanreject"; return;
            elseif contains(f, "save_psd_figure"); stage = "psd"; return;
            elseif contains(f, "save_subject_checkpoint"); stage = "save"; return;
            end
        end
    end
end

function n = get_nbchan_safe(EEG)
    if isstruct(EEG) && isfield(EEG, 'nbchan') && isnumeric(EEG.nbchan) && ~isempty(EEG.nbchan)
        n = EEG.nbchan;
    else
        n = NaN;
    end
end
