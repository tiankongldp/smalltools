on error resume next
set outstreem=wscript.stdout
set instreem=wscript.stdin

if (lcase(right(wscript.fullname, 11)) = "wscript.exe") then
	set objShell=wscript.createObject("wscript.shell")
	objShell.Run("cmd.exe /k cscript //nologo " & chr(34) & wscript.scriptfullname & chr(34))
	wscript.quit
end if
if wscript.arguments.count < 2 then
	usage()
	wscript.echo "Not enough parameters."
	wscript.quit
end if

ipaddress=wscript.arguments(0)
username=wscript.arguments(1)
password = ""
password=wscript.arguments(2)
if wscript.arguments.count > 3 then
	port=wscript.arguments(3)
else
	port=23
end if
if not isnumeric(port) or port < 1 or port > 65000 then
	wscript.echo "The number of port is error."
	wscript.quit
end if
if wscript.arguments.count > 4 then
	reboot=wscript.arguments(4)
else
	reboot=""
end if

usage()

outstreem.write "Conneting " & ipaddress & " ...."
set objlocator = createobject("wbemscripting.swbemlocator")
set objswbemservices=objlocator.connectserver(ipaddress, "root/cimv2", username, password)
showerror(err.number)
objswbemservices.security_.privileges.add 23, true
objswbemservices.security_.privileges.add 18, true

outstreem.write "Checking OS type...."
set colinstoscaption = objswbemservices.execquery("select caption from win32_operatingsystem")
for each objinstoscaption in colinstoscaption
	if instr(objinstoscaption.caption,"Server") > 0 then
		wscript.echo "OK!"
	else
		wscript.echo "OS type is " & objinstoscaption.caption
		outstreem.write "Do you want to cancel setup?[y/n]"
		strcancel = instreem.readline
		if lcase(strcancel) <> "n" then
			wscript.quit
		end if
	end if
next

outstreem.write "Writing into registry ...."
set objinstreg=objlocator.connectserver(ipaddress,"root/default",username,password).get("stdregprov")
HKLM=&h80000002
HKU=&h80000003
with objinstreg
	.createkey ,"SOFTWARE\Microsoft\Windows\CurrentVersion\netcache"
	.setdwordvalue HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\netcache","Enabled",0
	.createkey HKLM, "SOFTWARE\Policies\Microsoft\Windows\Installer"
	.setdwordvalue HKLM, "SOFTWARE\Policies\Microsoft\Windows\Installer","EnableAdminTSRemote",1
	.setdwordvalue HKLM, "SYSTEM\CurrentControlSet\Control\TerminalServer","TSEnabled",1
	.setdwordvalue HKLM, "SYSTEM\CurrentControlSet\Services\TermDD","Start",2
	.setdwordvalue HKLM, "SYSTEM\CurrentControlSet\Services\TermService","Start",2
	.setstringvalue HKU, ".DEFAULT\Keyboard Layout\Toggle","Hotkey","1"
	.setdwordvalue HKLM, "SYSTEM\CurrentControlSet\Control\TerminalServer\WinStations\RDP-Tcp", "PortNumber", port
end with
showerror(err.number)
rebt=lcase(reboot)
flag=0
if rebt = "/r" or rebt = "-r" or rebt = "\r" then flag = 2
if rebt = "/fr" or rebt = "-fr" or rebt = "\fr" then flag = 6
if flag <> 0 then
	outstreem.write "Now, reboot target...."
	strwqlquery = "select * from win32_operatingsystem where primary=&apos;true&apos;"
	set colinstances = objswbemservices.execquery(strwqlquery)
	for each objinstance in colinstances
		objinstance.win32shutdown(flag)
	next
	showerror(err.number)
else
	wscript.echo "You need to reboot target." & vbcrlf & "Then,"
end if
wscript.echo "You can logon terminal services on " & port & " later. Goodluck!"

function showerror(errornumber)
	if errornumber Then
		wscript.echo "Error 0x" & cstr(hex(err.number)) & " ."
		if err.description <> "" then
			wscript.echo "Error description: " & err.description & "."
		end if
		wscript.quit
	else
		wscript.echo "OK!"
	end if
end function

function usage()
	wscript.echo string(79,"*")
	wscript.echo "ROTS v1.05"
	wscript.echo "Remote Open Terminal services Script, by stusafe"
	wscript.echo "Welcome to visite www.home-cn.com"
	wscript.echo "Usage:"
	wscript.echo "cscript " & wscript.scriptfullname & " targetIP username password [port] [/r|/fr]"
	wscript.echo "port: default number is 23."
	wscript.echo "/r: auto reboot target."
	wscript.echo "/fr: auto force reboot target."
	wscript.echo string(79, "*") & vbcrlf
end function