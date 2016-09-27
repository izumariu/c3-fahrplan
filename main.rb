#!/usr/bin/ruby
require 'net/http'
require 'io/console'
require 'json'
require 'time'
include Net

def putsCharwise(s,reference)
	for ch in s.split("")
		print ch
		sleep 0.005
	end
	reference!=nil&&(((s.length-reference.length).times{print " ";sleep 0.001})rescue nil)
	puts "                            "
	sleep 0.005
end

print "// Getting current year....."
year = Time.now.to_s.split(" ")[0].split("-")[0]
puts year
begin
	print "// Getting JSON....."
	jsonfile = JSON.parse(HTTP.get(URI("https://events.ccc.de/congress/#{year}/Fahrplan/schedule.json")))
	puts "OK"
rescue
	puts "FAILURE"
	print "// The Fahrplan of this year could not be found. Use the last one (#{(year.to_i-1).to_s}) instead? (Y/n) "
	desc=STDIN.getch;puts(desc);!(desc.upcase=="Y"||desc=="\r")&&(puts("// Quitting.");exit(0))
	year = (year.to_i-1).to_s
	puts "// Year was set to #{year}"
	retry
end

puts "##########################################################################"
puts "This is the Fahrplan for CCCongress #{year}, v#{jsonfile["schedule"]["version"]}"
print(`clear`||`cls`)
loop do
	print "\033[0;0H"
	days=jsonfile["schedule"]["conference"]["days"].map{|d|d["date"]}
	day = days[0]  #  !!!REMOVE PRESET DATE!!!
	dayc = jsonfile["schedule"]["conference"]["days"][days.index(day)]
	next_talks_prev=next_talks rescue nil
	next_talks={};dayc["rooms"].each_key{|k|next_talks[k]={"speaker"=>"","name"=>"","description"=>"","time_left"=>""}}
	dayc["rooms"].each_pair{|hall,curr_room|
		i = 0
		while Time.parse(curr_room[i]["start"])-Time.now <= 0
			i+=1
		end
		if i < dayc["rooms"][hall].length
			select = dayc["rooms"][hall][i]
			next_talks[hall]["speaker"]     = []
				select["persons"].each{|p|next_talks[hall]["speaker"] << p["public_name"]}
				next_talks[hall]["speaker"] = next_talks[hall]["speaker"].join(", ")
			next_talks[hall]["name"]        = select["title"]
			next_talks[hall]["description"] = select["subtitle"]
			next_talks[hall]["time_left"]   = 
				(((Time.parse(select["start"])-Time.now)/60).round(1).ceil/60).to_i.to_s+"h"+(((Time.parse(select["start"])-Time.now)/60).round(1).ceil%60).to_s+"min"
		else
			if dayc["date"]!=days[-1]
				select = jsonfile["schedule"]["conference"]["days"][days.index(day)+1]
				next_talks[hall]["speaker"]     = []
					select["persons"].each{|p|next_talks[hall]["speaker"] << p["public_name"]}
					next_talks[hall]["speaker"] = next_talks[hall]["speaker"].join(", ")
				next_talks[hall]["name"]        = select["title"]
				next_talks[hall]["description"] = select["subtitle"]
				next_talks[hall]["time_left"]   = 
					(((Time.parse(select["start"])-Time.now)/60).round(1).ceil/60).to_i.to_s+"h"+(((Time.parse(select["start"])-Time.now)/60).round(1).ceil%60).to_s+"min"
			else
				next_talks[hall]["speaker"]     = nil
				next_talks[hall]["name"]        = nil
				next_talks[hall]["description"] = nil
					next_talks[hall]["time_left"]   = nil
			end
		end
	}

	putsCharwise "##################################",nil
	putsCharwise "#           NEXT TALKS           #",nil
	putsCharwise "##################################",nil
	next_talks.each_pair do |k,v|
		putsCharwise k.upcase,nil
		if v["speaker"]!=nil
			putsCharwise "[#{v["speaker"]}]",(next_talks[k]["speaker"] rescue nil)
			putsCharwise "\"#{v["name"]}\"",(next_talks[k]["name"] rescue nil)
			v["description"].match(/^[ \n\t\r\f]*$/)==nil ? (putsCharwise "{"+v["description"]+"}",(next_talks[k]["description"] rescue nil)) : (putsCharwise "{--No subtitle--}",nil)
			putsCharwise "=> starting in "+v["time_left"],nil
		else
			putsCharwise "[No more talks left]",nil
		end
		puts ""
	end
	#10.times{puts "                                                                "}
	until Time.now.to_s.split(" ")[1].match(/^\d{2}\:\d{2}\:01/);end
end
