function [err, mes] = setWavelength(wl, device)

y = version('-release');
y = str2num(y(1:4));

try ~isMATLABReleaseOlderThan("R2020b");
    isOld = false;
catch
    isOld = true;
end

% New way
if ~isOld %~isMATLABReleaseOlderThan("R2020b")
    
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
        if contains(curr_wl, "*")
            err = 2;
            mes = [num2str(wl) 'nm is out of bounds for this device or the device is confused. If you believe the value is in range, try settign to a different value, then resetting to the desired value.'];
            readline(device); % To empty bad line that falsely confirms set outside of bounds
            error(mes)
        end
        if try_count > 10
            break
        end
    
        % Give up after 10 tries (error)
        try_count = try_count+1;
    end
    
    if curr_wl == command
        err = 0;
        mes = '';
    elseif contains(curr_wl, "*")
            err = 2;
            mes = [command 'nm is out of bounds for this device.'];
            error(mes)
    else
        err = 1;
        mes = ['Failed to validate LCTF tuned to ', num2str(wl), 'nm.'];
        error(mes)
    end
else
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
end