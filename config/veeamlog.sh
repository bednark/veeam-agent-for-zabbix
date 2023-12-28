#!/bin/bash

function get_result () {
  LOG_PATH='/var/log/veeam/Backup'
  JOB_DIR=$(sudo ls -t $LOG_PATH | head -n 1)

  if [ -z $JOB_DIR  ] ; then
    echo '[{"job_name": "", "job_status": "FAILED", "description": "Job directory not found"}]'
    exit 0
  fi

  SESSION_DIR=$(sudo ls -t $LOG_PATH/$JOB_DIR -I *.tar.gz | head -n 1)
  LOG_FILE_PATH=$LOG_PATH'/'$JOB_DIR'/'$SESSION_DIR/Job.log

  if [ -z $(sudo ls $LOG_PATH'/'$JOB_DIR'/'$SESSION_DIR | grep Job.log) ] ; then
    echo '[{"job_name": "'$JOB_DIR'", "job_status": "FAILED", "description": "Log file not found"}]'
    exit 0
  fi

  LOG_CHARSET=$(sudo file -i $LOG_FILE_PATH)
  LOG_STDOUT=''

  if [[ $LOG_CHARSET =~ 'charset=utf-8' ]] ; then
    LOG_STDOUT=$(sudo cat $LOG_FILE_PATH)
  else
    sudo iconv -f 'ISO-8859-1' -t 'UTF-8' $LOG_FILE_PATH -o $LOG_PATH'/'$JOB_DIR'/'$SESSION_DIR/Job_UTF.log
    LOG_FILE_PATH=$LOG_PATH'/'$JOB_DIR'/'$SESSION_DIR/Job_UTF.log
    LOG_STDOUT=$(sudo cat $LOG_FILE_PATH)
    sudo rm -f $JOB_FILE_PATH
  fi

  if [[ $LOG_STDOUT =~ 'JOB STATUS: SUCCESS.' ]] ; then
    echo '[{"job_name": "'$JOB_DIR'", "job_status": "SUCCESS", "description": "Job ended with success"}]'
  else
    echo '[{"job_name": "'$JOB_DIR'", "job_status": "FAILED", "description": "Job ended with fail"}]'
  fi
}

JOB_RESULT=$(get_result)

if [ -z $1 ] ; then
  exit 0
fi

if [ $1 = 'json' ] ; then
  echo $JOB_RESULT
elif [ $1 = 'num' ] ; then
  if [[ $JOB_RESULT =~ 'SUCCESS' ]] ; then
    echo 2
  else
    echo 0
  fi
fi