function err = setWavelength(wl, device)

y = version('-release');
y = str2num(y(1:4));
if isMATLABReleaseOlderThan("R2020b")
    command = convertCharsToStrings(['W  ', num2str(wl), '.000']);
    
    % Send serial command to query (W)avelength to input
    fprintf(device, command);
    fgets(device);
    
    % Check for answer
    wl_chars = fgets(device);
    
    if wl_chars == command
        err = 1;
        warning('LCTF did not return expected response.')
    else
        wl = str2num(wl_chars{1}(4:end));
    end
else
    command = convertCharsToStrings(['W  ', num2str(wl), '.000']);
    
    % Send serial command to change (W)avelength to input
    writeline(device, command);
    
    % Query current (W)avelength
    writeline(device, "W ?")
    
    curr_wl = "";
    try_count = 0;
    
    while curr_wl ~= command
        % Check request results
        curr_wl = readline(device);
        
        if try_count > 3
            break
        end
    
        % Give up after 10 tries (error)
        try_count = try_count+1;
    end
    
    if curr_wl == command
        err = 0;
    else
        err = ['Failed to validate LCTF tuned to ', num2str(wl), 'nm.']
        warning(err)
    end
end