# get_git_issue - retrieve issue from git repo, write issue (and comments) as json file
# get_git_issues repo username password issue issues_dir
require 'octokit'
require 'csv'
require 'date'
require 'json'

# The project you are mirroring issues from
REPO = ARGV[0]
USERNAME = ARGV[1]
PASSWORD = ARGV[2]
ISSUE = ARGV[3]
ISSUE_DIR = ARGV[4]
LOOP_FLAG = ARGV[5]

class GH
  attr_accessor :repo
  attr_accessor :client
  attr_accessor :issues
  attr_accessor :comments

  def initialize(repo)
    @repo = repo
    @client = Octokit::Client.new(:login => USERNAME, :password => PASSWORD, auto_traversal: true)
  end

  def get_all_issues()
    repo = @repo
    client = @client
    issues = client.list_issues(repo)
    puts repo
    puts issues.total_count
    count = 0
    begin
      issues.map { |issue|
        count = count + 1
        puts count
        if count > 500 
          raise SystemExit
        end
        r = issue.to_hash() 
        r[:user] = r[:user].to_hash
        puts r[:number]
      } 
    end while (issues = client.last_response.rels[:next])
  end

  def get_issue(issue_id)
    repo = @repo
    client = @client
    # puts(repo)
    issue = client.issue(repo, issue_id)
    issue["comments"] = client.issue_comments(repo,issue_id) 
    r = issue.to_hash() 
    r[:user] = r[:user].to_hash
    r[:assignee] = r[:assignee] ? r[:assignee].to_hash : nil
    r[:pull_request] = r[:pull_request] ? r[:pull_request].to_hash : nil
    r[:labels] = r[:labels].map { | label | 
           label.to_hash }
    # puts r[:user], r[:labels]
    # puts r[:comments]
    return issue
  end
  # get them one at a time

  def generate_json(issue)
    # convert issues and comments to json with appropriate fields
    # need owner, reportedBy title description content
    # number -> "_id"
    # user->login to reportedBy
    # assignee->login to reportedBy
    # title to title
    # body -> content
    # comments need author and content    
    # so map body to content
    # user->login to author
    # body to content

      newissue = Hash.new
      newissue["_id"] = issue[:number]
      newissue["created_at"] = issue[:created_at]
      newissue["reportedBy"] = issue[:user][:login]
      newissue["owner"] = ((issue[:assignee])?issue[:assignee][:login]:"")
      newissue["content"] = (issue[:title] ? issue[:title] : "") + "\n" + (issue[:body] ? issue[:body] : "")
      newissue["comments"] = issue["comments"].map { |comment| 
        newcomment = Hash.new
        newcomment["content"] = comment[:body]
        newcomment["author"] = comment[:user].is_a?(Hash) ? comment[:user][:login] : ""
        newcomment["created_at"] = comment[:created_at]
        newcomment["html_url"] = comment[:html_url]
	newcomment
      }
      { "doc" => newissue }
    return JSON.pretty_generate( newissue )
  end
end

gh = GH.new(REPO);
if LOOP_FLAG == "-All"
  gh.get_all_issues()
else
  if !File.file?(ISSUE_DIR + "/" + ISSUE + ".json")
    issue = gh.get_issue(ISSUE);
    issue_json = gh.generate_json( issue )
    File.new(ISSUE_DIR + "/" + ISSUE + ".json","w").write( issue_json )
  end 
end

