function n00_save_config(configuration_file, configuration)

configuration_text = jsonencode(configuration);
configuration_text = n00_indent_json_string(configuration_text);
configuration_text = strrep(configuration_text, '''<[]>''', '[]');
configuration_text = strrep(configuration_text, '''<{}>''', '{}');

file_id = fopen(configuration_file, 'w');
fwrite(file_id, configuration_text);
fclose(file_id);

end