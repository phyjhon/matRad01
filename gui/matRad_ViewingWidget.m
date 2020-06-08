classdef matRad_ViewingWidget < matRad_Widget
    
    properties
     
        plane;
        slice;
        selectedBeam = 1;
        profileOffset = 0;
        typeOfPlot = 1;
        colorData;
        doseColorMap = 'jet';
        ctColorMap = 'bone';
        cMapSize = 64;
        plotCT = true;
        plotContour = true;
        plotIsoCenter = true;
        plotPlan = false;
        plotDose = true;
        plotIsoDoseLines = true;
        plotIsoDoseLinesLabels = false;
        plotLegend = true;
        plotColorBar = true;
        ProfileType = 'lateral';
        SelectedDisplayOption ='';
        %rememberCurrAxes = true;
        %cBarChanged = true;
        CutOffLevel= 0.01;
        dispWindow= cell(3,2);%{[],[];[0.0267,1.69207],[-1000,1040];[0,2.797],[0,2.797]}; %cell(3,2);
        doseOpacity = 0.6;
        IsoDose_Levels = 1;
        NewIsoDoseFlag = true;
        cBarHandle;
        dcmHandle;
        panHandle;
        zoomHandle;
        legendHandle;
        scrollHandle;
        lockUpdate =false;
        %plotlegend=false;
    end
    
    properties (SetAccess=private)
        
        IsoDose_Contours; %only updated from within this class
        VOIPlotFlag;
        DispInfo;
        AxesHandlesVOI;
    end
    
    events
        plotUpdated
    end
    
    methods
        function this = matRad_ViewingWidget(handleParent)
            if nargin < 1
                handleParent = figure(...
                    'Units','characters',...
                    'Position',[170.4 45 140.4 45.5384615384615],...
                    'Visible','on',...
                    'Color',[0.501960784313725 0.501960784313725 0.501960784313725],...  'CloseRequestFcn',@(hObject,eventdata) figure1_CloseRequestFcn(this,hObject,eventdata),...
                    'IntegerHandle','off',...
                    'Colormap',[0 0 0.5625;0 0 0.625;0 0 0.6875;0 0 0.75;0 0 0.8125;0 0 0.875;0 0 0.9375;0 0 1;0 0.0625 1;0 0.125 1;0 0.1875 1;0 0.25 1;0 0.3125 1;0 0.375 1;0 0.4375 1;0 0.5 1;0 0.5625 1;0 0.625 1;0 0.6875 1;0 0.75 1;0 0.8125 1;0 0.875 1;0 0.9375 1;0 1 1;0.0625 1 1;0.125 1 0.9375;0.1875 1 0.875;0.25 1 0.8125;0.3125 1 0.75;0.375 1 0.6875;0.4375 1 0.625;0.5 1 0.5625;0.5625 1 0.5;0.625 1 0.4375;0.6875 1 0.375;0.75 1 0.3125;0.8125 1 0.25;0.875 1 0.1875;0.9375 1 0.125;1 1 0.0625;1 1 0;1 0.9375 0;1 0.875 0;1 0.8125 0;1 0.75 0;1 0.6875 0;1 0.625 0;1 0.5625 0;1 0.5 0;1 0.4375 0;1 0.375 0;1 0.3125 0;1 0.25 0;1 0.1875 0;1 0.125 0;1 0.0625 0;1 0 0;0.9375 0 0;0.875 0 0;0.8125 0 0;0.75 0 0;0.6875 0 0;0.625 0 0;0.5625 0 0],...
                    'MenuBar','none',...
                    'Name','MatRad Viewing',...
                    'NumberTitle','off',...
                    'HandleVisibility','callback',...
                    'Tag','figure1',...
                    'PaperSize',[20.99999864 29.69999902]);
                
            end
            
            this = this@matRad_Widget(handleParent);
            [env, ~] = matRad_getEnvironment();
            
            if nargin < 1
                % create the handle objects if there's no parent
                this.scrollHandle = this.widgetHandle;
                
                % only available in MATLAB
                if strcmp(env,'MATLAB')
                    this.dcmHandle = datacursormode(this.widgetHandle);
                    this.panHandle = pan(this.widgetHandle);
                    this.zoomHandle = zoom(this.widgetHandle);
                end
            end
            this.update();
        end
        
        function this=initialize(this)
