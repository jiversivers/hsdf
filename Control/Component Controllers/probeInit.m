%% probeInit
function probe = probeInit(port)
probe = serialport(port, 115200, "Parity", "none", "DataBits", 8, "StopBits", 1, "FlowControl", "None");
probe.setDTR(true)
probe.setRTS(true)
end