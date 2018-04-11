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
events.table=table({},[],[],[],[],{}, [], [], [], [], [], [], [], [], [], [], [], [], []);
events.table.Properties.VariableNames={'filename', 'start_date', 'end_date',...
    'duration', 'classification', 'component',...
    'vx_max', 'vx_mean', 'vy_max', 'vy_mean', 'vz_max', 'vz_mean', 'vr_max', 'vr_mean',...
    'x', 'y', 'z', 'r',...
    'spacecraft'};

%define meta paths and names
meta.filepath = path.meta_data_dir{1};
meta.filename = 'meta.csv';

%loop through all files in data.filepath directory
for file=1:numel(data.filename)
    tic %track time for each loop
    %extract filedate in new format
    dataname_split=strsplit(data.filename{file},'_');
    data.filedate{file}=datenum(dataname_split{2}, 'yyyymmdd');

    %get the spacecraft
    spacecraft=strsplit(data.filename{file}, '_');
    spacecraft=spacecraft{1};
    spacecraft=uint8(str2double(spacecraft(2)));
    
    %load current data
    data.table = readtable([data.filepath, '\\', data.filename{file}], 'Delimiter', ';');
    
    %delete the events column which is not required anymore
    exist_column=strcmp('events',data.table.Properties.VariableNames);
    exist_column=exist_column(exist_column==1);
    if exist_column
        data.table.events=[];
    end
    
    %get the velocities
    vx=data.table.vx_gsm;
    vy=data.table.vy_gsm;
    vz=data.table.vz_gsm;
    vr=data.table.vr_gsm;
    
    %get the coordinates
    x=data.table.x_gsm;
    y=data.table.y_gsm;
    z=data.table.z_gsm;
    r=data.table.r_gsm;
    
    %get the timestamp
    t=data.table.dt;
    
    %get the filename
    filename=data.filename{file};
    
    %look for bbf in different velocities (currently, all events that occur
    %in v_x, v_y and v_z also occur in v_r)
    [vx_events, vx_event_properties, ~]=bbf_finder('vx', vx, vy, vz, vr, x, y, z, r, t, spacecraft, filename);
    [vy_events, vy_event_properties, ~]=bbf_finder('vy', vx, vy, vz, vr, x, y, z, r, t, spacecraft, filename);
    [vz_events, vz_event_properties, ~]=bbf_finder('vz', vx, vy, vz, vr, x, y, z, r, t, spacecraft, filename);
    [vr_events, vr_event_properties, events_total]=bbf_finder('vr', vx, vy, vz, vr, x, y, z, r, t, spacecraft, filename);
    
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
    meta_spacecraft{file}=spacecraft;
    
    display(sprintf('*** Analyzing file %d/%d took %0.2fs ***', file, numel(data.filename), toc))
   
end





%export event data if there is no old data available
if ~exist([events.filepath, '\\', events.filename],'file')
    %sort the table after their start date
    events.table=sortrows(events.table, 'start_date');
    writetable(events.table, [events.filepath, '\\', events.filename], 'Delimiter', ';');
else
    %read the old data
    events.old_table=readtable([events.filepath, '\\', events.filename], 'Delimiter', ';');
    
    %add all files from the old table that have not been updates
    updated_events=ismember(events.old_table.start_date,events.table.start_date);
    events.table=vertcat(events.table, events.old_table(find(~updated_events),:));
    
    %sort the table after their start date
    events.table=sortrows(events.table, 'start_date');
    
    %export the meta data
    writetable(events.table, [events.filepath, '\\', events.filename], 'Delimiter', ';');
end




%write meta data to table
meta.table = table(meta_filename', meta_date_string',...
    cell2mat(meta_date_number'), cell2mat(meta_events_total'), cell2mat(meta_events_class'), cell2mat(meta_spacecraft'));
meta.table.Properties.VariableNames = {'filename', 'date_string', 'date_number', 'events_total', 'events_class', 'spacecraft'};

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
function [vi_events, event_properties, events_total]=bbf_finder(component, vx, vy, vz, vr, x, y, z, r, t, spacecraft, filename)

%choose the current velocity component
switch component
    case 'vx'
        vi=vx;
    case 'vy'
        vi=vy;
    case 'vz'
        vi=vz;
    case 'vr'
        vi=vr;
