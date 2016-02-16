# New PMA load from cvs a

# install.packages(‘dplyr’)
library(dplyr)
# install.packages(‘lubridate’)
library(lubridate)
# install.packages(‘ggplot2’)
library(ggplot2)
# install.packages(‘ggthemes’)
library(ggthemes)
loadPMAVulns <- function(path) {
	
	wb = loadWorkbook(path)
	ovcD = readWorksheet(wb,sheet="Sheet1")
	
# patching data in a few spots…
	ovcD[747,]$Activity <- "Function Test"
	ovcD[747,]$Trigger <- "Test Interaction"
	ovcD[747,]$Impact <- "Integrity Security"
	ovcD[747,]$Target <- "Code"
	ovcD[747,]$DefectType <- "Algorithm Method"
	ovcD[747,]$Source <- "Developed in-house"
	ovcD[ovcD$DefectType %in% c("Checking "),]$DefectType <- "Checking"
	ovcD[ovcD$Impact %in% c("Integrity Security "),]$Impact <- "Integrity Security"
	ovcD[ovcD$Age %in% c("ReFixed"),]$Age <- "Refixed"
	ovcD[ovcD$Source %in% c("Reused From Library"),]$Source <- "Reused from library"
	
# set up factors
	si_levels = c("Spoofing", "Tampering",  "Repudiation", "Information Disclosure", "Denial of Service", "Elevation of Privilege")
	si_labels=c("S","T","R", "I", "D", "E")
	ovcD$SecurityImpact <- factor(ovcD$SecurityImpact,exclude=c("N/A"),levels=si_levels,labels=si_labels,ordered=TRUE)
	ovcD$PrePost <- ifelse (ovcD$Creditee=="Developer","Pre-Release","Post-Release")
	ovcD$Activity <- factor(ovcD$Activity,levels=c("Design Review","Code Inspection","Unit Test","Function Test","System Test","In Use","In Lab"),labels=c("Design Review","Code Inspection","Unit Test","Function Test","System Test","In Use","In Lab"))
	ovcD$BugType <- factor(ovcD$BugType,levels=c("Vulnerability","Defect"))
	ovcD$Trigger <- factor(ovcD$Trigger,levels=unique(ovcD$Trigger),labels=unique(ovcD$Trigger))
	ovcD$DefectType <- factor(ovcD$DefectType,levels=unique(ovcD$DefectType),labels=unique(ovcD$DefectType))
	
# project-specific data frames
	ovcFF = ovcD[ovcD$Repo == "MOZILLA",]
	ovcPMA = ovcD[ovcD$Repo == "PHPMYADMIN",]
	
	pmaVulns <-ovcPMA[ovcPMA$BugType=="Vulnerability",c("BugID","BugType","ShortDesc","CreationDate","ReleaseDate","PatchDate","Cve","PrePost")]
	return(pmaVulns) 
}

library(XLConnect)
pmaVulns <- loadPMAVulns("data/ODC+V.xlsx")
pmaVulns$ProjectMonth <- projectdate(as.Date(pmaVulns$CreationDate))

library(devtools)
devtools::load_all("~/github/SPEFTools/",TRUE)

conn <- src_mysql("phpmyadmin_cvsa",user="spef",password="spefftw2015")
spdf <- build_spdf(conn)


projTimeline <-data.frame(ProjectMonth=seq(from=as.Date(min(spdf$ProjectMonth)), to=as.Date(max(spdf$ProjectMonth)),by='month'))


# get, plot issues
projIssues <- read.csv("issue_events.csv",header=TRUE,row.names=NULL)
ggplot(data=projIssues[as.Date(projIssues$ProjectMonth) %in% seq(from=as.Date("2005-01-01"), to=as.Date("2014-04-01"),by='month'),],aes(x=ProjectMonth)) + geom_bar(aes(y=..count..,group=Practice),position=position_dodge()) + facet_grid(Practice~.) + theme_tufte() + theme(strip.text.y = element_text(angle=0))

