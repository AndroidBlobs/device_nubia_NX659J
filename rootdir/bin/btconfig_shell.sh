#!/vendor/bin/sh

#Read the arguments passed to the script
LOG_TAG="btnb-btconfig-sh"
LOG_NAME="${0}:"
BIN_PATH=/vendor/bin/btconfig

# call status : "running","true","false"
CMD_CALL_STATUS="running"

# ble test ogf ocf
HCI_BLE_OGF=0x08
HCI_BLE_OCF_LE_RX_V1=0x1D
HCI_BLE_OCF_LE_TX_V1=0x1E
HCI_BLE_OCF_LE_RX_V2=0x33
HCI_BLE_OCF_LE_TX_V2=0x34
HCI_BLE_OCF_LE_RX_V3=0x4F
HCI_BLE_OCF_LE_TX_V3=0x50

logd ()
{
  /system/bin/log -t $LOG_TAG -p d "$LOG_NAME $@"
}

# call status : "running","true","false"
set_call_status ()
{
    setprop vendor.wl.bt.btconfig.status $1
}

# return pid
check_wdsdaemon_exists ()
{
  pid=$(ps -ef | grep wdsdaemon | grep -v grep | awk '{print $2}')
  if [ "${pid}" -gt 0 ];then
	return 1
  fi

  return 0
}

# wait for 3s
ensure_wdsdaemon_exists ()
{
  # start it if needed
  check_wdsdaemon_exists
  if [ $? -eq 0 ];then
	logd "daemon not started, start it now ..."
	$(/vendor/bin/wdsdaemon -su >/dev/null 2>&1 &)
    # it will take sometime to initialize uart
    sleep 3s
  else
    return 1
  fi

  #check if started
  check_wdsdaemon_exists
  if [ $? -eq 0 ];then
      logd "daemon start failed"
      return 0
  else
      logd "daemon start success"
      return 1
  fi
}

cmd_help ()
{
    echo "reset -- Reset Target"
    echo "edutm -- Enter DUT Mode"
    echo "hciinq -- Inquiry start"
    echo "hciinqcnl -- Inquiry Cancel"
    echo "lert <RX_Channel> -- Put unit in LE RX mode at rx_channel (0..39)"
    echo "lett <TX_Channel> <Length_Of_Test_Data> <Packet_Payload> -- Put unit in LE TX mode at tx_channel (0..39) with packet of given length (0..37) and packet_payload"
    echo "lete -- End LE test"
    echo "rawcmd -- RAW HCI Command ex) rawcmd ogf ocf <bytes>"
    echo "lerx_v1 <RX_Channel>"
    echo "letx_v1 <TX_Channel> <Length_Of_Test_Data> <Packet_Payload>"
    echo "lerx_v2 <RX_Channel> <PHY> <Modulation_Index>"
    echo "letx_v2 <TX_Channel> <Length_Of_Test_Data> <Packet_Payload> <PHY>"
    echo "lerx_v3 <RX_Channel> <PHY> <Modulation_Index> <Expected_CTE_Length> <Expected_CTE_Type>"
    echo "\t<Slot_Durations> <Length_of_Switching_Pattern> <Antenna_IDs[i]>"
    echo "letx_v3 <TX_Channel> <Length_Of_Test_Data> <Packet_Payload> <PHY> <CTE_Length> <CTE_Type>"
    echo "\t<Length_of_Switching_Pattern> <Antenna_IDs[i]>"
    echo "\n********************le test parameters*****************************"
    echo "RX_Channel,TX_Channel : (0x00 to 0x27)=(Frequency-2402)/2"
    echo "Length_Of_Test_Data : (0x00 to 0xFF), Length in bytes of payload data in each packet"
    echo "Packet_Payload : (0x00 to 0x07)"
    echo "\t0x00 : Pseudo-Random bit sequence 9"
    echo "\t0x01 : Repeated '11110000'"
    echo "\t0x02 : Repeated '10101010'"
    echo "\t0x03 : Pseudo-Random bit sequence 15"
    echo "\t0x04 : Repeated '11111111'"
    echo "\t0x05 : Repeated '00000000'"
    echo "\t0x06 : Repeated '00001111'"
    echo "\t0x07 : Repeated '01010101'"
    echo "PHY : (0x00 to 0x04)"
    echo "\t0x01 : LE 1M"
    echo "\t0x02 : LE 2M"
    echo "\t0x03 : LE Coded PHY with S=8 data coding"
    echo "\t0x04 : LE Coded PHY with S=2 data coding"
    echo "Modulation_Index : (0x00 to 0x01)"
    echo "\t0x00 : Assume transmitter will have a standard modulation index"
    echo "\t0x01 : Assume transmitter will have a stable modulation index"
    echo "Expected_CTE_Length : (0x00,0x02 to 0x14)"
    echo "\t0x00 : No Constant Tone Extension expected"
    echo "\t0x02 to 0x14 : Expected length of the Constant Tone Extension in 8 us units"
    echo "Expected_CTE_Type : (0x00 to 0x02)"
    echo "\t0x00 : Expect AoA Constant Tone Extension"
    echo "\t0x01 : Expect AoD Constant Tone Extension with 1 us slots"
    echo "\t0x02 : Expect AoD Constant Tone Extension with 2 us slots"
    echo "Slot_Durations : (0x01 to 0x02)"
    echo "\t0x01 : Switching and sampling slots are 1 us each"
    echo "\t0x02 : Switching and sampling slots are 2 us each"
    echo "Length_of_Switching_Pattern : (0x02 to 0x4B), The number of Antenna IDs in the pattern"
    echo "Antenna_IDs[i] : (0xXX), List of Antenna IDs in the pattern"
    echo "CTE_Length : (0x00,0x02 to 0x14)"
    echo "\t0x00 : Do not transmit a Constant Tone Extension"
    echo "\t0x02 to 0x14 : Length of the Constant Tone Extension in 8 us units"
    echo "CTE_Type : (0x00 to 0x02)"
    echo "\t0x00 : AoA Constant Tone Extension"
    echo "\t0x01 : AoD Constant Tone Extension with 1 us slots"
    echo "\t0x02 : AoD Constant Tone Extension with 2 us slots"
    echo "*******************************************************************\n"
}

