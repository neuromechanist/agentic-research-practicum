function csvPath = write_qa_channels_csv(outDir, row)
%WRITE_QA_CHANNELS_CSV Append a QA row to the per-phase CSV log.
%   csvPath = hbn.write_qa_channels_csv(outDir, row) appends one row to
%   <outDir>/qa_channels.csv. If the file does not exist, the header is
%   written first. `row` is a struct with fields:
%     participant_id, status, n_channels_before, n_channels_after,
%     rejected_channels, srate, cleanline_status, duration_s, error_message.
%
%   `status` should be "ok" when preprocessing succeeded, or
%   "failed_<stage>" (e.g. "failed_hpf") when a subject aborted at a given
%   stage; "missing_from_import" marks subjects that appeared in the
%   eligible list but were not returned by pop_importbids. `error_message`
%   is the MATLAB error message for failures, empty string otherwise.
%
%   Numeric fields that do not apply to a failed row (e.g. n_channels_after
%   before rejection ran) may be passed as NaN; they write as empty cells.
    arguments
        outDir (1,1) string
        row struct
    end
    if ~isfolder(outDir); mkdir(outDir); end
    csvPath = fullfile(outDir, "qa_channels.csv");

    header = ["participant_id","status","n_channels_before","n_channels_after", ...
        "rejected_channels","srate","cleanline_status","duration_s","error_message"];
    needsHeader = ~isfile(csvPath);

    fid = fopen(csvPath, "a");
    if fid < 0
        error("hbn:write_qa_channels_csv:open_failed", "could not open %s", csvPath);
    end
    cleanup = onCleanup(@() fclose(fid));

    if needsHeader
        fprintf(fid, "%s\n", strjoin(header, ","));
    end

    rejected = field_or_default(row, "rejected_channels", "");
    if ~isempty(rejected) && ~(isstring(rejected) && isscalar(rejected) && rejected == "")
        rejected = strjoin(string(rejected), ";");
    else
        rejected = "";
    end

    cells = [ ...
        csv_escape(string(field_or_default(row, "participant_id", ""))), ...
        csv_escape(string(field_or_default(row, "status", "unknown"))), ...
        numeric_cell(field_or_default(row, "n_channels_before", NaN)), ...
        numeric_cell(field_or_default(row, "n_channels_after", NaN)), ...
        csv_escape(rejected), ...
        numeric_cell(field_or_default(row, "srate", NaN)), ...
        csv_escape(string(field_or_default(row, "cleanline_status", ""))), ...
        numeric_cell(field_or_default(row, "duration_s", NaN)), ...
        csv_escape(string(field_or_default(row, "error_message", "")))];
    fprintf(fid, "%s\n", strjoin(cells, ","));
end

function v = field_or_default(s, name, default)
    if isfield(s, name)
        v = s.(name);
    else
        v = default;
    end
end

function c = numeric_cell(x)
    if isnan(x)
        c = "";
    elseif x == floor(x)
        c = sprintf("%d", x);
    else
        c = sprintf("%.3f", x);
    end
end

function out = csv_escape(s)
    s = string(s);
    needs = contains(s, ",") || contains(s, '"') || contains(s, newline);
    if needs
        out = """" + replace(s, """", """""") + """";
    else
        out = s;
    end
end
