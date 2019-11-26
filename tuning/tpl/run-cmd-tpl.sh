#!/bin/bash
#chkconfig - 99 1
#pidfile /home/monitor/monitor_agent/agent.pid

### BEGIN INIT INFO
# Provides:          monitor-agent
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: OM monitor agent.
# Description:       OM monitor agent.
### END INIT INFO

RES_COL=60
MOVE_TO_COL="echo -en \\033[${RES_COL}G"
SETCOLOR_SUCCESS="echo -en \\033[1;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_WARNING="echo -en \\033[1;33m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"
myecho_success() {
    $MOVE_TO_COL
    echo -n "["
    $SETCOLOR_SUCCESS
    echo -n $"  OK  "
    $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    return 0
}
myecho_failure() {
    $MOVE_TO_COL
    echo -n "["
    $SETCOLOR_FAILURE
    echo -n $"FAILED"
    $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    return 1
}
myecho_warning() {
    $MOVE_TO_COL
    echo -n "["
    $SETCOLOR_WARNING
    echo -n $"WARNING"
    $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    return 1
}
mySuccess(){
    echo -n $*
    myecho_success
    echo ""
}
myFailure(){
    echo -n $*
    myecho_failure
    echo ""
}
myWarning(){
    echo -n $*
    myecho_warning
    echo ""
}

myCheckpid() {
    local i
    for i in $* ; do
        [ -d "/proc/$i" ] && return 0
    done
    return 1
}


myCheckpidfile(){
# return 0   process exists
# return 1   file not exists
# return 2   file exists but process not exists
    file=$1
    if [ ! -f $file ]; then
        return 1
    fi
    local pid=`cat $file`
    if [ -z $pid ]; then
        return 1
    fi
    myCheckpid $pid
    ret=$?
    if [ $ret -eq 0 ]; then
        return 0
    else
        return 2
    fi
}

JAVA_VERSION=1.5
s=`java -version 2>&1`;
i=0;
for e in $s; do
    if [ $i -eq 2 ]; then
        len=${#e};
        len=$(($len-2));
        JAVA_VERSION=${e:1:3};
        break;
    fi;
    i=$(($i+1));
done;
JAVA_COMMAND="java"
if [ "$JAVA_VERSION"  \> 1.5  ]; then
    JAVA_COMMAND="java";
    echo "JAVA_VERSION:$JAVA_VERSION";
else

    #debian
    FIND=0;
    JAVA_TMP_HOME="/usr/lib/jvm/java-6-sun"
    if [ -e $JAVA_TMP_HOME -a  $FIND -eq 0 ]; then
        FIND=1;
        JAVA_COMMAND="$JAVA_TMP_HOME/bin/java"
        echo "debian JAVA_COMMAND: $JAVA_COMMAND";
    fi

    JAVA_TMP_HOME="/home/monitor/jdk1.6.0_29"
    if [ -d $JAVA_TMP_HOME -a $FIND -eq 0 ]; then
        FIND=1;
        JAVA_COMMAND="$JAVA_TMP_HOME/bin/java"
        echo "JAVA_COMMAND: $JAVA_COMMAND";
    fi

    #redhat
    JAVA_TMP_HOME="/usr/java/latest"
    if [ -e $JAVA_TMP_HOME -a $FIND -eq 0 ]; then
        FIND=1;
        JAVA_COMMAND="$JAVA_TMP_HOME/bin/java"
        echo "redhat JAVA_COMMAND: $JAVA_COMMAND";
    fi

    if [ ! -x $JAVA_COMMAND ]; then
        echo "$JAVA_COMMAND is not a excutable command!"
        exit 1
    fi
fi

shellfile=$0
while [ -L $shellfile ]; do
    shellfile=`readlink -f $shellfile`
    if [ ! -e $shellfile ]; then
        echo "$shellfile not exits!"
        exit 1
    fi
done

#
BASE_HOME=$(cd "$(dirname "$shellfile")"; pwd)
if [ ! -d $BASE_HOME ]; then
    echo "$BASE_HOME is not a directory!"
    exit 1
fi

#
PID_FILE="/var/lock/sw_monitor.pid"
MONITOR_JAR="$BASE_HOME/sw_monitor.jar"
JARS=`ls $BASE_HOME/*.jar`
for jar in $JARS; do
    MONITOR_JAR=$jar
done

MONITOR_APPNAME="SwitchMonitor"
#-Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000 -Dcom.sun.management.jmxremote.port=9312
OPTS="-server -jar -Xmx64m -Xms32m   -Dcom.xx.appname=$MONITOR_APPNAME"
COMMAND="$JAVA_COMMAND $OPTS $MONITOR_JAR"
STOP_COMMAND="kill -9"
NAME="OM Switch Monitor"

cd "$BASE_HOME";
echo "BASE_HOME:"`pwd`;
echo "";

start(){
    echo $COMMAND
    echo -n "start to run $NAME"
    myCheckpidfile $PID_FILE
    ret=$?
    if [ $ret -eq 0 ]; then
        echo ""
        myWarning "$NAME already exists!"
        return 0;
    elif [ $ret -eq 1 ] || [ $ret -eq 2 ]; then
        $COMMAND > /dev/null 2>&1 &
        pid=$!
        sleep 2
        myCheckpid $pid
        ret=$?
        if [ $ret -eq 1 ]; then
            myFailure
            return 1
        else
            mySuccess
            echo "$pid" > $PID_FILE
            chmod 666 $PID_FILE > /dev/null 2>&1 || ""
            return 0
        fi
    fi
}

stop(){
    echo -n "stopping $NAME"
    myCheckpidfile $PID_FILE
    ret=$?
    if [ $ret -eq 0 ]; then
        pid=`cat $PID_FILE`
        $STOP_COMMAND $pid >/dev/null
        sleep 2
        myCheckpid $pid
        ret=$?
        if [ $ret -eq 1 ]; then
            mySuccess
            rm -rf $PID_FILE > /dev/null 2>&1 || ""
            return 0
        else
            myFailure
            return 1
        fi
    elif [ $ret -eq 1 ]; then
        echo ""
        myWarning "$NAME not run"
        return 1
    else
        echo ""
        myWarning "$NAME pid file exists but not run"
        return 1
    fi
}

status(){
    myCheckpidfile $PID_FILE
    ret=$?
    if [ $ret -eq 0 ]; then
        pid=`cat $PID_FILE`
        mySuccess "$NAME is running with pid=$pid"
        exit 0
    elif [ $ret -eq 1 ]; then
        echo ""
        mySuccess "$NAME is not running"
        exit 1
    else
        myWarning "$NAME is not running but pid file exists"
        exit 2
    fi
}

restart(){
    stop
    start
    return 0
}

case $1 in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    restart)
        restart
        ;;
    *)
        echo "Usage $0 start|stop|restart|status|dellog"
        exit 1;
        ;;
esac
