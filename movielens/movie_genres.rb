#!/usr/bin/ruby

INFILE=ARGV[0]
OUTFILE=ARGV[1]

File.open(OUTFILE, "w") do |outfile|
  File.open(INFILE, "r") do |infile|
    infile.each_line do |line|
      fields=line.split("\t")
      fields[1].split('|').each do |genres|
        outfile.puts "#{fields[0]}\t#{genres}"
      end
    end
  end
end
