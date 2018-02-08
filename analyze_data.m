function analyze_data()

%read paths
path=readtable('.\..\analysis\path.csv', 'Delimiter', ';');

%define all data paths and names
data.filepath = path.extracted_data_dir{1};
data.filename = dir([data.filepath, '\\*.csv']);
data.filename = {data.filename.name};

%define meta paths and names
meta.filepath = path.meta_data_dir{1};
meta.filename = 'meta.csv';

%loop through all files in data.filepath directory
for file=1:numel(data.filename)
    tic %track time for each loop
    %extract filedate in new format
    dataname_split=strsplit(data.filename{file},'_');
    data.filedate{file}=datenum(dataname_split{2}, 'yyyymmdd');
    
    %load current daata
    data.table = readtable([data.filepath, '\\', data.filename{file}], 'Delimiter', ';');
        
    %get the velocities
    vx=data.table.vx_gsm3;
    vy=data.table.vy_gsm3;
    vz=data.table.vz_gsm3;
    vr=data.table.vr_gsm3;
    
    %get the coordinates
    x=data.table.x_gsmRE3;
    y=data.table.y_gsmRE3;
    z=data.table.z_gsmRE3;
    r=data.table.r_gsmRE3;
    
    %look for bbf in different velocities (currently, all events that occur
    %in v_x, v_y and v_z also occur in v_r)
    [vx_events, ~]=bbf_finder(vx, vx, x);
    [vy_events, ~]=bbf_finder(vy, vx, x);
    [vz_events, ~]=bbf_finder(vz, vx, x);
    [vr_events, events_total]=bbf_finder(vr, vx, x);
    
    %add the events to the data table
    data.table.vx_events=vx_events;
    data.table.vy_events=vy_events;
    data.table.vz_events=vz_events;
    data.table.vr_events=vr_events;
    
    %save table to character seperated value file
    writetable(data.table, [data.filepath, '\\', data.filename{file}], 'Delimiter', ';')
        
    %gather meta data
    meta_filename{file}=data.filename{file};
    meta_date_string{file}=datestr(data.filedate{file}, 'dd-mmm-yy');
    meta_date_number{file}=data.filedate{file};
    if sum(vr_events)>0
        meta_events_total{file}=int8(events_total);
        meta_events_class{file}=int8(max(vr_events));
    else
        meta_events_total{file}=int8(0);
        meta_events_class{file}=int8(0);
    end
        
    display(sprintf('*** Analyzing file %d/%d took %0.2fs ***', file, numel(data.filename), toc))
    
end

%write meta data to table

meta.table = table(meta_filename', meta_date_string',...
    cell2mat(meta_date_number'), cell2mat(meta_events_total'), cell2mat(meta_events_class'));
meta.table.Properties.VariableNames = {'filename', 'date_string', 'date_number', 'events_total', 'events_class'};

%export meta data if there is no old data available
if ~exist([meta.filepath, '\\', meta.filename],'file')
    writetable(meta.table, [meta.filepath, '\\', meta.filename], 'Delimiter', ';');
    return
end

%read the old data
meta.old_table=readtable([meta.filepath, '\\', meta.filename], 'Delimiter', ';');

%add all files from the old table that have not been updates
updated_files=ismember(meta.old_table.date_number,meta.table.date_number);
meta.table=vertcat(meta.table, meta.old_table(find(~updated_files),:));
meta.table=sortrows(meta.table, 'date_number');

%export the meta data
writetable(meta.table, [meta.filepath, '\\', meta.filename], 'Delimiter', ';');

%close all openend files
fclose('all');

end




%find bbf events based on one velocity v_i and a positive v_x component
function [vi_events, events_total]=bbf_finder(vi, vx, x)

%initialize vector that contain 0 for no event and 1 for
%events
vi_events=zeros(size(vi));

%count the total number of events
events_total=0;

%initialize start- end end indices for the events
start_index=1;
end_index=1;

%ensure that each event is only tracked once
new_event=0;

%iterate through each the velocity vector
for index=2:numel(vi)
    %possible events start at v > 100km/s and ends at v < 100km/s
    if vi(index)>100 && vi(index-1)<100
        start_index=index-1;
    elseif vi(index-1)>100 && vi(index)<100
        end_index=index;
        new_event=1;
    end
    
    %bbf occurs if v between start_index and end_index is once > 400km/s and the x-component (check_sum) is predominantly positive
    check_values=vx(start_index:end_index);
    check_values=check_values(~isnan(check_values)); %exclude nans
    check_values=check_values(abs(check_values) < 3e3); %exclude unreasonable values above 3000km/s
    check_sum=sum(check_values);

    %check if the bbf criteria are fulfilled
    if ~isempty(find(vi(start_index:end_index)>400)) && check_sum>0 && new_event==1
        new_event=0;
        events_total=events_total+1;
        %check whether event is in magnetotail (x comomponent predominantly
        %negative
        check_values=x(start_index:end_index);
        check_values=check_values(~isnan(check_values)); %exclude nans
        check_sum=sum(check_values);
        
        if check_sum<0
            class=2;
        else
            class=1;
        end
        
        vi_events(start_index:end_index)=class*ones(size(vi_events(start_index:end_index)));
    end
    
end

end