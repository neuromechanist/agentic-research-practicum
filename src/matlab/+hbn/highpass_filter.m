function EEG = highpass_filter(EEG, hz)
%HIGHPASS_FILTER 1 Hz high-pass via pop_eegfiltnew (default FIR).
%   EEG = hbn.highpass_filter(EEG, hz) applies a high-pass at `hz` with no
%   low-pass. 1 Hz is the ICA/AMICA convention; lower cutoffs inject drift
%   that destabilizes decomposition.
    arguments
        EEG struct
        hz (1,1) double {mustBePositive}
    end
    EEG = pop_eegfiltnew(EEG, hz, 0);
end
