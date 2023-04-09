## About

For those who are tired to write complicated ffmpeg commands every time creating webm/mp4 video file.

## Usage

1. Put your configuration in `make_webm_launch.sh` file.

  * Ensure you are using right paths for `bash`, `ffmpeg`, `ffprobe`, `mpv`, `date`, `wc` and `rm` (comment out `ffprobe`, `mpv`, `wc`, `rm` if you don't need them).

  * Put path to video `FILE`, run `make_webm_launch.sh` in terminal to see `ffprobe` output, then press `Ctrl+C`.

  * Put id of desired internal streams in `VIDEO`, `AUDIO` and `SUBS` or live some of them blank.

  * `SS` and `TO` are start and final time points. You can also live them blank.

  * Fill `CONT`, `CV`, `CRF`, `ENCODE_SPEED`, `CA`, `BA`, `TEMP`. Other variables may be blank or commented out.

2. Run `make_webm_launch.sh` again.

## Variables description

`SS`, `TO` - start and final time points in HH:MM:SS.ms format, for example 00:05:05.0 or 01:20:15.330; number of digits of Milliseconds shoud be equal in both `SS` and `TO`.

`VIDEO`, `AUDIO`, `SUBS` - indexes of used streams in `FILE` you can see in ffprobe output: `Stream #0:0: Video: h264 (Main)`...`Stream #0:1: Audio: aac (LC)` (it is the second digit in d:d pair).

`CONT` - output container: `webm`, `mp4` or `mkv`.

`SCALE` - suitable to reduce video scale (https://trac.ffmpeg.org/wiki/Scaling).

`PIX_FMT` - pixel format; supported formats: `ffmpeg -pix_fmts`; formats supported by encoder: `ffmpeg -h encoder=libx265`; for maximum compatibility with players use `yuv420p`, otherwise live it blank.

`CV` - video coding format: `vp9`, `x264`, `x265`, `copy`. Should be compatible with `CONT`.

`CRF` - video quality; see Settings recommendations section below.

`ENCODE_SPEED` - it is the same as `cpu-used` for libvpx-vp9 and `preset` for libx264/libx265 codecs; must be in 0..8 range, where 0 is the best quality and slowest encode speed.

`CA` - audio codec: `libopus`, `libfdk_aac`, `copy`, etc. Should be compatible with `CONT`.

`BA` - audio bitrate, `192K` means 192 kbps.

`TITLE` - metadata title.

`VIDEO_LANG`, `AUDIO_LANG`, `SUBS_LANG` - languages of internal streams; it is good practice to define them.

`HARDSUB` - if `true`, subtitles burned into video, if `false`, subtitles added as separate stream.

`TEMP` - folder for temporary files and output.

## Settings recommendations

Below are some FFmpeg speed and quality settings recommended alongside internet.

**VP9**

The CRF value can be from 0–63. Recommended values range from 15–35, with 31 being recommended for 1080p HD video.

Recommended quality settings: https://developers.google.com/media/vp9/settings/vod/

`tile-columns`, `row-mt` (change these settings in `make_webm.sh` acording number of your processor threads): https://stackoverflow.com/questions/41372045/vp9-encoding-limited-to-4-threads

**x265**

The default CRF is 28, and it should visually correspond to libx264 video at CRF 23, but result in about half the file size.

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
2.3.1      Fix audio file cutting. Fix file size show.  
3.0 &nbsp; Add picking of hevc/x264 `PRESET`. Remove rarely used webm option `SKIP_PASS_1`.  
3.0.1      Simplify code.  
4.0 &nbsp; Replace `PRESET` and `cpu-used` by common `ENCODE_SPEED` option.  
5.0 &nbsp; Add video `SCALE`. Add picking `VIDEO` stream. Replace `start`, `end` aliases with empty strings. Rename `make_webm_next.sh`->`make_webm.sh`, `make_webm_main.sh`->`make_webm_launch.sh`.  
6.0 &nbsp; Add video `PIX_FMT`. Add variables description in README.  
