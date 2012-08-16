Sourced Server script
=====================

I created this script because we have multiple servers and using single scripts just didn't work for me anymore. Since then i improved upon it in my own way (there are bound to be better sollutions, but it works for me) currently it has the following options:

	start		Start the server
	stop		Stop the server
	update		Update the server
	verify		Verify the server
	kill		Kill the server/screen
	status		Get the status of the server
	send		Send command to screen of server
	link		Update and create symbolic links
	cleanup		Cleanup old logs/sprays/etc 
        push		Push a folder

To understand how this script works, you need to have a proper layout on how you keep your servers in line.

You have your home folder, in our case called /home/lz in here we have the servers.sh, in that same folder you have the .servers file. In this example you type in all the servers you have which reflects in directory's on the filesystem.

Lets say you have "SERVERS='dustbowl'" in your .servers that would also mean that you have a installation in /home/lz/dustbowl. If you have another server, add it to the SERVERS and make sure you have that installed.

Now we also need to add a .config.sh inside each folder of your SERVERS, so you place the example .config.sh (ofcourse change to your setup) into /home/lz/dustbowl.

Thats it if you want to use everything the script has to offer EXCEPT for the "link" option.

Using the link option
---------------------

If you want to link all your files shared and non shared plugins/configs you need to make some extra directorys. For each gametype (that is tf/css/whatever) you need to make a folder called /home/lz/shared/tf/plugins /home/lz/shared/tf/configs.

In /home/lz/shared/tf you will need to have 2 files. They are called <gametype>.links.txt <gametype>.shared.txt
And lastly create a /home/lz/shared/configs

For each gametype you need to have those folders and txt files present!

in the <gametype>.links.txt you can have something like:

	cfg/server.cfg
	cfg/autoexec.cfg

And in the <gametype>.shared.txt you can have:

	addons/sourcemod/configs/databases.cfg

So now you would say, whats the point of all this? If you have a ton of servers running on the same box you will have 1 folder which houses all your plugins. So if a update comes out for 1 plugin that is used on several of your servers you dont need to go through all servers. Also your config files for all important files in the links file will be in 1 central place, without having to cd to all your servers (they are all symbolic linked) also handy is the shared one, which can be shared across gametypes mostly. The databases.cfg stays the same and any change you will likely want to update all servers.

Multi Server (other physical machines) setup
--------------------------------------------

Here comes the good part, if you have multiple phsyical machines and have servers on those in the same homedir folder you can use a tool called "unison" you can look up documentation on it but it allows for you to sync folders like rsync does for instance, but then via ssh. Setup a public keypair between the machines and use unison to sync that plugins/config folders! That way if you update a plugin it will also get synced to the other boxes. I have the complete /shared folder sync to the other boxes. Do keep in mind that if you go for multiple setup that its wise to put your servers.sh in /shared/bin and link it to your home folder. (so if a update is out or you make changes, it gets synced too!)

Cleanup
-------

Just a simple cleanup, put the ./servers.sh cleanup all (to do all servers) in a crontab and it will clean out sprays/replays/logs/sourcemod logs etc that are older then 7 days. You could use a plugin, but why install a plugin on 20+ servers if you can do it with a script too.

Send
----

The ./servers.sh send command can be used with "all" or just the server name, handy if you want to issue something via the commandline. I used this back in the days before using SSMS, my other tool.

Push
----

For now its hardcoded that it uses ~/sources/push folder to push files to. What it does it will copy the contents of this folder to the base of the install (so goldrush/orangebox/tf/ for instance) so make sure you have all the correct folders in there, if you want to add a plugin it needs to be in addons/sourcemod/plugins for it to work.

3 options:
	./servers.sh push goldrush - Does a push of the contents of those files towards the goldrush server
	./servers.sh push all - Does a push to ALL servers (if you want to roll out a sourcemod new version for instance)
	./servers.sh push all tf - Checks the gametype and only pushes the files to all servers with the gametype tf

Do remember that this does copy files over so be carefull with this, test before you run this and see if it is handy for you as it is for me. I can update my sourcemod on all servers in less then 5 minutes on 40 servers.

Question / Feedback
-------------------

I am sure this is not enough info for everyone, but i do stress out that you need to be a pretty good admin/linux guy to understand these tricks. Any "starters" should not touch this thing in a long shot because i cannot be held responsible for anything that happens here.

Or go to https://forums.alliedmods.net/showthread.php?t=182517
