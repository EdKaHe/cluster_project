function plot_events()

%read paths
path=readtable('.\..\analysis\path.csv', 'Delimiter', ';');

%set the paths
events.filepath=path.events_dir{1};
events.filename='events.csv';

%read the events table
events.table=readtable([events.filepath, '\\', events.filename], 'Delimiter', ';');
%sort rows after classification
events.table=sortrows(events.table, 'classification');
% %extract 2006
% start_date=datenum('01-Jan-06', 'dd-mmm-yy');
% end_date=datenum('31-Dec-06', 'dd-mmm-yy');
% events.table=events.table(events.table.start_date>=start_date & events.table.start_date<=end_date,:);
%change event duration from seconds to minutes
events.table.duration=events.table.duration/60;

%close all opened figures
close all

%Create figure
events.fig = figure('Visible','off');
events.fig.Position=[25,150,1020,640];

%Create the axes
events.ax = axes('Units','pixels');
%Style the axes
hold(events.ax, 'on')
events.ax.Box='on';
events.ax.XLabel.String='';%'Datetime';
events.ax.YLabel.String='Duration in (min)';
events.ax.FontSize=12;
twelve_weeks=12*7;
events.ax.XLim=[min(events.table.start_date)-twelve_weeks*0.05, min(events.table.start_date)+twelve_weeks*1.05];
events.ax.YLim=[min(events.table.duration)-0.05*(max(events.table.duration)-min(events.table.duration)), max(events.table.duration)+0.05*(max(events.table.duration-min(events.table.duration)))];
%change x-axis to date-axis
one_week=7;
events.ax.XTick=(min(events.table.start_date)-twelve_weeks*0.05:one_week:max(events.table.start_date)+twelve_weeks*0.05);
datetick(events.ax, 'x', 'dd-mmm-yy', 'keeplimits', 'keepticks')
events.ax.XTickLabelRotation=90;
%position the axes
events.ax.Position=[100, 125, 700, 420];
%style the grid
events.ax.XGrid='on';
events.ax.YGrid='on';

%show additional information
dcm = datacursormode(events.fig);
dcm.Enable='on';
dcm.UpdateFcn=@add_infobox;

%Create popup menu to select x-data
events.popup.xdata = uicontrol('Style', 'popup');
%style the popup menu
events.popup.xdata.String={'t', 'x', 'y', 'z', 'r'};
events.popup.xdata.Callback=@update_xdata;
events.popup.xdata.FontSize=10;
%position the popup menu
popup_xdata_width=200;
popup_xdata_height=50;
popup_xdata_xpos=events.ax.Position(1)+events.ax.Position(3)-popup_xdata_width;
popup_xdata_ypos=events.ax.Position(2)+events.ax.Position(4)-10;
events.popup.xdata.Position=[popup_xdata_xpos, popup_xdata_ypos, popup_xdata_width, popup_xdata_height];

%Create popup menu to select y-data
events.popup.ydata = uicontrol('Style', 'popup');
%style the popup menu
events.popup.ydata.String={'duration', 'v_max', 'v_mean', 'classification'};
events.popup.ydata.Callback=@update_ydata;
events.popup.ydata.FontSize=10;
%position the popup menu
popup_ydata_width=200;
popup_ydata_height=50;
popup_ydata_xpos=events.ax.Position(1)+events.ax.Position(3)+5;
popup_ydata_ypos=events.ax.Position(2)+events.ax.Position(4)-10;
events.popup.ydata.Position=[popup_ydata_xpos, popup_ydata_ypos, popup_ydata_width, popup_ydata_height];

%create a slider to go through data
events.slider.date = uicontrol('Style', 'slider');
events.slider.date.Min = 0;
events.slider.date.Max = max(events.table.start_date)-min(events.table.start_date)-twelve_weeks;
events.slider.date.SliderStep=[2/(max(events.table.start_date)-min(events.table.start_date)), 7/(max(events.table.start_date)-min(events.table.start_date))];
%position the slider
slider_date_width=events.ax.Position(3)-popup_ydata_width-20;
slider_date_height=popup_ydata_height/2;
slider_date_xpos=events.ax.Position(1);
slider_date_ypos=popup_ydata_ypos+popup_ydata_height/2;
events.slider.date.Position=[slider_date_xpos, slider_date_ypos, slider_date_width, slider_date_height];
%update slider continuosly
addlistener(events.slider.date, 'Value', 'PostSet', @update_date);

