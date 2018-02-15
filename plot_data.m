function plot_data()
close all

%read paths
path=readtable('.\..\analysis\path.csv', 'Delimiter', ';');

%define all data paths and names
data.filepath = path.extracted_data_dir{1};
data.filename = dir([data.filepath, '\\', '*.csv']);
data.filename = {data.filename.name};
%get dates from data filenames in format yy/mm/dd
for file=1:numel(data.filename)
    dataname_split=strsplit(data.filename{file},'_');
    data.filedate{file}=datenum(dataname_split{2}, 'yyyymmdd');
end
data.filedate=cell2mat(data.filedate);
%read the date to a data table
data.table = readtable([data.filepath, '\\', data.filename{35}], 'Delimiter', ';');

%change all zeros (no event) to nans
data.table.vx_events(data.table.vx_events==0)=nan;
data.table.vy_events(data.table.vy_events==0)=nan;
data.table.vz_events(data.table.vz_events==0)=nan;
data.table.vr_events(data.table.vr_events==0)=nan;




%define all meta paths and names
meta.filepath = path.meta_data_dir{1};
meta.filename = 'meta.csv';
%read the meta data
meta.table = readtable([meta.filepath, '\\', meta.filename], 'Delimiter', ';');




%Create plasma figure
plasma.fig = figure('Visible','off');
plasma.fig.Position=[25,150,600,450];

