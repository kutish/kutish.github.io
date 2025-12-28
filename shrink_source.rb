require 'fileutils'

# --- CONFIGURATION ---
SOURCE_FOLDER = 'assets/images'
MAX_WIDTH     = 2000  # Max width in pixels
QUALITY       = 85    # JPEG quality (0-100)
# ---------------------

# Check if Vips is installed
unless system("vips -v > nul 2>&1")
  puts "Error: 'vips' command not found. Please ensure Libvips is in your PATH."
  exit
end

puts "🔍 Scanning #{SOURCE_FOLDER} for large images..."
count = 0
saved_space_mb = 0

Dir.glob("#{SOURCE_FOLDER}/**/*.{jpg,jpeg,png,JPG,JPEG,PNG}") do |file|
  # Get current file size
  original_size = File.size(file)
  
  # Escape file path for shell command
  safe_path = "\"#{file}\""
  
  # Create a temporary output filename
  temp_output = "#{file}.tmp.jpg"
  safe_temp = "\"#{temp_output}\""

  # Run vips thumbnail command
  # This command resizes the image to fit within MAX_WIDTH x MAX_WIDTH
  # while maintaining aspect ratio, and auto-rotates based on EXIF data.
  success = system("vips thumbnail #{safe_path} #{safe_temp} #{MAX_WIDTH} --height #{MAX_WIDTH}")

  if success
    new_size = File.size(temp_output)

    # Only overwrite if the new file is actually smaller
    if new_size < original_size
      FileUtils.mv(temp_output, file)
      saved = (original_size - new_size) / 1024.0 / 1024.0
      saved_space_mb += saved
      puts "✅ Shrunk: #{file} (-#{saved.round(2)} MB)"
      count += 1
    else
      # If the original was already small, just delete the temp file
      File.delete(temp_output)
      puts "Skipped (already small): #{file}"
    end
  else
    puts "❌ Failed to process: #{file}"
    File.delete(temp_output) if File.exist?(temp_output)
  end
end

puts "------------------------------------------------"
puts "🎉 Done! Resized #{count} images."
puts "💾 Total space saved: #{saved_space_mb.round(2)} MB"