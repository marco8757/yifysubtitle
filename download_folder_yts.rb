require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'fileutils'
require 'json'
require 'zip/zip'

# global variable for subtitle site base url
$SUBS_BASE_DOMAIN = 'https://yifysubtitles.org'

def get_all_movie_folder
  folder_name = Dir.entries(ENV['DOWNLOAD_FOLDER']).select {|entry| File.directory? File.join(ENV['DOWNLOAD_FOLDER'],entry) and !(entry =='.' || entry == '..') && entry.include?('YTS')}
  
  puts folder_name
  folder_name.each do |folder|
    get_imdb_id(folder) if (Dir.open(ENV['DOWNLOAD_FOLDER'] + folder).entries.select {|entry| File.join('.',entry) and entry.end_with?('.srt')}).empty?
  end
end

def get_imdb_id(folder_name)
  puts "Downloading for #{folder_name}"
  movie_name = URI.escape(folder_name.split('(')[0].strip)
  year = folder_name.split('(')[1].split(')')[0]

  json_result  = open("http://www.omdbapi.com/?apikey=#{ENV['OMDB_API_KEY']}&s=#{movie_name}&y=#{year}") {|f| f.read }

  parsed_json = JSON.parse(json_result)


  if parsed_json['Response'] != 'False' && parsed_json['Search'][0].any?
    imdb_movie(parsed_json['Search'][0]['imdbID'], folder_name)
    # puts parsed_json['Search'][0]['imdbID']
  else
    puts "Can't find subtitle for #{folder_name}"
    puts "Error: #{parsed_json}"
  end


end


def imdb_movie(imdb_code, folder_name)
  doc = Nokogiri::HTML(open("#{$SUBS_BASE_DOMAIN}/movie-imdb/" + imdb_code))
  downloaded = false
  puts "Loaded page"

  doc.css(".table tr.high-rating").each_with_index do |table_row, table_row_index|
    # puts table_row.css('flag').to_s
    if table_row.css('.flag').first['class'].include?('flag-gb')
      puts "Found english sub with rating: #{table_row.css('.rating-cell span').text}"
      download_zip("#{$SUBS_BASE_DOMAIN}" + table_row.css('.download-cell a').first['href'], folder_name)
      downloaded = true
      break
    end
  end

  if !downloaded

    puts "No high rated subtitle found, getting the best one now"

    doc.css(".table tr[data-id]").each_with_index do |table_row, table_row_index|
      if table_row.css('.flag').first['class'].include?('flag-gb')
        puts "Found english sub with rating: #{table_row.css('.rating-cell span').text}"
        download_zip("#{$SUBS_BASE_DOMAIN}" + table_row.css('a').first['href'], folder_name)
        downloaded = true
        break
      end
    end


  end

end

def download_zip(link, folder_name)

  puts folder_name

  doc = Nokogiri::HTML(open(link))
  
  File.open("./subtitle.zip", "wb") do |file|
    file.write open("#{$SUBS_BASE_DOMAIN}" + doc.css('a.btn-icon.download-subtitle').first['href']).read
  end
  puts "Downloaded"

  Zip::ZipFile.open("./subtitle.zip") { |zip_file|
     zip_file.each { |f|
     f_path=File.join(ENV['DOWNLOAD_FOLDER'] + folder_name, f.name)
     FileUtils.mkdir_p(File.dirname(f_path))
     zip_file.extract(f, f_path) unless File.exist?(f_path)
   }
  }
  puts "Unzipped"

  File.delete("./subtitle.zip") if File.exist?("./subtitle.zip")


end


get_all_movie_folder()