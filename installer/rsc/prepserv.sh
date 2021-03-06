hostname_base="Generic Arma3"
hostname_id1=' Server 1 |'
hostname_id2=' Server 2 |'
hostname_id3=' Server 3 |'

# build modlist

#debug lines
#mods="_mods/@cba_a3;_mods/@rhsafrf;"
#servermods=";_mods/@slmd;_mods/@slz;"

mods=""
servermods=""
hostname_mods=""

while read line; do
	apptype=$(echo $line | awk '{ printf "%s", $3 }')
	appname=$(echo $line | awk '{ printf "%s", $1 }')
	appkey=$(echo $line | awk -v var=$(( $serverid + 3 )) '{ printf "%s", $var }')
	applistname=$(echo $line | awk '{ printf "%s", $7 }')

	#echo "appname ${appname} appkey ${appkey} apptype ${apptype} applistname ${applistname}"

	if [ "${apptype}" = "mod" ] && [ "${appkey}" = "1" ]; then
		mods=${mods}"_mods/@"${appname}";"
	fi

        if [ "${apptype}" = "smod" ] && [ "${appkey}" = "1" ]; then
                servermods=${servermods}"_mods/@"${appname}";"
        fi

	if [ "${applistname}" != "xx" ] && [ "${appkey}" = "1" ]; then
		if [ "${hostname_mods}" = "" ]; then
		hostname_mods=${hostname_mods}" ${applistname}"
		else
		hostname_mods=${hostname_mods}", ${applistname}"
		fi
	fi
done < ${basepath}/scripts/modlist.inp

export mods=$mods
export servermods=$servermods

if [ "${hostname_mods}" = "" ]; then
	hostname_mods=${hostname_mods}" Vanilla"
fi

# make hostname
case "$serverid" in
1)
hostname_base=${hostname_base}${hostname_id1}
;;
2)
hostname_base=${hostname_base}${hostname_id2}
;;
3)
hostname_base=${hostname_base}${hostname_id3}
;;
esac
hostname=${hostname_base}${hostname_mods}

# generate cfg-file
echo "//-------------------------------------
//DO NOT MODIFY THIS FILE, IT IS GENERATED BY A SCRIPT
//modify a3common.cfg and a3indi\[i\].cfg  instead.
//
//***Start of scripted part***
//

hostname = \"${hostname}\";

//
//***End of Scripted part***
//
//------------------------------------
//*** a3common.cfg ***" > $config
chown ${useradm}:${profile} $config
chmod 664 $config
#
cat ${cfg_dir}/a3common.cfg >> ${config}
echo "//
//------------------------------------
//***a3indi${serverid}.cfg ***
//" >> ${config}
cat ${cfg_dir}/a3indi${serverid}.cfg >> ${config}

# make symlinks to the keys
find ${basepath}/a3srv${serverid}/keys/ -maxdepth 1 -type l -delete
ln -s ${basepath}/a3master/keys/a3.bikey ${basepath}/a3srv${serverid}/keys/
while read line; do
	apptype=$(echo $line | awk '{ printf "%s", $3 }')
        appname=$(echo $line | awk '{ printf "%s", $1 }')
        appkey=$(echo $line | awk -v var=$(( $serverid + 3 )) '{ printf "%s", $var }' )
        #echo "appkey = ${appkey} for ${appname}"
        if [ "${apptype}" != "smod" ] && [ "${appkey}" = "1" ]; then
	#echo " ... ${appname}-key on server #${serverid}"
		find ${basepath}/a3master/_mods/@${appname}/ -type f -name "*.bikey" -exec ln -sf {} ${basepath}/a3srv${serverid}/keys/ \;
        fi
done < ${basepath}/scripts/modlist.inp
