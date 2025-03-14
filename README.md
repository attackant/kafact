# KAFACT ⚡︎ **K**ick **A**ss **F**ree **A**udio **C**leanup **T**ool

A powerful local solution for processing videos with professional-grade audio enhancements, without the cost or limitations of cloud services like Auphonic. Thanks to Auphonic for the inspriation, I think they have a cool service if you need more freatures, including an API. Check 'em out.

Backstory is that I wanted cleaner audio for [my YouTube channel](https://www.youtube.com/@RenaissanceDaddy) without using fancy mics, and found some cloud services that could do this, but for the upload times were killing me, so I made this Bash script.

## Features

- 🔊 Studio-quality audio cleanup for your videos
- 🎬 Optional video resizing to 1080p for optimal YouTube uploads
- 🖥️ 100% local processing - no upload/download times or browser tabs to keep open
- ⚙️ Customizable presets to match your exact needs
- 🤖 Simple automation to streamline your workflow
- 📱 Works seamlessly with videos from Android phones or any source

## How It Works

KAFACT uses FFmpeg to apply a series of audio enhancements similar to what commercial services offer:

- Noise reduction and speech isolation
- Adaptive leveling and compression
- Loudness normalization for consistent audio levels
- Silence detection and removal
- Metadata embedding

## Requirements / Prerequisites
   - FFmpeg (v4.0 or higher recommended)
   - Bash shell (v4.0 or higher)
   - Basic command line knowledge
   - Storage space (processed videos may be similar in size to originals)
- Basic command line knowledge

## Installation

### macOS

```
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install FFmpeg and Codecs
brew install ffmpeg rnnoise fdk-aac libass librsvg libvorbis libvpx opus x265

# Clone this repository wherever you want it
git clone https://github.com/attackant/kafact.git
cd kafact

# Make the script executable
chmod +x kafact.sh
```

### Ubuntu/Debian

```
# Install required packages
sudo apt-get update
sudo apt-get install -y ffmpeg

# Clone this repository
git clone https://github.com/attackant/kafact.git
cd kafact

# Make the script executable
chmod +x kafact.sh

# Copy preset file to your home directory
mkdir -p ~/Videos
```

## Quick Start

1. Copy your videos to `~/Videos/raw/`
2. Run the script:
   ```
   ./kafact.sh
   ```
3. Find your processed videos in `~/Videos/processed/`

## Configuration

Edit the preset file to adjust audio and video processing parameters:

```
# Edit preset file
nano ~/Videos/youtube_preset.conf
```

The preset file contains well-documented settings for:
- Noise reduction strength
- Compression levels
- Loudness targets
- Silence detection thresholds
- Video quality settings
- Metadata fields

## Advanced Usage

### Custom Directories and Presets

```
./kafact.sh --input /path/to/videos --output /path/to/output --preset /path/to/custom_preset.conf
```

### Processing Single Files

```
./kafact.sh --single /path/to/video.mp4
```

### Creating Specialized Presets

Copy the default preset to create specialized versions:

```
cp ~/Videos/kafact/youtube_preset.conf ~/Videos/kafact/podcast_preset.conf
```

Then edit to match your specific needs. (Where `~/Videos/kafact/` is the folder you cloned the repo.)

## Workflow Tips

### Android to Mac Workflow

1. Connect your Android phone via USB
2. Copy videos to your Mac
3. Run KAFACT to process them
4. Upload the processed videos to YouTube

### Automation

You can set up automations to:
- Process videos when they're copied to a specific folder
- Run KAFACT automatically when your phone is connected
- Create scheduled batch processing jobs

### **Command Examples**:

   ```
   # Process with detailed output
   ./kafact.sh --verbose
   
   # Show commands without executing (for testing)
   ./kafact.sh --dry-run
   
   # Force overwrite of existing files
   ./kafact.sh --force
   ```

   ## Troubleshooting
   
   ### Common Issues
   
   - **"No MP4 files found"**: Ensure your videos are in the correct input directory and have .mp4 extension
   - **FFmpeg errors**: Make sure you have the latest version of FFmpeg installed
   - **Processing seems slow**: Video processing is CPU-intensive; consider using a shorter preset for quicker processing
   
   Check the log file at `~/Videos/kafact_log.txt` for detailed error information.

   ## Version History
   
   - **v1.1** - Added single file processing, dry run mode, and better error handling
   - **v1.0** - Initial release with basic audio enhancement functionality

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by the functionality of Auphonic
- Built on the powerful FFmpeg framework
- Created by Animal Taggart

## Support

If you find this tool useful, consider:
- Starring the repository
- Sharing it with other creators
- Contributing improvements
- Fork it, go crazy, do your thing

For questions or support, open an issue on GitHub.