# get, plot emails
projEmails <- read.csv("email_events.csv",header=TRUE,row.names=NULL)
ggplot(data=projEmails[as.Date(projEmails$ProjectMonth) %in% seq(from=as.Date("2005-01-01"), to=as.Date("2014-04-01"),by='month'),],aes(x=ProjectMonth)) + geom_bar(aes(y=..count..,group=Practice),position=position_dodge()) + facet_grid(Practice~.) + theme_tufte() + theme(strip.text.y = element_text(angle=0))

# plot context factors
ggplot(data=spdf[as.Date(spdf$ProjectMonth) %in% seq(from=as.Date("2001-04-01"), to=as.Date("2014-04-01"),by='month') & spdf$Factor %in% c("VDensity","Churn","Commits","Devs","SLOC"),]) + geom_line(aes(x=ProjectMonth,y=Value,group=Factor)) + facet_grid(Factor~.,scales="free_y") + theme(strip.text.y = element_text(angle=0))

# Compute VDensity, VRE
pmaVulns$N <- 1
tmpSeries1 <- alignPoints(pmaVulns,group_by(pmaVulns[pmaVulns$BugType == "Vulnerability",],ProjectMonth), projTimeline,"Vulns")

tmpSeries2 <- alignPoints(pmaVulns,group_by(pmaVulns[pmaVulns$BugType == "Vulnerability"  & pmaVulns$PrePost=="Pre-Release",],ProjectMonth), projTimeline,"PreVulns")

projSLOCRow <- spdf[spdf$Factor=="SLOC",]
vdensity <- makeRatio(tmpSeries1,projSLOCRow,"VDensity")
vre <- makeRatio(tmpSeries2,tmpSeries1,"VRE")

spdf <- rbind(spdf,vdensity)
spdf <- rbind(spdf,vre)

month_number <- function(month,projTimeline) { 32 + length(seq(projTimeline[1,],month,by='month')) }
new_machines <- 
function(month,projTimeline) {
# download_slope estimates linear trend by month
	download_slope = 200000/180
# usage - not everyone who downloads will use it… usage estimates percentage who do
	usage = .2
	return(trunc(month_number(month,projTimeline) * download_slope * usage)) 
}

mach <- data.frame(ProjectMonth=projTimeline,Machines=NA)
for (m in 1:175) {
	mach[m,]$Machines <- new_machines(mach[m,]$ProjectMonth,projTimeline)
}
mach$Total <- 0
mach$Total <-cumsum(mach$Machines)
tmpMach <- data.frame(ProjectMonth=mach$ProjectMonth,Factor="Machines",Value=mach$Total)
spdf <- rbind(spdf,tmpMach)

ggplot(data=spdf[as.Date(spdf$ProjectMonth) %in% seq(from=as.Date("2001-04-01"), to=as.Date("2014-04-01"),by='month') & spdf$Factor %in% c("VRE","VDensity","Churn","Commits","Devs","SLOC"),]) + geom_line(aes(x=ProjectMonth,y=Value,group=Factor)) + facet_grid(Factor~.,scales="free_y") + theme(strip.text.y = element_text(angle=0))

# Just the context factors
ggplot(data=spdf[as.Date(spdf$ProjectMonth) %in% seq(from=as.Date("2001-04-01"), to=as.Date("2014-04-01"),by='month') & spdf$Factor %in% c("SLOC","Churn","Devs","Machines"),]) + geom_line(aes(x=ProjectMonth,y=Value,group=Factor)) + facet_grid(Factor~.,scales="free_y") + theme(strip.text.y = element_text(angle=0))

ggsave("pma_context.png",ggplot(data=spdf[as.Date(spdf$ProjectMonth) %in% seq(from=as.Date("2001-04-01"), to=as.Date("2014-04-01"),by='month') & spdf$Factor %in% c("SLOC","Churn","Devs","Machines"),]) + geom_line(aes(x=ProjectMonth,y=Value,group=Factor)) + facet_grid(Factor~.,scales="free_y") + theme(strip.text.y = element_text(angle=0)),width=7,height=3.5)


