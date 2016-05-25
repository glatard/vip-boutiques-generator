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
    --disthausdorffmoy)
    DISTHAUSDORFFMOY="$2"
    ;;
    --disthausdorff)
    DISTHAUSDORFF="$2"
    ;;
    --pnv)
    PNV="$2"
    ;;
    --ppv)
    PPV="$2"
    ;;
    --specificity)
    SPECIFICITY="$2"
    ;;
    --sensibility)
    SENSIBILITY="$2"
    ;;
    --dice)
    DICE="$2"
    ;;
    --jaccard)
    JACCARD="$2"
    ;;
    --image_input)
    IMAGE_INPUT="$2"
    ;;
    --image_reference)
    IMAGE_REFERENCE="$2"
    ;;
    --text)
    TEXT="$2"
    ;;
        --metric_results)
    METRIC_RESULTS="$2"
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

BOUTIQUES_COMMAND_LINE='SegPerfAnalyser'

BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'-o'/" $METRIC_RESULTS"}

    if [ "$DISTHAUSDORFFMOY" = "true" ]
then
  # flag is set: replace command-line key by flag value
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'DISTHAUFMOY'/-m}
else
  # flag is unset: remove command-line key from command-line. 
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'DISTHAUFMOY'/""}
fi
    if [ "$DISTHAUSDORFF" = "true" ]
then
  # flag is set: replace command-line key by flag value
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'DISTHAUF'/-M}
else
  # flag is unset: remove command-line key from command-line. 
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'DISTHAUF'/""}
fi
    if [ "$PNV" = "true" ]
then
  # flag is set: replace command-line key by flag value
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'PNV'/-n}
else
  # flag is unset: remove command-line key from command-line. 
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'PNV'/""}
fi
    if [ "$PPV" = "true" ]
then
  # flag is set: replace command-line key by flag value
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'PPV'/-p}
else
  # flag is unset: remove command-line key from command-line. 
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'PPV'/""}
fi
    if [ "$SPECIFICITY" = "true" ]
then
  # flag is set: replace command-line key by flag value
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'SPECIFICITY'/-c}
else
  # flag is unset: remove command-line key from command-line. 
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'SPECIFICITY'/""}
fi
    if [ "$SENSIBILITY" = "true" ]
then
  # flag is set: replace command-line key by flag value
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'SENSIBILITY'/-e}
else
  # flag is unset: remove command-line key from command-line. 
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'SENSIBILITY'/""}
fi
    if [ "$DICE" = "true" ]
then
  # flag is set: replace command-line key by flag value
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'DICE'/-d}
else
  # flag is unset: remove command-line key from command-line. 
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'DICE'/""}
fi
    if [ "$JACCARD" = "true" ]
then
  # flag is set: replace command-line key by flag value
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'JACCARD'/-j}
else
  # flag is unset: remove command-line key from command-line. 
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'JACCARD'/""}
fi
                 LOCAL_FILE_NAME=`basename $IMAGE_INPUT`
    BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'INPUT'/"-i ${LOCAL_FILE_NAME}"}
                       LOCAL_FILE_NAME=`basename $IMAGE_REFERENCE`
    BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'REFERENCE'/"-r ${LOCAL_FILE_NAME}"}
          if [ "$TEXT" = "true" ]
then
  # flag is set: replace command-line key by flag value
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'TEXT'/-t}
else
  # flag is unset: remove command-line key from command-line. 
  BOUTIQUES_COMMAND_LINE=${BOUTIQUES_COMMAND_LINE//'TEXT'/""}
fi

# Command-line execution #

cat << DOCKERJOB > .dockerjob.sh
#!/bin/bash -l
${BOUTIQUES_COMMAND_LINE}
DOCKERJOB

chmod 755 .dockerjob.sh 
docker run --rm -v $PWD:/gasw-execution-dir -v $PWD/../cache:$PWD/../cache -w /gasw-execution-dir fcervenansky/segperformance  ./.dockerjob.sh 

if [ $? != 0 ]
then
    echo "SegPerfAnalyser execution failed!"
    exit 1
fi

echo "Execution of SegPerfAnalyser completed."

