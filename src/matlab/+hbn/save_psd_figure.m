function pngPath = save_psd_figure(EEG, outDir, stageTag, note)
%SAVE_PSD_FIGURE Write an EEGLAB-style PSD PNG tagged by pipeline stage.
%   pngPath = hbn.save_psd_figure(EEG, outDir, stageTag) uses EEGLAB's
%   spectopo (plot enabled) to render the multi-channel PSD exactly as
%   EEGLAB would draw it interactively, then saves the resulting figure to
%   <outDir>/<subject>/figures/<subject>_<stageTag>_psd.png at 150 DPI.
%
%   pngPath = hbn.save_psd_figure(EEG, outDir, stageTag, note) annotates
%   the title with the supplied note, for example "SKIPPED (Nyquist)".
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

    % spectopo opens its own figure when plot is enabled. Let it do so,
    % grab the handle, hide it, annotate, and save.
    spectopo(EEG.data(:,:), EEG.pnts, EEG.srate, ...
        'freqrange', [0 EEG.srate/2], ...
        'plot', 'on', ...
        'verbose', 'off');

    h = gcf;
    set(h, 'Visible', 'off', 'Position', [100 100 1000 600]);
    titleStr = sprintf("%s | %s | n_{chan}=%d | srate=%d Hz", ...
        subjId, stageTag, EEG.nbchan, EEG.srate);
    if note ~= ""
        titleStr = sprintf("%s  [%s]", titleStr, note);
    end
    sgtitle(h, titleStr, 'Interpreter','tex', 'FontWeight','bold');

    exportgraphics(h, pngPath, 'Resolution', 150);
    close(h);
end
