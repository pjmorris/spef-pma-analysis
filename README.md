
# SP-EF Data Collection for phpMyAdmin

Documentation, scripts, and data for SP-EF analysis of phpMyAdmin.

To plot the graphs shown in the MSR 2016 paper (and similar graphs) based on the final dataset, follow the directions in [Show me the graphs](#graphs).  To regenerate the dataset used to plot the graphs from the component data, follow the directions in [Show me the components](#components).  To build the component data from the original phpMyAdmin datasources, follow the directions in [Show me the sources](#sources).

## <a name=“graphs”></a>Show me the graphs

### Preliminaries: loading the plotting library and the plot data
```
# install.packages(“ggplot2”)
library(ggplot2)
pmadf <- read.csv(“data/pmadf.csv”)
pmadf$ProjectMonth <- as.Date(pmadf$ProjectMonth) # Cleans up x-axis plot

```


### Context Factors
```
ggplot(data=pmadf[as.Date(pmadf$ProjectMonth) %in% seq(from=as.Date("2008-04-01"), to=as.Date("2014-04-01"),by='month') & pmadf$Factor %in% c("SLOC","Churn","Devs","Machines"),]) + geom_line(aes(x=ProjectMonth,y=Value,group=Factor)) + facet_grid(Factor~.,scales="free_y") + theme(strip.text.y = element_text(angle=0))
```

### Outcome Measures
```
ggplot(data=pmadf[as.Date(pmadf$ProjectMonth) %in% seq(from=as.Date("2008-04-01"), to=as.Date("2014-04-01"),by='month') & pmadf$Factor %in% c("VDensity","VRE"),]) + geom_line(aes(x=ProjectMonth,y=Value,group=Factor)) + facet_grid(Factor~.,scales="free_y") + theme(strip.text.y = element_text(angle=0))
```

### Practice Adherence
```
ggplot(data=pmadf[as.Date(pmadf$ProjectMonth) %in% seq(from=as.Date("2008-04-01"), to=as.Date("2014-04-01"),by='month') & pmadf$Factor %in% c(" Publish Operations Guide",          " Apply Secure Coding Standards",     " Track Vulnerabilities", " Document Technical Stack"," Perform Security Testing", " Apply Security Requirements", " Provide Security Training", " Apply Security Tooling"," Perform Security Review", " Perform Threat Modeling", " Improve Development Process"," Apply Data Classification Scheme"),]) + geom_line(aes(x=ProjectMonth,y=Value,group=Factor)) + facet_grid(Factor~.,scales="free_y") + theme(strip.text.y = element_text(angle=0))
```


## <a name=“components”></a> Show me the components

### CVSAnaly database

To read data into R from the phpmyadmin metrics database, 

To restore our backup of the phpmyadmin metrics database, log in to mysql, and create a database:
```
mysql -u your_mysql_user -p
mysql> create database phpmyadmin_cvsa;
mysql> quit
```
and then restore our data to the database:
```
mysql -u your_mysql_user -p phpmyadmin_cvsa < phpmyadmin_cvsa_db.sql
```

To generate your own copy of the phpmyadmin metrics database, run cvsanly2 on the phpmyadmin repo, as described [below](#cvsanaly).



### Issue Classifications - classify issues by practice adherence keywords, generate issue events  
```
ruby extract_issue.rb phpMyAdmin pma/issues > issue_events.csv
```


### Email Classifications - classify emails by practice adherence keywords, generate email events
```
ruby extract_email.rb phpMyAdmin pma/emails > pma/email_events.csv
```

### 

## <a name=“sources”></a> Show me the sources

### ToDo: Add code from pma_cvsa_dataload.R

### phpMyAdmin source code repository

#### Clone a local copy of the phpmyadmin repo: 
```
git clone https://github.com/phpmyadmin/phpmyadmin
```
####<a name=“cvsanaly”></a> Run CVSAnalY on phpmyadmin repo
```
cvsanaly2 --db-driver mysql --db-user your_mysql_user --db-password your_mysql_password --db-database phpmyadmin_cvsa --metrics-all --extensions=CommitsLOC,CommitsLOCDet,FileTypes,Metrics,MetricsEvo,Months,Weeks
```

### phpMyAdmin github issues

#### Get issues from phpmyadmin github issues list

##### get_git_issue creates a json file containing the issue description and comments
##### get_git_issue uses 2 github requests per file, so 2500 issues per hour is the max rate, given the 5000/hour request rate limit github imposes.
```
 for issue in `seq 1 2000`; do ruby get_git_issue.rb phpmyadmin/phpmyadmin your_gitid your_git_password $issue pma/issues; done;
for issue in `seq 2001 3000`; do ruby get_git_issue.rb phpmyadmin/phpmyadmin your_gitid your_git_password $issue pma/issues; done; &
```


### phpMyAdmin developer emails
```
mkdir pma/emails
cd pma/emails
```
```
wget https://lists.phpmyadmin.net/pipermail/developers/2014-January.txt.gz

wget https://lists.phpmyadmin.net/pipermail/developers/2014-February.txt.gz

wget https://lists.phpmyadmin.net/pipermail/developers/2014-March.txt.gz

wget https://lists.phpmyadmin.net/pipermail/developers/2014-April.txt.gz

wget https://lists.phpmyadmin.net/pipermail/developers/2014-May.txt.gz

wget https://lists.phpmyadmin.net/pipermail/developers/2014-June.txt.gz

wget https://lists.phpmyadmin.net/pipermail/developers/2014-July.txt.gz

wget https://lists.phpmyadmin.net/pipermail/developers/2014-August.txt.gz

wget https://lists.phpmyadmin.net/pipermail/developers/2014-September.txt.gz

wget https://lists.phpmyadmin.net/pipermail/developers/2014-October.txt.gz

wget https://lists.phpmyadmin.net/pipermail/developers/2014-November.txt.gz

wget https://lists.phpmyadmin.net/pipermail/developers/2014-December.txt.gz

[Repeat for 2013, … , 2001]

gunzip pma/emails *.gz
```



