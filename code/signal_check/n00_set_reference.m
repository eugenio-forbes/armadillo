%%% Based on input referencing method, this function sets every electrode's
%%% reference channel numbers. Returns edited electrode list.

function electrode_list = n00_set_reference(electrode_list, referencing_method)

n_electrodes = height(electrode_list);

switch referencing_method
    case {'CAR', 'none'}
        electrode_list.reference = [];
        
    case 'white-matter'
        electrode_list.reference = electrode_list.white_matter_reference;
        
    case 'bipolar'
        electrode_list.reference = electrode_list.bipolar_reference;
        has_bipolar_reference = electrode_list.has_bipolar_reference;
        electrode_list(~has_bipolar_reference, :) = [];
        
    case 'laplacian'
        electrode_list.reference = electrode_list.laplacian_reference;
        has_laplacian_reference = electrode_list.has_laplacian_reference;
        electrode_list(~has_laplacian_reference, :) = [];
        
    case 'canal5'
        electrode_list.reference = repmat(5, n_electrodes, 1);
        electrode_list(channel_number == 5, :) = [];
        
    case 'canal6'
        electrode_list.reference = repmat(6, n_electrodes, 1);
        electrode_list(channel_number == 6, :) = [];
        
    case 'canal5y6'
        electrode_list.reference = repelem({[5, 6]}, n_electrodes, 1);
        electrode_list(ismember(channel_number, [5, 6]), :) = [];
        
end

end