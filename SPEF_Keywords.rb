# Keywords (implemented as regexps) for SPEF Practices
module SPEF_Keywords
    # Keywords to match against our security, practice topics
    williams_security_terms = /crash|denial of service|access level|sizing issues|resource consumption|data loss|flood|integrity|overflow|null problem|overload|protection|leak/
    gegick_security_terms = /security|vulnerability|vulnerable|hole|exploit|attack|bypass|backdoor|threat|expose|breach|violate|fatal|blacklist|overrun|insecure/

   ADCS = /street address|credit card number|data classification|data inventory|Personally Identifiable Information (PII)|user data|privacy/
   ASR = /authentication|authorization|requirement|use case|scenario|specification|confidentiality|availability|integrity|non-repudiation|user role|regulations|contractual agreements|obligations|risk assessment|FFIEC|GLBA|OCC|PCI DSS|SOX|HIPAA/ 
   PTM = /threats|attackers|attacks|attack pattern|attack surface|vulnerability|exploit|misuse case|abuse case/ 
   DTS = /stack|operating system|database|application server|runtime environment|language|library|component|patch|framework|sandbox|environment|network|tool|compiler|service|version/ 

   ASCS =	/avoid|banned|buffer overflow|checklist|code|code review|code review checklist|coding technique|commit checklist|dependency|design pattern|do not use|enforce function|firewall|grant|input validation|integer overflow|logging|memory allocation|methodology|policy|port|security features|security principle|session|software quality|source code|standard|string concatenation|string handling function|SQL Injection|unsafe functions|validate|XML parser/ 

   AST = /automate|automated|automating|code analysis|coverage analysis|dynamic analysis|false positive|fuzz test|fuzzer|fuzzing|malicious code detection|scanner|static analysis|tool/ 
   PST = /boundary value|boundary condition|edge case|entry point|input validation|interface|output validation|replay testing|security tests|test|tests|test plan|test suite|validate input|validation testing|regression test/ 
   PPT = /penetration/ 
   PSR = /architecture analysis|attack surface|bug bar|code review|denial of service|design review|elevation of privilege|information disclosure|quality gate|release gate|repudiation|review|security design review|security risk assessment|spoofing|tampering|STRIDE/ 

   POG = /administrator|alert|configuration|deployment|error message|guidance|installation guide|misuse case|operational security guide|operator|security documentation|user|warning/ 
   TV = /bug|bug bounty|bug database|bug tracker|defect|defect tracking|incident|incident response|severity|top bug list|vulnerability|vulnerability tracking/ 
   IDP = /architecture analysis|code review|design review|development phase,gate|root cause analysis|software development lifecycle|software process/ 
   PSTR = /awareness program|class|conference|course|curriculum|education|hiring|refresher|mentor|new developer|new hire|on boarding|teacher|training/ 

   Topics = [
         { :topic => "Security Advisory", :keywords => /PMASA|home_page\/security/ },
         { :topic => "Security Related", :keywords => williams_security_terms },
         { :topic => "Security Related", :keywords => gegick_security_terms },
         { :topic => "Apply Data Classification Scheme", :keywords => ADCS },
         { :topic => 'Apply Security Requirements', :keywords => ASR },
	 { :topic => 'Perform Threat Modeling', :keywords => PTM },
	 { :topic => 'Document Technical Stack', :keywords => DTS },
         { :topic => 'Apply Secure Coding Standards', :keywords => ASCS },
         { :topic => 'Apply Security Tooling', :keywords =>	AST },
         { :topic => 'Perform Security Testing', :keywords =>	PST },
         { :topic => 'Perform Penetration Testing', :keywords => 	PPT },
         { :topic => 'Perform Security Review', :keywords => PSR },
         { :topic => 'Publish Operations Guide', :keywords => POG },
         { :topic => 'Track Vulnerabilities', :keywords => TV },	
         { :topic => 'Improve Development Process', :keywords => IDP },
         { :topic => 'Provide Security Training', :keywords =>	PSTR }
         ]
end # module SPEF_Keywords

# require 'SPEF_Keywords'
 
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
