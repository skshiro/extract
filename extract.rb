#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

require "date"
require "fileutils"

def windows?(platform = RUBY_PLATFORM)
  platform =~ /win/i and platform !~ /darwin/
end

Signal.trap(:INT){
  puts "\nCTRL+C press."
  print DATA.read
  exit(0)
}

dir_date = "../release/"+Date.today.strftime("%Y%m%d")+"/#{File::basename(Dir::pwd)}/"
dirs = {} 
del_count = 0
puts "cp to [#{dir_date}] input file list. Cancel to CTRL+C."
while line = gets
  #use windows only
  line.gsub!(/\\/,"/")
  #use svn diff --summarize -r 5754:HEAD
  next if /^D .*/ =~ line
  line.sub!(/^[AM] */,"")
  #use git diff HEAD^ --name-only
  next unless /^src\/main\/(java|resources|webapp)/ =~ line

  cp_name = line.chomp!.
    sub(/\.java$/,".class").
#    sub(/^src\/main\/(java|resources)\//,"target/test-classes/")
    sub(/^src\/main\/(java|resources)\//,"src/main/webapp/WEB-INF/classes/")
  begin
    unless File.exist?(cp_name)
	puts " deleted? ... (#{cp_name})"
	del_count += 1
	next
    end
    next unless File.stat(cp_name).file?
    raise if line =~ /\.(java|properties)$/ &&
            File.stat(cp_name).mtime < File.stat(line).mtime
  rescue
    #recover to [pipe error].
    while gets
    end
    puts <<EOF
Not (found|newer) this file ... (#{cp_name})
Do you make compile or eclipse-refreash? and retry command.
EOF
    exit -1
  end
  dir_name = File::dirname(cp_name).sub(/^src\/main\/webapp/,dir_date).chomp

  dirs[dir_name] = [] unless dirs.key? dir_name
  dirs[dir_name] << cp_name
  if /.class$/ =~ cp_name
    Dir[cp_name.sub(/\.class/,"$*.class")].each do |name|
      dirs[dir_name] << name
    end
  end
end
dirs.each do |key,values|
  puts "cp to #{key}"
  FileUtils::mkdir_p(key)
  values.each do |item|
    puts "   => #{item}"
    FileUtils::cp item,key
  end
end
puts <<EOF
done to (#{dir_date})
OK!(#{del_count} files delete?)
EOF

__END__
using ...
 ex. svn
   svn diff --summarize -r 5754:HEAD | extract.rb
 ex. git
   git diff --name-only HEAD^ | extract.rb
 ex. list-file.
   extract.rb < p.txt

