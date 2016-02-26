#!/bin/bash

# --------------------------------------------------------------------------------
# VARS & FUNCTIONS
# --------------------------------------------------------------------------------

function quit() {
	echo -e "ERROR: $@"
	exit 2
}
function points() {
	local w
	[ -z "$1" ] && w=$1 || w=1
	sleep $w ; echo -n "." ; sleep $w ; echo -n "." ; sleep $w ; echo "." ; sleep $w ;
}

SCRIPT="$0"
CONF="${SCRIPT/.sh/.conf}"
INC="${SCRIPT/.sh/.inc.sh}"

# include inc.sh variables (TODOS, ARCHIVE_CONF_FILES, ADMIN_USER, SAVE_USER, OTHER_USERS)
[ ! -f "$INC" ] && touch $INC
[ -f "$INC" ] || quit "'$INC' inc file not found"
[ -f $CONF ] || quit "'$CONF' conf file not found"

echo "editing inc & conf file to configure include & todos"
sleep 1
echo -n "vi $INC $CONF "
points
vi $INC $CONF || quit "editing conf & inc files failed"
. $INC || quit "'$INC' inc file include failed"

TODOS="`grep -vE "(^#|^$)" $CONF | awk -f= '{print $1}'`"

for todo in $TODOS ; do
	case $todo in
		server*) echo "$todo=toConfigure" >> $CONF ;;
		*) echo "$todo=todo" >> $CONF ;;
	esac
done

function getFunction() {
	local todo="$1"
	grep "^function do_$todo" $SCRIPT
}

function isTodo() {
	local key=$1
	if [ ! -z "$key" ] ; then
		local val=`awk -F= '$1 ~ /^'$key'/ {print $2}' $CONF`
		if [ -z "$val" ] ; then
			quit "$key not found in $CONF"
		else
			if [ "$val" == 'todo' ] ; then
				echo "$key ..."
			else
				echo "$key is '$val'... skipping"
				return 1
			fi
		fi
	else
		quit "isTodo: key not set"
	fi
}

function setDone() {
	local key=$1
	if [ ! -z "$key" ] ; then
		local val=`grep "^$key" $CONF`
		if [ -z "$val" ] ; then
			quit "$key not found in $CONF"
		else
			sed -i 's/\('$key'\)=todo/\1=done/' $CONF \
				&& echo "$key DONE"
		fi
	else
		quit "setTodo: key not set"
	fi
}

function setError() {
	local key=$1
	if [ ! -z "$key" ] ; then
		local val=`grep "^$key" $CONF`
		if [ -z "$val" ] ; then
			quit "$key not found in $CONF"
		else
			sed -i 's/\('$key'\)=todo/\1=ERROR/' $CONF \
				&& echo "$key DONE"
		fi
	else
		quit "setTodo: key not set"
	fi
}


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


# CONFIG THIS SCRIPT
# ----------------------------------------
function do_confHookScript() {
	vi $CONF
}

# --------------------------------------------------------------------------------
# UTILS
# --------------------------------------------------------------------------------

# INSTALLATIONS
# ----------------------------------------
function do_aptDate() {
	apt-get -y update \
		&& apt-get -y upgrade
}

function do_aptUtils() {
	apt-get -y install vim screen htop sudo aptitude lsof curl lynx git-core wget \
		&& apt-get -y remove --purge nano
}

# CONFIGURATIONS
# ----------------------------------------
function do_configFiles() {
	if [ -e "$ARCHIVE_CONF_FILES" ] ; then
		here="`pwd`"
		cd / \ # go to root
			&& tar -xf "$here/$ARCHIVE_CONF_FILES" \ # extract
			&& cd "$here" # return to start path
	else
		echo "$ARCHIVE_CONF_FILES : no such file or directory"
		return 1
	fi
}
function do_configVim() {
	echo -e "runtime! debian.vim\nse nu\nse ruler\nsyntax on\nse background=dark\nse \
		ai\nse shiftwidth=2\nse tabstop=2\n" > /etc/vim/vimrc
}
function do_configSsh() {
	echo "implements here the following content"
	echo "# Authentication:"
	echo "LoginGraceTime 120"
	echo "#PermitRootLogin without-password"
	echo "PermitRootLogin no"
	echo "StrictModes yes"
	echo "AllowUsers $ADMIN_USER $SAVE_USER $OTHER_USERS"
	points
	vi /etc/ssh/sshd_config
	return 0
}
function do_configFirewall() {
	vi /sbin/firewall.sh \
		&& chmod +x /sbin/firewall.sh \
		&& echo "#/sbin/firewall.sh > /dev/null 2>&1" >> /etc/rc.local \
		&& vi /etc/rc.local
}
function do_configGit() {
	return 0
}
function do_configScreen() {
	return 0
}
function do_configSave() {
	return 0
}

function do_security() {
	echo "todo : implements here"
	echo "mail (spamassassin)"
	echo "jailChroot"
	echo "fail2ban ssh ?"
	echo "denyhosts !"
	points
	return 0
}

# USERS
# ----------------------------------------
function do_adminUser() {
	if [ -z "$ADMIN_USER" ] ; then
		adduser $ADMIN_USER \
			&& adduser $ADMIN_USER sudo
	else
		quit "ADMIN_USER NOT SET"
	fi
}
function do_saveUser() {
	if [ -z "$SAVE_USER" ] ; then
		quit "SAVE USER NOT SET"
	else
		adduser $SAVE_USER
	fi
}
function do_otherUsers() {
	if [ -z "$OTHER_USERS" ] ; then
		echo "OTHER USERS NOT SET"
	else
		local user
		for user in $OTHER_USERS ; do
			adduser $user
		done
	fi
}

# PERMISSIONS
# ----------------------------------------
function do_permissions() {
	visudo
}

# END OF UTILS -------------------------------------------------------------------


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


# --------------------------------------------------------------------------------
# SERVERS
# --------------------------------------------------------------------------------

# WEB
# ----------------------------------------
function do_serverWeb() {
	apt-get install -y apache2 libapache2-mod-php5 php5-cli openssl php5-mysql \
		&& a2enmode ssl \
		&& a2enmode proxy \
		&& a2enmode proxy_http \
		&& a2enmode rewrite
}

# SQL
# ----------------------------------------
function do_serverSql() {
	apt-get install -y mysql-client-5.5 mysql-server-5.5
}

# JAVA
# ----------------------------------------
function do_serverJava() {
	apt-get install -y openjdk-7-jre
}

# END OF SERVERS -----------------------------------------------------------------

# --------------------------------------------------------------------------------
# RUN SCRIPT
# --------------------------------------------------------------------------------

for todo in $TODOS ; do
	f=`getFunction $todo`
	if [ ! -z "$f" ] ; then
		isTodo $todo
		if [ $? -eq 0 ] ; then
			echo -n "do_$todo found ($f) "
			points 0.5
			do_$todo \
				&& setDone $todo \
				|| setError $todo
		fi
	else
		quit "do_$todo is not a function"
	fi
done
