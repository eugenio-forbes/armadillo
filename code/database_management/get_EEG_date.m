function eeg_date_ms = get_EEG_date(eeg_file_name)

%%% Modified nk_split_2 function to get EEG recording start date in seconds  

file_id = fopen(eeg_file_name);

device_block_length = 128;
fseek(file_id, device_block_length + 18, 'bof');

block_address = fread(file_id, 1, '*int32');
fseek(file_id, block_address + 18, 'bof');

block_address = fread(file_id, 1, '*int32');
fseek(file_id, block_address + 20, 'bof');

T_year = bcdConverter(fread(file_id, 1, '*uint8'));
T_month = bcdConverter(fread(file_id, 1, '*uint8'));
T_day = bcdConverter(fread(file_id, 1, '*uint8'));
T_hour = bcdConverter(fread(file_id, 1, '*uint8'));
T_minute = bcdConverter(fread(file_id, 1, '*uint8'));
T_second = bcdConverter(fread(file_id, 1, '*uint8'));

date_vector = [T_year, T_month, T_day, T_hour, T_minute, T_second];

eeg_date_ms = datetime(date_vector, 'Format', 'uuuu-MM-dd HH:mm:ss.SSS');

fclose(file_id);

end

function out = bcdConverter(bits_in)

  x = dec2bin(bits_in, 8);
  out = 10 * bin2dec(x(1:4)) + bin2dec(x(5:8));

end