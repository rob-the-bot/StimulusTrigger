# StimulusTrigger

This repo hosts the code for displaying stimulus videos in MATLAB, and communicates with StreamPix through UDP trigger to start/end recording.

## Things to know
1. The stimulus files should be in the format of 720x1280 logical arrays saved in `mat` format, saved in the [Stim](Stim/) folder.
2. The stimuli are played at 30FPS.
3. The order of the stimulus playback are governed by the launch file [`stimulus_order.csv`](stimulus_order.csv).
4. Line 62 which sends trigger to StreamPix can be modified to

```MATLAB
fwrite(u, 'Action0001[create new mp4 and start recording()]:');
```

which will create a new mp4 file (mostly used for online compression) and start recording.

To use this program with StreamPix, first set up the UDP trigger module in StreamPix and set the port to 6610

## Future improvements
1. Line 7 `HOSTNAME` can be changed to something like `127.0.0.1` which represents localhost, if the experiment is conducted using just one PC.
2. The program reads duplicated stimuli multiple times, this can be improved by setting up something like a dictionary or a look-up table.
