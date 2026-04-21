function paramsPath = phase1_preprocess(opts)
%PHASE1_PREPROCESS Channel-level preprocessing for HBN R3 "ThePresent".
%   paramsPath = phase1_preprocess() runs the full eligible cohort.
%   paramsPath = phase1_preprocess(Name=Value,...) overrides defaults.
%
%   Pipeline per subject:
%     stage 00 raw PSD  ->  1 Hz high-pass  ->  stage 01 PSD
%       ->  conditional cleanline (no-op at 100 Hz)  ->  stage 02 PSD
%       ->  pop_clean_rawdata channels-only          ->  stage 03 PSD
%       ->  save checkpoint + QA row
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
    if numel(ALLEEG) ~= numel(eligible)
        [STUDY, ALLEEG] = hbn.filter_study_subjects(STUDY, ALLEEG, eligible); %#ok<ASGLU>
    end

    for i = 1:numel(ALLEEG)
        EEG = ALLEEG(i);
        subjId = string(EEG.subject);
        if subjId == ""; subjId = string(EEG.setname); end
        fprintf("[phase1] (%d/%d) %s ...\n", i, numel(ALLEEG), subjId);

        tStart = tic;
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

        hbn.save_subject_checkpoint(EEG, opts.OutDir, opts.Task);

        hbn.write_qa_channels_csv(opts.OutDir, struct( ...
            'participant_id', subjId, ...
            'n_channels_before', nBefore, ...
            'n_channels_after', EEG.nbchan, ...
            'rejected_channels', rejected, ...
            'srate', EEG.srate, ...
            'cleanline_status', cleanlineStatus, ...
            'duration_s', toc(tStart)));
    end

    paramsPath = hbn.write_params_json(opts.OutDir, opts, struct( ...
        'n_subjects_processed', numel(ALLEEG), ...
        'bids_import_scratch', importDir));
    fprintf("[phase1] done. params at %s\n", paramsPath);
end
