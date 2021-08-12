#-
#- Analyze Apache Access Log
#-
#- $Header: acclog_analyze.sh v1.4 cwjeong noship $
#-
#- Description : Gather status data from Apache access log
#-
#- Change History
#- 2017/06/21 Initial
#- 2017/06/23 Changed for reading compressed log
#- 2017/06/28 One-Pass reading for performance improvement
#- 2017/06/30 Changed for next bug fix
#- 2017/07/03 One-Pass reading bug fix
#-

#-------------------------------------------------------------------------------
#- Apache env
#-------------------------------------------------------------------------------

DIR=`dirname $0`
. $DIR/acclog_analyze.conf

fn_chk_errpage()
{
  inst=$1
  instno=$2
  logpos=$3

 # $CATCMD $access_logs | $AWKCMD -v unit=$unit -v inst=$inst -v instno=$instno -v logpos=$logpos -v host=$HOSTNAME '
  echo $access_logs | $AWKCMD -v unit=$unit -v inst=$inst -v instno=$instno \
                              -v logpos=$logpos -v host=$HOSTNAME -v zcatcmd=$ZCATCMD '
#==============================================================================
# Convert URL
#==============================================================================
function ConvertURL(fullurl) {
  gsub(/%26/, "&", fullurl)
  gsub(/%2F/, "/", fullurl)
  gsub(/%3D/, "=", fullurl)
  gsub(/%3F/, "?", fullurl)
  gsub(/"/, "", fullurl)

  v = split(fullurl, a, "?")
  v = split(a[1], b, ";")         # For ERP R12 /forms/lservlet;jsessionid=ac...
  purl = b[1];
  parm = a[2]

  convurl = ""
  nparm = split(parm, arrparm, "&")
  if (purl ~ "/OA.jsp" || purl ~ "/RF.jsp") {
    if (arrparm[1] ~ "^page="   || arrparm[1] ~ "^OAFunc="       || arrparm[1] ~ "^_rc=" ||
        arrparm[1] ~ "^region=" || arrparm[1] ~ "^akRegionCode=" || arrparm[1] ~ "^function_id=") {
      convurl = arrparm[1]
    }
    for (i=2; i <= nparm; i++) {
      if (arrparm[i] ~ "^page=" || arrparm[i] ~ "^OAFunc=" || arrparm[i] ~ "^_rc=") {
        convurl = arrparm[i]
        break
      }
    }
  } else if (purl ~ "/EAI/receiver") {
    # POST /C46/C46010/EAI/receiver?tc=HNMAD112&seq=59 HTTP/1.1" 207 - 0
    if (arrparm[1] ~ "^tc=") {
      convurl = arrparm[1]
    }
  }
  
  if (convurl == "") {
    convurl = purl
  }
  return convurl
}

function PrintValue() {
  printf "<|hostname|instname|inst#|errstat|err_cnt|avg_resp|err_url|err_refer\n"

  for (url in err400) {
    if (err400[url] > 20)
      printf ">|%s|%s|%s|Err_4xx|%d|%.2f|%s|%s\n", host, inst, instno, err400[url], 0, url, ref400[url]
  }
  for (url in err500) {
    if (err500[url] > 20)
      printf ">|%s|%s|%s|Err_5xx|%d|%.2f|%s|%s\n", host, inst, instno, err500[url], 0, url, ref500[url]
  }
  for (url in err600) {
    if (err600[url] > 20)
      printf ">|%s|%s|%s|Err_6xx|%d|%.2f|%s|%s\n", host, inst, instno, err600[url], 0, url, ref600[url]
  }
  for (url in err700) {
    if (err700[url] > 20)
      printf ">|%s|%s|%s|Err_6xx|%d|%.2f|%s|%s\n", host, inst, instno, err700[url], 0, url, ref700[url]
  }
  for (url in badresp) {
    if (badresp[url] > 5)
      printf ">|%s|%s|%s|BadResp|%d|%.2f|%s|%s\n", host, inst, instno, badresp[url], badrsum[url]/badresp[url], url, refbad[url]
  }
}

BEGIN {
  if (logpos != "") {
    x = split(logpos, arr, ",")
    url_pos=arr[3]
    code_pos=(arr[4] > 0 ? arr[4] : NF-arr[4])
    if (arr[7] != "X") {
      resp_pos=(arr[7] > 0 ? arr[7] : NF-arr[7])
      microsec = 1
    } else if (arr[6] != "X") {
      resp_pos=(arr[6] > 0 ? arr[6] : NF-arr[6])
      microsec = 0
    }
    ref_pos=(arr[8] > 0 ? arr[8] : (arr[8] == "X" ? arr[8] : NF-arr[8]))
  } else {
    url_pos=7
    code_pos=9
    resp_pos=11
    microsec = 0
    ref_pos="X"
  }
}

{
  x = split($0, logarr) 
  for (ll = 1; ll <= x; ll++) {
    if (logarr[ll] ~ /.gz$/ || logarr[ll] ~ /.Z$/) {
      cmd = zcatcmd " " logarr[ll]
    } else {
      cmd = "cat " logarr[ll]
    }
    while (cmd | getline) {
      #---- Parse access_log ------------------------------------------------------
      statcode = $(code_pos) + 0
      if (resp_pos <= NF)
        resptime = (microsec == 1 ? $(resp_pos)/1000000. : $(resp_pos) + 0)
      else
        resptime = 0

      pageurl = ""
      if (statcode >= 900) {
        # MES, Okay
      } else if (statcode >= 700) {
        pageurl = ConvertURL($(url_pos))
        if (ref_pos != "X") callurl = ConvertURL($(ref_pos))

        err700[pageurl]++
        if (callurl != "" && ref700[pageurl] !~ callurl)
          if (ref700[pageurl] == "") ref700[pageurl] = callurl
          else  ref700[pageurl] = ref700[pageurl] ", " callurl
      } else if (statcode >= 600) {
        pageurl = ConvertURL($(url_pos))
        if (ref_pos != "X") callurl = ConvertURL($(ref_pos))

        err600[pageurl]++
        if (callurl != "" && ref600[pageurl] !~ callurl)
          if (ref600[pageurl] == "") ref600[pageurl] = callurl
          else  ref600[pageurl] = ref600[pageurl] ", " callurl
      } else if (statcode >= 500) {
        pageurl = ConvertURL($(url_pos))
        if (ref_pos != "X") callurl = ConvertURL($(ref_pos))

        err500[pageurl]++
        if (callurl != "" && ref500[pageurl] !~ callurl)
          if (ref500[pageurl] == "") ref500[pageurl] = callurl
          else  ref500[pageurl] = ref500[pageurl] ", " callurl
      } else if (statcode >= 400) {
        pageurl = ConvertURL($(url_pos))
        if (ref_pos != "X") callurl = ConvertURL($(ref_pos))

        err400[pageurl]++
        if (callurl != "" && ref400[pageurl] !~ callurl)
          if (ref400[pageurl] == "") ref400[pageurl] = callurl
          else  ref400[pageurl] = ref400[pageurl] ", " callurl
      }

      if (resptime > 10) {
        if (pageurl == "") {
          pageurl = ConvertURL($(url_pos))
          if (ref_pos != "X") callurl = ConvertURL($(ref_pos))
        }
        badresp[pageurl]++
        badrsum[pageurl] = badrsum[pageurl] + resptime
        if (callurl != "" && refbad[pageurl] !~ callurl)
          if (refbad[pageurl] == "") refbad[pageurl] = callurl
          else  refbad[pageurl] = refbad[pageurl] ", " callurl
      }
    }
    close(cmd)
  }
}    

END {
  print "[ERRPAGE_DATA]"
  print ""
  PrintValue()
}'

}

fn_chk_transaction()
{
  unit=$1
  inst=$2
  instno=$3
  logpos=$4

  echo $access_logs | $AWKCMD -v unit=$unit -v inst=$inst -v instno=$instno \
                              -v logpos=$logpos -v host=$HOSTNAME -v zcatcmd=$ZCATCMD '
#==============================================================================
# Convert blank separated string to associative array
#
#   "Jan Feb Mar ..." ==> arr["Jan"] = 1, arr["Feb"] = 2, arr["Mar"] = 3, ...
#==============================================================================
function asplit(str, arr) {
  n = split(str, temp)
  for (i = 1; i <= n; i++)
    arr[temp[i]] = i
  return n
} 
  
#==============================================================================
# Convert date string format in access_log to normal format
# 
#   24/Apr/2007:09:13:33 ==> 2007/04/24                 1D
#   24/Apr/2007:09:13:33 ==> 2007/04/24 09:00           1H
#   24/Apr/2007:09:13:33 ==> 2007/04/24 09:10           10M
#   24/Apr/2007:09:13:33 ==> 2007/04/24 09:13           1M
#   24/Apr/2007:09:13:33 ==> 2007/04/24 09:13:30        10S
#   24/Apr/2007:09:13:33 ==> 2007/04/24 09:13:33        1S
#==============================================================================
function datestr(str, unit) {
  v = split(substr(str,1,11), ymd, "/");
  
  if (ymd[2] in month) ymd[2] = month[ymd[2]]
  if (unit == "1D") {
    str = sprintf("%04d/%02d/%02d", ymd[3], ymd[2], ymd[1]);
  } else if (unit == "1H") {
    str = sprintf("%04d/%02d/%02d %s00", ymd[3], ymd[2], ymd[1], substr(str,13,3));
  } else if (unit == "10M") {
    str = sprintf("%04d/%02d/%02d %s0", ymd[3], ymd[2], ymd[1], substr(str,13,4));
  } else if (unit == "1M") {
    str = sprintf("%04d/%02d/%02d %s", ymd[3], ymd[2], ymd[1], substr(str,13,5));
  } else if (unit == "10S") {
    str = sprintf("%04d/%02d/%02d %s0", ymd[3], ymd[2], ymd[1], substr(str,13,7));
  } else if (unit == "1S") {
    str = sprintf("%04d/%02d/%02d %s", ymd[3], ymd[2], ymd[1], substr(str,13,8));
  } else {
    str = "" 
  }   
  return str
} 
  
#==============================================================================
# Print out KPI values for each time period
#==============================================================================
function PrintValue(unit) {

  printf "<|hostname|instname|inst#|basetime|access#|ip_cnt|avgsize|maxsize|avgresp|maxresp"
  printf "|<=2s#|<=5s#|<=10s#|>10s#|%s|%s|%s|%s|%s|%s|%s", "<=2s%","<=5s%","<=10s%",">10s%","App_OK%","App_Err%","Srv_Err%"
  for (code = 100; code < 1000; code++) {
    if (codetotal[code] > 0) printf "|>%s", code
  }
  for (code = 100; code < 1000; code++) {
    if (codetotal[code] > 0) printf "|>%s%", code
  }
  print ""

  narray = (unit == "1M" ? n1M : (unit == "10M" ? n10M : (unit == "1H" ? n1H : n1D)))
  for (i = 1; i <= narray; i++) {
    SAVETIME = (unit == "1M" ? time_1M[i] : (unit == "10M" ? time_10M[i] : (unit == "1H" ? time_1H[i] : time_1D[i])))
    basetime = datestr(SAVETIME, unit)
    if (basetime ~ /0000/) continue

    avgtm = timesum[SAVETIME] / acccnt[SAVETIME]
    avgsz = sizesum[SAVETIME] / acccnt[SAVETIME]

    printf ">|%s|%s|%s|%s|%d|%d|%.2f|%.2f|%.2f",
           host, inst, instno, basetime, acccnt[SAVETIME], ipcnt[SAVETIME], avgsz, sizemax[SAVETIME], avgtm
    if (microsec == 1) printf "|%.2f", respmax[SAVETIME]
    else               printf "|%d", respmax[SAVETIME]
    
    printf "|%d|%d|%d|%d", s2_cnt[SAVETIME], s5_cnt[SAVETIME], s10_cnt[SAVETIME], bad_cnt[SAVETIME]

    printf "|%.2f",  s2_cnt[SAVETIME]/acccnt[SAVETIME]*100.
    printf "|%.2f",  s5_cnt[SAVETIME]/acccnt[SAVETIME]*100.
    printf "|%.2f", s10_cnt[SAVETIME]/acccnt[SAVETIME]*100.
    printf "|%.2f", bad_cnt[SAVETIME]/acccnt[SAVETIME]*100.
    printf "|%.2f",  app_ok[SAVETIME]/acccnt[SAVETIME]*100.
    printf "|%.2f", app_err[SAVETIME]/acccnt[SAVETIME]*100.
    printf "|%.2f", srv_err[SAVETIME]/acccnt[SAVETIME]*100.

    for (code = 100; code < 1000; code++) {
      if (codetotal[code] > 0) printf "|%d", codesum[SAVETIME, code]
    }
    for (code = 100; code < 1000; code++) {
      if (codetotal[code] > 0) printf "|%.2f", codesum[SAVETIME, code]/acccnt[SAVETIME]*100.
    }
    print ""
  }
}

function accumulate(idx) {
  acccnt[idx]++
  timesum[idx] = timesum[idx] + resptime
  sizesum[idx] = sizesum[idx] + pagesize
  if (respmax[idx] < resptime) respmax[idx] = resptime
  if (sizemax[idx] < pagesize) sizemax[idx] = pagesize

  if (resptime <= 2) { s2_cnt[idx]++
  } else if (resptime <= 5) { s5_cnt[idx]++
  } else if (resptime <= 10) { s10_cnt[idx]++
  } else { bad_cnt[idx]++
  }

  if (statcode >= 900) { app_ok[idx]++
  } else if (statcode >= 700) { app_ok[idx]++
  } else if (statcode >= 600) { app_err[idx]++
  } else if (statcode >= 500) { srv_err[idx]++
  } else if (statcode >= 400) { app_err[idx]++
  } else { app_ok[idx]++
  }

  if (ippercnt[idx, ipaddr] == 0) ipcnt[idx]++
  ippercnt[idx, ipaddr]++

  codesum[idx, statcode]++
  codetotal[statcode]++
}

function registertime(timearr, ntime, unittime, unit) {
  n = ntime
  convdate = datestr(unittime, unit)
  convarrn = datestr(timearr[n], unit)
  if (convarrn < convdate) {		# New Time frame
    timearr[++n] = unittime
    return n
  } else if (convarrn > convdate) {	# Past Time frame then search
    for (i = ntime-1; i > 0; i--) {
      convtemp = datestr(timearr[i], unit)
      if (convtemp == convdate) {	# If found then return
        return n
      } else if (convtemp < convdate) { # New Time frame then insert
        for (j = ntime; j <= i; j--) {
          timearr[j+1] = timearr[j]
        }
        timearr[j] = unittime
        return n+1
      }
    }
    if (i <= 0) return -1	# Error
  }
  return -1	# Error
}

BEGIN {
  asplit("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", month)

  if (logpos != "") {
    x = split(logpos, arr, ",")
    ip_pos=arr[1]
    time_pos=arr[2]
    url_pos=arr[3]
    code_pos=(arr[4] > 0 ? arr[4] : NF-arr[4])
    size_pos=(arr[5] > 0 ? arr[5] : NF-arr[5])
    if (arr[7] != "X") {
      resp_pos=(arr[7] > 0 ? arr[7] : NF-arr[7])
      microsec = 1
    } else if (arr[6] != "X") {
      resp_pos=(arr[6] > 0 ? arr[6] : NF-arr[6])
      microsec = 0
    }
  } else {
    ip_pos=1
    time_pos=4
    url_pos=7
    code_pos=9
    size_pos=10
    resp_pos=11
    microsec = 0
  }

  n1M = n10M = n1H = n1D = 0
}

{
  x = split($0, logarr) 
  for (ll = 1; ll <= x; ll++) {
    if (logarr[ll] ~ /.gz$/ || logarr[ll] ~ /.Z$/) {
      cmd = zcatcmd " " logarr[ll]
    } else {
      cmd = "cat " logarr[ll]
    }
    while (cmd | getline) {
      #---- Parse access_log ------------------------------------------------------
      v = split($(ip_pos),a,":");
      ipaddr = a[v]
      if (ipaddr != "127.0.0.1" && length($time_pos) > 20) {
        statcode = $(code_pos) + 0
        pagesize = $(size_pos)/1024.
        if (resp_pos <= NF)
          resptime = (microsec == 1 ? $(resp_pos)/1000000. : $(resp_pos) + 0)
        else
          resptime = 0 

        # Print out KPI values for prev time period (same time unit interval)
        unittime_1D = substr($time_pos, 2, 12)         # 24/Apr/2007:
        unittime_1H = substr($time_pos, 2, 15)         # 24/Apr/2007:09:
        unittime_10M = substr($time_pos, 2, 16)        # 24/Apr/2007:09:0
        unittime_1M = substr($time_pos, 2, 18)         # 24/Apr/2007:09:00:
      
        if (time_1M[n1M]   != unittime_1M)  n1M  = registertime(time_1M,  n1M,  unittime_1M,  "1M")
        if (time_10M[n10M] != unittime_10M) n10M = registertime(time_10M, n10M, unittime_10M, "10M")
        if (time_1H[n1H]   != unittime_1H)  n1H  = registertime(time_1H,  n1H,  unittime_1H,  "1H")
        if (time_1D[n1D]   != unittime_1D)  n1D  = registertime(time_1D,  n1D,  unittime_1D,  "1D")
      
        accumulate(unittime_1M)
        accumulate(unittime_10M)
        accumulate(unittime_1H)
        accumulate(unittime_1D)
      }
    }
    close(cmd)
  }
}

END {

  print ""
  print "[TPMSTAT_DATA]"
  print ""
  PrintValue("1M")

  print ""
  print "[TP10MSTAT_DATA]"
  print ""
  PrintValue("10M")

  print ""
  print "[TPHSTAT_DATA]"
  print ""
  PrintValue("1H")

  print ""
  print "[TPDSTAT_DATA]"
  print ""
  PrintValue("1D")
  print ""
}'

}

# Access_log format
#   "%h %l %u %t \"%r\" %>s %b %T \"%{Referer}i\" \"%{User-Agent}i\"" \

fn_logformat()
{
  formatstr=$1

  resps="X"
  respus="X"
  ref="X"
  pos=0
  for f in $formatstr; do
    pos=`expr $pos + 1`
    case "$f" in 
      "%h")
        ip=$pos
        ;;
      "%t")
        time=$pos
        pos=`expr $pos + 1`
        ;;
      "\"%r\"")
        pos=`expr $pos + 1`
        url=$pos
        pos=`expr $pos + 1`
        ;;
      "%s")              # Status code
        code=$pos
        ;;
      "%>s")             # Status code
        code=$pos
        ;;
      "%b")              # Bytes
        size=$pos
        ;;
      "%T")              # Second
        resps=$pos
        ;;
      "%D")              # Micro second
        respus=$pos
        ;;
      "\"%{Referer}i\"")
        ref=$pos
        ;;
      "\"%{User-Agent}i\"")
        agent=$pos
        ;;
      *)
        ;;
    esac
  done

  if [[ $agent -gt 0 ]] ; then
    if [ "$resps" != "X" -a $resps -gt $agent ] ; then
      resps=`expr $pos - $resps`
    fi
    if [ "$respus" != "X" -a $respus -gt $agent ] ; then
      respus=`expr $pos - $respus`
    fi
    if [ "$ref" != "X" -a $ref -gt $agent ] ; then
      ref=`expr $pos - $ref`
    fi
    if [[ $size -gt $agent ]] ; then
      size=`expr $pos - $size`
    fi
    if [[ $code -gt $agent ]] ; then
      code=`expr $pos - $code`
    fi
  fi

  logposition="$ip,$time,$url,$code,$size,$resps,$respus,$ref"
}

