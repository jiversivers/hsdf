function lctf = vsInit(port)


y = version('-release');
y = str2num(y(1:4));
% New way
try %if ~isMATLABReleaseOlderThan("R2020b");
    % Connect to LCTF
    lctf = serialport(port, 115200);  % 115200 is baudrate determined through trial and error
    configureTerminator(lctf, "CR")     % Set line terminator to carriage return
    
    % % Check the status
    % writeline(lctf, @)
    % status = readline(lctf)
    % 
    % if status ~= 11000010
    % 
    %     write(lctf '')
    
    % Send serial command to (A)waken the LCTF (need to add serial number)
    writeline(lctf, "A ");
    readline(lctf);
    
    % Query current Status
    writeline(lctf, "A ?")
    readline(lctf);
    status = "";
    try_count = 0;
    
    while status ~= "a     0"
       
        % Check request results
        status = readline(lctf);
        
        
        % Give up after 10 tries (error)
        try_count = try_count+1;
        if try_count > 3
            break
        end
    end
    
    if status ~= "a     0"
        error("Failed to validate wake/sleep status. Either no response was recieved, or an unexpected response was returned from the device.")
    end
    
    writeline(lctf, 'R 1')
    readline(lctf);

%Old way
catch
    % Connect to LCTF
    lctf = serial(port,'BaudRate',115200); % Maybe 230400
    fopen(lctf);
    
    % Send serial command to (A)waken the LCTF (need to add serial number)
    fprintf(lctf,"A ");
    fget(lctf);
    
    % Query current Status
    fprintf(lctf, "A ?");
    fgets(lctf);
    status = "";
    try_count = 0;
    
    while status ~= "a     0"
        
        % Check request results
        status = fgets(lctf);
        
        % Give up after 10 tries (error)
        try_count = try_count+1;
        if try_count > 3
            break
        end
    end
    
    if status ~= "a     0"
        error("Failed to validate wake/sleep status. Either no response was recieved, or an unexpected response was retruned from the device.")
    end
    
    fprintf(lctf, "R 1")
    fgets(lctf)
    
end
