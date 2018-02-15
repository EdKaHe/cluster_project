function analyze_data()

%read paths
path=readtable('.\..\analysis\path.csv', 'Delimiter', ';');

%define all data paths and names
data.filepath = path.extracted_data_dir{1};
data.filename = dir([data.filepath, '\\*.csv']);
data.filename = {data.filename.name};

%define meta paths and names
events.filepath=path.events_dir{1};
events.filename='events.csv';
events.table=table({},[],[],[],[],{});
events.table.Properties.VariableNames={'filename', 'start_date', 'end_date',...
    'duration', 'classification', 'component'};

%define meta paths and names
meta.filepath = path.meta_data_dir{1};
meta.filename = 'meta.csv';

%loop through all files in data.filepath directory
for file=1:numel(data.filename)
    tic %track time for each loop
    %extract filedate in new format
    dataname_split=strsplit(data.filename{file},'_');
    data.filedate{file}=datenum(dataname_split{2}, 'yyyymmdd');
    
    %load current data
    data.table = readtable([data.filepath, '\\', data.filename{file}], 'Delimiter', ';');
    
    %delete the events column which is not required anymore
    exist_column=strcmp('events',data.table.Properties.VariableNames);
    exist_column=exist_column(exist_column==1);
    if exist_column
        data.table.events=[];
    end
    
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
    
    %get the timestamp
    t=data.table.date_number;
    
    %get the filename
    filename=data.filename{file};
    
    %look for bbf in different velocities (currently, all events that occur
    %in v_x, v_y and v_z also occur in v_r)
    [vx_events, vx_event_properties, ~]=bbf_finder(vx, vx, x, t, 'vx', filename);
    [vy_events, vy_event_properties, ~]=bbf_finder(vy, vx, x, t, 'vy', filename);
    [vz_events, vz_event_properties, ~]=bbf_finder(vz, vx, x, t, 'vz', filename);
    [vr_events, vr_event_properties, events_total]=bbf_finder(vr, vx, x, t, 'vr', filename);
    
    %add the events to the data table
    data.table.vx_events=vx_events;
    data.table.vy_events=vy_events;
    data.table.vz_events=vz_events;
    data.table.vr_events=vr_events;
    
    %save table to character seperated value file
    writetable(data.table, [data.filepath, '\\', data.filename{file}], 'Delimiter', ';')
    
    
    
    
    %add the event properties to the event table
    events.table=vertcat(events.table, vx_event_properties, vy_event_properties,...
        vz_event_properties, vr_event_properties);
    %delete rows that containt nans (no event detected)
    events.table=events.table(~any(ismissing(events.table)'),:);
    
    
    
    
    %gather meta data
    meta_filename{file}=data.filename{file};
    meta_date_string{file}=datestr(data.filedate{file}, 'dd-mmm-yy');
    meta_date_number{file}=data.filedate{file};
    if sum(vr_events)>0
        meta_events_total{file}=uint16(events_total);
        meta_events_class{file}=uint16(max(vr_events));
    else
        meta_events_total{file}=uint16(0);
        meta_events_class{file}=uint16(0);
    end
    
    display(sprintf('*** Analyzing file %d/%d took %0.2fs ***', file, numel(data.filename), toc))
    
end




%sort the table after their start date
events.table=sortrows(events.table, 'start_date');

%export event data if there is no old data available
if ~exist([events.filepath, '\\', events.filename],'file')
    writetable(events.table, [events.filepath, '\\', events.filename], 'Delimiter', ';');
else
    %read the old data
    events.old_table=readtable([events.filepath, '\\', events.filename], 'Delimiter', ';');
    
    %add all files from the old table that have not been updates
    updated_events=ismember(events.old_table.start_date,events.table.start_date);
    events.table=vertcat(events.table, events.old_table(find(~updated_events),:));
    
    %export the meta data
    writetable(events.table, [events.filepath, '\\', events.filename], 'Delimiter', ';');
end




%write meta data to table
meta.table = table(meta_filename', meta_date_string',...
    cell2mat(meta_date_number'), cell2mat(meta_events_total'), cell2mat(meta_events_class'));
meta.table.Properties.VariableNames = {'filename', 'date_string', 'date_number', 'events_total', 'events_class'};

%export meta data if there is no old data available
if ~exist([meta.filepath, '\\', meta.filename],'file')
    %sort table after the date columns
    meta.table=sortrows(meta.table, 'date_number');
    
    %export the meta data
    writetable(meta.table, [meta.filepath, '\\', meta.filename], 'Delimiter', ';');
else
    %read the old data
    meta.old_table=readtable([meta.filepath, '\\', meta.filename], 'Delimiter', ';');
    
    %add all files from the old table that have not been updates
    updated_files=ismember(meta.old_table.date_number,meta.table.date_number);
    meta.table=vertcat(meta.table, meta.old_table(find(~updated_files),:));
    
    %sort table after the date columns
    meta.table=sortrows(meta.table, 'date_number');
    
    %export the meta data
    writetable(meta.table, [meta.filepath, '\\', meta.filename], 'Delimiter', ';');
end




%close all openend files
fclose('all');

end




%find bbf events based on one velocity v_i and a positive v_x component
function [vi_events, event_properties, events_total]=bbf_finder(vi, vx, x, t, component, filename)

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

%initialize event properties
event_filename={nan};
event_start_date={nan};
event_end_date={nan};
event_duration={nan};
event_classification={nan};
event_component={nan};

%iterate through each the velocity vector
for index=2:numel(vi)
    %possible events start at v > 100km/s and ends at v < 100km/s
    if vi(index)>100 && vi(index-1)<100
        start_index=index-1;
    elseif vi(index-1)>100 && vi(index)<100
        end_index=index;
        new_event=1;
    end

    %check if velocity is above 400km/s
    if ~isempty(find(vi(start_index:end_index)>400)) && new_event==1
        new_event=0;
        events_total=events_total+1;
        
        %check whether position is predominantly in front or behind the earth 
        check_pos=x(start_index:end_index);
        check_pos=check_pos(~isnan(check_pos)); %exclude nans
        check_pos=sum(check_pos);

        %check whether velocity is predominantly negative or positive
        check_vel=vx(start_index:end_index);
        check_vel=check_vel(~isnan(check_vel)); %exclude nans
        check_vel=check_vel(abs(check_vel) < 3e3); %exclude unreasonable values above 3000km/s
        check_vel=sum(check_vel);
        
        if check_pos<=0 && check_vel>=0
            class=3;
        elseif check_pos>0 && check_vel<0
            class=2;
        else
            class=1;
        end
        
        vi_events(start_index:end_index)=class*ones(size(vi_events(start_index:end_index)));
        
        %extract event properties
        event_filename{events_total}=filename;
        event_start_date{events_total}=t(start_index);
        event_end_date{events_total}=t(end_index);
        event_duration{events_total}=(t(end_index)-t(start_index))*24*60*60;
        event_classification{events_total}=class;
        event_component{events_total}=component;
    end
    
end




%write properties to table
event_properties=table(event_filename', cell2mat(event_start_date'), cell2mat(event_end_date'), cell2mat(event_duration'), cell2mat(event_classification'), event_component');
event_properties.Properties.VariableNames={'filename', 'start_date', 'end_date',...
    'duration', 'classification', 'component'};

end