%             updateIsoDoseLineCache(this);
            %update(this);
        end
        
        function this=update(this)
            if ~this.lockUpdate
                updateValues(this);
                UpdatePlot(this);
                notifyPlotUpdated(this);
            end
        end
        
        function notifyPlotUpdated(obj)
            [env, ~] = matRad_getEnvironment();
            % handle environment
            switch env
                case 'MATLAB'
                    notify(obj, 'plotUpdated');
                case 'OCTAVE'
            end
            
        end
        
        function set.plane(this,value)
            this.plane=value;
            update(this);
        end
        
        function set.slice(this,value)
            % project to allowed set (between min and max value)
            newSlice = max(value,1);
            if evalin('base','exist(''ct'')') 
                ct=evalin('base','ct');
                newSlice = min(newSlice,ct.cubeDim(this.plane));
            else
                newSlice=1;
            end
            
            this.slice=newSlice;
            update(this);
        end
        
        function set.selectedBeam(this,value)
            this.selectedBeam=value;
            update(this);
        end
        
        function set.profileOffset(this,value)
            this.profileOffset=value;
            update(this);
        end
        
        function set.typeOfPlot(this,value)
            this.typeOfPlot=value;
            update(this);
        end
        
        function set.colorData(this,value)
            this.colorData=value;
            update(this);
        end
        
        function set.doseColorMap(this,value)
            this.doseColorMap=value;
            update(this);
        end
        
        function set.ctColorMap(this,value)
            this.ctColorMap=value;
            update(this);
        end
        
        function set.cMapSize(this,value)
            this.cMapSize=value;
            update(this);
        end
        
        function set.plotCT(this,value)
            this.plotCT=value;
            update(this);
        end
        
        function set.plotContour(this,value)
            this.plotContour=value;
            update(this);
        end
        
        function set.plotIsoCenter(this,value)
            this.plotIsoCenter=value;
            update(this);
        end
        
        function set.plotPlan(this,value)
            this.plotPlan=value;
            update(this);
        end
        
        function set.plotDose(this,value)
            this.plotDose=value;
            update(this);
        end
        
        function set.plotIsoDoseLines(this,value)
            this.plotIsoDoseLines=value;
            update(this);
        end
        
        function set.plotIsoDoseLinesLabels(this,value)
            this.plotIsoDoseLinesLabels=value;
            update(this);
        end
        
        function set.plotLegend(this,value)
            this.plotLegend=value;
            this.legendToggleFunction();
        end
        
        function set.plotColorBar(this,value)
            this.plotColorBar=value;
            this.colorBarToggleFunction();
        end
                
        function set.ProfileType(this,value)
            this.ProfileType=value;
            update(this);
        end
        
        function set.SelectedDisplayOption(this,value)
            this.SelectedDisplayOption=value;
            update(this);
        end
        
        
        function set.CutOffLevel(this,value)
            this.CutOffLevel=value;
            update(this);
        end
        
        function set.dispWindow(this,value)
            this.dispWindow=value;
            update(this);
        end
        
        function set.doseOpacity(this,value)
            this.doseOpacity=value;
            update(this);
        end
        
        function set.IsoDose_Levels(this,value)
            this.IsoDose_Levels=value;
            updateIsoDoseLineCache(this);
            %update(this);
        end
        
        function set.IsoDose_Contours(this,value)
            this.IsoDose_Contours=value;
            update(this);
        end
        
        function set.NewIsoDoseFlag(this,value)
            this.NewIsoDoseFlag=value;
            update(this);
        end
        
        function set.dcmHandle(this,value)
            this.dcmHandle=value;
            set(this.dcmHandle,'DisplayStyle','window');
            %Add the callback for the datacursor display
            set(this.dcmHandle,'UpdateFcn',@(hObject, eventdata)dataCursorUpdateFunction(this, hObject, eventdata));
        end
        
        function set.scrollHandle(this,value)
            this.scrollHandle=value;
            % set callback for scroll wheel function
            set(this.scrollHandle,'WindowScrollWheelFcn',@(src,event)matRadScrollWheelFcn(this,src,event));
        end
    end
    
    methods(Access = protected)
        function this = createLayout(this)
            h88 = this.widgetHandle;
            
            h89 = axes(...
                'Parent',h88,...
                'XTick',[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1],...
                'XTickLabel',{  '0'; '0.1'; '0.2'; '0.3'; '0.4'; '0.5'; '0.6'; '0.7'; '0.8'; '0.9'; '1' },...
                'YTick',[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1],...
                'YTickLabel',{  '0'; '0.1'; '0.2'; '0.3'; '0.4'; '0.5'; '0.6'; '0.7'; '0.8'; '0.9'; '1' },...
                'Position',[0.0718390804597701 0.0354391371340524 0.902298850574712 0.929121725731895],...
                 'Tag','axesFig'); 
                 %'SortMethod','childorder',...
                %'ButtonDownFcn',@(hObject,eventdata)axesFig_ButtonDownFcn(this,hObject,eventdata),...
                % 'FontSize',9.63,...  'FontName','CMU Serif',...
            %'Colormap',[0 0 0.5625;0 0 0.625;0 0 0.6875;0 0 0.75;0 0 0.8125;0 0 0.875;0 0 0.9375;0 0 1;0 0.0625 1;0 0.125 1;0 0.1875 1;0 0.25 1;0 0.3125 1;0 0.375 1;0 0.4375 1;0 0.5 1;0 0.5625 1;0 0.625 1;0 0.6875 1;0 0.75 1;0 0.8125 1;0 0.875 1;0 0.9375 1;0 1 1;0.0625 1 1;0.125 1 0.9375;0.1875 1 0.875;0.25 1 0.8125;0.3125 1 0.75;0.375 1 0.6875;0.4375 1 0.625;0.5 1 0.5625;0.5625 1 0.5;0.625 1 0.4375;0.6875 1 0.375;0.75 1 0.3125;0.8125 1 0.25;0.875 1 0.1875;0.9375 1 0.125;1 1 0.0625;1 1 0;1 0.9375 0;1 0.875 0;1 0.8125 0;1 0.75 0;1 0.6875 0;1 0.625 0;1 0.5625 0;1 0.5 0;1 0.4375 0;1 0.375 0;1 0.3125 0;1 0.25 0;1 0.1875 0;1 0.125 0;1 0.0625 0;1 0 0;0.9375 0 0;0.875 0 0;0.8125 0 0;0.75 0 0;0.6875 0 0;0.625 0 0;0.5625 0 0],...
                
            h90 = get(h89,'title');
            
            set(h90,...
                'Parent',h89,...
                'Units','data',...
                'FontUnits','points',...
                'Color',[0 0 0],...
                'Position',[0.500000554441759 1.00453467465753 0.5],...
                'PositionMode','auto',...
                'Interpreter','tex',...
                'Rotation',0,...
                'RotationMode','auto',...
                'FontName','Helvetica',...
                'FontSize',10.593,...
                'FontAngle','normal',...
                'FontWeight','normal',...
                'HorizontalAlignment','center',...
                'HorizontalAlignmentMode','auto',...
                'VerticalAlignment','bottom',...
                'VerticalAlignmentMode','auto',...
                'EdgeColor','none',...
                'LineStyle','-',...
                'LineWidth',0.5,...
                'BackgroundColor','none',...
                'Margin',2,...
                'Clipping','off',...
                'XLimInclude','on',...
                'YLimInclude','on',...
                'ZLimInclude','on',...
                'Visible','on',...
                'HandleVisibility','off',...
                'BusyAction','queue',...
                'Interruptible','on',...
                'HitTest','on');
                %'PickableParts','visible'); this gave an error in octave
            
            h91 = get(h89,'xlabel');
            
            set(h91,...
                'Parent',h89,...
                'Units','data',...
                'FontUnits','points',...
                'Color',[0.15 0.15 0.15],...
                'Position',[0.500000476837158 -0.0373767115122652 0],...
                'PositionMode','auto',...
                'Interpreter','tex',...
                'Rotation',0,...
                'RotationMode','auto',...
                'FontName','CMU Serif',...
                'FontSize',10.593,...
                'FontAngle','normal',...
                'FontWeight','normal',...
                'HorizontalAlignment','center',...
                'HorizontalAlignmentMode','auto',...
                'VerticalAlignment','top',...
                'VerticalAlignmentMode','auto',...
                'EdgeColor','none',...
                'LineStyle','-',...
                'LineWidth',0.5,...
                'BackgroundColor','none',...
                'Margin',3,...
                'Clipping','off',...
                'XLimInclude','on',...
                'YLimInclude','on',...
                'ZLimInclude','on',...
                'Visible','on',...
                'HandleVisibility','off',...
                'BusyAction','queue',...
                'Interruptible','on',...
                'HitTest','on');%,...
                %'PickableParts','visible');
            
            h92 = get(h89,'ylabel');
            
            set(h92,...
                'Parent',h89,...
                'Units','data',...
                'FontUnits','points',...
                'Color',[0.15 0.15 0.15],...
                'Position',[-0.0474647368237942 0.500000476837158 0],...
                'PositionMode','auto',...
                'Interpreter','tex',...
                'Rotation',90,...
                'RotationMode','auto',...
                'FontName','CMU Serif',...
                'FontSize',10.593,...
                'FontAngle','normal',...
                'FontWeight','normal',...
                'HorizontalAlignment','center',...
                'HorizontalAlignmentMode','auto',...
                'VerticalAlignment','bottom',...
                'VerticalAlignmentMode','auto',...
                'EdgeColor','none',...
                'LineStyle','-',...
                'LineWidth',0.5,...
                'BackgroundColor','none',...
                'Margin',3,...
                'Clipping','off',...
                'XLimInclude','on',...
                'YLimInclude','on',...
                'ZLimInclude','on',...
                'Visible','on',...
                'HandleVisibility','off',...
                'BusyAction','queue',...
                'Interruptible','on',...
                'HitTest','on');%,...
                %'PickableParts','visible');
            
            h93 = get(h89,'zlabel');
            
            set(h93,...
                'Parent',h89,...
                'Units','data',...
                'FontUnits','points',...
                'Color',[0.15 0.15 0.15],...
                'Position',[0 0 0],...
                'PositionMode','auto',...
                'Interpreter','tex',...
                'Rotation',0,...
                'RotationMode','auto',...
                'FontName','CMU Serif',...
                'FontSize',10,...
                'FontAngle','normal',...
                'FontWeight','normal',...
                'HorizontalAlignment','left',...
                'HorizontalAlignmentMode','auto',...
                'VerticalAlignment','middle',...
                'VerticalAlignmentMode','auto',...
                'EdgeColor','none',...
                'LineStyle','-',...
                'LineWidth',0.5,...
                'BackgroundColor','none',...
                'Margin',3,...
                'Clipping','off',...
                'XLimInclude','on',...
                'YLimInclude','on',...
                'ZLimInclude','on',...
                'Visible','off',...
                'HandleVisibility','off',...
                'BusyAction','queue',...
                'Interruptible','on',...
                'HitTest','on');%,...
                %'PickableParts','visible');           
            
            this.createHandles();
            
        end
    end
    
    methods
        function UpdatePlot(this)
            
            handles = this.handles;
            
            %profile on;
            axes(handles.axesFig);
            
            % this is necessary to prevent multiple callbacks of update plot drawing on
            % top of each other in matlab <2014
            drawnow;
            
            defaultFontSize = 8;
            currAxes            = axis(handles.axesFig);
            AxesHandlesVOI      = cell(0);
            
            AxesHandlesCT_Dose  = cell(0);
            AxesHandlesIsoDose  = cell(0);
            
             if evalin('base','exist(''pln'')') && ...
                evalin('base','exist(''ct'')') && evalin('base','exist(''cst'')')
            
                ct  = evalin('base','ct');
                cst = evalin('base','cst');
                pln = evalin('base','pln');
                
                 cst = matRad_computeVoiContoursWrapper(cst,ct);
