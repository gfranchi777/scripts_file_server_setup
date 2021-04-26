#!/bin/bash
################################################################################
# Script used to delete unnecessary files from the server as well as 
# restore proper file permissions on media drives.
#
# @author wpnx777
#
#===============================================================================
# Change Log
#===============================================================================
#
# Version 1.0: Initial Version.
# Version 1.1: Add immutable property to media files.
# Version 1.2: Add media audit files in ~/logs.
# Version 1.3: Seperate the script into functions.
# Version 1.4: Add creation of media directory symlinks.
# Version 1.5: Add sorted movie report.
# Version 1.6: Added test and error conditional case to main program.
# Version 1.7: Added email functionality and html formatted logs.
################################################################################

################################################################################
# Variables
################################################################################
currDate=`date +\%Y-\%m-\%d`
dayOfMonth=`date '+%d'`

mediaSourceBaseDir=/media/wpnx777/mediaDirs
mediaTargetBaseDir=/home/wpnx777
logsBaseDir=/var/log/server-refresh/${currDate}

mediaSourceDirs=("${mediaSourceBaseDir}/movies1"
                 "${mediaSourceBaseDir}/movies2"
				 "${mediaSourceBaseDir}/movies3"
                 "${mediaSourceBaseDir}/tvseries1"
                 "${mediaSourceBaseDir}/videos1")

mediaTargetDis=("${mediaTargetBaseDir}/movies"
                "${mediaTargetBaseDir}/tv"
				"${mediaTargetBaseDir}/videos")

numColsInTable=2

emailFile=${logsBaseDir}/${currDate}-server-refresh.html
sortedMovieList=${logsBaseDir}/${currDate}-sorted-movie-list.html

################################################################################
# Functions
################################################################################

# Perform server updates
#
# @author wpnx777
# @version 1.0
# @return None
function aptUpdate {
  printSectionHeader "Updating Server Operating System"
  
  echo "      <tr>"
  printSectionMessage "Performing Apt Updates"
  
  sudo apt -qqy update && \
  sudo apt -qqy upgrade && \
  sudo apt -qqy autoremove
  
  cmdExitStatus
  echo "      </tr>"
}

function cleanupFiles {
  printSectionHeader "Cleaning Up Unnecessary Files"
  deleteDSStore
  deleteIncompleteDownloads
}

