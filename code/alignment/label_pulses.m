function pulse_info = label_pulses(plot_file,events_pulses,eeg_pulses,eeg_starts,eeg_ends,do_plot)
n_eeg_files = length(eeg_starts);

[diff_test_events,diff_break_events,diff_event_events,...
    n_pulse_tests_events,n_breaks_events,test_n_pulses_events,...
    test_starts_events,block_starts_events,block_ends_events] = get_pulse_diff_types(events_pulses);

[diff_test_eeg,diff_break_eeg,diff_event_eeg,...
    n_pulse_tests_eeg,n_breaks_eeg,test_n_pulses_eeg,...
    test_starts_eeg,block_starts_eeg,block_ends_eeg] = get_pulse_diff_types(eeg_pulses);

pulse_info = struct;

pulse_info.diff_test_events = diff_test_events;
pulse_info.diff_event_events = diff_event_events;
pulse_info.diff_break_events = diff_break_events;
pulse_info.n_pulse_tests_events = n_pulse_tests_events;
pulse_info.n_breaks_events = n_breaks_events;
pulse_info.test_n_pulses_events = test_n_pulses_events;
pulse_info.test_starts_events = test_starts_events;
pulse_info.block_starts_events = block_starts_events;
pulse_info.block_ends_events = block_ends_events;
pulse_info.diff_test_eeg = diff_test_eeg;
pulse_info.diff_event_eeg = diff_event_eeg;
pulse_info.diff_break_eeg = diff_break_eeg;
pulse_info.n_pulse_tests_eeg = n_pulse_tests_eeg;
pulse_info.n_breaks_eeg = n_breaks_eeg;
pulse_info.test_n_pulses_eeg = test_n_pulses_eeg;
pulse_info.test_starts_eeg = test_starts_eeg;
pulse_info.block_starts_eeg = block_starts_eeg;
pulse_info.block_ends_eeg = block_ends_eeg;

if do_plot
    figure_width = 1920;
    figure_height = 1080;
    common_limits = [min(events_pulses(1),eeg_pulses(1)),max(events_pulses(end),eeg_pulses(end))];
    [~,~,blue,~,~,green,pink] = get_color_selection();
    
    figure('Units','pixels','Position',[0 0 figure_width figure_height],'Visible','off')
    
    subplot(1,2,1)
    
    hold on
    scatter(events_pulses(diff_event_events),events_pulses(diff_event_events),[],repmat(green,sum(diff_event_events),1),'o')
    scatter(events_pulses(block_starts_events),events_pulses(block_starts_events),[],repmat(pink,length(block_starts_events),1),'o','filled')
    scatter(events_pulses(block_ends_events),events_pulses(block_ends_events),[],repmat(pink,length(block_ends_events),1),'o','filled')
    scatter(events_pulses(diff_test_events),events_pulses(diff_test_events),[],repmat(blue,sum(diff_test_events),1),'o')
    xlim(common_limits);xticks([]);xticklabels([]);
    ylim(common_limits);yticks([]);yticklabels([]);
    if n_eeg_files > 1
        for idx = 2:n_eeg_files
            plot([eeg_ends(idx-1),eeg_ends(idx-1)],common_limits,'--k')
            plot([eeg_starts(idx),eeg_starts(idx)],common_limits,'--k')
        end
    end
    hold off
    
    subplot(1,2,2)
    
    hold on
    scatter(eeg_pulses(diff_event_eeg),eeg_pulses(diff_event_eeg),[],repmat(green,sum(diff_event_eeg),1),'o')
    scatter(eeg_pulses(block_starts_eeg),eeg_pulses(block_starts_eeg),[],repmat(pink,length(block_starts_eeg),1),'o','filled')
    scatter(eeg_pulses(block_ends_eeg),eeg_pulses(block_ends_eeg),[],repmat(pink,length(block_ends_eeg),1),'o','filled')
    scatter(eeg_pulses(diff_test_eeg),eeg_pulses(diff_test_eeg),[],repmat(blue,sum(diff_test_eeg),1),'o')
    if n_eeg_files > 1
        for idx = 2:n_eeg_files
            plot([eeg_ends(idx-1),eeg_ends(idx-1)],common_limits,'--k')
            plot([eeg_starts(idx),eeg_starts(idx)],common_limits,'--k')
        end
    end
    xlim(common_limits);xticks([]);xticklabels([]);
    ylim(common_limits);yticks([]);yticklabels([]);
    hold off
    
    print(plot_file,'-dpng')
    close all
end
end