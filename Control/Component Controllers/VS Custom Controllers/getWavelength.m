function [wl, err] = getWavelength(device)

y = version('-release');
y = str2num(y(1:4));
if isMATLABReleaseOlderThan("R2020b")

    % Pre-COVID (lol) MATLAB
    command = convertCharsToStrings('W  ?');

    % Send serial command to query (W)avelength to input
    fprintf(device, command);
    fgets(device);
    
    % Check for answer
    wl_chars = readline(device);
    
    if wl_chars == command
        err = 1;
        warning('LCTF did not return expected response.')
    else
        wl = str2num(wl_chars{1}(4:end));
    end

else
    % Post-COVID MATLAB
    command = convertCharsToStrings('W  ?');
    
    % Send serial command to query (W)avelength to input
    writeline(device, command);
    readline(device);
    
    % Check for answer
    wl_chars = readline(device);
    
    if wl_chars == command
        err = 1;
        warning('LCTF did not return expected response.')
    else
        wl = str2num(wl_chars{1}(4:end));
    end
end