%create textboxes for duration
events.text.duration=uicontrol('Style', 'text');
events.text.duration.String='duration in (min)';
events.text.duration.HorizontalAlignment='left';
%position the textbox
text_duration_width=popup_ydata_width/2;
text_duration_height=slider_date_height;
text_duration_xpos=events.ax.Position(1)+events.ax.Position(3)+5;
text_duration_ypos=events.ax.Position(2)+events.ax.Position(4)-text_duration_height;
events.text.duration.Position=[text_duration_xpos, text_duration_ypos, text_duration_width, text_duration_height];

%create a editable textbox to set minimum value of duration
events.edit.min_duration=uicontrol('Style', 'edit');
events.edit.min_duration.String=num2str(min(events.table.duration)); 
events.edit.min_duration.Callback=@filter_data;
%position the textbox
edit_min_duration_width=popup_ydata_width/2;
edit_min_duration_height=slider_date_height;
edit_min_duration_xpos=text_duration_xpos;
edit_min_duration_ypos=text_duration_ypos-edit_min_duration_height+10;
events.edit.min_duration.Position=[edit_min_duration_xpos, edit_min_duration_ypos, edit_min_duration_width, edit_min_duration_height];

%create a editable textbox to set maximum value of duration
events.edit.max_duration=uicontrol('Style', 'edit');
events.edit.max_duration.String=num2str(max(events.table.duration)); 
events.edit.max_duration.Callback=@filter_data;
%position the textbox
edit_max_duration_width=popup_ydata_width/2;
edit_max_duration_height=slider_date_height;
edit_max_duration_xpos=text_duration_xpos+edit_max_duration_width+5;
edit_max_duration_ypos=text_duration_ypos-edit_min_duration_height+10;
events.edit.max_duration.Position=[edit_max_duration_xpos, edit_max_duration_ypos, edit_max_duration_width, edit_max_duration_height];

%create textboxes for v_max
events.text.v_max=uicontrol('Style', 'text');
events.text.v_max.String='v_max in (km/s)';
events.text.v_max.HorizontalAlignment='left';
%position the textbox
text_v_max_width=popup_ydata_width/2;
text_v_max_height=slider_date_height;
text_v_max_xpos=events.ax.Position(1)+events.ax.Position(3)+5;
text_v_max_ypos=edit_max_duration_ypos-text_v_max_height-10;
events.text.v_max.Position=[text_v_max_xpos, text_v_max_ypos, text_v_max_width, text_v_max_height];

%create a editable textbox to set minimum value of v_max
events.edit.min_v_max=uicontrol('Style', 'edit');
events.edit.min_v_max.String=num2str(min(events.table.v_max)); 
events.edit.min_v_max.Callback=@filter_data;
%position the textbox
edit_min_v_max_width=popup_ydata_width/2;
edit_min_v_max_height=slider_date_height;
edit_min_v_max_xpos=text_v_max_xpos;
edit_min_v_max_ypos=text_v_max_ypos-edit_min_v_max_height+10;
events.edit.min_v_max.Position=[edit_min_v_max_xpos, edit_min_v_max_ypos, edit_min_v_max_width, edit_min_v_max_height];

%create a editable textbox to set maximum value of v_max
events.edit.max_v_max=uicontrol('Style', 'edit');
events.edit.max_v_max.String=num2str(max(events.table.v_max)); 
events.edit.max_v_max.Callback=@filter_data;
%position the textbox
edit_max_v_max_width=popup_ydata_width/2;
edit_max_v_max_height=slider_date_height;
edit_max_v_max_xpos=text_v_max_xpos+edit_max_v_max_width+5;
edit_max_v_max_ypos=text_v_max_ypos-edit_min_v_max_height+10;
events.edit.max_v_max.Position=[edit_max_v_max_xpos, edit_max_v_max_ypos, edit_max_v_max_width, edit_max_v_max_height];

%create textboxes for v_mean
events.text.v_mean=uicontrol('Style', 'text');
events.text.v_mean.String='v_mean in (km/s)';
events.text.v_mean.HorizontalAlignment='left';
%position the textbox
text_v_mean_width=popup_ydata_width/2;
text_v_mean_height=slider_date_height;
text_v_mean_xpos=events.ax.Position(1)+events.ax.Position(3)+5;
text_v_mean_ypos=edit_max_v_max_ypos-text_v_mean_height-10;
events.text.v_mean.Position=[text_v_mean_xpos, text_v_mean_ypos, text_v_mean_width, text_v_mean_height];

