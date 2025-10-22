function n03_filter_electrode_list(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo/parent_directory';
    username = 'username';
    analysis_folder_name = 'armadillo';
else
    root_directory = varargin{1};
    username = varargin{2};
    analysis_folder_name = varargin{3};
end

%%% List directories
analysis_directory = fullfile(root_directory, username, analysis_folder_name);
list_directory = fullfile(analysis_directory, 'lists');

%%% Load electrode list
load(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');

unspecified_location = {'Anterior Prefrontal', 'Lateral Prefrontal', 'MEG DIPOLE', 'Prefrontal'};

unspecified_segment = {'Central Sulcus', 'Cingulate Gyrus', 'Cingulate Sulcus', ...
    'Collateral Sulcus', 'Frontal Operculum', 'Fusiform Gyrus', 'Hippocampus', 'IFG', ...
    'IFS', 'ITG', 'ITS', 'Insula', 'MFG', 'MOTOR', 'MTG', 'Occipital Gyrus', 'Operculum', ...
    'Orbital Gyrus', 'Orbital Sulcus', 'PHG', 'Parietal Operculum', 'Pars Opercularis', 'Postcentral Sulcus', ...
    'Precentral Sulcus', 'Precuneus', 'SENSORY', 'SFG', 'SFS', 'STG', 'STS', 'Sulcus'};

bad_words = {'OUT', 'Lesion', 'FCD', 'Resection', 'Heterotopia', 'MCD', 'Tuber'};

bad_electrodes = contains(electrode_list.neurologist_location, bad_words);
potentially_bad = strcmp(electrode_list.neurologist_location, '');

auto_bad = ismember(electrode_list.automatic_location, {'WM', 'empty', ''});
glasser_bad = ismember(electrode_list.glasser_location, {'WM', 'empty', ''});
confirmed_bad = potentially_bad & (auto_bad|glasser_bad);

all_bad = bad_electrodes | confirmed_bad;

electrode_list(all_bad, :) = [];

n_electrodes = height(electrode_list);
neurologist = electrode_list.neurologist_location;

for idx = 1:n_electrodes
    
    this_neurologist = neurologist{idx};
    
    if contains(this_neurologist, bad_words)
        
        if contains(this_neurologist, ' vs ')
            
            bad_word_locations = cell2mat(cellfun(@(x) strfind(this_neurologist, x), bad_words, 'UniformOutput', false));
            
            vs_locations = strfind(this_neurologist, ' vs ');
            
            for jdx = 1:length(bad_words)
                this_neurologist = strrep(this_neurologist, bad_words{jdx}, '');
            end
            
            while contains(this_neurologist, '  ')
                this_neurologist = strrep(this_neurologist, '  ', ' ');
            end
            
            while contains(this_neurologist, 'vs vs')
                this_neurologist = strrep(this_neurologist, 'vs vs', 'vs');
            end
            
            if length(this_neurologist)>=4 && any(bad_word_locations<vs_locations(1))
                if strcmp(this_neurologist(1:4), ' vs ')
                    this_neurologist(1:4) = [];
                end
            end
            
            if length(this_neurologist)>=4 && any(bad_word_locations>vs_locations(end))
                if strcmp(this_neurologist(end - 3:end), ' vs ')
                    this_neurologist(end - 3:end) = [];
                end
            end
            
        else
        
            for jdx = 1:length(bad_words)
                this_neurologist = strrep(this_neurologist, bad_words{jdx}, '');
            end
            
            while contains(this_neurologist, '  ')
                this_neurologist = strrep(this_neurologist, '  ', ' ');
            end
        
        end
        
        if isempty(this_neurologist)
            this_neurologist = 'empty';
        end
        
        neurologist{idx} = strtrim(this_neurologist);
    
    end

end

electrode_list.neurologist_location = neurologist;
electrode_list.automatic_location   = lower(electrode_list.automatic_location);
electrode_list.glasser_location     = lower(electrode_list.glasser_location);

[neurologist_table, automatic_table, glasser_table] = make_label_tables(electrode_list);

undecided = false(n_electrodes, 1);
auto_replacement = cell(n_electrodes, 1);
glasser_replacement = cell(n_electrodes, 1);
best_replacement = cell(n_electrodes, 1);

for idx = 1:n_electrodes

    neurologist = electrode_list.neurologist_location{idx};
    glasser = electrode_list.glasser_location{idx};
    automatic = electrode_list.automatic_location{idx};
    is_central = contains(neurologist, {'pre', 'post'}) && contains(neurologist, {'cg', 'central'});
    is_undecided = contains(neurologist, [{'vs'}, bad_words]) && ~is_central;
    
    if is_undecided
    
        undecided(idx) = true;
        
        options = strsplit(neurologist, ' vs ');
        
        this_auto = contains(automatic_table.automatic, automatic);
        this_auto_neuro = automatic_table.neurologist{this_auto};
        this_auto_n_neuro = automatic_table.n_neurologist{this_auto};
        bad_auto_neuro = contains(this_auto_neuro, {'wm', 'vs', 'out', 'empty'});
        this_auto_neuro(bad_auto_neuro) = [];
        this_auto_n_neuro(bad_auto_neuro) = [];
        
        if ~isempty(this_auto_neuro)
            [n_auto, best_auto] = max(this_auto_n_neuro);
            auto_replacement{idx} = this_auto_neuro{best_auto};
        else
            n_auto = 0;
        end
        
        this_glasser = contains(glasser_table.glasser, glasser);
        this_glasser_neuro = glasser_table.neurologist{this_glasser};
        this_glasser_n_neuro = glasser_table.n_neurologist{this_glasser};
        bad_glasser_neuro = contains(this_glasser_neuro, {'wm', 'vs', 'out', 'empty'});
        this_glasser_neuro(bad_glasser_neuro) = [];
        this_glasser_n_neuro(bad_glasser_neuro) = [];
        
        if ~isempty(this_glasser_neuro)
            [n_glasser, best_glasser] = max(this_glasser_n_neuro);
            glasser_replacement{idx} = this_glasser_neuro{best_glasser};
        else
            n_glasser = 0;
        end
        
        if n_glasser + n_auto > 0
        
            if n_glasser > n_auto
                best_replacement{idx} = glasser_replacement{idx};
            else
                best_replacement{idx} = auto_replacement{idx};
            end
            
        end
        
    elseif is_central
    
        undecided(idx) = true;
        
        if contains(neurologist, 'pre') && contains(neurologist, 'post')
        
            if contains('automatic', 'pre')
                auto_replacement{idx} = 'pre-central gyrus';
            end
            
            if contains('automatic', 'post')
                auto_replacement{idx} = 'post-central gyrus';
            end
            
            if contains('glasser', 'pre')
                glasser_replacement{idx} = 'pre-central gyrus';
            end
            
            if contains('glasser', 'post')
                glasser_replacement{idx} = 'post-central gyrus';
            end
            
            if isempty(auto_replacement{idx}) && isempty(glasser_replacement{idx})
                best_replacement{idx} = 'pre-central Gyrus';
            elseif ~isempty(auto_replacement{idx}) && ~isempty(glasser_replacement{idx})
                best_replacement{idx} = auto_replacement{idx};
            else
            
                if isempty(auto_replacement)
                    best_replacement{idx} = glasser_replacement{idx};
                else
                    best_replacement{idx} = auto_replacement{idx};
                end
                
            end
            
        elseif contains(neurologist, 'pre')
        
            auto_replacement{idx} = 'pre-central gyrus';
            glasser_replacement{idx} = 'pre-central gyrus';
            best_replacement{idx} = 'pre-central gyrus';
            
        elseif contains(neurologist, 'post')
        
            auto_replacement{idx} = 'post-central gyrus';
            glasser_replacement{idx} = 'Post-central gyrus';
            best_replacement{idx} = 'post-central gyrus';
        
        end
    
    end

end

electrode_list.glasser_replacement = glasser_replacement;
electrode_list.auto_replacement    = auto_replacement;
electrode_list.best_replacement    = best_replacement;
electrode_list.neurologist         = best_replacement;

undecided = electrode_list(undecided, :);

[neurologist_table, automatic_table, glasser_table] = make_label_tables(electrode_list);

end


function [neurologist_table, automatic_table, glasser_table] = make_label_tables(electrode_list)

all_neurologist = electrode_list.neurologist_location;
all_glasser     = electrode_list.glasser_location;
all_automatic   = electrode_list.automatic_location;

neurologist = unique(all_neurologist);
n_unique = length(neurologist);
n_total = NaN(n_unique, 1);
glasser = cell(n_unique, 1);
n_glasser = cell(n_unique, 1);
automatic = cell(n_unique, 1);
n_automatic = cell(n_unique, 1);

for idx = 1:n_unique

    this_neurologist = neurologist{idx};
    row_indices = strcmp(all_neurologist, this_neurologist);
    n_total(idx) = sum(row_indices);
    these_glasser = all_glasser(row_indices);
    glasser{idx} = unique(these_glasser);
    n_glasser{idx} = cellfun(@(x) sum(strcmp(these_glasser, x)), unique(these_glasser));
    these_automatic = all_automatic(row_indices);
    automatic{idx} = unique(these_automatic);
    n_automatic{idx} = cellfun(@(x) sum(strcmp(these_automatic, x)), unique(these_automatic));    

end

neurologist_table = table(neurologist, n_total, automatic, n_automatic, glasser, n_glasser);

glasser = unique(all_glasser);
n_unique = length(glasser);
n_total = NaN(n_unique, 1);
neurologist = cell(n_unique, 1);
n_neurologist = cell(n_unique, 1);
automatic = cell(n_unique, 1);
n_automatic = cell(n_unique, 1);

for idx = 1:n_unique

    this_glasser = glasser{idx};
    row_indices = strcmp(all_glasser, this_glasser);
    n_total(idx) = sum(row_indices);
    these_neurologist = all_neurologist(row_indices);
    neurologist{idx} = unique(these_neurologist);
    n_neurologist{idx} = cellfun(@(x) sum(strcmp(these_neurologist, x)), unique(these_neurologist));
    these_automatic = all_automatic(row_indices);
    automatic{idx} = unique(these_automatic);
    n_automatic{idx} = cellfun(@(x) sum(strcmp(these_automatic, x)), unique(these_automatic));
        
end

glasser_table = table(glasser, n_total, automatic, n_automatic, neurologist, n_neurologist);

automatic = unique(all_automatic);
n_unique = length(automatic);
n_total = NaN(n_unique, 1);
neurologist = cell(n_unique, 1);
n_neurologist = cell(n_unique, 1);
glasser = cell(n_unique, 1);
n_glasser = cell(n_unique, 1);

for idx = 1:n_unique

    this_automatic = automatic{idx};
    row_indices = strcmp(all_automatic, this_automatic);
    n_total(idx) = sum(row_indices);
    these_neurologist = all_neurologist(row_indices);
    neurologist{idx} = unique(these_neurologist);
    n_neurologist{idx} = cellfun(@(x) sum(strcmp(these_neurologist, x)), unique(these_neurologist));
    these_glasser = all_glasser(row_indices);
    glasser{idx} = unique(these_glasser);
    n_glasser{idx} = cellfun(@(x) sum(strcmp(these_glasser, x)), unique(these_glasser));
        
end

automatic_table = table(automatic, n_total, glasser, n_glasser, neurologist, n_neurologist);

end


function location_table = make_location_table(electrode_list)

all_neurologist_labels = unique(electrode_list.neurologist_location);

locations = cellfun(@(x) strsplit(x, ' VS ')', all_neurologist_labels, 'UniformOutput', false);
locations = unique(vertcat(locations{:}));
locations = [append('Left ', locations);append('Right ', locations)];
one_exception = contains(locations, 'Interhemispheric Fissure');
locations(one_exception) = [];
locations = [locations;'Interhemispheric Fissure'];

location_counts = zeros(length(locations), 1);
location_subjects = cell(length(locations), 1);
location_coordinates = cell(length(locations), 3);

for idx = 1:height(electrode_list)
    
    neurologist_location = electrode_list.neurologist_location{idx};
    coordinates = electrode_list.coordinates{idx};
    hemisphere = electrode_list.hemisphere{idx};
    subject = electrode_list.subject_ID(idx);
    options = strsplit(neurologist_location, ' VS ');
    options = options(~strcmp(options, ''));
    
    if ~isempty(options) && ~strcmp(hemisphere, 'check')
        
        switch hemisphere
            case 'left'
                options = append('Left ', options);
            case 'right'
                options = append('Right ', options);
        end
        
        location_indices = cellfun(@(x) find(strcmp(locations, x)), options);
        n_indices = length(location_indices);
        location_counts(location_indices) = location_counts(location_indices) + 1;
        
        for jdx = 1:n_indices
            
            location_index = location_indices(jdx);
            location_subjects{location_index} = cat(1, location_subjects{location_index}, subject);
            
            if ~isempty(coordinates) && ~any(isnan(coordinates))
                location_coordinates{location_index} = cat(1, location_coordinates{location_index}, coordinates);
            end
        
        end
    
    end
    
    clear neurologist_location options coordinates hemisphere subject location_indices

end

location_n_subjects = cellfun(@(x) length(unique(x)), location_subjects);
location_coordinate_means = cell(length(locations), 1);
location_coordinate_stds = cell(length(locations), 1);

for idx = 1:length(locations)
    
    all_coordinates = location_coordinates{idx};
    
    if ~isempty(all_coordinates)
        location_coordinate_means{idx} = mean(all_coordinates, 1);
        location_coordinate_stds{idx} = std(all_coordinates, 0, 1);
    end

end

location_table = table;
location_table.location     = locations;
location_table.n_subjects   = location_n_subjects;
location_table.n_electrodes = location_counts;
location_table.mean         = location_coordinate_means;
location_table.std          = location_coordinate_stds;

location_table(location_counts == 0, :) = [];

end