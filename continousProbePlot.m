function continousProbePlot(probe, initialData)

if ~exist("initialData","var")
    sampleNumber = [];
    doOutput = [];
else
    sampleNumber = cell2mat(cellfun(@str2num, initialData(:,1), 'UniformOutput',false));
    doOutput(sampleNumber, :) = cell2mat(cellfun(@str2num, initialData(:,9), 'UniformOutput', false));
end

while probe.NumBytesAvailable ~= 0
    data = readProbe(probe);
    sampleNumber = cell2mat(cellfun(@str2num, data(:,1), 'UniformOutput',false));
    doOutput(sampleNumber, :) = cell2mat(cellfun(@str2num, data(:,9), 'UniformOutput', false));
    hold on
    scatter(1:10:10*length(doOutput), doOutput)
    axis([10*(find(doOutput~=0, 1)-1), 10*length(doOutput), 0, max(doOutput)])
    delay = 0;
    while probe.NumBytesAvailable == 0 && delay < 15
        pause(1)
        delay = delay + 1;
    end
end