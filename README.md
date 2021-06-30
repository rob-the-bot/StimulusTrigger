# StimulusTrigger

This repo hosts the code for displaying stimulus videos in MATLAB, and communicates with StreamPix through UDP trigger to start/end recording.

## Things to know
1. The stimulus files should be in the format of 720x1280 logical arrays saved in `mat` format.
2. The stimuli are played at 30FPS.
3. The order of the stimulus playback are governed by the launch file `stimulus_order.csv`.

To use this program with StreamPix, first set up the UDP trigger module in StreamPix and set the port to 6610

## Future improvements
1. Line 7 `HOSTNAME` can be changed to something like `127.0.0.1` which represents localhost, if the experiment is conducted using just one PC.
2. Line 62 which sends trigger to 
3. The program reads duplicated stimuli multiple times, this can be improved by setting up something like a dictionary or a look-up table.