%     
%                 this.SelectedDisplayOption ='physicalDose';
                % define context menu for structures
                this.VOIPlotFlag=false(size(cst,1),1);
                for i = 1:size(cst,1)
                    if cst{i,5}.Visible
                        this.VOIPlotFlag(i) = true;
                    end
                end
% 
% %                 if ~isfield(ct, 'cubeHU')
% %                     handles.cubeHUavailable = false;
% %                 else
% %                     handles.cubeHUavailable = true;
% %                 end
             else
%                 this.SelectedDisplayOption ='';
                 cla(handles.axesFig, 'reset')
                 return
             end
            
            
            
            %% If resultGUI exists, then an optimization has been performed
            if evalin('base','exist(''resultGUI'')') 
                Result = evalin('base','resultGUI');
            end
            
            
            
            %% set and get required variables
            %plane = get(handles.popupPlane,'Value');
            %slice = round(get(handles.sliderSlice,'Value'));
            hold(handles.axesFig,'on');
            if this.typeOfPlot==1 %get(handles.popupTypeOfPlot,'Value')==1
                set(handles.axesFig,'YDir','Reverse');
            end
            
            %% Remove colorbar?
            %plotColorbarSelection = get(handles.popupmenu_chooseColorData,'Value');
          
%             if this.typeOfPlot==2 || this.colorData == 1
% %                 if isfield(handles,'cBarHandle')
% %                     delete(handles.cBarHandle);
% %                 end
%                 %The following seems to be necessary as MATLAB messes up some stuff
%                 %with the handle storage
%                 ch = findall(gcf,'tag','Colorbar');
%                 if ~isempty(ch)
%                     delete(ch);
%                 end
%             end
            
            selectIx = this.colorData; %get(handles.popupmenu_chooseColorData,'Value');
            
            cla(handles.axesFig);
            %% plot ct - if a ct cube is available and type of plot is set to 1 and not 2; 1 indicate cube plotting and 2 profile plotting
            if ~isempty(ct) && this.typeOfPlot==1
                
                if selectIx == 3
                    ctIx = 2;
                else
                    ctIx = selectIx;
                end
                
                if isfield(ct, 'cube')
                    plotCtCube = ct.cube;
                else
                    plotCtCube = ct.cubeHU;
                end
                
                ctMap = matRad_getColormap(this.ctColorMap,this.cMapSize);
                
