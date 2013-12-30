JSMinifierAndUploader
=====================

An assets minifier that automatically upload the files to an FTP server


Example:

ruby minifier.rb -s C:/git/website/assets -f ftp-credentials.txt -d assets

The ftp credentials file is a plaintext file with the host in the first line, the user in the second and the password in the third one.


Credits:

https://github.com/sstephenson/ruby-yui-compressor
