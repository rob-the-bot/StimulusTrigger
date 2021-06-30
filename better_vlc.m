clear; close all
%% Parameters
WAIT_TIME = 0; % can be set to 0, just some interval between the recording starts and the stimulus playback
% Make sure the stimulus is finished within the STIMULUS_TIME!! Otherwise
% weird stuff will happen
STIMULUS_TIME = 20; % seconds between the start of the stimulus and the start of the next stimulus
HOSTNAME = '10.161.10.129'; % Change this if your change the imagine computer
FRAMEPERIOD = 0.033; % 1/30, which is 30FPS
TRANSITION_FRAMES = 450; % 450 frames
% Change the 2 integers depending on the resolution of the projector screen
WIDTH = 1280; HEIGHT = 720;

str = 'Action0001[Mark Frame()]:'; % String to send through UDP to StreamPix

%% Aligning the fish
% Display the figure in the second monitor (projector)
figure2('WindowState', 'fullscreen', 'MenuBar', 'none',  'ToolBar', 'none','units','normalized','outerposition',[0 0 1 1]) 

grid = load('Stim/grid.mat');
grid = grid.TempMovie;
h = imshow(grid);

disp('Press a key when the fish is aligned!')
pause

%% Load the movies
disp('LOADING')

black_screen = zeros(HEIGHT, WIDTH, 'logical');
black_screen(1,1) = 1;
blank_screen = load('Stim/blank.mat');
blank_screen = blank_screen.TempMovie;

[~,~,order] = xlsread('stimulus_order.csv');
movies = cell(length(order), 1);
transitions = nan(length(order), 1);

for movie_id=1:length(order)
    movies{movie_id} = load(['Stim/', order{movie_id}, '.mat']);
    movies{movie_id} = movies{movie_id}.TempMovie;
    
    % The following 20 lines are pre-filling transition movies to our raw
    % stimulus movies (can be removed if the stimulus background is constant)
    transition_movie = nan;
    if movie_id < length(order) % not the last movie
       if order{movie_id}(1) == 'B' && order{movie_id+1}(1) == 'B'
           transitions(movie_id) = 0; % 0 means black to black
       elseif order{movie_id}(1) == 'D' && order{movie_id+1}(1) == 'D'
           transitions(movie_id) = 1; % 1 means white to white
       elseif order{movie_id}(1) == 'B' && order{movie_id+1}(1) == 'D'
           transitions(movie_id) = 2; % 2 means black to white
       elseif order{movie_id}(1) == 'D' && order{movie_id+1}(1) == 'B'
           transitions(movie_id) = 3; % 3 means white to black
       end
    end
end
disp('LOADED')

%% Send UDP tigger to StreamPix to start recording
u = udp(HOSTNAME,6610);
fopen(u);
fwrite(u, 'Action0001[create new sequence and start recording()]:');

%% 3 second wait time at the start
disp('SOME WAITING TIME')
pause(WAIT_TIME)

%% Play the movies
user_data = struct();
user_data.movies = movies;
user_data.fig_handler = h;
user_data.udp = u;
user_data.str = str;
user_data.FRAMEPERIOD = FRAMEPERIOD;
user_data.TRANSITION_FRAMES = TRANSITION_FRAMES;
user_data.order = order;
user_data.timers = cell(length(order),1);
user_data.black_screen = black_screen;
user_data.blank_screen = blank_screen;
user_data.transitions = transitions;

% setting up the timer callback function
t1 = timer('ExecutionMode', 'fixedRate','Period', STIMULUS_TIME,...
    'TasksToExecute', length(order),'TimerFcn', @display_stimulus,...
    'UserData', user_data);

start(t1);wait(t1);delete(t1);
pause(STIMULUS_TIME); imshow(black_screen)
%% Stop the recording and close the UDP socket
fwrite(u, 'Action0001[Stop Record()]:');
% fwrite(u, 'Action0001[create new sequence()]:');
fclose(u);


%% Timer callback function
function display_stimulus(TimerH, ~)
    data = TimerH.UserData;
    movie_id = TimerH.TasksExecuted;
    movie = data.movies{movie_id};
   
    % setting up the timer callback function
    data.timers{movie_id} = timer('ExecutionMode', 'fixedRate','Period', data.FRAMEPERIOD,...
        'TasksToExecute', size(movie, 3)+data.TRANSITION_FRAMES, 'TimerFcn', @display_img,...
        'UserData', {movie, data.fig_handler, data.udp, data.str, ...
        data.TRANSITION_FRAMES, data.transitions(movie_id), ...
        data.black_screen, data.blank_screen});
    
    start(data.timers{movie_id});

    disp(['Stimulus', num2str(movie_id), ' - ', data.order{movie_id}])
end

%% Timer callback function
function display_img(TimerH, ~)
    data = TimerH.UserData;
    frame_num = TimerH.TasksExecuted;
    
    % Update the frame
    if frame_num <= size(data{1}, 3)
        data{2}.CData = data{1}(:,:,frame_num);
    else % transition frames
        if data{6} == 0 % black to black
            data{2}.CData = data{7};
        elseif data{6} == 1 % white to white
            data{2}.CData = data{8};
        elseif data{6} == 2 % black to white
            transition_frame = data{8}.*((frame_num - size(data{1}, 3))/data{5});
            transition_frame(1,1) = 1;
            data{2}.CData = transition_frame;
        elseif data{6} == 3 % white to black
            transition_frame = data{8}.*(1 - (frame_num - size(data{1}, 3))/data{5});
            transition_frame(1,1) = 1;
            data{2}.CData = transition_frame;
        end
    end
        
    if frame_num==1 % First frame of the stimulus movie, send UDP packet
        fwrite(data{3}, data{4});
    end
    drawnow;
    
    if frame_num == (size(data{1}, 3)+data{5}) % Last frame 
        disp('finished')
        stop(TimerH); delete(TimerH);
    end
end