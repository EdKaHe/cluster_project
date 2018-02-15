function extract_events()

%read paths
path=readtable('.\..\analysis\path.csv', 'Delimiter', ';');

%define all data paths and names
data.filepath = path.extracted_data_dir{1};
data.filename = dir([data.filepath, '\\*.csv']);
data.filename = {data.filename.name};

%loop through all files in data.filepath directory
for file=1:numel(data.filename)
    tic %track time for each loop
    %extract filedate in new format
    dataname_split=strsplit(data.filename{file},'_');
    data.filedate{file}=datenum(dataname_split{2}, 'yyyymmdd');
    
    %load current data
    data.table = readtable([data.filepath, '\\', data.filename{file}], 'Delimiter', ';');
    
    [vx.filename, vx.start_date, vx.end_date, vx.duration, vx.classification]=get_properties(data.table);
    [vy.filename, vy.start_date, vy.end_date, vy.duration, vy.classification]=get_properties(data.table);
    [vz.filename, vz.start_date, vz.end_date, vz.duration, vz.classification]=get_properties(data.table);
    [vr.filename, vr.start_date, vr.end_date, vr.duration, vr.classification]=get_properties(data.table);
end

    function get_properties(data)
        
    end

end