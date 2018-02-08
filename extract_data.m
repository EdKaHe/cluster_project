function extract_data(startdate, enddate)

%read paths
path=readtable('.\..\analysis\path.csv', 'Delimiter', ';');
full_data_dir=path.full_data_dir{1};
extracted_data_dir=path.extracted_data_dir{1};
irfu_dir=path.irfu_dir{1};

%Make function executable without input arguments
if nargin==0
    display('No input arguments are given! Default values are taken...')
    startdate=[2016, 01, 01]; %[yy mm dd]
    enddate=[2016, 12, 31]; %[yy mm dd]
elseif nargin==1
    display('Please enter start- and enddate! Process aborted...')
    return
elseif nargin>3
    display('Too many input arguments! Process aborted...') 
    return
end



%convert dates to datenumber objects
startdate_number=datenum(startdate);
enddate_number=datenum(enddate);

%generate array with all day between start- and enddate
time_period=startdate_number:enddate_number;





for id=1:numel(time_period)
    tic


    
    
    %convert each day to a date string
    date_number=time_period(id);
    date_string=datestr(date_number);
    
    %convert date to chars with leading zeros for numbers below 10
    date_year=sprintf('%02d',year(date_string));
    date_month=sprintf('%02d',month(date_string));
    date_day=sprintf('%02d',day(date_string));
    
    %search for the data directory from the specified date
    search_dir = [full_data_dir, '\\*', date_year, date_month, date_day, '*'];
    data_dir = dir(search_dir);
    data_dir = [full_data_dir, '\\', data_dir.name];
   
    %change to the data directory and set the relative path to the irfu
    %code directory
    cd(data_dir)
    if ~exist('subpath', 'var')
        subpath=genpath(irfu_dir);
        addpath(subpath);
    end
    
    
    %% PARAMETERS
    
    % Physical units:
    Units = irf_units();
    
    %Relevant spacecraft: (either integer 1-4 or array of integers, e.g.
    %[1, 3, 4])
    SC_hia = 2;
    SC_all = [1 2 3 4];
    
    %% READ/CALCULATE EPHIMERIS
    try
        % Rxyz [km -> RE]
        c_eval('[~,~,gseR?] = c_caa_var_get(''sc_r_xyz_gse__C?_CP_AUX_POSGSE_1M'');', SC_all);  % km
        c_eval('gsmR?=irf_gse2gsm(gseR?);', SC_all);
        c_eval('gsmR?=irf_abs(gsmR?);', SC_all); % With total value in last column,
        c_eval('gseR?=irf_abs(gseR?);', SC_all);
        c_eval('gseRE? = [gseR?(:,1), gseR?(:,2:end) / Units.RE*1000];');
        c_eval('gsmRE? = [gsmR?(:,1), gsmR?(:,2:end) / Units.RE*1000];');
        
        %% READ/CALCULATE CIS: V
        
        % V_hia [m/s]:
        c_eval('[~,~,gseVhia?]=c_caa_var_get(''velocity_gse__C?_CP_CIS_HIA_ONBOARD_MOMENTS'');', SC_hia);
        c_eval('gsmVhia?=irf_gse2gsm(gseVhia?);', SC_hia);
        c_eval('gsmVhia?=irf_abs(gsmVhia?);',SC_hia);
        c_eval('gseVhia?=irf_abs(gseVhia?);',SC_hia);
    catch
        continue
    end
    
    gsmVhia3=gsmVhia2;
    gseVhia3=gseVhia2;
    
    if isempty(gseVhia3) && isempty(gsmVhia3) %analyze data if velocity data is available
       gseVhia3=nan(size(gseRE3));
       gseVhia3(:,1)=gseRE3(:,1);
       gsmVhia3=nan(size(gseRE3));
       gsmVhia3(:,1)=gseRE3(:,1);
    end
    
    %resample timelines
    t_gseVhia3=gseVhia3(:,1); %reference timeline from velocity data of SC3
    t_gsmVhia3=gsmVhia3(:,1); %reference timeline from velocity data of SC3
    t_gseRE3=gseRE3(:,1);
    t_gsmRE3=gsmRE3(:,1);
    gseVhia3_res=gseVhia3(:,2:5); %actually not resampled since gseVhia3 is reference
    
    %resample gsm velocity if possible
    if size(gsmVhia3,1)>1
        %resample data if more than one datapoint is available
        gsmVhia3_res=interp1(t_gsmVhia3,gsmVhia3(:,2:5),t_gseVhia3);
    else
        %no resampling possible for a single datapoint
        gsmVhia3_res=gsmVhia3(:,2:5);
    end
    %resample gse coordinates if possible
    if size(gseRE3,1)>1
        %resample data if more than one datapoint is available
        gseRE3_res=interp1(t_gseRE3,gseRE3(:,2:5),t_gseVhia3);
    else
        %no resampling possible for a single datapoint
        gseRE3_res=gseRE3(:,2:5);
    end
    %resample gsm coordinates if possible
    if size(gsmRE3,1)>1
        %resample data if more than one datapoint is available
        gsmRE3_res=interp1(t_gsmRE3,gsmRE3(:,2:5),t_gseVhia3);
    else
        %no resampling possible for a single datapoint
        gsmRE3_res=gsmRE3(:,2:5);
    end
    
    %generate variables required for table dataformat
    date_number=datenum(irf_time(t_gseVhia3,'epoch>vector'));
    x_gseRE3=gseRE3_res(:,1);
    y_gseRE3=gseRE3_res(:,2);
    z_gseRE3=gseRE3_res(:,3);
    r_gseRE3=gseRE3_res(:,4);
    x_gsmRE3=gsmRE3_res(:,1);
    y_gsmRE3=gsmRE3_res(:,2);
    z_gsmRE3=gsmRE3_res(:,3);
    r_gsmRE3=gsmRE3_res(:,4);
    vx_gse3=gseVhia3_res(:,1);
    vy_gse3=gseVhia3_res(:,2);
    vz_gse3=gseVhia3_res(:,3);
    vr_gse3=gseVhia3_res(:,4);
    vx_gsm3=gsmVhia3_res(:,1);
    vy_gsm3=gsmVhia3_res(:,2);
    vz_gsm3=gsmVhia3_res(:,3);
    vr_gsm3=gsmVhia3_res(:,4);
    
    %create data table for spacecraft 3
    dt3=table(date_number, x_gseRE3, y_gseRE3, z_gseRE3, r_gseRE3,...
        x_gsmRE3, y_gsmRE3, z_gsmRE3, r_gsmRE3,...
        vx_gse3, vy_gse3, vz_gse3, vr_gse3,...
        vx_gsm3, vy_gsm3, vz_gsm3, vr_gsm3);
    
    %save table to character seperated value file
    if ~exist(extracted_data_dir,'dir')
        mkdir(extracted_data_dir);
    end
    writetable(dt3, [extracted_data_dir, '\\sc3_', date_year, date_month, date_day, '.csv'], 'Delimiter', ';')
    
    
    
    
    display(sprintf('*** Generating file %d/%d took %0.2fs ***', id, numel(time_period), toc))
end




%go back to initial directory
cd(full_data_dir)




end