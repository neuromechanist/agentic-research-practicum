function pngPath = save_psd_figure(EEG, outDir, stageTag, note)
%SAVE_PSD_FIGURE Write an EEGLAB-style PSD PNG tagged by pipeline stage.
%   pngPath = hbn.save_psd_figure(EEG, outDir, stageTag) uses EEGLAB's
%   spectopo (plot enabled) to render the multi-channel PSD exactly as
%   EEGLAB would draw it interactively, then saves the resulting figure to
%   <outDir>/<subject>/figures/<subject>_<stageTag>_psd.png at 150 DPI.
%
%   pngPath = hbn.save_psd_figure(EEG, outDir, stageTag, note) annotates
%   the title with the supplied note, for example "SKIPPED (Nyquist)".
%
%   The function snapshots existing figure handles before calling spectopo
%   and takes the newly-created one via setdiff so it never grabs an
%   unrelated figure via gcf. The handle is closed via onCleanup so an
%   exception during export does not leak a handle across a batch.
    arguments
        EEG struct
        outDir (1,1) string
        stageTag (1,1) string
        note (1,1) string = ""
    end
    subjId = string(EEG.subject);
    if subjId == ""
        subjId = string(EEG.setname);
    end
    figDir = fullfile(outDir, subjId, "figures");
    if ~isfolder(figDir); mkdir(figDir); end
    pngPath = fullfile(figDir, sprintf("%s_%s_psd.png", subjId, stageTag));

    before = findall(groot, 'Type', 'figure');
    % spectopo's upper bound is strictly below Nyquist; asking for exact
    % srate/2 triggers the pwelch edge-bin assertion on some MATLAB builds.
    topFreq = max(1, EEG.srate/2 - 1);
    spectopo(EEG.data(:,:), EEG.pnts, EEG.srate, ...
        'freqrange', [0 topFreq], ...
        'plot', 'on', ...
        'verbose', 'off');
    after = findall(groot, 'Type', 'figure');
    newFigs = setdiff(after, before);
    if isempty(newFigs)
        error("hbn:save_psd_figure:no_figure", ...
            "spectopo did not produce a figure for %s at stage %s", ...
            subjId, stageTag);
    end
    h = newFigs(end);
    guard = onCleanup(@() close_if_valid(h));

    set(h, 'Visible', 'off', 'Position', [100 100 1000 600]);
    titleStr = sprintf("%s | %s | n_{chan}=%d | srate=%d Hz", ...
        subjId, stageTag, EEG.nbchan, EEG.srate);
    if note ~= ""
        titleStr = sprintf("%s  [%s]", titleStr, note);
    end
    sgtitle(h, titleStr, 'Interpreter','tex', 'FontWeight','bold');

    exportgraphics(h, pngPath, 'Resolution', 150);
end

function close_if_valid(h)
    if ~isempty(h) && isgraphics(h)
        close(h);
    end
end
