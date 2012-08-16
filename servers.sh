#!/bin/bash

# Server startup script for linux servers for lethal-zone.eu
#
# Snelvuur script thingy.

# Read out the servers (to keep this file common across servers)
. ~/.servers
export MALLOC_CHECK_=0 # i dont need my srcds.exe to crash when its just a simple error that can go to stderr

echo "Server startup 1.1b www.lethal-zone.eu"
echo "--------------"

function actions {
     echo "./servers.sh <action> <servername> [gametype]"
     echo ""
     echo "Actions:"
     echo "- start      Start the server"
     echo "- stop       Stop the server"
     echo "- update     Update the server"
     echo "- verify     Verify the server"
     echo "- kill       Kill the server/screen"
     echo "- status     Get the status of the server"
     echo "- send       Send command to screen of server"
     echo "- link       Update and create symbolic links"
     echo "- cleanup    Cleanup old logs/sprays/etc"
     echo "- push       push data from ~/sources/push"
}

function push {
     if ! [ -d ~/sources/push ] ;then
        echo "No source folder found!"
	exit 99
     fi

     if [ -d $1/ ] && [ "$1" != "" ]  ;then
        cp -r ~/sources/push/* $1/$2/
     else
        echo "Wrong servername, directory not found, skipping"
     fi
}


if [ "$1" == "" ]
then
     echo "Please supply the action for this server:"
     actions
     echo ""
     echo "Servers:"
     echo "- $SERVERS"
     echo "Gametypes:"
     echo "- $(for i in `for i in $SERVERS; do grep "GAME=" $i/.config.sh|cut -d "=" -f 2; done|sort -u`; do echo -n "$i " ; done)"
     echo ""
     echo "Leave <servername> empty to get status/fullname"
     exit 1
fi

if [ "$2" == "" ]
then
     echo "Please supply the servername for this server:"
     echo "./servers.sh $1 <servername>"
     if [ "$1" == "send" ]; then
      echo "<servername> can also be replaced by \"all\" when you use the send command"
     fi
     for i in $SERVERS
     do
	format="%-10s = %-1s %-1s %-1s\n"
      cd $i
      . ./.config.sh
       if [ -e "$WD/$i.pid" ]; then
         if [ -e "$WD/update.lock" ]; then
          printf "$format" "$i" "$SERVERNAME" "RUNNING" "-lock"
	 else
          printf "$format" "$i" "$SERVERNAME" "RUNNING"
         fi
       else
	 if [ -e "$WD/update.lock" ]; then
          printf "$format" "$i" "$SERVERNAME" "STOPPED" "-lock"
         else
          printf "$format" "$i" "$SERVERNAME" "STOPPED"
         fi
       fi
      cd ..
     done
     exit 1
fi

case "$1" in
     start|status|stop|update|verify|kill|send|link|cleanup|push)
      if [ -e "$2/.config.sh" ]; then
       . ./$2/.config.sh
      else
	if [ "$1" == "link" ] || [ "$1" == "cleanup" ] || [ "$1" == "push" ] ; then
		OK=OK
	else
	if [ "$2" == "all" ]; then
         echo "- Using \"all\" for send command"
          if [ "$4" == "" ]; then
           echo "- You didn't supply the <gametype> as 4rth value"
           exit 1
          else
           echo "- Sending towards servers with gametype $4"
          fi
        else
         echo "Serverdetails on $2 do not exist!"
         echo "Valid entry's : $SERVERS"
         exit 1
	fi
	fi
      fi
     ;;
esac

if [ "$1" == "send" ]; then
      if [ "$3" == "" ]; then
         echo "- ./servers.sh send <server> <command> <gametype>"
         echo "- Example: ./servers.sh send bbal \"sm_csay server has maintenance\" <gametype>"
         echo "                <gametype> is only used in combination when <server> is \"all\""
	 exit 1
      fi
fi

case "$1" in
     start)
      if [ -e "$WD/$2.pid" ]; then
	echo "It is running, you damn fool!"
	exit 1
      fi
      echo "Starting $SERVERNAME"
      sleep 1
      cd $WD
       screen -A -m -d -S $2 ./srcds_run -debug -autoupdate -game "$GAME" +ip $IP -port $PORT+## $OPTIONS -pidfile $WD/$2.pid
     ;;
     status)
      if [ -e "$WD/$2.pid" ]; then
       echo "- Screen should be runnning"
        PID=`cat $WD/$2.pid`
       echo "- Process details: "
        PROCS=`ps -ef|grep $PID|grep -v grep`
        if [ "$PROCS" == "" ];then
         echo "- Looks like you killed the screen but pid is still active..."
        else
         echo $PROCS
        fi
       echo "- ---------------"
       echo "- Verify correctness"
      else
       echo "- No pid file could be found, did you make a mistake? I'll print the output off ps -ef for port $PORT for you:"
       OUTPUT=`ps -ef|grep $PORT|grep -v grep`
       if [ "$OUTPUT" == "" ];then
        echo "- It seems there is no output for it, so it must be really down."
       else
        echo $OUTPUT
        echo "- It might still be starting up, only when the process is started the pid file will be there"
       fi
      exit 1
      fi
     ;;
     stop)
      echo "- Issuing a quit command"
      KILLPID=`ps -ef|grep SCREEN|grep $2|grep $PORT|grep -v grep|awk {'print $2'}`
      screen -X -S $KILLPID quit
      rm -rf $WD/$2.pid
     ;;
     verify)
      echo "- Issuing a update -verify all on $SERVERNAME"
      cd $2
       ./steam -command update -game "$GAME" -dir . -verify_all
      echo "- All done"
     ;;
     update)
      echo "- Issuing a update command for $SERVERNAME"
      cd $2
       ./steam -command update -game "$GAME" -dir .
      echo "- All done"
     ;;
     send)
      if [ "$2" = "all" ];then
        for i in $SERVERS
        do
	 . ./$i/.config.sh
	 if [ "$GAME" = "$4" ]; then
          SESSION=`ps -ef|grep SCREEN|grep $i/|grep -v grep|awk {'print $2'}`
	  if [ $SESSION ]; then
	   echo "- Sending \"$3\" to $i"
           screen -S $SESSION.$i -p 0 -X stuff "$3"
	  else
           echo "- Screen session does not seem active for $i"
          fi
         else
          echo "- $i is not a server with gametype \"$4\""
         fi
        done
      else  
        SESSION=`ps -ef|grep SCREEN|grep $2/|grep -v grep|awk {'print $2'}`
        if [ $SESSION ]; then
	 echo "- Sending \"$3\" to $2"
         screen -S $SESSION.$2 -p 0 -X stuff "$3"
        else
         echo "- Screen session does not seem active for $2"
        fi
      fi
     ;;
     link)

     if [ "$2" != "all" ]; then
	SERVERS=$2
     fi

     for x in $SERVERS
     do
	     . ./$x/.config.sh
             if [ "$2" == "all" ]; then
		echo "Linking stuff for $SERVERNAME"
             fi
	     PLUGINS="$WD/$GAME/addons/sourcemod/plugins"
             SVRROOT="$WD/$GAME/"
     	cd $PLUGINS
	     for i in `find *.smx -maxdepth 1 -type f -exec basename {} \;` 
	     do
	      if [ -h $PLUGINS/$i ]; then
		echo ""
    	   else
 	       echo "$i is not linked, linking"
		 if [ -f ~/shared/$GAME/plugins/$i ]; then 
  	        echo "Plugin is present in shared folder, giving preference"
 	         rm $PLUGINS/$i
     	     ln -s ~/shared/$GAME/plugins/$i $PLUGINS/$i
 	        else
	          echo "No plugin found in shared folder, copying current"
	          cp $PLUGINS/$i ~/shared/$GAME/plugins/
	          rm $PLUGINS/$i
	          ln -s ~/shared/$GAME/plugins/$i $PLUGINS/$i
		fi
	       fi
	     done
		if [ -f ~/shared/$GAME/$GAME.links.txt ];then
             for b in `cat ~/shared/$GAME/$GAME.links.txt`
             do
		cd $SVRROOT
		if [ -h $b ]; then
			CHECK=OK
		else
	              if [ -f $b ]; then
			echo "$b is not linked, linking"
			BASE=`basename $b`
			mkdir -p ~/shared/$GAME/configs/$x
			if [ -f ~/shared/$GAME/configs/$x/$BASE ]; then
				echo "Config is present in shared folder, giving preference"
				rm $b
				ln -s ~/shared/$GAME/configs/$x/$BASE $b
			else
				echo "No config found in shared folder, copying current"
				cp $b ~/shared/$GAME/configs/$x/$BASE
				rm $b
				ln -s ~/shared/$GAME/configs/$x/$BASE $b
			fi
                      fi
		fi
             done
		else
			echo "Links data does not exist for game type $GAME"
		fi
		if [ -f ~/shared/$GAME/$GAME.shared.txt ];then
             for b in `cat ~/shared/$GAME/$GAME.shared.txt`
             do
		cd $SVRROOT
		if [ -h $b ]; then
			CHECK=OK
		else
                      if [ -f $b ]; then
			echo "$b is not linked, linking"
			BASE=`basename $b`
			if [ -f ~/shared/configs/$BASE ]; then
				echo "Config is present in shared folder, giving preference"
				rm $b
				ln -s ~/shared/configs/$BASE $b
			else
				echo "No config found in shared folder, copying current"
				cp $b ~/shared/configs/$BASE
				rm $b
				ln -s ~/shared/configs/$BASE $b
			fi
                      fi
		fi
             done 
		else
			echo "Shared data does not exist for game type $GAME"
		fi
	     echo "Linking done.."
		cd ~
     done
     ;;
     cleanup)
     if [ "$2" != "all" ]; then
        SERVERS=$2
     fi
      echo "- Issuing a cleanup command"
     HOMEDIR=`pwd`
     for x in $SERVERS
     do
             cd $HOMEDIR
             . ./$x/.config.sh
             if [ "$2" == "all" ]; then
                echo "Cleaning up stuff for $SERVERNAME"
             fi
             # Cleanup folders
             SMDIRLOG="$WD/$GAME/addons/sourcemod/logs/"
             SPRAYDIR="$WD/$GAME/downloads/"
             ROOTLOG="$WD/$GAME/logs/"
             REPLAYDIR="$WD/$GAME/replay/server/"
             SVRROOT="$WD/$GAME/"

             if [ -d $WD ] ;then
               cd $WD && pwd && nice -19 find . -maxdepth 1 -name "core.*" -type f -mtime +7 -exec rm {} \;
             fi
             if [ -d $SMDIRLOG ] ;then
               cd $SMDIRLOG && pwd && nice -19 find -type f -mtime +7 -exec rm {} \;
             fi
             if [ -d $SPRAYDIR ] ;then
               cd $SPRAYDIR && pwd && nice -19 find -type f -mtime +7 -exec rm {} \;
             fi
             if [ -d $ROOTLOG ] ;then
               cd $ROOTLOG && pwd && nice -19 find -type f -mtime +7 -exec rm {} \;
             fi
             if [ "$GAME" = "tf" ]; then
               if [ -d $REPLAYDIR ] ;then
                 cd $REPLAYDIR && pwd && nice -19 find -type f -mtime +7 -exec rm {} \;
               fi
             fi
     done
     ;;
     push)
      echo "- Issuing a push of ~/sources/push"
     if [ "$2" != "all" ]; then
        SERVERS=$2
     fi

     if [ "$2" == "all" ]; then
	echo "Are you sure you want to push out ~/sources/push to ALL servers/gametypes?"
        echo " - To specify only tf server, add tf to it."
	echo " - Press Ctrl-c to abort, or any key to continue"
	read anykey
     fi

     for x in $SERVERS
     do
             . ~/$x/.config.sh
             if [ "$2" == "all" ]; then
             	if [ "$3" != "" ]; then
			if [ "$3" == "$GAME" ];then
                		echo "pushing stuff towards $SERVERNAME (only $3)"
				push $WD $GAME
                	else
			        echo "Skipping $SERVERNAME (not matching $3)" 
			fi
		else
			echo "pushing stuff towards $SERVERNAME"
			push $WD $GAME
		fi
             else
                 echo "pushing stuff towards $SERVERNAME"
                 push $WD $GAME
             fi
     done

     ;;
     kill)
      echo "- Issuing a kill for $SERVERNAME server/screen"
      KILLPID=`ps -ef|grep SCREEN|grep $2|grep $PORT|grep -v grep|awk {'print $2'}`
      screen -X -S $KILLPID kill
      rm -rf $WD/$2.pid
     ;;
     *)
     echo "The <action> '$1' is not a valid entry:"
     actions
     ;;
esac
exit 0
