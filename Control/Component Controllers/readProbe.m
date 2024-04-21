%%readProbe
function data = readProbe(probe)

byts = probe.NumBytesAvailable;
if byts ~=0
    out = read(probe, byts, 'string');
    out = cellstr(splitlines(out));
    out = cellfun(@(x) strsplit(x, ';'), out, 'UniformOutput', false);
    maxLen = max(cellfun(@numel, out));
    data = cell(numel(out), maxLen);
    for ii = 1:numel(out)
        data(ii,:) = out{ii,:};
    end
else
    data = {};

end