%                 if isempty(this.dispWindow{ctIx,2})
%                     this.dispWindow{ctIx,2} = [min(reshape([ct.cubeHU{:}],[],1)) max(reshape([ct.cubeHU{:}],[],1))];
%                 end
                
                if this.plotCT %get(handles.radiobtnCT,'Value')
                    [AxesHandlesCT_Dose{end+1},~,~] = matRad_plotCtSlice(handles.axesFig,plotCtCube,1,this.plane,this.slice,ctMap,this.dispWindow{ctIx,1});
                    
                    % plot colorbar? If 1 the user asked for the CT
                    if this.colorData == 2
                        %Plot the colorbar
                        this.cBarHandle = matRad_plotColorbar(handles.axesFig,ctMap,this.dispWindow{ctIx,1},'fontsize',defaultFontSize);
                        
                        %adjust lables
                        if isfield(ct,'cubeHU')
                            set(get(this.cBarHandle,'ylabel'),'String', 'Hounsfield Units','fontsize',defaultFontSize);
                        else
                            set(get(this.cBarHandle,'ylabel'),'String', 'Electron Density','fontsize',defaultFontSize);
                        end
                        % do not interprete as tex syntax
                        set(get(this.cBarHandle,'ylabel'),'interpreter','none');
                    end
                end
            end
            
            %% plot dose cube
            if this.typeOfPlot== 1  && exist('Result','var') % handles.State >= 1 && 
                doseMap = matRad_getColormap(this.doseColorMap,this.cMapSize);
                doseIx  = 3;
                
                dose = Result.(this.SelectedDisplayOption);
                
                % dose colorwash
                if ~isempty(dose) && ~isvector(dose)
                    
%                     if isempty(this.dispWindow{doseIx,2})
%                         this.dispWindow{doseIx,2} = [min(dose(:)) max(dose(:))];   % set min and max dose values
%                     end
                    
                    if this.plotDose %get(handles.radiobtnDose,'Value')
                        [doseHandle,~,~] = matRad_plotDoseSlice(handles.axesFig,dose,this.plane,this.slice,this.CutOffLevel,this.doseOpacity,doseMap,this.dispWindow{doseIx,1});
                        AxesHandlesCT_Dose{end+1}         = doseHandle;
                    end
                    
                    % plot colorbar?
                    if this.colorData > 2  %&& this.cBarChanged
                        %Plot the colorbar
                        this.cBarHandle = matRad_plotColorbar(handles.axesFig,doseMap,this.dispWindow{selectIx,1},'fontsize',defaultFontSize);
                        
                        if this.plotColorBar
                            set(this.cBarHandle,'Visible','on')
                        else
                            set(this.cBarHandle,'Visible','off')
                        end
                        %adjust lables
                        Idx = find(strcmp(this.SelectedDisplayOption,this.DispInfo(:,1)));
                        set(get(this.cBarHandle,'ylabel'),'String', [this.DispInfo{Idx,1} ' ' this.DispInfo{Idx,3} ],'fontsize',defaultFontSize);
                        % do not interprete as tex syntax
                        set(get(this.cBarHandle,'ylabel'),'interpreter','none');
                    end
                end
                
                
                %% plot iso dose lines
                if this.plotIsoDoseLines %get(handles.radiobtnIsoDoseLines,'Value')
                    plotLabels = this.plotIsoDoseLinesLabels; %get(handles.radiobtnIsoDoseLinesLabels,'Value') == 1;
%                     
%                     %Sanity Check for Contours, which actually should have been
%                     %computed before calling UpdatePlot
%                     if isempty(this.IsoDose_Contours) %~isfield(handles.IsoDose,'Contours')
%                         try
%                             this.IsoDose_Contours = matRad_computeIsoDoseContours(dose,this.IsoDose_Levels);
%                         catch
%                             %If the computation didn't work, we set the field to
%                             %empty, which will force matRad_plotIsoDoseLines to use
%                             %matlabs contour function instead of repeating the
%                             %failing computation every time
%                             this.IsoDose_Contours = [];
%                             warning('Could not compute isodose lines! Will try slower contour function!');
%                         end
%                      end
                    AxesHandlesIsoDose = matRad_plotIsoDoseLines(handles.axesFig,dose,this.IsoDose_Contours,this.IsoDose_Levels,plotLabels,this.plane,this.slice,doseMap,this.dispWindow{doseIx,1},'LineWidth',1.5);
                end
            end
            
