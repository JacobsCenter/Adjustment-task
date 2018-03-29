%% Setup

% Clear the workspace
close all;
clearvars;
sca;

%Set to '2' for testing purposes. Change to '0' during data collection (on windows PC)
Screen('Preference', 'SkipSyncTests', 2)

% Setup PTB with some default values
PsychDefaultSetup(2); 

%makes screen translucent
%PsychDebugWindowConfiguration( );


%% Getting ID of participant

ParticipantID = (cell2mat(inputdlg("Participant ID")));
while isempty(ParticipantID)
    ParticipantID = (cell2mat(inputdlg("You need to provide a participant ID:")));
end

%disable input to matlab editor
ListenChar(-1);
%% Retrieve stimulus data

imageFolder = '101 faces';
imgArray = dir(fullfile(imageFolder,'*.jpg'));
imgList = {imgArray(:).name};

%total number of images in folder
nImages = length(imgList);

%total number of morph frames per identity
nFrames = 101;

%total number of unique faces
nTrials = nImages / nFrames;

%Stimulus values
imgArr = cell2mat(imgList');
preStimValues = str2num(imgArr(:,7:9))';
%standardizing stim values to 0-100.
stimValues = (preStimValues-min(preStimValues)) / (max(preStimValues)-min(preStimValues)) * 100;

%set image scale size
imgscale = 1;

% Randomize the trial list
randomizedTrials = randperm(nTrials);

%% Screen setup

% Set the screen number to the external secondary monitor if there is one connected
screenNumber = max(Screen('Screens'));

%HideCursor(screenNumber);

% Define black, white and grey
white = WhiteIndex(screenNumber);
grey = white / 2;
black = BlackIndex(screenNumber);

% Open the screen
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [] ,  32 ,  2,...
    [], [],  kPsychNeed32BPCFloat);

% Flip to clear
Screen('Flip', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

%screen size in pixels
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Set the text size
Screen('TextSize', window, 40);

% Query the maximum priority level
topPriorityLevel = MaxPriority(window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Here we set the initial position of the mouse to be in the centre of the
% screen
SetMouse(xCenter, yCenter);


%% Timing Information       

% Presentation Time in seconds and frames
presTimeSecs = 0.5;
presTimeFrames = round(presTimeSecs / ifi);

% Interstimulus interval time in seconds and frames
isiTimeSecs = 2;
isiTimeFrames = round(isiTimeSecs / ifi);

% Numer of frames to wait before re-drawing
waitframes = 1;


%% Display introduction screens

% Make a vector to record the response for each trial
respVector = zeros(2, nTrials);   

% If this is the first trial we present a start screen and wait for a key-press
DrawFormattedText(window, ...
    'In dieser Aufgabe erscheinen Gesichter mehrerer Personen. \n\nEntscheide, ob die Person Wut oder Freude zeigt.\nBei Wut, drücke die LINKE Pfeiltaste.\nBei Freude, drücke die RECHTE Pfeiltaste.\n\n -- Weiter mit Leertaste -- ',...
    'center', 'center', black);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, ...
    'Antworte schnell und spontan.\n\nIn einigen Fällen wird nicht eindeutig sein, ob die Person Wut oder Freude zeigt.\nWähle die Emotion, die am Ehesten zutrifft.\n\n -- Weiter mit Leertaste -- ',...
    'center', 'center', black);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, ...
    '-- Drücke die Leertaste, um zu starten --',...
    'center', screenYpixels-100, black);
Screen('Flip', window);
KbStrokeWait;

%% Animation loop: Loop for the total number of trials

%Set font size
Screen('TextSize', window, 50);

%start main loop
for trial = 1:nTrials

    % Change the blend function to draw an antialiased fixation point
    % in the centre of the screen
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
 
    % Flip again to sync us to the vertical retrace at the same time as
    % drawing our fixation point
    Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
    vbl = Screen('Flip', window);

    % Now we present the isi interval with fixation point minus one frame
    % because we presented the fixation point once already when getting a
    % time stamp
    for frame = 1:isiTimeFrames - 1

       
        %Draw the happy and angry indicators
        DrawFormattedText(window,'WUT','right', screenYpixels-100, black, [], [], [], [], [], [100, 100, screenXpixels-100, screenYpixels-100]);
        DrawFormattedText(window,'FREUDE',100, screenYpixels-100, black);
        % Draw the fixation point
        Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);

        % Flip to the screen
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    end
    
    respToBeMade = true;
    while ~KbCheck
        
        %get X-coordinate of the mouse
        mx = GetMouse();
        
        %scale mx down to face morph range
        scaleX = floor(mx/screenXpixels*nFrames);
        
        %select the right identity
        namecond = imgArr(:,6) == int2str(randomizedTrials(trial));
        subimgArr = imgArr(namecond,:);
        
        file = subimgArr(scaleX+1,:);
        fimg = imread(fullfile(imageFolder,file));
        imageTexture = Screen('MakeTexture', window, fimg);
        [s1, s2, s3] = size(fimg);  
        Screen('DrawTexture', window, imageTexture, [], [screenXpixels/2 - s2*imgscale/2 screenYpixels/2 - s1*imgscale/2  xCenter+s2*imgscale/2 yCenter+s1*imgscale/2], 0);
        % Set the right blend function for drawing the gabors
        Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO');
        %Draw the happy and angry indicators
        DrawFormattedText(window,'WÜTEND','right', screenYpixels-100, black, [], [], [], [], [], [100, 100, screenXpixels-100, screenYpixels-100]);
        DrawFormattedText(window,'GLÜCKLICH',100, screenYpixels-100, black);
        % Flip to the screen
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi); 
    end
      response = scaleX;

    % Change the blend function to draw an antialiased fixation point
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    % Draw the fixation point
    Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
    %Draw the happy and angry indicators
    DrawFormattedText(window,'WUT','right', screenYpixels-100, black, [], [], [], [], [], [100, 100, screenXpixels-100, screenYpixels-100]);
    DrawFormattedText(window,'FREUDE',100, screenYpixels-100, black);
    % Flip to the screen
    vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);


    % Record the response
    respVector(1,trial) = trial;
    respVector(2,trial) = response;

    
    disp("Number of trials remaining: ");
    nrem = nTrials - trial;
    disp (nrem);
end  

% imgNames = string(imgArr(randomizedTrials, :));
% data = table(imgNames, 100-stimValues(randomizedTrials)', respVector', respTime', 'VariableNames', {'image', 'angerIntensity', 'respondAngry', 'reactionTime'});

% figure;
% dataray = table2array(data);
% %preparing data for plotting
% values = str2double(dataray(:,2:3));
% 
% mResp = zeros(101,2);
% for intensity = 1:101
%  %   insy = (intensity - 6) * 0.1;
%     index = abs(values(:,1) - (intensity-1)) < eps;
%     %index = (values(:,1) == exp);
%     mResp(102-intensity, :) = [intensity-1, mean(values(index, 2))];
% end
%     
% plot(mResp(:,2), 'ro-', 'MarkerFaceColor', 'r');
% axis([0 100 min(mResp(:, 2)) max(mResp(:, 2))]);
% xlabel('Happy --- Angry');
% ylabel('IsAngry');
% title('Psychometric function');
% writetable(data, ParticipantID)
% Clean up
ListenChar(0);
sca;