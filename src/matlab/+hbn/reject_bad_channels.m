function [EEG, rejected] = reject_bad_channels(EEG, opts)
%REJECT_BAD_CHANNELS Channel-level rejection via pop_clean_rawdata.
%   [EEG, rejected] = hbn.reject_bad_channels(EEG, opts) runs
%   pop_clean_rawdata in channel-rejection-only mode: no ASR, no windowed
%   rejection, no additional high-pass. `rejected` is a string array of
%   channel labels that were removed, derived by diffing chanlocs pre/post.
%
%   The Cz reference electrode in the HBN BIDS dataset is flat by
%   construction and is typically flagged by this step; that is expected
%   behavior, not a pipeline failure. See `.context/research.md` for the
%   full rationale.
%
%   Errors if pop_clean_rawdata returns zero channels (hbn:reject_bad_channels:all_rejected).
    arguments
        EEG struct
        opts struct
    end
    before = string({EEG.chanlocs.labels});
    EEG = pop_clean_rawdata(EEG, ...
        'FlatlineCriterion', 'off', ...
        'ChannelCriterion', opts.ChannelCriterion, ...
        'LineNoiseCriterion', opts.LineNoiseCriterion, ...
        'Highpass', 'off', ...
        'BurstCriterion', 'off', ...
        'WindowCriterion', 'off', ...
        'BurstRejection', 'off', ...
        'Distance', 'Euclidian', ...
        'fusechanrej', 1);
    after = string({EEG.chanlocs.labels});
    rejected = setdiff(before, after, 'stable');

    if EEG.nbchan == 0
        error("hbn:reject_bad_channels:all_rejected", ...
            "pop_clean_rawdata removed every channel (subject=%s)", string(EEG.subject));
    end
    if EEG.nbchan < numel(before) * 0.5
        warning("hbn:reject_bad_channels:over_half_rejected", ...
            "Rejected %d of %d channels for subject %s", ...
            numel(before) - EEG.nbchan, numel(before), string(EEG.subject));
    end
end