%create a editable textbox to set minimum value of v_mean
events.edit.min_v_mean=uicontrol('Style', 'edit');
events.edit.min_v_mean.String=num2str(min(events.table.v_mean)); 
events.edit.min_v_mean.Callback=@filter_data;
%position the textbox
edit_min_v_mean_width=popup_ydata_width/2;
edit_min_v_mean_height=slider_date_height;
edit_min_v_mean_xpos=text_v_mean_xpos;
edit_min_v_mean_ypos=text_v_mean_ypos-edit_min_v_mean_height+10;
events.edit.min_v_mean.Position=[edit_min_v_mean_xpos, edit_min_v_mean_ypos, edit_min_v_mean_width, edit_min_v_mean_height];

%create a editable textbox to set maximum value of v_mean
events.edit.max_v_mean=uicontrol('Style', 'edit');
events.edit.max_v_mean.String=num2str(max(events.table.v_mean)); 
events.edit.max_v_mean.Callback=@filter_data;
%position the textbox
edit_max_v_mean_width=popup_ydata_width/2;
edit_max_v_mean_height=slider_date_height;
edit_max_v_mean_xpos=text_v_mean_xpos+edit_max_v_mean_width+5;
edit_max_v_mean_ypos=text_v_mean_ypos-edit_max_v_mean_height+10;
events.edit.max_v_mean.Position=[edit_max_v_mean_xpos, edit_max_v_mean_ypos, edit_max_v_mean_width, edit_max_v_mean_height];

%create textboxes for classification
events.text.classification=uicontrol('Style', 'text');
events.text.classification.String='classification';
events.text.classification.HorizontalAlignment='left';
%position the textbox
text_classification_width=popup_ydata_width/2;
text_classification_height=slider_date_height;
text_classification_xpos=events.ax.Position(1)+events.ax.Position(3)+5;
text_classification_ypos=edit_max_v_mean_ypos-text_classification_height-10;
events.text.classification.Position=[text_classification_xpos, text_classification_ypos, text_classification_width, text_classification_height];

%create a editable textbox to set minimum value of classification
events.edit.min_classification=uicontrol('Style', 'edit');
events.edit.min_classification.String=num2str(min(events.table.classification));
events.edit.min_classification.Callback=@filter_data;
%position the textbox
edit_min_classification_width=popup_ydata_width/2;
edit_min_classification_height=slider_date_height;
edit_min_classification_xpos=text_classification_xpos;
edit_min_classification_ypos=text_classification_ypos-edit_min_classification_height+10;
events.edit.min_classification.Position=[edit_min_classification_xpos, edit_min_classification_ypos, edit_min_classification_width, edit_min_classification_height];

%create a editable textbox to set maximum value of classification
events.edit.max_classification=uicontrol('Style', 'edit');
events.edit.max_classification.String=num2str(max(events.table.classification));
events.edit.max_classification.Callback=@filter_data;
%position the textbox
edit_max_classification_width=popup_ydata_width/2;
edit_max_classification_height=slider_date_height;
edit_max_classification_xpos=text_classification_xpos+edit_max_classification_width+5;
edit_max_classification_ypos=text_classification_ypos-edit_max_classification_height+10;
events.edit.max_classification.Position=[edit_max_classification_xpos, edit_max_classification_ypos, edit_max_classification_width, edit_max_classification_height];

%create textboxes for classification
events.text.total_events=uicontrol('Style', 'text');
events.text.total_events.String=sprintf('Total events: %0.0f', numel(events.table.start_date(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String))));
events.text.total_events.HorizontalAlignment='left';
events.text.total_events.FontWeight='Bold';
events.text.total_events.FontSize=10;
%position the textbox
text_total_events_width=popup_ydata_width;
text_total_events_height=slider_date_height;
text_total_events_xpos=events.ax.Position(1)+events.ax.Position(3)+5;
text_total_events_ypos=edit_max_classification_ypos-text_total_events_height-20;
events.text.total_events.Position=[text_total_events_xpos, text_total_events_ypos, text_total_events_width, text_total_events_height];

%set the data for plot
xdata=events.table.start_date(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String));
ydata=events.table.duration(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String));
cdata=events.table.classification(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String));
%plot the data
events.plot=scatter(xdata, ydata, 'filled');
%style the plot
events.plot.SizeData=50;
events.plot.CData=create_colormap(cdata);
events.plot.LineWidth=2;
events.plot.MarkerFaceAlpha=0.4;