dec2hex ()
{
  val=0
  for var in $@
  do
    val=$(printf "0x%x\n" ${var})
	#echo will return value
	echo ${val}
  done
}

cmd_start ()
{
    ensure_wdsdaemon_exists
}

cmd_stop ()
{
  pid=$(ps -ef | grep wdsdaemon | grep -v grep | awk '{print $2}')
  if [ "${pid}" -gt 0 ];then
    kill -9 ${pid}
	logd "stop wdsdaemon"
  else
    logd "wdsdaemon stopped"
  fi
}

cmd_reset ()
{
  ${BIN_PATH} reset
}

cmd_edutm ()
{
  ${BIN_PATH} edutm
}

cmd_hciinq ()
{
  #${BIN_PATH} hciinq 33 8b 9e 12 5
  strs=$(${BIN_PATH} hciinq 33 8b 9e 12 5 2>&1)

  #remove the space
  array=(${strs// /})

  device_found=0
  for var in ${array[@]}
  do
    #echo $var
	if [ ${device_found} -eq 1 ];then
		#parse data
		#remove '['
		temp1=$(echo ${var//[/})
		#replace ']' to ' '
		temp2=$(echo ${temp1//]/ })
		#split string to array
		OLD_IFS="$IFS"
		IFS=" "
		arr=($temp2)
		IFS="$OLD_IFS"
		#get address
		echo "address : "${arr[8]}:${arr[7]}:${arr[6]}:${arr[5]}:${arr[4]}:${arr[3]}
		logd "found device address : ${arr[8]}:${arr[7]}:${arr[6]}:${arr[5]}:${arr[4]}:${arr[3]}"
		let device_found=0
	elif [ ${var} == "INQRESULTEVENTRECEIVED" ];then
		let device_found=1
	else
		let device_found=0
	fi
  done
}

cmd_hciinqcnl ()
{
  ${BIN_PATH} hciinqcnl
}

cmd_lert ()
{
  ${BIN_PATH} lert $1
}

cmd_lett ()
{
  ${BIN_PATH} lett $1 $2 $3
}

cmd_lerx_v1 ()
{
  arr=$(dec2hex $@)
  ${BIN_PATH} rawcmd ${HCI_BLE_OGF} ${HCI_BLE_OCF_LE_RX_V1} ${arr}
}

cmd_letx_v1 ()
{
  arr=$(dec2hex $@)
  ${BIN_PATH} rawcmd ${HCI_BLE_OGF} ${HCI_BLE_OCF_LE_TX_V1} ${arr}
}

cmd_lerx_v2 ()
{
  arr=$(dec2hex $@)
  ${BIN_PATH} rawcmd ${HCI_BLE_OGF} ${HCI_BLE_OCF_LE_RX_V2} ${arr}
}

cmd_letx_v2 ()
{
  arr=$(dec2hex $@)
  ${BIN_PATH} rawcmd ${HCI_BLE_OGF} ${HCI_BLE_OCF_LE_TX_V2} ${arr}
}

cmd_lerx_v3 ()
{
  arr=$(dec2hex $@)
  ${BIN_PATH} rawcmd ${HCI_BLE_OGF} ${HCI_BLE_OCF_LE_RX_V3} ${arr}
}

cmd_letx_v3 ()
{
  arr=$(dec2hex $@)
  ${BIN_PATH} rawcmd ${HCI_BLE_OGF} ${HCI_BLE_OCF_LE_TX_V3} ${arr}
}

cmd_lete ()
{
  #${BIN_PATH} lete
  strs=$(${BIN_PATH} lete 2>&1)

  #remove the space
  array=(${strs// /})

  recv_dump="RECV<-dump"
  data_counts=16
  for var in ${array[@]}
  do
	tmparr=(${var//:/ })
	#echo "length is : "${#tmparr[@]}
	if [ ${tmparr[0]} == ${recv_dump} ];then
		values=${tmparr[1]}
		#for test, packets=3850
		#values="0e06011f20000a0f"
		if [ ${#values} -eq ${data_counts} ];then
			#0e 06 01 1f 20 00 00 00
			ogf=${values:6:2}
			ocf=${values:8:2}
			low=${values:12:2}
			high=${values:14:2}
			if [ ${ogf} == "1f" -a ${ocf} == "20" ];then
				lowval=$((16#${low}))
				highval=$((16#${high}))
				packets=$(echo "${highval}*2^8+${lowval}"|bc)
				# get packets
				echo ${packets}
				logd "get packets : ${packets}"
				exit 0
			fi
		fi
	fi
  done
}

cmd_lete2 ()
{
  #${BIN_PATH} lete
  strs=$(${BIN_PATH} lete 2>&1)

  #remove the space
  array=(${strs// /})

  length=${#array[@]}
  #split string to array
  OLD_IFS="$IFS"
  IFS="="
  arr=(${array[length-1]})
  IFS="$OLD_IFS"
  # get packets
  echo ${arr[1]}
  logd "get packets : ${arr[1]}"
}

cmd_rawcmd ()
{
  ${BIN_PATH} rawcmd $@
}

cmd_names=("help" "start" "stop" "reset" "edutm" "hciinq" "hciinqcnl" "lert" "lett" "lerx_v1" "letx_v1" "lerx_v2" "letx_v2" "lerx_v3" "letx_v3" "lete" "rawcmd")
cmd_funcs=(cmd_help cmd_start cmd_stop cmd_reset cmd_edutm cmd_hciinq cmd_hciinqcnl cmd_lert cmd_lett cmd_lerx_v1 cmd_letx_v1 cmd_lerx_v2 cmd_letx_v2 cmd_lerx_v3 cmd_letx_v3 cmd_lete cmd_rawcmd)

logd "receive : $@"

tmp_params=$@
cmd=${tmp_params%% *}
params=${tmp_params#* }

# process stop
if [ "stop" = ${cmd} ];then
    check_wdsdaemon_exists
    if [ $? -eq 0 ];then
        set_call_status "true"
        logd "daemon stopped before"
        exit 0
    fi
fi

# start wdsdaemon before connect to it
ensure_wdsdaemon_exists
if [ $? -eq 0 ];then
    logd "cmd not execute : ${cmd}"
    set_call_status "false"
    exit 0
fi

CALL_STATUS="true"
logd "executing : ${cmd}"
index=0
found_cmd=0
for var in ${cmd_names[@]}
do
    if [ ${cmd} = ${var} ];then
		let found_cmd=1
		logd "call ${cmd_funcs[index]}"
		${cmd_funcs[index]} ${params}
		break
	fi
	let index++
done

if [ ${found_cmd} -eq 1 ];then
	logd "finish : ${cmd}"
else
	CALL_STATUS="false"
	logd "invalid command"
fi

set_call_status ${CALL_STATUS}

exit 0
