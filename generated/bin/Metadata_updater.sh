#!/bin/bash

#     Functions     #

function info {
  local D=`date`
  echo [ INFO - $D ] $*
}

function warning {
  local D=`date`
  echo [ WARN - $D ] $*
}

function error {
  local D=`date`
  echo [ ERROR - $D ] $* >&2
}

function downloadLFN {

  local LFN=$1
  local LOCAL=${PWD}/`basename ${LFN}`

  info "getting file size and computing sendReceiveTimeout"
  size=`lfc-ls -l ${LFN} | awk -F' ' '{print $5}'`
  sendReceiveTimeout=`echo $[${size}/150/1024]`
  if [ "$sendReceiveTimeout" = "" ] || [ $sendReceiveTimeout -le 900 ]; then echo "sendReceiveTimeout empty or too small, setting it to 900s"; sendReceiveTimeout=900; else echo "sendReceiveTimeout is $sendReceiveTimeout"; fi;
  info "Removing file ${LOCAL} in case it is already here"
  \rm -f ${LOCAL}

  info "Checking if the file is on local SE ${VO_BIOMED_DEFAULT_SE}"
  local closeSURL=`lcg-lr lfn:${LFN} | grep ${VO_BIOMED_DEFAULT_SE}`
  if [ "${closeSURL}" != "" ]
  then
    info "It is. Trying to download the file from there"
    LINE="lcg-cp -v --connect-timeout 10 --sendreceive-timeout $sendReceiveTimeout --bdii-timeout 10 --srm-timeout 30 ${closeSURL} file:${LOCAL}"
    info ${LINE}
    ${LINE} &> lcg-log
    if [ $? = 0 ]
    then
      info "lcg-cp worked fine"
      lcg_source=`cat lcg-log | awk -F"://" '/Trying SURL srm/ {print $2}' | awk -F"/" '{print $1}'|awk -F":" '{print $1}'`;
      lcg_destination=`hostname`;
      lcg_time=`cat lcg-log | awk '/Transfer took/ {print $3$4}'`;
      info "DownloadCommand=lcg-cp Source=$lcg_source Destination=$lcg_destination Size=$size Time=$lcg_time";
      return 0
    else
      error "It failed, falling back on regular lcg-cp"
    fi
  else
    info "It's not, falling back on regular lcg-cp"
  fi

info "Downloading file ${LFN}..."
LINE="lcg-cp -v --connect-timeout 10 --sendreceive-timeout $sendReceiveTimeout --bdii-timeout 10 --srm-timeout 30 lfn:${LFN} file:${LOCAL}"
info ${LINE}
${LINE} &> lcg-log
if [ $? = 0 ]
then
  info "lcg-cp worked fine"
  lcg_source=`cat lcg-log | awk -F"://" '/Trying SURL srm/ {print $2}' | awk -F"/" '{print $1}'|awk -F":" '{print $1}'`;
  lcg_destination=`hostname`;
  lcg_time=`cat lcg-log | awk '/Transfer took/ {print $3$4}'`;
  info "DownloadCommand=lcg-cp Source=$lcg_source Destination=$lcg_destination Size=$size Time=$lcg_time";
else
  error "lcg-cp failed"
  error "`cat lcg-log`"
  return 1
fi
\rm lcg-log 
}

# Arguments parsing #

shift # first parameter is always results directory

while [[ $# > 0 ]]
do
key="$1"
case $key in
    --json_file)
    JSON_FILE="$2"
    ;;
    --challenger_email)
    CHALLENGER_EMAIL="$2"
    ;;
    --pipeline_name)
    PIPELINE_NAME="$2"
    ;;
    --team_name)
    TEAM_NAME="$2"
    ;;
        --output_file)
    OUTPUT_FILE="$2"
    ;;
    *) # unknown option
    echo "Unknown option: $1"
    exit 1
    ;;
esac
shift # past argument or value
shift
done

# Command-line construction #

BOUTIQUES_COMMAND_LINE='metadata-updater.py [INPUT_FILE] [OUTPUT_FILE] [EMAIL] [PIPELINE_NAME] [TEAM]'

BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[OUTPUT_FILE]'/" $OUTPUT_FILE"}

                 LOCAL_FILE_NAME=`basename $JSON_FILE`
    BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[INPUT_FILE]'/" ${LOCAL_FILE_NAME}"}
                  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[EMAIL]'/" $CHALLENGER_EMAIL"}
                  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[PIPELINE_NAME]'/" $PIPELINE_NAME"}
                  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[TEAM]'/" $TEAM_NAME"}
      
# Command-line execution #

cat << DOCKERJOB > .dockerjob.sh
#!/bin/bash -l
${BOUTIQUES_COMMAND_LINE}
DOCKERJOB

chmod 755 .dockerjob.sh 
docker run --rm -v $PWD:/gasw-execution-dir -v $PWD/../cache:$PWD/../cache -w /gasw-execution-dir glatard/fli-metadata-updater  ./.dockerjob.sh 

if [ $? != 0 ]
then
    echo "Metadata_updater execution failed!"
    exit 1
fi

echo "Execution of Metadata_updater completed."

