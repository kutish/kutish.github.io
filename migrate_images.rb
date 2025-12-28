require 'find'
require 'fileutils'

# --- CONFIGURATION ---
# 1. The specific folder to scan
search_folder = 'china/_posts' 

# 2. The part of the path to STRIP out (so /assets/images/china... becomes china...)
prefix_to_remove = "/assets/images/"
# ---------------------

# Safety check: Ensure the folder exists
unless Dir.exist?(search_folder)
  puts "Error: Could not find folder '#{search_folder}'"
  puts "Are you running this script from the root of your project?"
  exit
end

# The Regex Pattern
# Matches: <figure> ... <img src="..."> ... <figcaption> ... </figure>
# It works even if the HTML is spread across multiple lines.
pattern = /<figure>\s*<img\s+src="([^"]+)"[^>]*>\s*<figcaption>(.*?)<\/figcaption>\s*<\/figure>/m

puts "Starting migration in: #{search_folder}"
count = 0

Find.find(search_folder) do |path|
  # Only process Markdown files
  next unless path =~ /\.(md|markdown)$/

  original_content = File.read(path)
  
  if original_content.match?(pattern)
    puts "Processing: #{path}"
    
    # Perform the replacement
    new_content = original_content.gsub(pattern) do
      full_src = $1  # The full src found in the HTML
      caption  = $2  # The caption text found in the HTML
      
      # CLEAN THE PATH:
      # 1. Remove "/assets/images/"
      # 2. Remove any leading slash just in case
      clean_path = full_src.sub(prefix_to_remove, '').sub(/^\//, '')

      # Generate the Jekyll Picture Tag
      <<~LIQUID.chomp
      <figure>
        {% picture default #{clean_path} alt="#{caption}" %}
        <figcaption>#{caption}</figcaption>
      </figure>
      LIQUID
    end

    File.write(path, new_content)
    count += 1
  end
end

puts "Done! Updated #{count} files."