%              selectIx = this.colorData; %get(handles.popupmenu_chooseColorData,'Value');
%              set(handles.txtMinVal,'String',num2str(handles.dispWindow{selectIx,2}(1,1)));
%              set(handles.txtMaxVal,'String',num2str(handles.dispWindow{selectIx,2}(1,2)));
            
            %% plot VOIs
            if this.plotContour && this.typeOfPlot==1 && exist('cst','var') && exist('ct','var') %&& get(handles.radiobtnContour,'Value') && handles.State>0
                AxesHandlesVOI = [AxesHandlesVOI matRad_plotVoiContourSlice(handles.axesFig,cst,ct,1,this.VOIPlotFlag,this.plane,this.slice,[],'LineWidth',2)];
            end
            this.AxesHandlesVOI=AxesHandlesVOI;
            
            %% Set axis labels and plot iso center
            matRad_plotAxisLabels(handles.axesFig,ct,this.plane,this.slice,defaultFontSize);
            
            if this.plotIsoCenter && this.typeOfPlot == 1 && ~isempty(pln) %get(handles.radioBtnIsoCenter,'Value') == 1 
                hIsoCenterCross = matRad_plotIsoCenterMarker(handles.axesFig,pln,ct,this.plane,this.slice);
            end
             
            if this.plotPlan && ~isempty(pln) %get(handles.radiobtnPlan,'value') == 1
                matRad_plotProjectedGantryAngles(handles.axesFig,pln,ct,this.plane);
            end
            
            %set axis ratio
            ratios = [1/ct.resolution.x 1/ct.resolution.y 1/ct.resolution.z];
            set(handles.axesFig,'DataAspectRatioMode','manual');
            if this.plane == 1
                res = [ratios(3) ratios(2)]./max([ratios(3) ratios(2)]);
                set(handles.axesFig,'DataAspectRatio',[res 1])
            elseif this.plane == 2 % sagittal plane
                res = [ratios(3) ratios(1)]./max([ratios(3) ratios(1)]);
                set(handles.axesFig,'DataAspectRatio',[res 1])
            elseif  this.plane == 3 % Axial plane
                res = [ratios(2) ratios(1)]./max([ratios(2) ratios(1)]);
                set(handles.axesFig,'DataAspectRatio',[res 1])
            end
            
            
            %% profile plot
            if this.typeOfPlot == 2 && exist('Result','var')
                % set SAD
                fileName = [pln.radiationMode '_' pln.machine];
                try
                    load(fileName);
                    SAD = machine.meta.SAD;
                catch
                    error(['Could not find the following machine file: ' fileName ]);
                end
                
                % clear view and initialize some values
                cla(handles.axesFig,'reset')
                set(gca,'YDir','normal');
                ylabel('{\color{black}dose [Gy]}')
                cColor={'black','green','magenta','cyan','yellow','red','blue'};
                
                % Rotate the system into the beam.
                % passive rotation & row vector multiplication & inverted rotation requires triple matrix transpose
                rotMat_system_T = transpose(matRad_getRotationMatrix(pln.propStf.gantryAngles(this.selectedBeam),pln.propStf.couchAngles(this.selectedBeam)));
                
                if strcmp(this.ProfileType,'longitudinal')
                    sourcePointBEV = [this.profileOffset -SAD   0];
                    targetPointBEV = [this.profileOffset  SAD   0];
                elseif strcmp(this.ProfileType,'lateral')
                    sourcePointBEV = [-SAD this.profileOffset   0];
                    targetPointBEV = [ SAD this.profileOffset   0];
                end
                
                rotSourcePointBEV = sourcePointBEV * rotMat_system_T;
                rotTargetPointBEV = targetPointBEV * rotMat_system_T;
                
                % perform raytracing on the central axis of the selected beam, use unit
                % electron density for plotting against the geometrical depth
                [~,l,rho,~,ix] = matRad_siddonRayTracer(pln.propStf.isoCenter(this.selectedBeam,:),ct.resolution,rotSourcePointBEV,rotTargetPointBEV,{0*ct.cubeHU{1}+1});
                d = [0 l .* rho{1}];
                % Calculate accumulated d sum.
                vX = cumsum(d(1:end-1));
                
                % this step is necessary if visualization is set to profile plot
                % and another optimization is carried out - set focus on GUI
                figHandles = get(0,'Children');
                idxHandle = [];
                if ~isempty(figHandles)
                    v=version;
                    if str2double(v(1:3))>= 8.5
                        idxHandle = strcmp({figHandles(:).Name},'matRadGUI');
                    else
                        idxHandle = strcmp(get(figHandles,'Name'),'matRadGUI');
                    end
                end
                figure(figHandles(idxHandle));
                
                % plot physical dose
                %Content =this.SelectedDisplayOption; %get(this.popupDisplayOption,'String');
                SelectedCube = this.SelectedDisplayOption; %Content{get(this.popupDisplayOption,'Value')};
                if sum(strcmp(SelectedCube,{'physicalDose','effect','RBExDose','alpha','beta','RBE'})) > 0
                    Suffix = '';
                else
                    Idx    = find(SelectedCube == '_');
                    Suffix = SelectedCube(Idx:end);
                end
                
                mPhysDose = Result.(['physicalDose' Suffix]);
                PlotHandles{1} = plot(handles.axesFig,vX,mPhysDose(ix),'color',cColor{1,1},'LineWidth',3); hold(handles.axesFig,'on');
                PlotHandles{1,2} ='physicalDose';
                ylabel(handles.axesFig,'dose in [Gy]');
                set(handles.axesFig,'FontSize',defaultFontSize);
                
                % plot counter
                Cnt=2;
                
                if isfield(Result,['RBE' Suffix])
                    
                    %disbale specific plots
                    %this.DispInfo{6,2}=0;
                    %this.DispInfo{5,2}=0;
                    %this.DispInfo{2,2}=0;
                    
                    % generate two lines for ylabel
                    StringYLabel1 = '\fontsize{8}{\color{red}RBE x dose [Gy(RBE)] \color{black}dose [Gy] ';
                    StringYLabel2 = '';
                    for i=1:1:size(this.DispInfo,1)
                        if this.DispInfo{i,2} && sum(strcmp(this.DispInfo{i,1},{['effect' Suffix],['alpha' Suffix],['beta' Suffix]})) > 0
                            %physicalDose is already plotted and RBExD vs RBE is plotted later with plotyy
                            if ~strcmp(this.DispInfo{i,1},['RBExDose' Suffix]) &&...
                                    ~strcmp(this.DispInfo{i,1},['RBE' Suffix]) && ...
                                    ~strcmp(this.DispInfo{i,1},['physicalDose' Suffix])
                                
                                mCube = Result.([this.DispInfo{i,1}]);
                                PlotHandles{Cnt,1} = plot(handles.axesFig,vX,mCube(ix),'color',cColor{1,Cnt},'LineWidth',3); hold(handles.axesFig,'on');
                                PlotHandles{Cnt,2} = this.DispInfo{i,1};
                                StringYLabel2 = [StringYLabel2  ' \color{'  cColor{1,Cnt} '}' this.DispInfo{i,1} ' ['  this.DispInfo{i,3} ']'];
                                Cnt = Cnt+1;
                            end
                        end
                    end
                    StringYLabel2 = [StringYLabel2 '}'];
                    % always plot RBExD against RBE
                    mRBExDose = Result.(['RBExDose' Suffix]);
                    vBED = mRBExDose(ix);
                    mRBE = Result.(['RBE' Suffix]);
                    vRBE = mRBE(ix);
                    
                    % plot biological dose against RBE
                    [ax, PlotHandles{Cnt,1}, PlotHandles{Cnt+1,1}]=plotyy(handles.axesFig,vX,vBED,vX,vRBE,'plot');hold(handles.axesFig,'on');
                    PlotHandles{Cnt,2}='RBExDose';
                    PlotHandles{Cnt+1,2}='RBE';
                    
                    % set plotyy properties
                    set(get(ax(2),'Ylabel'),'String','RBE [a.u.]','FontSize',8);
                    ylabel({StringYLabel1;StringYLabel2})
                    set(PlotHandles{Cnt,1},'Linewidth',4,'color','r');
                    set(PlotHandles{Cnt+1,1},'Linewidth',3,'color','b');
                    set(ax(1),'ycolor','r')
                    set(ax(2),'ycolor','b')
                    set(ax,'FontSize',8);
                    Cnt=Cnt+2;
                end
                
                % asses target coordinates
                tmpPrior = intmax;
                tmpSize = 0;
                for i=1:size(cst,1)
                    if strcmp(cst{i,3},'TARGET') && tmpPrior >= cst{i,5}.Priority && tmpSize<numel(cst{i,4}{1})
                        linIdxTarget = unique(cst{i,4}{1});
                        tmpPrior=cst{i,5}.Priority;
                        tmpSize=numel(cst{i,4}{1});
                        VOI = cst{i,2};
                    end
                end
                
                str = sprintf('profile plot - central axis of %d beam gantry angle %d? couch angle %d?',...
                    this.selectedBeam ,pln.propStf.gantryAngles(this.selectedBeam),pln.propStf.couchAngles(this.selectedBeam));
                h_title = title(handles.axesFig,str,'FontSize',defaultFontSize);
                pos = get(h_title,'Position');
                set(h_title,'Position',[pos(1)-40 pos(2) pos(3)])
                
                % plot target boundaries
                mTargetCube = zeros(ct.cubeDim);
                mTargetCube(linIdxTarget) = 1;
                vProfile = mTargetCube(ix);
                WEPL_Target_Entry = vX(find(vProfile,1,'first'));
                WEPL_Target_Exit  = vX(find(vProfile,1,'last'));
                PlotHandles{Cnt,2} =[VOI ' boundary'];
                
                if ~isempty(WEPL_Target_Entry) && ~isempty(WEPL_Target_Exit)
                    hold(handles.axesFig,'on');
                    PlotHandles{Cnt,1} = ...
                        plot([WEPL_Target_Entry WEPL_Target_Entry],get(handles.axesFig,'YLim'),'--','Linewidth',3,'color','k');hold(handles.axesFig,'on');
                    plot([WEPL_Target_Exit WEPL_Target_Exit],get(handles.axesFig,'YLim'),'--','Linewidth',3,'color','k');hold(handles.axesFig,'on');
                    
                else
                    PlotHandles{Cnt,1} =[];
                end
                
                Lines  = PlotHandles(~cellfun(@isempty,PlotHandles(:,1)),1);
                Labels = PlotHandles(~cellfun(@isempty,PlotHandles(:,1)),2);
                l=legend(handles.axesFig,[Lines{:}],Labels{:});
                xlabel('radiological depth [mm]','FontSize',8);
                grid on, grid minor
            else
                % create legend for the visible VOI
                if this.typeOfPlot==2 || ~this.plotContour || isempty([this.AxesHandlesVOI{:}]) %isempty(find(this.VOIPlotFlag, 1))
                    l=legend(handles.axesFig,'off');
                else
                    % store the lines as a private property
                    l=legend(handles.axesFig, [this.AxesHandlesVOI{:}], cst{this.VOIPlotFlag,2});
                end
            end
            set(l,'FontSize',defaultFontSize);
            if this.plotLegend
                set(l,'Visible','on')
            else
                set(l,'Visible','off')
            end
            this.legendHandle=l;
            
            %zoom(handles.figure1,'reset');
            axis(handles.axesFig,'tight');
            