%make figure visible after adding all features
events.fig.Visible='on';

    %create a colormap with a classification dependent coloring
    function cmap=create_colormap(classification)
        cmap=zeros(numel(classification),3);
        cmap(classification==1,:)=ones(size(classification(classification==1)))*[0.95,0.95,0];
        cmap(classification==2,:)=ones(size(classification(classification==2)))*[1,0.6,0];
        cmap(classification==3,:)=ones(size(classification(classification==3)))*[0.75,0,0];
    end

    %add information box when datapoint is clicked
    function textbox=add_infobox(empty,click_event)
        %get the position clicked on
        position = click_event.Position;
        
        %find the additional data
        current_xdata=events.popup.xdata.String(events.popup.xdata.Value);
        current_xdata=current_xdata{1};
        current_ydata=events.popup.ydata.String(events.popup.ydata.Value);
        current_ydata=current_ydata{1};

        event_index=find(events.table.(current_xdata)==position(1) & events.table.(current_ydata)==position(2));

        %if the same event exist twice, delete the one that belongs to vr
        if numel(event_index)>1
            event_index=event_index(find(~ismember(events.table.component(event_index),'vr')));
        end
        %get the data of the event clicked on
        start_date=events.table.start_date(event_index);
        end_date=events.table.end_date(event_index);
        duration=events.table.duration(event_index);
        classification=events.table.classification(event_index);
        component=events.table.component(event_index);
        v_max=events.table.v_max(event_index);
        v_mean=events.table.v_mean(event_index);

        %format the component
        component=strsplit(component{1}, 'v');
        component=sprintf('v_%s', component{2});
        
        %create the textbox
        textbox = {sprintf('Startdate: %s', datestr(start_date, 'dd-mmm-yy HH:MM:SS')),...
            sprintf('Enddate: %s', datestr(end_date, 'dd-mmm-yy HH:MM:SS')),...
            sprintf('Duration: %0.2f min', duration),...
            sprintf('v_max: %0.0f km/s', v_max),...
            sprintf('v_mean: %0.0f km/s', v_mean),...
            sprintf('Classification: %d', classification),...
            sprintf('Component: %s', component)};
    end

    function update_xdata(source,event)
        %get the selected date from the user selection
        selection_string=source.String(source.Value); 
        selection_string=selection_string{1};
        
        switch selection_string
            case 't'
                %update the plot data
                xdata=events.table.start_date(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String));
                events.plot.XData=xdata;
                %restyl the axis
                events.ax.XLabel.String='';
                twelve_weeks=12*7;
                events.ax.XLim=[min(events.table.start_date)-twelve_weeks*0.05, min(events.table.start_date)+twelve_weeks*1.05];
                %change x-axis to date-axis
                one_week=7;
                events.ax.XTick=(min(events.table.start_date)-twelve_weeks*0.05:one_week:max(events.table.start_date)+twelve_weeks*0.05);
                datetick(events.ax, 'x', 'dd-mmm-yy', 'keeplimits', 'keepticks')
                events.ax.XTickLabelRotation=90;
                %make the slider visible
                events.slider.date.Visible='on';
            case 'x'
                %reset the axis
                events.ax.XTickMode='auto';
                events.ax.XTickLabelMode='auto';
                %update the plot data
                xdata=events.table.x(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String));
                events.plot.XData=xdata;
                %restyle the axis
                events.ax.XLim=[-22 22];
                events.ax.XLabel.String='x in (r_{E})';
                %make the slider invisible
                events.slider.date.Visible='off';
            case 'y'
                %reset the axis
                events.ax.XTickMode='auto';
                events.ax.XTickLabelMode='auto';
                %update the plot data
                xdata=events.table.y(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String));
                events.plot.XData=xdata;
                %restyle the axis
                events.ax.XLim=[-22 22];
                events.ax.XLabel.String='y in (r_{E})';
                %make the slider invisible
                events.slider.date.Visible='off';
            case 'z'
                %reset the axis
                events.ax.XTickMode='auto';
                events.ax.XTickLabelMode='auto';
                %update the plot data
                xdata=events.table.z(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String));
                events.plot.XData=xdata;
                %restyle the axis
                events.ax.XLim=[-22 22];
                events.ax.XLabel.String='z in (r_{E})';
                %make the slider invisible
                events.slider.date.Visible='off';
            case 'r'
                %reset the axis
                events.ax.XTickMode='auto';
                events.ax.XTickLabelMode='auto';
                %update the plot data
                xdata=events.table.r(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String));
                events.plot.XData=xdata;
                %restyle the axis
                events.ax.XLim=[-22 22];
                events.ax.XLabel.String='r in (r_{E})';
                %make the slider invisible
                events.slider.date.Visible='off';
            otherwise
                return
        end
    end

    function update_ydata(source,event)
        %get the selected date from the user selection
        selection_string=source.String(source.Value); 
        selection_string=selection_string{1};
        
        switch selection_string
            case 'duration'
                %update the plot data
                ydata=events.table.duration(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String));
                events.plot.YData=ydata;
                %restyle the axis
                events.ax.YLim=[min(ydata)-0.05*(max(ydata)-min(ydata)), max(ydata)+0.05*max((ydata-min(ydata)))];
                events.ax.YLabel.String='Duration in (min)';
            case 'v_max'
                %update the plot data
                ydata=events.table.v_max(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String));
                events.plot.YData=ydata;
                %restyle the axis
                events.ax.YLim=[min(ydata)-0.05*(max(ydata)-min(ydata)), max(ydata)+0.05*max((ydata-min(ydata)))];
                events.ax.YLabel.String='v_{max} in (km/s)';
            case 'v_mean'
                %update the plot data
                ydata=events.table.v_mean(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String));
                events.plot.YData=ydata;
                %restyle the axis
                events.ax.YLim=[min(ydata)-0.05*(max(ydata)-min(ydata)), max(ydata)+0.05*max((ydata-min(ydata)))];
                events.ax.YLabel.String='v_{mean} in (km/s)';
            case 'classification'
                %update the plot data
                ydata=events.table.classification(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String));
                events.plot.YData=ydata;
                %restyle the axis
                events.ax.YLim=[min(ydata)-0.05*(max(ydata)-min(ydata)), max(ydata)+0.05*max((ydata-min(ydata)))];
                events.ax.YLabel.String='Classification';
            otherwise
                return
        end
    end

    function update_date(source, event)
        %calculate the index set by the slider value
        date_shift=event.AffectedObject.Value;
        events.ax.XLim=[min(events.table.start_date)+date_shift-twelve_weeks*0.05, min(events.table.start_date)+date_shift+twelve_weeks*1.05];
    end



    function filter_data(source, event)
        %change the displayed number of total events
        events.text.total_events.String=sprintf('Total events: %0.0f', numel(events.table.start_date(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String))));
        
        %get the selected date from the user selection
        selection_xdata=events.popup.xdata.String(events.popup.xdata.Value);
        selection_xdata=selection_xdata{1};
        selection_ydata=events.popup.ydata.String(events.popup.ydata.Value);
        selection_ydata=selection_ydata{1};
        
        %set c-data
        cdata=create_colormap(events.table.classification);
        
        %select the correct x-data
        switch selection_xdata
            case 't'
                xdata=events.table.start_date;
            case 'x'
                xdata=events.table.x;
            case 'y'
                xdata=events.table.y;
            case 'z'
                xdata=events.table.z;
            case 'r'
                xdata=events.table.r;
            otherwise
                return
        end
        
        %select the correct y-data
        switch selection_ydata
            case 'duration'
                ydata=events.table.duration;
            case 'v_max'
                ydata=events.table.v_max;
            case 'v_mean'
                ydata=events.table.v_mean;
            case 'classification'
                ydata=events.table.classification;
            otherwise
                return
        end
        
        %get data that meets conditions
        try
            xdata=xdata(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String));
            ydata=ydata(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String));
            cdata=cdata(events.table.duration>=str2double(events.edit.min_duration.String) & events.table.duration<=str2double(events.edit.max_duration.String) & events.table.v_max<=str2double(events.edit.max_v_max.String) & events.table.v_max>=str2double(events.edit.min_v_max.String) & events.table.v_mean<=str2double(events.edit.max_v_mean.String) & events.table.v_mean>=str2double(events.edit.min_v_mean.String) & events.table.classification<=str2double(events.edit.max_classification.String) & events.table.classification>=str2double(events.edit.min_classification.String),:);
        catch
            return
        end
        %update the plot data
        [events.plot.XData, events.plot.YData, events.plot.CData]=deal(xdata, ydata, cdata);
        %restyle the axis
        try
            events.ax.YLim=[min(ydata)-0.05*(max(ydata)-min(ydata)), max(ydata)+0.05*max((ydata-min(ydata)))];
        catch
            return
        end
    end



end