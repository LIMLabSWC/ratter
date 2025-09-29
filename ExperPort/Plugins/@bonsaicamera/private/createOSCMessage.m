function oscPacket = createOSCMessage(address, arg)
% Ensure address and arg are char (not string)
if isstring(address)
    address = char(address);
end
if isstring(arg)
    arg = char(arg);
end

% Helper to pad with nulls to 4-byte alignment
    function bytes = padNulls(str)
        strBytes = uint8([str, 0]);  % null-terminated
        padding = mod(4 - mod(length(strBytes), 4), 4);
        bytes = [strBytes, zeros(1, padding, 'uint8')];
    end

% Address (e.g., "/camera", "/record")
addrBytes = padNulls(address);

% Type Tag String (e.g., ",s" for a single string argument)
typeTag = ',s';
tagBytes = padNulls(typeTag);

% Argument (e.g., "start")
argBytes = padNulls(arg);

% Combine all parts
oscPacket = [addrBytes, tagBytes, argBytes];

end
