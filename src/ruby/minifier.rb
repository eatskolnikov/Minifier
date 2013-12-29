require 'uglifier'
require 'net/ftp'
require 'optparse'
require 'FileUtils'
require 'yui/compressor'
 
hash_options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: your_app [options]"
  opts.on('-s [ARG]', '--sources_path [ARG]', "Specify the sources folder") do |v|
    hash_options[:s] = v
	puts hash_options[:s]
  end
  opts.on('-d [ARG]', '--destination_path [ARG]', "Specify the destination folder, if unspecified the source folder will be mirrored on server root") do |v=''|
    hash_options[:destination_path] = v
  end
  opts.on('-f [arg]', '--ftp_config_file [arg]', "Specify the path to the file containing the ftp server url and credentials") do |v|
    hash_options[:ftp_config_file] = v
  end
  opts.on('--version', 'Display the version') do 
    puts "0.1"
    exit
  end
  opts.on('-h', '--help', 'Display this help') do 
    puts opts
    exit
  end
end.parse!

if !Dir::exist?(hash_options[:s])
	puts 'The specified source path is not valid or doesnt exists'
	puts "'" << hash_options[:s] << "'"
	exit
end
if !hash_options[:ftp_config_file] == nil or !File::exist?(hash_options[:ftp_config_file])
	puts 'The specified ftp config file path is not valid'
	puts "'" << hash_options[:ftp_config_file] << "'"
	exit
end

ftp_configs = {}
lines=File.open(hash_options[:ftp_config_file]).readlines
ftp_configs[:server] = lines[0];
ftp_configs[:user] = lines[1];
ftp_configs[:pwd] = lines[2];

@tmpdir = Dir.mktmpdir("jsau_tmp") 
@original_path = hash_options[:s]
@destination = hash_options[:destination_path]

def minify(path, parents='/')
	puts path
	Dir.foreach(path) do |f|
		next if f == '.' or f == '..'
		next_path = File.join(path, f)
		if(File.directory?(next_path))
			minify(next_path, next_path.sub(@original_path,""))
		else
			if(File.extname(f) == ".js" or File.extname(f) == ".css")
				
				FileUtils.mkpath(@tmpdir+parents) if(!Dir.exists?(@tmpdir+parents))
				open(File.join(@tmpdir+parents, f), "w") do |tmpfile| 
					if(f.include? "min.js" or f.include? "min.css")
						tmpfile.write File.read(next_path)
					else
						compressor = YUI::CssCompressor.new if File.extname(f) == ".css"
						compressor = YUI::JavaScriptCompressor.new if File.extname(f) == ".js"
						tmpfile.write compressor.compress File.read(next_path)
					end
				end
			end
		end
	end
end

minify(hash_options[:s])


#Net::FTP.open('example.com') do |ftp|
#  ftp.login
#  files = ftp.chdir('pub/lang/ruby/contrib')
#  files = ftp.list('n*')
#  ftp.getbinaryfile('nif.rb-0.91.gz', 'nif.gz', 1024)
#end