require 'rubygems'
require 'json'
require 'Time'
require 'csv'

def get_content(issue)
  parsed = JSON.parse(issue)
  contents = parsed['content']
  parsed['comments'].each do |c|
    contents << c['content']
  end
return contents
end


require './SPEF_Keywords'
 
# print line with project, date, source, creator, issue #, reporter, keywords, topic
def write_data_row(d,project="phpMyAdmin",topic="",source="Bug Tracker")

  current = DateTime.parse(d['created_at'])
  print (current >> 1).strftime("%Y-%m-01"), ", "
  print (current).strftime("%Y-%m-%d"), ", "
  print project, ", ", topic, ", ",  source,  ", ", d['_id'], ", "
  print d['reportedBy'], ", ", d['owner'], ", "  # , d['content'] 
  print "\n"
end

project = ARGV[0]
pathname = ARGV[1]
# header line for csv file, define field names
print "ProjectMonth,EventDate,Project,Practice,Source,DocId,creator,assignee,\n"
Dir.foreach(pathname) do |filename|
  next if filename == '.' or filename == '..'
  next if filename.scan('.json').length == 0
  file = File.read(pathname + '/' + filename) 

  if ! file.valid_encoding?
    file = file.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')
  end

  begin
    parsed = JSON.parse(file)
  rescue Exception
    puts ("Couldn't parse " + filename)
  end

  contents = get_content(file)
  # Following line writes a file containing the text of the issue and its comments
  # File.new(pathname + '/' + String(parsed['_id']) + ".txt","w").write( contents )
  # puts(String(parsed['_id']))
  SPEF_Keywords::Topics.map { |t| 
    if contents.scan(t[:keywords]).length > 0
       write_data_row(parsed,project="phpMyAdmin",t[:topic],source="Bug Tracker")
    end
  }
end