# Echo an appropriate message based on the exit code returned by the
# previously run command.
#
# @author wpnx777
# @version 1.0
# @return An appropriate message based on the exit code returned by the
#         previously run command.
function cmdExitStatus {
  if [ $? -eq 0 ]; then
    if [ $# -eq 0 ]; then
      echo "        <td class=\"messages.success\">Completed Successfully.</td>"
	fi
  elif [ $? -eq 1 ]; then
    echo "        <td class=\"messages.notgingToDo\">Nothing Needs To Be Done.</td>"
  else
    echo "        <td class=\"messages.failure\">Failed.<br><br>${?}</td>"
  fi
}

# Create audit logs for the current run cycle
#
# @author wpnx777
# @version 1.0
# @return None
function createAuditLogs {
  printSectionHeader "Creating Media File Audit Logs"
  
  for dir in ${mediaSourceDirs[@]}; do
    echo "      <tr>"
	printSectionMessage "Creating Audit File For $dir: "
    
	tree $dir > $logsBaseDir/`basename $dir`-audit-$currDate.log
    
	cmdExitStatus
    chmod 600 $logsBaseDir/*
	echo "      </tr>"
  done
}

# Create the directory specified in $1
#
# @author wpnx777
# @version 1.0
# @param $1 The path to the directory to create
# @return 0 if the directory was created, 1 if it was not.
function createLogDir {
  created=1
  if ! dirExists ${logsBaseDir}; then
    mkdir ${logsBaseDir}

    if [ $? -eq 0 ]; then
      chmod 700 ${logsBaseDir}
      created=0
    fi
  fi
}

# Create the email file
#
# @author wpnx777
# @version 1.0
# @param $1 The path to the directory to create
# @return None
function createEmailFile {
  created=1
  if ! emailFileExists ${emailFile}; then
    touch ${emailFile}
    
	if [ $? -eq 0 ]; then
      chmod 700 ${emailFile}
	  created=0
    fi
  fi
}

# Create a text file which contains a sorted list of all movie
# files in /home/wpnx777/movies sorted in descending order
#
# @author wpnx777
# @version 1.0
# @return None
function createSortedMovieListFile {
  printSectionHeader "Creating Movie List Sorted By Date Descending"
  
  echo "      <tr>"
  printSectionMessage "Creating Sorted Movies List"
 
  find ${mediaSourceBaseDir}/movies* -name lost+found -prune -o \
  -type f | sed 's#.*/##' > ${sortedMovieList}
  
  cmdExitStatus
  echo "      </tr>"
  echo "      <tr>"
  
  printSectionMessage "Changing Permissions On Sorted Movie List"
  chmod 600 ${sortedMovieList}
  cmdExitStatus
  echo "      </tr>"
}

# Create media symlinks in home folder
# 
# @author wpnx777
# @version 1.0
# @return None
function createSymLinks {
  printSectionHeader "Creating Media Directory SymLinks"
  echo "      <tr>"
  printSectionMessage "Removing SymLink For Movies: "
  
  rm -rf /home/wpnx777/movies/*
  cmdExitStatus
  
  echo "      </tr>"
  echo "      <tr>"
  printSectionMessage "Creating SymLink For Movies: "
  
  find ${mediaSourceBaseDir}/movies*/* -maxdepth 0 -type d \
  -not -path "*lost+found*" -exec ln -s '{}' /home/wpnx777/movies \;
  cmdExitStatus
  
  echo "      </tr>"
  echo "      <tr>"
  printSectionMessage "Removing SymLink For TV Series: "
  
  rm -rf /home/wpnx777/tv/*
  cmdExitStatus
  
  echo "      </tr>"
  echo "      <tr>"
  printSectionMessage "Creating SymLink For TV Series: "
  
  find ${mediaSourceBaseDir}/tvseries*/* -maxdepth 0 -type d \
  -not -path "*lost+found*" -exec ln -s '{}' /home/wpnx777/tv/ \;
  cmdExitStatus
  
  echo "      </tr>"
  echo "      <tr>"
  printSectionMessage "Removing SymLink For Videos: "
  
  rm -rf /home/wpnx777/videos/*
  cmdExitStatus
  
  echo "      </tr>"
  echo "      <tr>"
  printSectionMessage "Creating SymLink For Videos: "
  
  find ${mediaSourceBaseDir}/videos*/* -maxdepth 0 -type d \
  -not -path "*lost+found*" -exec ln -s '{}' /home/wpnx777/videos/ \;
  cmdExitStatus
  
  echo "      </tr>"
}

# Delete all DS Store files created by OSX when files are copied
#
# @author wpnx777
# @version 1.0
# @return None
function deleteDSStore {
  #Delete all DS_Store files found in /home/wpnx777 (Following any symlinks)
  echo "      <tr>"
  printSectionMessage "Removing All DS_Store Files"
  find -L $HOME/ -name *DS_Store* -exec rm -f '{}' \; -print 2>&1 | \
  grep -v "Permission denied"
  cmdExitStatus
  echo "      </tr>"
}

# Delete all incomplete download files
#
# @author wpnx777
# @version 1.0
# @return None
function deleteIncompleteDownloads {
  echo "      <tr>"
  printSectionMessage "Removing $HOME/downloads/sabnzbd/incomplete/*"
  rm -rf $HOME/downloads/sabnzbd/incomplete/*
  cmdExitStatus
  echo "      </tr>"
}

# Verifiy if the directory specified in $1 exists. If it does return 0 if it
# does not then return 1.
#
# @author wpnx777
# @version 1.0
# @param $1 The path to the directory to verify
# @return 0 if the directory exists, 1 if it does not.
function dirExists {
  exists=0
  if [ ! -z "${1}" ]; then
    if [ ! -d "${1}" ]; then
      exists=1
    fi
  fi

  return $exists
}

# Verify if a file with the same name already exists
#
# @author wpnx777
# @version 1.0
# @return none
function emailFileExists {
  exists=0
  if [ ! -z "${1}" ]; then
    if [ ! -f "${1}" ]; then
	  exists=1
	fi
  fi

  return $exists
}

# Generates the html footer of an email file
#
# @author wpnx777
# @version 1.0
# @return none
function genEmailFooter {
  echo "    </table>"
  echo "  </body>"
  echo "</html>"
}

# Generates the html header of an email file
#
# @author wpnx777
# @version 1.0
# @return none
function genEmailHeader {
  echo "<html>"
  echo "  <head>"
  echo "    <title>Nightly Server Refresh - ${currDate}</title>"
  echo "    <style>"
  echo "      td.messages.failure {"
  echo "        font-color: red;"
  echo "      }"
  echo "      td.messages.nothingToDo {"
  echo "        font-color: blue;"
  echo "      }"
  echo "      td.messages.success {"
  echo "        font-color: green;"
  echo "      }"
  echo "      td.sectionHeader {"
  echo "        font-size: 20px;"
  echo "        font-weight: bold;"
  echo "        text-align: center;"
  echo "      }"
  echo "      body {"
  echo "        font-family: \"Courier New\";"
  echo "      }"
  echo "      table,th,td {"
  echo "        border: 1px solid black;"
  echo "      }"
  echo "    </style>"
  echo "  </head>"
  echo "  <body>"
  echo "    <table>"
}

# Print the header inside a section of the file
#
# @author wpnx777
# @version 1.0
# @return none
function printSectionHeader {
  echo "      <tr>"
  echo "        <td class=\"sectionHeader\" colspan=\"${numColsInTable}\">${1}</td>"
  echo "      </tr>"
}

# Print a message inside a section of the file
#
# @author wpnx777
# @version 1.0
# @return none
function printSectionMessage {
  echo "        <td class=\"sectionMessage\">${1}</td>"
}

# Redirect standard output to the email file
#
# @author wpnx777
# @version 1.0
# @return none
function redirectStdOut {
  exec &> ${emailFile}
}

# Reset media file permissions to make accidental deletion
# of files impossible
#
# @author wpnx777
# @version 1.0
# @return None
function resetMediaPermissions {
  printSectionHeader "Resetting Media Permissions"
  
  for dir in ${mediaSourceDirs[@]}; do
    echo "      <tr>"
    printSectionMessage "Removing Immutable From Files In $dir"
    
	find $dir/ -name lost+found -prune -o -type f -exec sudo chattr -i '{}' \;
    cmdExitStatus
    
	echo "      </tr>"
	echo "      <tr>"
    printSectionMessage "Resetting $dir Directory Permissions"
    
	find $dir/ -name lost+found -prune -o -type d -exec chmod 700 '{}' \;
    cmdExitStatus
    
	echo "      </tr>"
    echo "      <tr>"
    printSectionMessage "Resetting $dir File Permissions"
    
	find $dir/ -name lost+found -prune -o -type f -exec chmod 400 '{}' \;
    cmdExitStatus
    
	echo "      </tr>"
    echo "      <tr>"
    printSectionMessage "Add Immutable To Files In $dir"
    
	find $dir/ -name lost+found -prune -o -type f -exec sudo chattr +i '{}' \;
    cmdExitStatus
	
	echo "      </tr>"
  done
}

# Delete all old log folders
#
# @author wpnx777
# @version 1.0
# @return None
function rotateLogs {
  if [ ${dayOfMonth} -eq "01" ]; then
    rm -rf /var/log/server-refresh/*
  fi
}

# Email the file that was generated
#
# @author wpnx777
# @version 1.0
# @return none
function sendEmail {
  cat ${emailFile} | sendmail -t
}

# Setup the filesystem before generating the files
#
# @author wpnx777
# @version 1.0
# @return none
function setupEnv {
  createLogDir
  createEmailFile
  rotateLogs
  redirectStdOut
}

# Execute the flow of the program
#
# @author wpnx777
# @version 1.0
# @return none
function updateServer {
  setupEnv
  genEmailHeader
  cleanupFiles
  resetMediaPermissions
  createSymLinks
  createAuditLogs
  createSortedMovieListFile
  aptUpdate
  genEmailFooter
}

################################################################################
# Main Program
################################################################################
#Refresh the server and create log files for the current run cycle
updateServer
