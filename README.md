## About

For those who are tired to write complicated ffmpeg commands every time creating webm/mp4 video file.

## Usage

1. Put your configuration in `make_webm_main.sh` file.

  * Ensure you are using right paths for `bash`, `ffmpeg`, `ffprobe`, `mpv`, `wc` and `rm` (comment out `ffprobe`, `mpv`, `wc` if you don't need them; uncomment `rm` to remove temporary subtitles after).
   
  * Put path to video file, run `make_webm_main.sh` in terminal to see `ffprobe` output, then press `Ctrl+C`.

  * Put id of desired internal streams in `AUDIO` and `SUBS` or live them blank.

  * `SKIP_PASS_1` helps when re-encode webm one more time.

2. Run `make_webm_main.sh` again.

## Settings recommendations

Below are some FFmpeg speed and quality settings recommended alongside internet.

**VP9**

The CRF value can be from 0–63. Recommended values range from 15–35, with 31 being recommended for 1080p HD video.

Recommended quality settings: https://developers.google.com/media/vp9/settings/vod/

`tile-columns`, `row-mt`: https://stackoverflow.com/questions/41372045/vp9-encoding-limited-to-4-threads

`cpu-used`: Valid range is from 0 to 8, higher numbers indicating greater speed and lower quality. The default value is 1, which will be slow and high quality.

**HEVC**

The default CRF is 28, and it should visually correspond to libx264 video at CRF 23, but result in about half the file size.

Available presets (hardcoded in `make_webm_next.sh`): `ultrafast`, `superfast`, `veryfast`, `faster`, `fast`, `medium` - default preset, `slow`, `slower`, `veryslow`.

**x264**

The range of the CRF scale is 0–51, where 0 is lossless, 23 is the default, and 51 is worst quality possible. A lower value generally leads to higher quality, and a subjectively sane range is 17–28. Consider 17 or 18 to be visually lossless or nearly so; it should look the same or nearly the same as the input but it isn't technically lossless.

The range is exponential, so increasing the CRF value +6 results in roughly half the bitrate / file size, while -6 leads to roughly twice the bitrate.

Note: The 0–51 CRF quantizer scale mentioned on this page only applies to 8-bit x264. When compiled with 10-bit support, x264's quantizer scale is 0–63. You can see what you are using by referring to the ffmpeg console output during encoding (yuv420p or similar for 8-bit, and yuv420p10le or similar for 10-bit). 8-bit is more common among distributors.

## Changelog

1.0 &nbsp; Stable release.  
1.0.1      Fix executable file extension dropped.  
1.1 &nbsp; Add option to remove temporary subtitles after processing.  
1.1.1      Simplify code.  
1.1.2      Partial fix issue when subtitles does't explicity determined.  
1.2 &nbsp; Add `copy` video encoder.  
2.0 &nbsp; Replace `-map` by explicit definition of internal streams.  
2.1 &nbsp; Add `libx264` video encoder.  
2.2 &nbsp; Add `start`, `end` aliases for time values.
2.2.1      Fix reading subtitles from within container.
2.3 &nbsp; Show output file size using `wc`.