end

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
event_vx_max={nan};
event_vx_mean={nan};
event_vy_max={nan};
event_vy_mean={nan};
event_vz_max={nan};
event_vz_mean={nan};
event_vr_max={nan};
event_vr_mean={nan};
event_x={nan};
event_y={nan};
event_z={nan};
event_r={nan};
event_spacecraft={nan};

%iterate through each the velocity vector
for index=2:numel(vi)
    %possible events start at v > 100km/s 
    if abs(vi(index))>=100 && abs(vi(index-1))<100
        start_index=index-1;
    elseif abs(vi(1))>=100 && index==2 %if the event has started before the beginning of the data set
        start_index=1;
    end
    %possible event ends at v < 100km/s
    if abs(vi(index-1))>=100 && abs(vi(index))<100
        end_index=index;
        new_event=1;
    elseif abs(vi(end))>=100 && index==numel(vi) %if the event has ended after the end of the data set
        end_index=numel(vi);
        new_event=1;
    end

    %check if velocity is above 400km/s
    if ~isempty(find(abs(vi(start_index:end_index))>400)) && new_event==1
        new_event=0;
        events_total=events_total+1;
        
        %check whether position is predominantly in front or behind the earth 
        check_pos=x(start_index:end_index);
        check_pos=check_pos(~isnan(check_pos)); %exclude nans
        check_pos=sum(check_pos);

        %check whether velocity is predominantly negative or positive
        check_vel=vx(start_index:end_index);
        check_vel=check_vel(~isnan(check_vel)); %exclude nans
        check_vel=check_vel(abs(check_vel) < 3e5); %exclude unreasonable values above 300,000km/s
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
        event_vx_max{events_total}=get_signed_max_abs(vx(start_index:end_index));
        event_vx_mean{events_total}=get_mean(vx(start_index:end_index));
        event_vy_max{events_total}=get_signed_max_abs(vy(start_index:end_index));
        event_vy_mean{events_total}=get_mean(vy(start_index:end_index));
        event_vz_max{events_total}=get_signed_max_abs(vz(start_index:end_index));
        event_vz_mean{events_total}=get_mean(vz(start_index:end_index));
        event_vr_max{events_total}=get_signed_max_abs(vr(start_index:end_index));
        event_vr_mean{events_total}=get_mean(vr(start_index:end_index));
        event_x{events_total}=get_location(x(start_index:end_index));
        event_y{events_total}=get_location(y(start_index:end_index));
        event_z{events_total}=get_location(z(start_index:end_index));
        event_r{events_total}=get_location(r(start_index:end_index));
        event_spacecraft{events_total}=spacecraft;
    end
    
    
end




%write properties to table
event_properties=table(event_filename', cell2mat(event_start_date'), cell2mat(event_end_date'), cell2mat(event_duration'), cell2mat(event_classification'), event_component',...
    cell2mat(event_vx_max'), cell2mat(event_vx_mean'), cell2mat(event_vy_max'), cell2mat(event_vy_mean'), cell2mat(event_vz_max'), cell2mat(event_vz_mean'), cell2mat(event_vr_max'), cell2mat(event_vr_mean'),...
    cell2mat(event_x'), cell2mat(event_y'), cell2mat(event_z'), cell2mat(event_r'),...
    cell2mat(event_spacecraft'));
event_properties.Properties.VariableNames={'filename', 'start_date', 'end_date',...
    'duration', 'classification', 'component', 'vx_max', 'vx_mean', 'vy_max', 'vy_mean', 'vz_max', 'vz_mean', 'vr_max', 'vr_mean', 'x', 'y', 'z', 'r', 'spacecraft'};
end

%get the signed maximum absolute value
function signed_max_abs_val=get_signed_max_abs(data)
    data=data(~isnan(data));
    [~,max_abs_index]=max(abs(data));
    signed_max_abs_val=data(max_abs_index);
end

%get the mean location of the event
function location=get_location(ri)
    location=ri(~isnan(ri));
    location=mean(location);
end

function mean_val=get_mean(data)
    data=data(~isnan(data));
    mean_val=mean(data);
end