#-------------------------------------------------------------------------------
#- Main routine
#-------------------------------------------------------------------------------

fn_initialize

for (( i = 0; i < ${#arr_instname[@]}; i++ )) ; do
  inst="${arr_instname[$i]}"
  instno="${arr_instno[$i]}"
  if [[ "${arr_access_bak[$i]}" = "-" ]] ; then
    loglist="${arr_access_cur[$i]}"
  else
    loglist="${arr_access_bak[$i]} ${arr_access_cur[$i]}"
  fi
  fn_logformat "${arr_logformat[$i]}"
  
  access_logs=`ls -tr $loglist | tail -8`
  
  output_file="Http_Perf_Extract_${HOSTNAME}_${inst}.out"
  reports=3

  echo Begin time : `date "+%F %T"` | tee $output_file

  echo ""  | tee -a $output_file
  echo "Gathering.....[Basic data                            ]  1 / $reports" | tee -a $output_file
  echo "[BASIC_DATA]" >> $output_file
  echo ""  >> $output_file
  echo "<|hostname|instname|inst#|LogFormat|access_log" >> $output_file
  for log in $access_logs ; do
    echo ">|$HOSTNAME|$inst|$instno|${arr_logformat[$i]}|$log" >> $output_file
  done

  echo ""  >> $output_file
  echo "Gathering.....[Transaction analysis                  ]  2 / $reports" | tee -a $output_file
  fn_chk_transaction 1M $inst $instno $logposition >> $output_file


  echo ""  >> $output_file
  echo "Gathering.....[Error page analysis                   ]  3 / $reports" | tee -a $output_file
  fn_chk_errpage $inst $instno $logposition | sort >> $output_file

  echo "[End of documents]" >> $output_file
  echo ""  | tee -a $output_file

  echo Complete time : `date "+%F %T"` | tee -a $output_file
done
