require 'rubygems'
require 'json'
require 'Time'
require './SPEF_Keywords'
 
# print line with project, date, source, creator, issue #, reporter, keywords, topic
def write_data_row(d_id,project_month,d_created_at,d_reportedBy,d_owner,project="phpMyAdmin",topic="",source="Bug Tracker",count,filename,d_content)

  print project_month, ", ", d_created_at, ", ", project, ", ", topic, ", ",  source,  ", ", d_id, ", ",
  d_reportedBy, ", ", d_owner, ", " , "\n" # d_content, ", ", count, ", ", filename
end

project = ARGV[0]
pathname = ARGV[1]
# print "ProjectMonth,EventDate,Project,Practice,Source,DocId,creator,assignee\n"
Dir.foreach(pathname) do |filename|
next if filename == '.' or filename == '..'
count = 0
d_reportedBy = 'pat'
d_owner = d_id = d_created_at = project_month = ""
d_content = "Content: "

File.open(pathname + '/' + filename).each do |l| 
  if ! l.valid_encoding?
    l = l.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')
  end
  if match = l[/^From (.*)$/,1]
    if count > 0
      SPEF_Keywords::Topics.map { |t| 
        if d_content.scan(t[:keywords]).length > 0
          write_data_row(d_id,project_month,d_created_at,d_reportedBy,d_owner,project=project,t[:topic],source="email",count,filename,d_content)
        end
      }
    end
    count = count + 1
    d_owner = d_id = d_created_at = project_month = ""
    d_content = "Content: "
  end
    if match = l[/^From: (.*)/, 1]
        d_owner = match
        # puts "d_owner: ", d_owner
    end
    if match  = l[/^Message-ID: (.*)/, 1]
      d_id = match
      # puts "d_id: ", d_id
    end
    if match  = l[/^Date: (.*)/, 1]
      tmp_date = match
      begin
        d_created_at = (Date.parse tmp_date).strftime("%Y-%m-%d")
        project_month = ((Date.parse tmp_date) >> 1).strftime("%Y-%m-01")
      rescue ArgumentError
        # d_created_at = save_date
      end
      # puts "project_month: ", d_created_at
    end
  d_content << l
# print count, ", ", d_content.length, ", " , "\n"
end
end
