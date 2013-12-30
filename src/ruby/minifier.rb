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
if hash_options[:destination_path] == nil
	hash_options[:destination_path] = ''
end

ftp_configs = {}
lines=File.open(hash_options[:ftp_config_file]).readlines
ftp_configs[:host] = lines[0].gsub("\n","").gsub("\r","");
ftp_configs[:user] = lines[1].gsub("\n","").gsub("\r","");
ftp_configs[:pwd] = lines[2].gsub("\n","").gsub("\r","");

@tmpdir = Dir.mktmpdir("jsau_tmp") 
@destination = hash_options[:destination_path]
@original_source = hash_options[:s]

moveToFtp = Proc.new do |f,d|
	destination_path = @destination+d
	Net::FTP.open(ftp_configs[:host],ftp_configs[:user],ftp_configs[:pwd]) do |ftp|
		curr_folder = ""
		folders = destination_path.split("/")
		folders.each do |folder_name| 
			curr_folder += folder_name+'/'
			begin
				ftp.mkdir(curr_folder)
			rescue
				next
			end
		end
		puts File.join(@destination+d,File.basename(f))
		ftp.put(f, File.join(@destination+d,File.basename(f)))
		ftp.close
	end
end

minify = Proc.new do |f,d|
	d = @tmpdir+d
	if(File.extname(f) == ".js" or File.extname(f) == ".css")
		FileUtils.mkpath(d) if(!Dir.exists?(d))
		open(d+File.basename(f),"w") do |tmpfile| 
			if(f.include? "min.js" or f.include? "min.css")
				tmpfile.write File.read(f)
			else
				puts f
				compressor = YUI::CssCompressor.new if File.extname(f) == ".css"
				compressor = YUI::JavaScriptCompressor.new if File.extname(f) == ".js"
				tmpfile.write compressor.compress File.read(f)
			end
		end
	end
end
def applyToTree(path, action, root=@original_source)
	Dir.foreach(path) do |f|
		next if f == '.' or f == '..'
		next_path = File.join(path, f)
		if(File.directory?(next_path))
			applyToTree(next_path, action,root)
		else
			action.call(next_path, next_path.sub(root,"").sub(File.basename(next_path),""))
		end
	end
end

puts "Minifying..."
applyToTree(hash_options[:s],minify)
puts "Uploading to FTP server..."
applyToTree(@tmpdir,moveToFtp,@tmpdir)



#Net::FTP.open(ftp_configs[:host],ftp_configs[:user],ftp_configs[:pwd]) do |ftp|
#  ftp.login
#  files = ftp.chdir('pub/lang/ruby/contrib')
#  files = ftp.list('n*')
#  ftp.getbinaryfile('nif.rb-0.91.gz', 'nif.gz', 1024)
#end