%Create the plasma axes
plasma.ax = axes('Units','pixels');
%Style the plasma axes
hold(plasma.ax, 'on')
plasma.ax.Box='on';
plasma.ax.XLabel.String='t in (hh:mm)';
plasma.ax.YLabel.String='v_{gsm} in (km/s)';
plasma.ax.FontSize=12;
if ~isnan(min([data.table.vx_gsm3', data.table.vy_gsm3', data.table.vz_gsm3'])) && ~isnan(max(data.table.vr_gsm3))
    plasma.ax.YLim=[1.1*min([data.table.vx_gsm3', data.table.vy_gsm3', data.table.vz_gsm3']), 1.1*max(data.table.vr_gsm3)];
end
%change x-axis to date-axis
four_hours=240/(60*24);
plasma.ax.XTick=(data.table.date_number(1):four_hours:data.table.date_number(end));
datetick(plasma.ax, 'x', 'HH:MM', 'keeplimits', 'keepticks')
%position the axes
plasma.ax.Position=[75, 75, 450, 320];
%style the grid
plasma.ax.XGrid='on';
plasma.ax.YGrid='on';


%highlight the bbf events in plasma plot
plasma.plot.c3=highlight_event(data.table,plasma.ax,3);
plasma.plot.c2=highlight_event(data.table,plasma.ax,2);
plasma.plot.c1=highlight_event(data.table,plasma.ax,1);

%create the timeline
plasma.plot.timeline=plot(plasma.ax, [data.table.date_number(1), data.table.date_number(1)], plasma.ax.YLim);
%style the timeline
plasma.plot.timeline.LineWidth=5;
plasma.plot.timeline.Color=[0.85,0.85,0.85];
plasma.plot.timeline.LineStyle='-';

%plot the plasma data
plasma.plot.vx=plot(plasma.ax, data.table.date_number, data.table.vx_gsm3);
plasma.plot.vy=plot(plasma.ax, data.table.date_number, data.table.vy_gsm3);
plasma.plot.vz=plot(plasma.ax, data.table.date_number, data.table.vz_gsm3);
plasma.plot.vr=plot(plasma.ax, data.table.date_number, data.table.vr_gsm3);
%style the plasma plot
plasma.plot.vx.LineWidth=2;
plasma.plot.vx.Color=[1,0,0];
plasma.plot.vx.LineStyle='-';
plasma.plot.vy.LineWidth=2;
plasma.plot.vy.Color=[0,1,0];
plasma.plot.vy.LineStyle='-';
plasma.plot.vz.LineWidth=2;
plasma.plot.vz.Color=[0,0,1];
plasma.plot.vz.LineStyle='-';
plasma.plot.vr.LineWidth=2;
plasma.plot.vr.Color=[0,0,0];
plasma.plot.vr.LineStyle='-';
%style the legend
plasma.plot.legend=legend(plasma.ax, [plasma.plot.vx, plasma.plot.vy, plasma.plot.vz, plasma.plot.vr], {'v_x', 'v_y', 'v_z', 'v_r'},...
    'FontSize', 12, 'Orientation', 'Horizontal');
plasma.plot.legend.BoxFace.ColorType='truecoloralpha';
plasma.plot.legend.BoxFace.ColorData=uint8([255,255,255,200]');
%add callbacks
plasma.plot.vx.ButtonDownFcn=@line_selected;
plasma.plot.vy.ButtonDownFcn=@line_selected;
plasma.plot.vz.ButtonDownFcn=@line_selected;
plasma.plot.vr.ButtonDownFcn=@line_selected;




%Create popup menu
plasma.popup_date = uicontrol('Style', 'popup');
%style the popup menu
plasma.popup_date.String=generate_popup_string();
plasma.popup_date.Callback=@update_data;
plasma.popup_date.FontSize=10;
%position the popup menu
popup_date_width=150;
popup_date_height=50;
popup_date_xpos=plasma.ax.Position(1)+plasma.ax.Position(3)-popup_date_width;
popup_date_ypos=plasma.ax.Position(2)+plasma.ax.Position(4)-10;
plasma.popup_date.Position=[popup_date_xpos, popup_date_ypos, popup_date_width, popup_date_height];




%Create slider
plasma.slider_time = uicontrol('Style', 'slider');
plasma.slider_time.Min = 0;
plasma.slider_time.Max = numel(data.table.date_number);
plasma.slider_time.SliderStep=[1/150, 1/25];
% plasma.slider_time.Callback=@update_time;
%position the slider
slider_time_width=plasma.ax.Position(3)-popup_date_width-20;
slider_time_height=popup_date_height/2;
slider_time_xpos=plasma.ax.Position(1);
slider_time_ypos=popup_date_ypos+popup_date_height/2;
plasma.slider_time.Position=[slider_time_xpos, slider_time_ypos, slider_time_width, slider_time_height];
%update slider continuosly
addlistener(plasma.slider_time, 'Value', 'PostSet', @update_time);




%Create space figure
location.fig = figure('Visible','off');
location.fig.Position=[650,150,900,450];

%Create the time axes
location.time.ax = axes('Units','pixels');
%Style the time axes
hold(location.time.ax, 'on')
location.time.ax.Box='on';
location.time.ax.XLabel.String='t in (hh:mm)';
location.time.ax.YLabel.String='r_{gsm} in (R_{E})';
location.time.ax.FontSize=12;
if ~isnan(min([data.table.x_gsmRE3', data.table.y_gsmRE3', data.table.z_gsmRE3'])) && ~isnan(max(data.table.r_gsmRE3))
    location.time.ax.YLim=[1.1*min([data.table.x_gsmRE3', data.table.y_gsmRE3', data.table.z_gsmRE3']),...
        1.1*max(data.table.r_gsmRE3)];
end
%change x-axis to date-axis
four_hours=240/(60*24);
location.time.ax.XTick=(data.table.date_number(1):four_hours:data.table.date_number(end));
datetick(location.time.ax, 'x', 'HH:MM', 'keeplimits', 'keepticks')
%position the axes
location.time.ax.Position=[75, 75, 350, 320];
%style the grid
location.time.ax.XGrid='on';
location.time.ax.YGrid='on';
%link the location.time and plasma axes
linkaxes([location.time.ax, plasma.ax], 'x');

%create the timeline
location.time.plot.timeline=plot(location.time.ax, [data.table.date_number(1), data.table.date_number(1)], location.time.ax.YLim);
%style the timeline
location.time.plot.timeline.LineWidth=5;
location.time.plot.timeline.Color=[0.85,0.85,0.85];
location.time.plot.timeline.LineStyle='-';

%highlight the bbf events in location plot
location.time.plot.c3=highlight_event(data.table,location.time.ax,3);
location.time.plot.c2=highlight_event(data.table,location.time.ax,2);
location.time.plot.c1=highlight_event(data.table,location.time.ax,1);

%plot the location.time data
location.time.plot.x=plot(location.time.ax, data.table.date_number, data.table.x_gsmRE3);
location.time.plot.y=plot(location.time.ax, data.table.date_number, data.table.y_gsmRE3);
location.time.plot.z=plot(location.time.ax, data.table.date_number, data.table.z_gsmRE3);
location.time.plot.r=plot(location.time.ax, data.table.date_number, data.table.r_gsmRE3);
%style the location.time plot
location.time.plot.x.LineWidth=2;
location.time.plot.x.Color=[1,0,0];
location.time.plot.x.LineStyle='-';
location.time.plot.y.LineWidth=2;
location.time.plot.y.Color=[0,1,0];
location.time.plot.y.LineStyle='-';
location.time.plot.z.LineWidth=2;
location.time.plot.z.Color=[0,0,1];
location.time.plot.z.LineStyle='-';
location.time.plot.r.LineWidth=2;
location.time.plot.r.Color=[0,0,0];
location.time.plot.r.LineStyle='-';
%style the legend
location.time.plot.legend=legend(location.time.ax, [location.time.plot.x, location.time.plot.y, location.time.plot.z, location.time.plot.r], {'x', 'y', 'z', 'r'},...
    'FontSize', 12, 'Orientation', 'Horizontal');
location.time.plot.legend.BoxFace.ColorType='truecoloralpha';
location.time.plot.legend.BoxFace.ColorData=uint8([255,255,255,200]');
%add callbacks
location.time.plot.x.ButtonDownFcn=@line_selected;
location.time.plot.y.ButtonDownFcn=@line_selected;
location.time.plot.z.ButtonDownFcn=@line_selected;
location.time.plot.r.ButtonDownFcn=@line_selected;

%Create the space axes
location.space.ax = axes('Units','pixels');
%Position the space axes
location.space.ax.Position = [500, 75, 350, 320];
%style the space axes
hold(location.space.ax, 'on');
location.space.ax.DataAspectRatio=[1,1,1];
location.space.ax.Box='on';
location.space.ax.XLabel.String='x_{gsm} in (R_{E})';
location.space.ax.YLabel.String='y_{gsm} in (R_{E})';
location.space.ax.ZLabel.String='z_{gsm} in (R_{E})';
location.space.ax.FontSize=12;
location.space.ax.View=[180, 90];
location.space.ax.XLim=[-20,20];
location.space.ax.YLim=[-20,20];
location.space.ax.ZLim=[-20,20];
%style the grid
location.space.ax.XGrid='on';
location.space.ax.YGrid='on';
location.space.ax.ZGrid='on';

%get earth coordinates
[x_earth, y_earth, z_earth] = sphere(10);
%plot the earth
location.space.plot.earth=surf(location.space.ax, x_earth, y_earth, z_earth);
%style the earth
location.space.plot.earth.FaceColor=[1,1,1];
location.space.plot.earth.FaceAlpha=0.9;
location.space.plot.earth.EdgeColor=[0,0,0];
location.space.plot.earth.EdgeAlpha=0.9;

%define borders of equatorial plane
xlim=location.space.ax.XLim;
ylim=location.space.ax.YLim;
x_eq=[xlim(1), xlim(1), xlim(2), xlim(2)];
y_eq=[ylim(1), ylim(2), ylim(1), ylim(2)];
z_eq=zeros(4);
[x_eq, y_eq] = meshgrid(x_eq,y_eq);
%plot equatorial plane
location.space.plot.equator=surf(location.space.ax, x_eq, y_eq, z_eq);
%style the equatorial plane
location.space.plot.equator.FaceColor=[1,1,1];
location.space.plot.equator.FaceAlpha=0.5;
location.space.plot.equator.EdgeAlpha=0;

%define borders of meridian plane
ylim=location.space.ax.YLim;
zlim=location.space.ax.ZLim;
x_eq=zeros(4);
y_eq=[ylim(1), ylim(2), ylim(1), ylim(2)];
z_eq=[zlim(1), zlim(1), zlim(2), zlim(2)];
[y_eq, z_eq] = meshgrid(y_eq,z_eq);
%plot meridian plane
location.space.plot.meridian=surf(location.space.ax, x_eq, y_eq, z_eq);
%style the equatorial plane
location.space.plot.meridian.FaceColor=[1,1,1];
location.space.plot.meridian.FaceAlpha=0.5;
location.space.plot.meridian.EdgeAlpha=0;

%plot the orbit
location.space.plot.orbit=plot3(location.space.ax,data.table.x_gsmRE3,data.table.y_gsmRE3,data.table.z_gsmRE3);
%style the orbit
location.space.plot.orbit.LineWidth=3;
location.space.plot.orbit.Color=[0.5,0.5,0.5];
location.space.plot.orbit.LineStyle='-';

%plot the events on the orbit
events=data.table.vr_events;
location.space.plot.c1=plot3(location.space.ax,nan,nan,nan);
[location.space.plot.c1.XData, location.space.plot.c1.YData, location.space.plot.c1.ZData]=deal(data.table.x_gsmRE3(events==1), data.table.y_gsmRE3(events==1), data.table.z_gsmRE3(events==1));
%style the events
location.space.plot.c1.LineStyle='none';
location.space.plot.c1.Color=[0.95,0.95,0.0];
location.space.plot.c1.Marker='o';
location.space.plot.c1.MarkerSize=5;
location.space.plot.c1.MarkerFaceColor=[0.95,0.95,0];

%plot the events on the orbit
events=data.table.vr_events;
location.space.plot.c2=plot3(location.space.ax,nan,nan,nan);
[location.space.plot.c2.XData, location.space.plot.c2.YData, location.space.plot.c2.ZData]=deal(data.table.x_gsmRE3(events==2), data.table.y_gsmRE3(events==2), data.table.z_gsmRE3(events==2));
%style the events
location.space.plot.c2.LineStyle='none';
location.space.plot.c2.Color=[1,0.6,0];
location.space.plot.c2.Marker='o';
location.space.plot.c2.MarkerSize=5;
location.space.plot.c2.MarkerFaceColor=[1,0.6,0];

%plot the events on the orbit
events=data.table.vr_events;
location.space.plot.c3=plot3(location.space.ax,nan,nan,nan);
[location.space.plot.c3.XData, location.space.plot.c3.YData, location.space.plot.c3.ZData]=deal(data.table.x_gsmRE3(events==3), data.table.y_gsmRE3(events==3), data.table.z_gsmRE3(events==3));
%style the events
location.space.plot.c3.LineStyle='none';
location.space.plot.c3.Color=[0.75,0,0];
location.space.plot.c3.Marker='o';
location.space.plot.c3.MarkerSize=5;
location.space.plot.c3.MarkerFaceColor=[0.75,0,0];

%plot the satellite
[x_sat, y_sat, z_sat] = sphere(20);
radius=0.5;
%plot the earth
location.space.plot.sat=surf(location.space.ax, x_sat*radius+data.table.x_gsmRE3(1), y_sat*radius+data.table.y_gsmRE3(1), z_sat*radius+data.table.z_gsmRE3(1));
%style the earth
location.space.plot.sat.FaceColor=[1,0,0];
location.space.plot.sat.FaceAlpha=0.9;
location.space.plot.sat.EdgeAlpha=0;





    function update_data(source,event)
        
        %get the selected date from the user selection
        str=source.String;
        val=source.Value;
        
        for date=1:numel(str)
            %check whether the filename matches the selected date
            if ~isempty(strfind(data.filename{date}, datestr(data.filedate(val), 'yymmdd')))
                %read new data from selected date
                data.table = readtable([data.filepath, '\\', data.filename{date}], 'Delimiter', ';');
                
                %adjust the slider range
                plasma.slider_time.Value = 0;
                plasma.slider_time.Max = numel(data.table.date_number);
                
                %update location.time plot
                four_hours=240/(60*24);
                location.time.ax.XTick=(min(data.table.date_number):four_hours:max(data.table.date_number(end)));
                if min(data.table.date_number)~=max(data.table.date_number)
                    location.time.ax.XLim=[min(data.table.date_number), max(data.table.date_number)];
                end
                if ~isnan(min([data.table.x_gsmRE3', data.table.y_gsmRE3', data.table.z_gsmRE3'])) && ~isnan(max(data.table.r_gsmRE3))
                    location.time.ax.YLim=[1.1*min([data.table.x_gsmRE3', data.table.y_gsmRE3', data.table.z_gsmRE3']), 1.1*max(data.table.r_gsmRE3)];
                end
                datetick(location.time.ax, 'x', 'HH:MM', 'keeplimits', 'keepticks')
                %update the location and time data
                [location.time.plot.x.XData, location.time.plot.x.YData]=deal(data.table.date_number, data.table.x_gsmRE3);
                [location.time.plot.y.XData, location.time.plot.y.YData]=deal(data.table.date_number, data.table.y_gsmRE3);
                [location.time.plot.z.XData, location.time.plot.z.YData]=deal(data.table.date_number, data.table.z_gsmRE3);
                [location.time.plot.r.XData, location.time.plot.r.YData]=deal(data.table.date_number, data.table.r_gsmRE3);
                %highlight the events in the satellite orbit
                events=data.table.vr_events;
                [location.space.plot.c1.XData, location.space.plot.c1.YData, location.space.plot.c1.ZData]=deal(data.table.x_gsmRE3(events==1), data.table.y_gsmRE3(events==1), data.table.z_gsmRE3(events==1));
                [location.space.plot.c2.XData, location.space.plot.c2.YData, location.space.plot.c2.ZData]=deal(data.table.x_gsmRE3(events==2), data.table.y_gsmRE3(events==2), data.table.z_gsmRE3(events==2));
                [location.space.plot.c3.XData, location.space.plot.c3.YData, location.space.plot.c3.ZData]=deal(data.table.x_gsmRE3(events==3), data.table.y_gsmRE3(events==3), data.table.z_gsmRE3(events==3));
                %draw orbit of satellite
                [location.space.plot.orbit.XData, location.space.plot.orbit.YData, location.space.plot.orbit.ZData]=deal(data.table.x_gsmRE3, data.table.y_gsmRE3, data.table.z_gsmRE3);
                %draw satellite
                [location.space.plot.sat.XData, location.space.plot.sat.YData, location.space.plot.sat.ZData]=deal(x_sat*radius+data.table.x_gsmRE3(1), y_sat*radius+data.table.y_gsmRE3(1), z_sat*radius+data.table.z_gsmRE3(1));
                
                %update plasma plot
                %adjust axis to new dates
                four_hours=240/(60*24);
                plasma.ax.XTick=(data.table.date_number(1):four_hours:data.table.date_number(end));
                if min(data.table.date_number)~=max(data.table.date_number)
                    plasma.ax.XLim=[min(data.table.date_number), max(data.table.date_number)];
                end
                if ~isnan(min([data.table.vx_gsm3', data.table.vy_gsm3', data.table.vz_gsm3'])) && ~isnan(max(data.table.vr_gsm3))
                    plasma.ax.YLim=[1.1*min([data.table.vx_gsm3', data.table.vy_gsm3', data.table.vz_gsm3']), 1.1*max(data.table.vr_gsm3)];
                end
                datetick(plasma.ax, 'x', 'HH:MM', 'keeplimits', 'keepticks')
                
                %update the velocity data
                [plasma.plot.vx.XData, plasma.plot.vx.YData]=deal(data.table.date_number, data.table.vx_gsm3);
                [plasma.plot.vy.XData, plasma.plot.vy.YData]=deal(data.table.date_number, data.table.vy_gsm3);
                [plasma.plot.vz.XData, plasma.plot.vz.YData]=deal(data.table.date_number, data.table.vz_gsm3);
                [plasma.plot.vr.XData, plasma.plot.vr.YData]=deal(data.table.date_number, data.table.vr_gsm3);
             
                %check whether there are bbf events and update data
                data.table.vr_events(data.table.vr_events==0)=nan; %change all zeros (no event) to nans
                
                %highlight the bbf events in the location plot
                plasma.plot.c1.delete;
                plasma.plot.c2.delete;
                plasma.plot.c3.delete;
                plasma.plot.c3=highlight_event(data.table,plasma.ax,3);
                plasma.plot.c2=highlight_event(data.table,plasma.ax,2);
                plasma.plot.c1=highlight_event(data.table,plasma.ax,1);
                
                %highlight the bbf events in the location plot
                location.time.plot.c1.delete;
                location.time.plot.c2.delete;
                location.time.plot.c3.delete;
                location.time.c3=highlight_event(data.table,location.time.ax,3);
                location.time.c2=highlight_event(data.table,location.time.ax,2);
                location.time.c1=highlight_event(data.table,location.time.ax,1);
                
              
                
                
                %exit loop after loading the data
                break
            end
        end
    end




    function update_time(source, event)
        %prevent possible indices of 0
        if floor(event.AffectedObject.Value)==0
            event.AffectedObject.Value=1;
        end
        
        %calculate the index set by the slider value
        index=floor(event.AffectedObject.Value);
        plasma.plot.timeline.XData=[data.table.date_number(index), data.table.date_number(index)];
        plasma.plot.timeline.YData=plasma.ax.YLim;
        location.time.plot.timeline.XData=[data.table.date_number(index), data.table.date_number(index)];
        location.time.plot.timeline.YData=location.time.ax.YLim;
        [location.space.plot.sat.XData, location.space.plot.sat.YData, location.space.plot.sat.ZData]=deal(x_sat*radius+data.table.x_gsmRE3(index), y_sat*radius+data.table.y_gsmRE3(index), z_sat*radius+data.table.z_gsmRE3(index));
        
    end




    function [popup_string]=generate_popup_string()
        common_dates=ismember(meta.table.date_number, data.filedate);
        common_events_total=meta.table.events_total(common_dates);
        common_events_class=meta.table.events_class(common_dates);
        formatted_data=datestr(data.filedate, 'dd-mmm-yy');
        
        popup_string=cell(size(data.filedate));
        for event=1:numel(common_events_total)
            if common_events_total(event)>=1
                popup_string{event}=[formatted_data(event,:), sprintf(' (T%.1dC%.1d)', common_events_total(event), common_events_class(event))];
            else
                popup_string{event}=[formatted_data(event,:)];
            end
        end
    end





    %callback when line is clicked
    function line_selected(clicked_handle, event_data)
        if clicked_handle.LineWidth==2
            clicked_handle.Color=[clicked_handle.Color(1:3), 0.1];
            clicked_handle.LineWidth=1.8;  
            uistack(clicked_handle, 'bottom')
        elseif clicked_handle.LineWidth==1.8
            clicked_handle.Color=[clicked_handle.Color(1:3), 1];
            clicked_handle.LineWidth=2;
            uistack(clicked_handle, 'top')
        end
    end



    
    %filter events after their classification
    function filtered_events=filter_event(events, class)
        events(events~=class)=nan;
        filtered_events=events/class;
    end



    function caxis_area=highlight_event(data,caxis,class)
        %create the area
        caxis_area=area(caxis, data.date_number, max(caxis.YLim)*filter_event(data.vr_events, class));
        %style the area
        caxis_area.LineWidth=3;
        caxis_area.LineStyle=':';
        caxis_area.EdgeAlpha=0.6;
        caxis_area.FaceAlpha=0.6;
        caxis_area.BaseLine.BaseValue=min(caxis.YLim);
        
        %style the area dependent on the classification
        if class==1
            caxis_area.FaceColor=[0.95,0.95,0];
            caxis_area.EdgeColor=[0.95,0.95,0];
        elseif class==2
            caxis_area.FaceColor=[1,0.6,0];
            caxis_area.EdgeColor=[1,0.6,0];
        elseif class==3
            caxis_area.FaceColor=[0.75,0,0];
            caxis_area.EdgeColor=[0.75,0,0];
        end;
        
        uistack(caxis_area, 'bottom');
    end



%turn on visibility after creating all axes and controls
plasma.fig.Visible = 'on';
location.fig.Visible = 'on';




end