%             if this.rememberCurrAxes
%                 axis(handles.axesFig);%currAxes);
%             end
            
            hold(handles.axesFig,'off');
            
            %this.cBarChanged = false;
            
%             if this.typeOfPlot==1
%                 UpdateColormapOptions(handles);
%             end
            
            %this.legendHandle=legend(handles.axesFig);
            this.handles = handles;
            %profile off;
            %profile viewer;
        end
       
        %Update IsodoseLines
        function this = updateIsoDoseLineCache(this)
            handles=this.handles;
            
            if evalin('base','exist(''resultGUI'')')
                
                resultGUI = evalin('base','resultGUI');
%                 % select first cube if selected option does not exist
%                 if ~isfield(resultGUI,this.SelectedDisplayOption)
%                     CubeNames = fieldnames(resultGUI);
%                     dose = resultGUI.(CubeNames{1,1});
%                 else
                     dose = resultGUI.(this.SelectedDisplayOption);
%                 end
%                 
%                 %if function is called for the first time then set display parameters
%                 if isempty(this.dispWindow{3,2})
%                     this.dispWindow{3,1} = [min(dose(:)) max(dose(:))]; % set default dose range
%                     this.dispWindow{3,2} = [min(dose(:)) max(dose(:))]; % set min max values
%                 end
%
%                 minMaxRange = this.dispWindow{3,1};
%                 % if upper colorrange is defined then use it otherwise 120% iso dose
%                 upperMargin = 1;
%                 if abs((max(dose(:)) - this.dispWindow{3,1}(1,2))) < 0.01  * max(dose(:))
%                     upperMargin = 1.2;
%                 end
%
%                 %this creates a loop(needed the first time a dose cube is loaded)
%                 if (length(this.IsoDose_Levels) == 1 && this.IsoDose_Levels(1,1) == 0) || ~this.NewIsoDoseFlag
%                     vLevels                  = [0.1:0.1:0.9 0.95:0.05:upperMargin];
%                     referenceDose            = (minMaxRange(1,2))/(upperMargin);
%                     this.IsoDose_Levels   = minMaxRange(1,1) + (referenceDose-minMaxRange(1,1)) * vLevels;
%                 end
this.IsoDose_Contours = matRad_computeIsoDoseContours(dose,this.IsoDose_Levels);
            end
            this.handles = handles;
        end
        
        %% Data Cursors
        function cursorText = dataCursorUpdateFunction(this,hObject, eventdata)%event_obj)
            % Display the position of the data cursor
            % obj          Currently not used (empty)
            % event_obj    Handle to event object
            % output_txt   Data cursor text string (string or cell array of strings).
            
            target = findall(0,'Name','matRadGUI');
            
            % Get GUI data (maybe there is another way?)
            %handles = guidata(target);
            
            % position of the data point to label
            pos = get(eventdata,'Position');
            
            %Different behavior for image and profile plot
            if this.typeOfPlot ==1 %get(handles.popupTypeOfPlot,'Value')==1 %Image view
                cursorText = cell(0,1);
                try
                    
                    if evalin('base','exist(''ct'')') %handles.State >= 1
