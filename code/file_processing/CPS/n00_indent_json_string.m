function indented_json_string = n00_indent_json_string(json_string)

indented_json_string = ['{', newline];

indent_level = 1;
is_new_line = true;

n_characters = length(json_string);

for idx = 2:n_characters - 1

    preceding_character = json_string(idx - 1);
    current_character = json_string(idx);
    next_character = json_string(idx + 1);
    
    switch current_character
        case ', '
            indented_json_string = append(indented_json_string, [current_character, newline]);
            is_new_line = true;
        
        case ':'
            indented_json_string = append(indented_json_string, [current_character, ' ']);
        
        case '{'
            if strcmp(next_character, '}')
                indented_json_string = append(indented_json_string, current_character);
            else
                indented_json_string = append(indented_json_string, [current_character, newline]);
                is_new_line = true;
                indent_level = indent_level + 1;
            end
        
        case '}'
            if strcmp(preceding_character, '{')
                indented_json_string = append(indented_json_string, current_character);
            else
                indent_level = indent_level - 1;
                indented_json_string = append(indented_json_string, [newline, repmat('  ', 1, indent_level), current_character]);
            end
        
        case '['
            if strcmp(next_character, ']')
                indented_json_string = append(indented_json_string, current_character);
            else
                indented_json_string = append(indented_json_string, [current_character, newline]);
                is_new_line = true;
                indent_level = indent_level + 1;
            end
        
        case ']'
            if strcmp(preceding_character, '[')
                indented_json_string = append(indented_json_string, current_character);
            else
                indent_level = indent_level - 1;
                indented_json_string = append(indented_json_string, [newline, repmat('  ', 1, indent_level), current_character]);
            end
        
        otherwise
            if is_new_line
                is_new_line = false;
                indented_json_string = append(indented_json_string, [repmat('  ', 1, indent_level), current_character]);
            else
                indented_json_string = append(indented_json_string, current_character);
            end
    end

end

indented_json_string = append(indented_json_string, [newline, '}']);
indented_json_string = strrep(indented_json_string, '''<[]>''', '[]');
indented_json_string = strrep(indented_json_string, '''<{}>''', '{}');

end