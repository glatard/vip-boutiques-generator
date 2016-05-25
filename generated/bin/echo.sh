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
    --important_parameter)
    IMPORTANT_PARAMETER="$2"
    ;;
    --flair_raw)
    FLAIR_RAW="$2"
    ;;
    --t1_raw)
    T1_RAW="$2"
    ;;
    --t2_raw)
    T2_RAW="$2"
    ;;
    --gado_raw)
    GADO_RAW="$2"
    ;;
    --pd_raw)
    PD_RAW="$2"
    ;;
    --flair_preprocessed)
    FLAIR_PREPROCESSED="$2"
    ;;
    --t1_preprocessed)
    T1_PREPROCESSED="$2"
    ;;
    --t2_preprocessed)
    T2_PREPROCESSED="$2"
    ;;
    --gado_preprocessed)
    GADO_PREPROCESSED="$2"
    ;;
    --pd_preprocessed)
    PD_PREPROCESSED="$2"
    ;;
    --mask)
    MASK="$2"
    ;;
        --segmentation_result_challenge)
    SEGMENTATION_RESULT_CHALLENGE="$2"
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

BOUTIQUES_COMMAND_LINE='echo [PARAM] [FLAIR_RAW] [T1_RAW] [T2_RAW] [GADO_RAW] [PD_RAW] [FLAIR_PREPROCESSED] [T1_PREPROCESSED] [T2_PREPROCESSED] [GADO_PREPROCESSED] [PD_PREPROCESSED] [MASK] > [OUTPUT_FILE]'

BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[OUTPUT_FILE]'/" $SEGMENTATION_RESULT_CHALLENGE"}

            BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[PARAM]'/" $IMPORTANT_PARAMETER"}
                       LOCAL_FILE_NAME=`basename $FLAIR_RAW`
    BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[FLAIR_RAW]'/" ${LOCAL_FILE_NAME}"}
                       LOCAL_FILE_NAME=`basename $T1_RAW`
    BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[T1_RAW]'/" ${LOCAL_FILE_NAME}"}
                       LOCAL_FILE_NAME=`basename $T2_RAW`
    BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[T2_RAW]'/" ${LOCAL_FILE_NAME}"}
                       LOCAL_FILE_NAME=`basename $GADO_RAW`
    BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[GADO_RAW]'/" ${LOCAL_FILE_NAME}"}
                       LOCAL_FILE_NAME=`basename $PD_RAW`
    BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[PD_RAW]'/" ${LOCAL_FILE_NAME}"}
                       LOCAL_FILE_NAME=`basename $FLAIR_PREPROCESSED`
    BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[FLAIR_PREPROCESSED]'/" ${LOCAL_FILE_NAME}"}
                       LOCAL_FILE_NAME=`basename $T1_PREPROCESSED`
    BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[T1_PREPROCESSED]'/" ${LOCAL_FILE_NAME}"}
                       LOCAL_FILE_NAME=`basename $T2_PREPROCESSED`
    BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[T2_PREPROCESSED]'/" ${LOCAL_FILE_NAME}"}
                       LOCAL_FILE_NAME=`basename $GADO_PREPROCESSED`
    BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[GADO_PREPROCESSED]'/" ${LOCAL_FILE_NAME}"}
                       LOCAL_FILE_NAME=`basename $PD_PREPROCESSED`
    BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[PD_PREPROCESSED]'/" ${LOCAL_FILE_NAME}"}
                       LOCAL_FILE_NAME=`basename $MASK`
    BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'[MASK]'/" ${LOCAL_FILE_NAME}"}
      
# Command-line execution #

cat << DOCKERJOB > .dockerjob.sh
#!/bin/bash -l
${BOUTIQUES_COMMAND_LINE}
DOCKERJOB

chmod 755 .dockerjob.sh 
docker run --rm -v $PWD:/gasw-execution-dir -v $PWD/../cache:$PWD/../cache -w /gasw-execution-dir centos:latest  ./.dockerjob.sh 

if [ $? != 0 ]
then
    echo "echo execution failed!"
    exit 1
fi

echo "Execution of echo completed."

