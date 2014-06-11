on error resume next
set outstreem=wscript.stdout
set instreem=wscript.stdin

if (lcase(right(wscript.fullname, 11)) = "wscript.exe") then
	set objShell = wscript.createObject("wscript.shell")
	objShell.Run("cmd.exe /k cscript //nologo " & chr(34) & wscript.scriptfullname & chr(34))
	wscript.quit
end if
if wscript.arguments.count < 3 then
	usage()
	wscript.echo "Not enough parameters."
	wscript.quit
end if

ipaddress = wscript.arguments(0)
username = wscript.arguments(1)
reboot = wscript.arguments(2)
password = "Gavi123456"

usage()
set objlocator = createobject("wbemscripting.swbemlocator")

do
	outstreem.write "Conneting " & ipaddress & " " & password &  " ...."
	set objswbemservices=objlocator.connectserver(ipaddress, "root/cimv2", username, password)
	showerror(err.number)
	If Err.Number then
		outstreem.write "Password:"
		password = instreem.ReadLine
		WScript.Echo ""
	Else
		Exit do
	End if
loop

objswbemservices.security_.privileges.add 23, true
objswbemservices.security_.privileges.add 18, true

outstreem.write "Checking OS type...."
set colinstoscaption = objswbemservices.execquery("select caption from win32_operatingsystem")
for each objinstoscaption in colinstoscaption
	if instr(objinstoscaption.caption, "Server") > 0 then
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

rebt=lcase(reboot)
flag=0
if rebt = "/r" or rebt = "-r" or rebt = "\r" then flag = 2
if rebt = "/fr" or rebt = "-fr" or rebt = "\fr" then flag = 6
if flag <> 0 then
	outstreem.write "Now, reboot target...."
	strwqlquery = "select * from win32_operatingsystem where primary = true"
	set colinstances = objswbemservices.execquery(strwqlquery)
	for each objinstance in colinstances
		objinstance.win32shutdown(flag)
	next
	showerror(err.number)
else
	wscript.echo "You need to reboot target." & vbcrlf & "Then,"
end if

function showerror(errornumber)
	if errornumber Then
		wscript.echo "Error 0x" & cstr(hex(err.number)) & " ."
		if err.description <> "" then
			wscript.echo "Error description: " & err.description & "."
		end if
	else
		wscript.echo "OK!"
	end if
end function

function usage()
	wscript.echo string(79,"*")
	wscript.echo "ROTS v1.05"
	wscript.echo "Remote reboot Script, by Mr.Liu"
	wscript.echo "Usage:"
	wscript.echo "cscript " & wscript.fullname & " targetIP username [/r|/fr]"
	wscript.echo "/r: auto reboot target."
	wscript.echo "/fr: auto force reboot target."
	wscript.echo string(79, "*") & vbcrlf
end function