%                         plane = get(handles.popupPlane,'Value');
%                         slice = round(get(handles.sliderSlice,'Value'));
                        
                        %Get the CT values
                        ct  = evalin('base','ct');
                        
                        %We differentiate between pos and ix, since the user may put
                        %the datatip on an isoline which returns a continous position
                        cubePos = zeros(1,3);
                        cubePos(this.plane) = this.slice;
                        cubePos(1:end ~= this.plane) = fliplr(pos);
                        cubeIx = round(cubePos);
                        
                        %Here comes the index permutation stuff
                        %Cube Index
                        cursorText{end+1,1} = ['Cube Index: ' mat2str(cubeIx)];
                        %Space Coordinates
                        coords = zeros(1,3);
                        coords(1) = cubePos(2)*ct.resolution.y;
                        coords(2) = cubePos(1)*ct.resolution.x;
                        coords(3) = cubePos(3)*ct.resolution.z;
                        cursorText{end+1,1} = ['Space Coordinates: ' mat2str(coords,5) ' mm'];
                        
                        ctVal = ct.cubeHU{1}(cubeIx(1),cubeIx(2),cubeIx(3));
                        cursorText{end+1,1} = ['HU Value: ' num2str(ctVal,3)];
                    end
                catch
                    cursorText{end+1,1} = 'Error while retreiving CT Data!';
                end
                
                
                    %Add dose information if available
                    if evalin('base','exist(''resultGUI'')') %handles.State == 3
                        %get result structure
                        result = evalin('base','resultGUI');
                        
                        %get all cubes from the ResultGUI 
                        resultNames = fieldnames(result); %get(handles.popupDisplayOption,'String');
                        
                        %Display all values of fields found in the resultGUI struct
                        for runResult = 1:numel(resultNames)
                            if ~isstruct(result.(resultNames{runResult,1})) && ~isvector(result.(resultNames{runResult,1}))
                            %try
                                name = resultNames{runResult};
                                if isfield(result,name) % (check the dimensions, same as CT)
                                    field = result.(name);
                                    val = field(cubeIx(1),cubeIx(2),cubeIx(3));
                                    cursorText{end+1,1} = [name ': ' num2str(val,3)];
                                end
                            %catch
                                %cursorText{end+1,1} = 'Error while retreiving Data!';
                            end
                        end
                    end
                
            else %Profile view
                cursorText = cell(2,1);
                cursorText{1} = ['Radiological Depth: ' num2str(pos(1),3) ' mm'];
                cursorText{2} = [get(target,'DisplayName') ': ' num2str(pos(2),3)];
            end
            
        end
        
        function matRadScrollWheelFcn(this,src,event)
            
            % compute new slice
            this.slice= this.slice - event.VerticalScrollCount;
            
            % update slider (use instead the update plot notification)
            %set(handles.sliderSlice,'Value',newSlice);

        end
        
        function legendToggleFunction(this,src,event)
            if isempty(this.legendHandle) || ~isobject(this.legendHandle)
                return;
            end
            if this.plotLegend
                set(this.legendHandle,'Visible','on')
            else
                set(this.legendHandle,'Visible','off')
            end
        end
        
        function colorBarToggleFunction(this,src,event)
            if isempty(this.cBarHandle) || ~isobject(this.cBarHandle)
                return;
            end
            if this.plotColorBar
                set(this.cBarHandle,'Visible','on')
            else
                set(this.cBarHandle,'Visible','off')
            end
        end
        
        function updateValues(this)
            this.lockUpdate=true;
            if isempty(this.colorData)
                if evalin('base','exist(''resultGUI'')')
                    this.colorData=3;
                elseif evalin('base','exist(''ct'')')
                    this.colorData=2;
                else %no data is loaded
                    this.colorData=1;
                end
            end
            
             if isempty(this.plane)
                 this.plane=3;
             end
             
             
             if evalin('base','exist(''resultGUI'')')
                 %selectionIndex = 2;
                 Result = evalin('base','resultGUI');
                 
                 this.DispInfo = fieldnames(Result);                 
                 for i = 1:size(this.DispInfo,1)
                     
                     % delete weight vectors in Result struct for plotting
                     if isstruct(Result.(this.DispInfo{i,1})) || isvector(Result.(this.DispInfo{i,1}))
                         Result = rmfield(Result,this.DispInfo{i,1});
                         this.DispInfo{i,2}=false;
                     else
                         %second dimension indicates if it should be plotted
                         this.DispInfo{i,2} = true;
                         % determine units
                         if strfind(this.DispInfo{i,1},'physicalDose')
                             this.DispInfo{i,3} = '[Gy]';
                         elseif strfind(this.DispInfo{i,1},'alpha')
                             this.DispInfo{i,3} = '[Gy^{-1}]';
                         elseif strfind(this.DispInfo{i,1},'beta')
                             this.DispInfo{i,3} = '[Gy^{-2}]';
                         elseif strfind(this.DispInfo{i,1},'RBExD')
                             this.DispInfo{i,3} = '[Gy(RBE)]';
                         elseif strfind(this.DispInfo{i,1},'LET')
                             this.DispInfo{i,3} = '[keV/um]';
                         else
                             this.DispInfo{i,3} = '[a.u.]';
                         end
                         this.DispInfo{i,4} = [];    % optional for the future: color range for plotting
                         this.DispInfo{i,5} = [];    % optional for the future: min max values
                     end
                 end
                 
                 if sum(strcmp(this.SelectedDisplayOption,fieldnames(Result))) == 0
                     this.SelectedDisplayOption = this.DispInfo{find([this.DispInfo{:,2}],1,'first'),1};
                 end
                 
                 dose = Result.(this.SelectedDisplayOption);
                 minMax = [min(dose(:)) max(dose(:))];
                 
                 if isempty(this.dispWindow{3,2})
                     this.dispWindow{3,1} = minMax; 
                     this.dispWindow{3,2} = minMax;
                 end
             elseif evalin('base','exist(''dij'')')
                 this.SelectedDisplayOption ='physicalDose';
             else
                 this.SelectedDisplayOption ='';
             end
             
             if evalin('base','exist(''ct'')')
                 selectionIndex = 2;
                 ct = evalin('base','ct');
                 if isfield(ct, 'cube')
                     ctCube=ct.cube{1};
                 else
                     ctCube=ct.cubeHU;
                 end
                 minMax = [min(reshape([ct.cubeHU{:}],[],1)) max(reshape([ct.cubeHU{:}],[],1))];
                 window = [min(ctCube(:)) max(ctCube(:))];  
                 
                  
                 
                 if isempty(this.slice)
                     if evalin('base','exist(''pln'')')
                         pln= evalin('base','pln');
                         if this.plane == 1
                             this.slice= ceil(pln.propStf.isoCenter(1,2)/ct.resolution.x);
                         elseif this.plane == 2
                             this.slice= ceil(pln.propStf.isoCenter(1,1)/ct.resolution.y);
                         elseif this.plane == 3
                             this.slice= ceil(pln.propStf.isoCenter(1,3)/ct.resolution.z);
                         end
                     else
                         this.slice=1;
                     end
                 end
             else
                 selectionIndex=1;
                 minMax = [0 1];
                 window=minMax;
             end
             
             if isempty(this.dispWindow{selectionIndex,2})
                 this.dispWindow{selectionIndex,1} = window;
                 this.dispWindow{selectionIndex,2} = minMax;
             end
             
             
            this.lockUpdate=false;
        end
    end
end