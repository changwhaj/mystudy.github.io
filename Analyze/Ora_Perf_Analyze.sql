--
-- Diagnose Oracle Database
--
-- $Header: Ora_Perf_Analyze.sql v1.4 cwjeong noship $
--
-- Description : Gather Oracle statsus data from AWR Repository
--
-- Change History
-- 2017/06/14 Initial
-- 2017/06/23 Changed for cluster instance
-- 2017/06/26 Changed for include today
-- 2017/07/05 Changed for bug fix on cloned instance
-- 2017/07/14 Changed for Wait class (time_waited_micro -> time_waited_micro_fg) 

--------------------------------------------------------------------------------
-- Set SQL*Plus env
--------------------------------------------------------------------------------
SET HEAD OFF
SET PAGESIZE 50000
SET ECHO OFF
SET VERIFY OFF
SET FEEDBACK OFF
SET TAB OFF
SET PAUSE OFF
SET TIME OFF
SET TIMING OFF
SET TERMOUT OFF
SET TRIMSPOOL ON
SET TRIM ON
SET LONG 30000
SET COLSEP '|'
SET LINESIZE 30000
COL LINES FORMAT A30000
SET ARRAYSIZE 1000


COL DBNAME NEW_VALUE DBNAME NOPRINT;
COL DBID   NEW_VALUE DBID   NOPRINT;

select name dbname, dbid from v$database;

COL DBNAME NEW_VALUE DBNAME PRINT;
COL DBID   NEW_VALUE DBID   PRINT;

COL INSTANCE NEW_VALUE INSTANCE NOPRINT;
COL TIMESTR  NEW_VALUE TIMESTR  NOPRINT;
COL DTFROM   NEW_VALUE DTFROM   NOPRINT;
COL DTEND    NEW_VALUE DTEND    NOPRINT;
COL ORAVER   NEW_VALUE ORAVER   NOPRINT;

select instance_name instance
     , to_char(sysdate,    'YYYYMMDD-HH24MI') timestr
     , to_char(sysdate-14, 'YYYYMMDD')        dtfrom
     , to_char(sysdate,    'YYYYMMDD')        dtend
     , to_number(replace(version,'.',''))     oraver
  from v$instance;

COL INSTANCE NEW_VALUE INSTANCE PRINT;
COL TIMESTR  NEW_VALUE TIMESTR  PRINT;
COL DTFROM   NEW_VALUE DTFROM   PRINT;
COL DTEND    NEW_VALUE DTEND    PRINT;
COL ORAVER   NEW_VALUE ORAVER   PRINT;

-- Number of Rows of SQL to display in each SQL section of the report
define top_n_sql = 5;
define num_inst = 2;
--------------------------------------------------------------------------------
-- Set Analyze period
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt 1. Input time using this format [YYYYMMDD]
accept dt_from prompt "   Begin date : [&dtfrom] "
accept dt_end  prompt "   End   date : [&dtend] "

SET TERMOUT OFF
COL DT_FROM NEW_VALUE DT_FROM NOPRINT;
COL DT_END  NEW_VALUE DT_END  NOPRINT;

select (case when '&dt_from' is null then '&dtfrom' else '&dt_from' end) dt_from
     , (case when '&dt_end'  is null then '&dtend'  else '&dt_end'  end) dt_end
  from dual;

-- select '&dtfrom' dt_from, '&dtend' dt_end from dual;

COL DT_FROM NEW_VALUE DT_FROM PRINT;
COL DT_END  NEW_VALUE DT_END  PRINT;

SET TERMOUT ON
prompt --> Begin date is [&dt_from], end date is [&dt_end]
prompt
SET TERMOUT OFF

COL SNAP_F  NEW_VALUE SNAP_F  NOPRINT;
COL SNAP_E  NEW_VALUE SNAP_E  NOPRINT;
COL REPORTS NEW_VALUE REPORTS NOPRINT;
COL IS_RAC  NEW_VALUE IS_RAC  NOPRINT;

select ( select min(snap_id) snap_f
           from dba_hist_snapshot
          where to_char(begin_interval_time, 'YYYYMMDD-HH24') >= '&dt_from' || '-00'
            and dbid = (select dbid from v$database) ) snap_f
     , ( select max(snap_id) snap_e
           from dba_hist_snapshot
          where to_char(begin_interval_time, 'YYYYMMDD-HH24') <= '&dt_end' || '-00'
            and dbid = (select dbid from v$database) ) snap_e
     , '15' reports
     , (select case when count(*) > 1 then 'YES' else 'NO' end from gv$instance) is_rac
  from dual;

COL TIME_F NEW_VALUE TIME_F NOPRINT;
COL TIME_E NEW_VALUE TIME_E NOPRINT;

select '''' || to_char(min(begin_interval_time),'YYYYMMDD-HH24') ||'''' time_f
     , '''' || to_char(max(begin_interval_time),'YYYYMMDD-HH24') ||'''' time_e
  from dba_hist_snapshot
 where snap_id between &snap_f and &snap_e
   and dbid = (select dbid from v$database) ;

COL SPOOL_NAME NEW_VALUE SPOOL_NAME NOPRINT;

--select 'Ora_Perf_Extract_'||'&dbname'||'_'||'&timestr'||'.out' spool_name from dual;
select 'Ora_Perf_Extract_'||'&dbname'||'.out' spool_name from dual;

COL SPOOL_NAME NEW_VALUE SPOOL_NAME PRINT;


--------------------------------------------------------------------------------
-- Spool ON
--------------------------------------------------------------------------------
spool &spool_name

select 'Begin time : '||to_char(sysdate, 'YYYY/MM/DD HH24:MI:SS') from dual;

--------------------------------------------------------------------------------
-- Basic Info
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt
prompt Gathering.....[Basic data                            ]  1 / &reports
SET TERMOUT OFF

prompt [BASIC_DATA]
-- dba_hist_database_instance

select '<|'|| 'dbname|dbid|instno|instname|hostname|platform|startup|version|' ||
       'snap_from|snap_end|time_from|time_end|hours|snap_interval|retention' as lines
  from dual
;

select '>|'|| di.db_name ||'|'|| di.dbid ||'|'|| di.instance_number ||'|'||
       di.instance_name ||'|'|| di.host_name ||'|'|| d.platform_name ||'|'||
       to_char(startup_time,'YYYY/MM/DD HH24:MI:SS') ||'|'|| version ||'|'||
       &snap_f ||'|'|| &snap_e ||'|'|| &time_f ||'|'|| &time_e ||'|'||
       ((to_date(&time_e,'YYYYMMDD-HH24')-to_date(&time_f,'YYYYMMDD-HH24'))*24+1) ||'|'''||
       snap_interval ||'|'''|| retention as lines
  from dba_hist_database_instance di, v$database d
     , dba_hist_wr_control        wr
 where di.dbid = &dbid -- and instance_number <= &&num_inst
   and di.dbid = wr.dbid
   and (instance_number, startup_time) in ( select instance_number
                                                 , max(startup_time) startime
                                              from dba_hist_database_instance
                                             where dbid = &dbid
                                             group by instance_number )
 order by di.dbid, di.instance_number
;


--------------------------------------------------------------------------------
-- Sysmetric summary
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt Gathering.....[Sysmetric summary                     ]  2 / &reports
SET TERMOUT OFF

prompt [SYSMETRIC_DATA]
-- dba_hist_sysmetric_summary

select '<|'|| 'inst|time|' ||
       'User_Calls/s|Executions/s|User_Trx/s|Redo_Gen/s|Logical_Reads/s|Phy_Read/s|Phy_Read_Dirt/s|' ||
       'DB_Block_Chgs/s|Phy_Write/s|Phy_Write_Dirt/s|Disk_Sorts/s|Hard_Parses/s|Enq_Waits/s|' ||
       'Session_Count|Avg_Act_Sessions|Host_CPU%|DB_CPU_Time%|Buff_Cache_Hit%|Lib_Cache_Hit%|' ||
       'Row_Cache_Hit%|Redo_Alloc_Hit%|Logons/s|Soft_Parse%|CPU_Usages/s|GC_CR_Blk_Rcvd/s|GC_Cur_Blk_Rcvd/s|' ||
       'DB_Wait_Time%|PGA_Cache_Hit%|Process_Limit%|DB_Times/s|Phy_Write_Total_Bytes/s|' ||
       'Phy_Write_Bytes/s|Curr_OS_Load|Act_Serial_Sessions|Act_Parallel_Sessions' as lines
  from dual
;

with tm as (
    select instno, time
      from ( select to_char(to_date(&time_f,'YYYYMMDD-HH24')+(level-1)/24, 'YYYYMMDD-HH24') time from dual
            connect by level <= (to_date(&time_e,'YYYYMMDD-HH24')-to_date(&time_f,'YYYYMMDD-HH24'))*24+1)
         , ( select instance_number instno from gv$instance ) -- where instance_number <= &&num_inst)
     order by 1, 2 )
select '>|'|| tm.instno ||'|'|| tm.time ||'|'||
       v2026 ||'|'|| v2121 ||'|'|| v2003 ||'|'|| v2016 ||'|'|| v2030 ||'|'|| v2004 ||'|'|| v2008 ||'|'|| v2071 ||'|'||
       v2006 ||'|'|| v2010 ||'|'|| v2051 ||'|'|| v2046 ||'|'|| v2061 ||'|'|| v2143 ||'|'|| v2147 ||'|'|| v2057 ||'|'||
       v2108 ||'|'|| v2000 ||'|'|| v2112 ||'|'|| v2110 ||'|'|| v2002 ||'|'|| v2018 ||'|'|| v2055 ||'|'|| v2075 ||'|'||
       v2094 ||'|'|| v2096 ||'|'|| v2107 ||'|'|| v2115 ||'|'|| v2118 ||'|'|| v2123 ||'|'|| v2124 ||'|'|| v2128 ||'|'||
       v2135 ||'|'|| v2148 ||'|'|| v2149 as lines
from (
select sn.instance_number instno
     , to_char(begin_interval_time, 'YYYYMMDD-HH24') time
     , nvl(round(avg(v2026),2),0) v2026
     , nvl(round(avg(v2121),2),0) v2121
     , nvl(round(avg(v2003),2),0) v2003
     , nvl(round(avg(v2016),2),0) v2016
     , nvl(round(avg(v2030),2),0) v2030
     , nvl(round(avg(v2004),2),0) v2004
     , nvl(round(avg(v2008),2),0) v2008
     , nvl(round(avg(v2071),2),0) v2071
     , nvl(round(avg(v2006),2),0) v2006
     , nvl(round(avg(v2010),2),0) v2010
     , nvl(round(avg(v2051),2),0) v2051
     , nvl(round(avg(v2046),2),0) v2046
     , nvl(round(avg(v2061),2),0) v2061
     , nvl(round(avg(v2143),2),0) v2143
     , nvl(round(avg(v2147),2),0) v2147
     , nvl(round(avg(v2057),2),0) v2057
     , nvl(round(avg(v2108),2),0) v2108
     , nvl(round(avg(v2000),2),0) v2000
     , nvl(round(avg(v2112),2),0) v2112
     , nvl(round(avg(v2110),2),0) v2110
     , nvl(round(avg(v2002),2),0) v2002
     , nvl(round(avg(v2018),2),0) v2018
     , nvl(round(avg(v2055),2),0) v2055
     , nvl(round(avg(v2075),2),0) v2075
     , nvl(round(avg(v2094),2),0) v2094
     , nvl(round(avg(v2096),2),0) v2096
     , nvl(round(avg(v2107),2),0) v2107
     , nvl(round(avg(v2115),2),0) v2115
     , nvl(round(avg(v2118),2),0) v2118
     , nvl(round(avg(v2123),2),0) v2123
     , nvl(round(avg(v2124),2),0) v2124
     , nvl(round(avg(v2128),2),0) v2128
     , nvl(round(avg(v2135),2),0) v2135
     , nvl(round(avg(v2148),2),0) v2148
     , nvl(round(avg(v2149),2),0) v2149
  from (
         select
                instance_number instno
              , snap_id
              , max(case metric_id when 2026 then average    end) v2026 -- User Calls Per Sec (Calls per sec)
              , max(case metric_id when 2121 then average    end) v2121 -- Executions Per Sec (Execute per Sec)
              , max(case metric_id when 2003 then average    end) v2003 -- User Transaction Per Sec (Transaction per sec)
              , max(case metric_id when 2016 then average    end) v2016 -- Redo Generated Per Sec (Bytes per sec)
              , max(case metric_id when 2030 then average    end) v2030 -- Logical Reads Per Sec (Reads per sec)
              , max(case metric_id when 2004 then average    end) v2004 -- Physical Reads Per Sec (Reads per sec)
              , max(case metric_id when 2008 then average    end) v2008 -- Physical Reads Direct Per Sec (Reads per sec)
              , max(case metric_id when 2071 then average    end) v2071 -- DB Block Changes Per Sec (Blocks per sec)
              , max(case metric_id when 2006 then average    end) v2006 -- Physical Writes Per Sec (Writes per sec)
              , max(case metric_id when 2010 then average    end) v2010 -- Physical Writes Direct Per Sec (Writes per sec)
              , max(case metric_id when 2051 then average    end) v2051 -- Disk Sort Per Sec (Sorts per sec)
              , max(case metric_id when 2046 then average    end) v2046 -- Hard Parse Count Per Sec (Parse per sec)
              , max(case metric_id when 2061 then average    end) v2061 -- Enqueue Waits Per Sec (Waits per sec)
              , max(case metric_id when 2143 then average    end) v2143 -- Session Count (Sessions)
              , max(case metric_id when 2147 then average    end) v2147 -- Average Active Sessions (Active Sessions)
              , max(case metric_id when 2057 then average    end) v2057 -- Host CPU Utilization (%)
              , max(case metric_id when 2108 then average    end) v2108 -- Database CPU Time Ratio (%)
              , max(case metric_id when 2000 then average    end) v2000 -- Buffer Cache Hit Ratio (%)
              , max(case metric_id when 2112 then average    end) v2112 -- Library Cache Hit Ratio (%)
              , max(case metric_id when 2110 then average    end) v2110 -- Row Cache Hit Ratio (%)
              , max(case metric_id when 2002 then average    end) v2002 -- Redo Allocation Hit Ratio (%)
              , max(case metric_id when 2018 then average    end) v2018 -- Logons Per Sec (Logons per seconds)
              , max(case metric_id when 2055 then average    end) v2055 -- Soft Parse Ratio (%)
              , max(case metric_id when 2075 then average/10 end) v2075 -- CPU Usage Per Sec (CentiSeconds2ms)*
              , max(case metric_id when 2094 then average    end) v2094 -- GC CR Block Received Per Second (Blocks per sec)
              , max(case metric_id when 2096 then average    end) v2096 -- GC Current Block Received Per Second (Blocks per sec)
              , max(case metric_id when 2107 then average    end) v2107 -- Database Wait Time Ratio (%)
              , max(case metric_id when 2115 then average    end) v2115 -- PGA Cache Hit % (%)
              , max(case metric_id when 2118 then average    end) v2118 -- Process Limit % (%)
              , max(case metric_id when 2123 then average/10 end) v2123 -- Database Time Per Sec (CentiSeconds2ms)*
              , max(case metric_id when 2124 then average    end) v2124 -- Physical Write Total Bytes Per Sec (Bytes per sec)
              , max(case metric_id when 2128 then average    end) v2128 -- Physical Write Bytes Per Sec (Bytes per sec)
              , max(case metric_id when 2135 then average    end) v2135 -- Current OS Load (Number of processes)
              , max(case metric_id when 2148 then average    end) v2148 -- Active Serial Sessions (Sessions)
              , max(case metric_id when 2149 then average    end) v2149 -- Active Parallel Sessions (Sessions)
           from dba_hist_sysmetric_summary
          where snap_id between &snap_f and &snap_e
            and metric_id in (2000,2002,2003,2004,2006,2008,2010,2016,2018,2026,2030,2046,2051,2055,2057,2061,2071,
                              2075,2094,2096,2107,2108,2110,2112,2115,2118,2121,2123,2124,2128,2135,2143,2147,2148,2149)
            and dbid = &dbid
            and group_id = 2
          group by instance_number
                 , snap_id
       )                 sm
     , dba_hist_snapshot sn
 where sm.instno  = sn.instance_number
   and sm.snap_id = sn.snap_id
   and sn.dbid    = &dbid
 group by sn.instance_number
        , to_char(begin_interval_time, 'YYYYMMDD-HH24')
order  by 1,2
) a, tm
 where tm.instno = a.instno(+)
   and tm.time  = a.time(+)
order  by tm.instno, tm.time
;


--------------------------------------------------------------------------------
-- Parameter history
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt Gathering.....[Parameter history                     ]  3 / &reports
SET TERMOUT OFF

prompt [PRAMETER_HISTORY]
-- dba_hist_parameter

select '<|'|| 'inst|time|' ||
       'change_cnt|resource_limit|db_recycle_cache_size|disk_asynch_io|filesystemio_options|__db_cache_size|' ||
       'result_cache_mode|parallel_threads_per_cpu|cpu_count|memory_target|log_buffer|shared_pool_size|' ||
       'db_file_multiblock_read_count|dml_locks|db_keep_cache_size|db_cache_size|pga_aggregate_target|' ||
       'compatible|ddl_lock_timeout|db_writer_processes|optimizer_features_enable|shared_pool_reserved_size|' ||
       'sga_target|sessions|__shared_pool_size|memory_max_target|undo_retention|dbwr_io_slaves|db_block_size|' ||
       'parallel_max_servers|sga_max_size|parallel_servers_target|open_links|open_cursors|processes|' ||
       'result_cache_max_result|result_cache_max_size' as lines
  from dual
;

with tm as (
    select instno, time
      from ( select to_char(to_date(&time_f,'YYYYMMDD-HH24')+(level-1)/24, 'YYYYMMDD-HH24') time from dual
            connect by level <= (to_date(&time_e,'YYYYMMDD-HH24')-to_date(&time_f,'YYYYMMDD-HH24'))*24+1)
         , ( select instance_number instno from gv$instance ) -- where instance_number <= &&num_inst)
     order by 1, 2 )
select '>|'|| tm.instno ||'|'|| tm.time ||'|'|| change_cnt ||'|'||
       a01 ||'|'|| a02 ||'|'|| a03 ||'|'|| a04 ||'|'|| a05 ||'|'|| a06 ||'|'|| a07 ||'|'|| a08 ||'|'|| a09 ||'|'|| a10 ||'|'||
       a11 ||'|'|| a12 ||'|'|| a13 ||'|'|| a14 ||'|'|| a15 ||'|'|| a16 ||'|'|| a17 ||'|'|| a18 ||'|'|| a19 ||'|'|| a20 ||'|'||
       a21 ||'|'|| a22 ||'|'|| a23 ||'|'|| a24 ||'|'|| a25 ||'|'|| a26 ||'|'|| a27 ||'|'|| a28 ||'|'|| a29 ||'|'|| a30 ||'|'||
       a31 ||'|'|| a32 ||'|'|| a33 ||'|'|| a34 ||'|'|| a35 ||'|'|| a36 as lines
  from (
select sn.instance_number instno
     , to_char(begin_interval_time, 'YYYYMMDD-HH24') time
     , nvl(      max(case when parameter_hash =   19363908 then value end)              , 0) as a01
     , nvl(round(max(case when parameter_hash =  409865660 then value end)/1024/1024, 1), 0) as a02
     , nvl(      max(case when parameter_hash =  629465343 then value end)              , 0) as a03
     , nvl(      max(case when parameter_hash =  752770605 then value end)              , 0) as a04
     , nvl(round(max(case when parameter_hash =  850433132 then value end)/1024/1024, 1), 0) as a05
     , nvl(      max(case when parameter_hash =  866827446 then value end)              , 0) as a06
     , nvl(      max(case when parameter_hash = 1020981983 then value end)              , 0) as a07
     , nvl(      max(case when parameter_hash = 1095434542 then value end)              , 0) as a08
     , nvl(round(max(case when parameter_hash = 1127054141 then value end)/1024/1024, 1), 0) as a09
     , nvl(round(max(case when parameter_hash = 1173026923 then value end)/1024/1024, 1), 0) as a10
     , nvl(round(max(case when parameter_hash = 1378805370 then value end)/1024/1024, 1), 0) as a11
     , nvl(      max(case when parameter_hash = 1428169303 then value end)              , 0) as a12
     , nvl(      max(case when parameter_hash = 1576699050 then value end)              , 0) as a13
     , nvl(round(max(case when parameter_hash = 1851163622 then value end)/1024/1024, 1), 0) as a14
     , nvl(round(max(case when parameter_hash = 1878231416 then value end)/1024/1024, 1), 0) as a15
     , nvl(round(max(case when parameter_hash = 2184567208 then value end)/1024/1024, 1), 0) as a16
     , nvl(      max(case when parameter_hash = 2586206788 then value end)              , 0) as a17
     , nvl(      max(case when parameter_hash = 2606707053 then value end)              , 0) as a18
     , nvl(      max(case when parameter_hash = 2675391963 then value end)              , 0) as a19
     , nvl(      max(case when parameter_hash = 2759770534 then value end)              , 0) as a20
     , nvl(round(max(case when parameter_hash = 3099794371 then value end)/1024/1024, 1), 0) as a21
     , nvl(round(max(case when parameter_hash = 3134551790 then value end)/1024/1024, 1), 0) as a22
     , nvl(      max(case when parameter_hash = 3194028855 then value end)              , 0) as a23
     , nvl(round(max(case when parameter_hash = 3212001714 then value end)/1024/1024, 1), 0) as a24
     , nvl(round(max(case when parameter_hash = 3306918234 then value end)/1024/1024, 1), 0) as a25
     , nvl(      max(case when parameter_hash = 3327480172 then value end)              , 0) as a26
     , nvl(      max(case when parameter_hash = 3394903742 then value end)              , 0) as a27
     , nvl(      max(case when parameter_hash = 3433134853 then value end)              , 0) as a28
     , nvl(      max(case when parameter_hash = 3629921023 then value end)              , 0) as a29
     , nvl(round(max(case when parameter_hash = 3640569645 then value end)/1024/1024, 1), 0) as a30
     , nvl(      max(case when parameter_hash = 3701086916 then value end)              , 0) as a31
     , nvl(      max(case when parameter_hash = 3842870833 then value end)              , 0) as a32
     , nvl(      max(case when parameter_hash = 4033294835 then value end)              , 0) as a33
     , nvl(      max(case when parameter_hash = 4162014761 then value end)              , 0) as a34
     , nvl(      max(case when parameter_hash = 4174962580 then value end)              , 0) as a35
     , nvl(      max(case when parameter_hash = 4221019766 then value end)              , 0) as a36
  from dba_hist_parameter pr
     , dba_hist_snapshot  sn
 where pr.instance_number = sn.instance_number
   and pr.snap_id         = sn.snap_id
   and pr.dbid            = sn.dbid
   and pr.dbid            = &dbid
   and pr.parameter_hash in (   19363908  -- resource_limit
                            ,  409865660  -- db_recycle_cache_size
                            ,  629465343  -- disk_asynch_io
                            ,  752770605  -- filesystemio_options
                            ,  850433132  -- __db_cache_size
                            ,  866827446  -- result_cache_mode
                            , 1020981983  -- parallel_threads_per_cpu
                            , 1095434542  -- cpu_count
                            , 1127054141  -- memory_target
                            , 1173026923  -- log_buffer
                            , 1378805370  -- shared_pool_size
                            , 1428169303  -- db_file_multiblock_read_count
                            , 1576699050  -- dml_locks
                            , 1851163622  -- db_keep_cache_size
                            , 1878231416  -- db_cache_size
                            , 2184567208  -- pga_aggregate_target
                            , 2586206788  -- compatible
                            , 2606707053  -- ddl_lock_timeout
                            , 2675391963  -- db_writer_processes
                            , 2759770534  -- optimizer_features_enable
                            , 3099794371  -- shared_pool_reserved_size
                            , 3134551790  -- sga_target
                            , 3194028855  -- sessions
                            , 3212001714  -- __shared_pool_size
                            , 3306918234  -- memory_max_target
                            , 3327480172  -- undo_retention
                            , 3394903742  -- dbwr_io_slaves
                            , 3433134853  -- db_block_size
                            , 3629921023  -- parallel_max_servers
                            , 3640569645  -- sga_max_size
                            , 3701086916  -- parallel_servers_target
                            , 3842870833  -- open_links
                            , 4033294835  -- open_cursors
                            , 4162014761  -- processes
                            , 4174962580  -- result_cache_max_result
                            , 4221019766) -- result_cache_max_size
   and pr.snap_id           between &snap_f and &snap_e
 group by sn.instance_number
        , to_char(begin_interval_time, 'YYYYMMDD-HH24')
) v1
, (
select /*+ ordered */ sn.instance_number instno
     , to_char(sn.begin_interval_time, 'YYYYMMDD-HH24') time
     , sum(change_cnt) change_cnt
  from (
         select instance_number instno
              , snap_id
              , parameter_name
              , case when parameter_name =  lag(parameter_name) over (order by instance_number, parameter_name, snap_id)
                      and value          <> lag(value         ) over (order by instance_number, parameter_name, snap_id)
                then 1 else 0 end  change_cnt
           from dba_hist_parameter
          where snap_id between &snap_f and &snap_e
       ) pr, dba_hist_snapshot  sn
 where pr.instno  = sn.instance_number
   and pr.snap_id = sn.snap_id
 group by sn.instance_number, to_char(sn.begin_interval_time, 'YYYYMMDD-HH24')
) v2, tm
 where tm.instno = v1.instno(+)
   and tm.time   = v1.time(+)
   and tm.instno = v2.instno(+)
   and tm.time   = v2.time(+)
order  by tm.instno, tm.time
;


--------------------------------------------------------------------------------
-- Parameter change history
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt Gathering.....[Parameter change history              ]  3'/ &reports
SET TERMOUT OFF

prompt [PARAMETER_CHANGE]
-- dba_hist_parameter

select '<|'|| 'inst|time|' ||
       'parameter_name|from -> to' as lines
  from dual
;
select '>'||instno ||'|'|| time ||'|'|| parameter_name ||'|'|| value as lines
  from (
        select sp.instance_number instno
             , to_char(sn.begin_interval_time, 'YYYYMMDD-HH24') time
             , parameter_name
             , case when sp.parameter_name =  lag(sp.parameter_name) over (order by sp.instance_number, sp.parameter_name, sp.snap_id)
                     and sp.value          <> lag(sp.value         ) over (order by sp.instance_number, sp.parameter_name, sp.snap_id)
                    then                      lag(sp.value         ) over (order by sp.instance_number, sp.parameter_name, sp.snap_id) || '->' || sp.value
                    end  value
          from dba_hist_parameter sp
             , dba_hist_snapshot  sn
         where sp.instance_number = sn.instance_number
           and sp.snap_id         = sn.snap_id
           and sn.snap_id   between &snap_f and &snap_e
           and sp.dbid            = sn.dbid
           and sp.dbid            = &dbid
        order  by sp.instance_number
                , sp.parameter_name
                , sp.snap_id
       ) a
 where a.value is not null
;



--------------------------------------------------------------------------------
-- Configuration check
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt Gathering.....[Configuration check                   ]  4 / &reports
SET TERMOUT OFF

prompt [CONF_CHECK_DATA]

select '<|'|| 'CheckID|Result|CheckRule|CheckBase' as lines
  from dual
;

select '>|Config-001|' ||
       case when cnt > 0 then 'NO' else 'OK' end  ||'|Cnt of Dictionary tablespace='|| cnt ||
       '|Cnt = 0' as lines
  from ( select count(*) cnt from dba_tablespaces where extent_management = 'DICTIONARY' )
---------
union all
---------
select '>|Config-002|' ||
       case when cnt > 0 then 'NO' else 'OK' end ||'|Cnt of Undo/Temp Tablespace with non-zero increase value='||cnt||
       '|Cnt = 0' as lines
  from ( select count(*) cnt
           from dba_tablespaces
          where extent_management = 'DICTIONARY' and pct_increase <> '0'
            and (contents in ('TEMPORARY','UNDO') or tablespace_name like '%RBS%'))
---------
union all
---------
select '>|Config-003|' ||
       case when cnt > 0 then 'NO' else 'OK' end ||'|Cnt of Temp Tablespace with permanent tablespace='|| cnt ||
       '|Cnt = 0' as lines
  from ( select count(*) cnt
           from dba_tablespaces
          where tablespace_name in (select distinct temporary_tablespace from dba_users where username != 'SYS')
            and contents <> 'TEMPORARY')
---------
union all
---------
select '>|Config-004|' ||
       case when upper(value) = 'TRUE' and mem=0 and sga=0 and &oraver > 112010 then 'NO' else 'OK' end ||
       '|Parameter value [_memory_imm_mode_without_autosga] ='|| value ||
         ', [memory_target]='||mem ||', [sga_target]='|| sga || ', version='||&oraver||
       '|[11.2.0.1] _memory_imm_mode_without_autosga=false when memory_target/sga_target=0'
       as lines
  from ( SELECT max(ksppstvl) value FROM x$ksppi a, x$ksppsv b WHERE a.indx=b.indx and ksppinm = '_memory_imm_mode_without_autosga')
     , ( select to_number(value) mem from v$parameter where name = 'memory_target')
     , ( select to_number(value) sga from v$parameter where name = 'sga_target')
---------
union all
---------
select '>|Config-005|' ||
       case when upper(value) = 'TRUE' and &oraver > 112010 then 'NO' else 'OK' end ||
       '|Parameter value [_use_adaptive_log_file_sync]='|| value || ', version='||&oraver||
       '|[11.2.0.1~] _use_adaptive_log_file_sync=false' as lines
  from ( SELECT max(ksppstvl) value FROM x$ksppi a, x$ksppsv b  where a.indx=b.indx and ksppinm = '_use_adaptive_log_file_sync')
---------
union all
---------
select '>|Config-006|' ||
       case when upper(value) <> 'FALSE' and &oraver = 111060 then 'CK' else 'OK' end ||
       '|Parameter value [_library_cache_advice]='|| value || ', version='||&oraver||
       '|[11.1.0.6] _library_cache_advice=false or Bug fix (7253837, 6879763)' as lines
  from ( SELECT max(ksppstvl) value FROM x$ksppi a, x$ksppsv b WHERE a.indx=b.indx and ksppinm = '_library_cache_advice')
---------
union all
---------
select '>|Config-006|' ||
       case when upper(value) <> '0' and &oraver <= 102000 then 'NO' else 'OK' end ||
       '|Parameter value [_gc_integrity_checks]='|| value || ', version='||&oraver||
       '|[~10.2.0.0] _gc_integrity_checks=0' as lines
  from ( SELECT max(ksppstvl) value FROM x$ksppi a, x$ksppsv b WHERE a.indx=b.indx and ksppinm = '_gc_integrity_checks')
---------
union all
---------
select '>|Bug-001|' ||
       case when cnt > 0 and &oraver <= 112036 then 'NO' else 'OK' end ||
       '|Cnt of parameter [log_archive_target]='|| cnt || ', version='||&oraver||
       '|[~11.2.0.3.6] Do not set log_archive_target parameter' as lines
  from ( select count(*) cnt from v$parameter where name = 'log_archive_target')
---------
union all
---------
select '>|Bug-002|' ||
       case when upper(value) <> 'FALSE' and &oraver <= 112020 then 'CK' else 'OK' end ||
       '|Cnt of parameter [db_cache_advice]='|| value || ', version='||&oraver||
       '|[~11.2.0.2.0] db_cache_advice=false or Patch (9903826)' as lines
  from ( select max(value) value, max(name) name from v$parameter where name = 'db_cache_advice')
---------
union all
---------
select '>|Perf-001|' ||
       case when aud <> 10000 or idg <> 1000 then 'NO' else 'OK' end ||
       '|Cache size of Sequence [AUDSES$]='||aud||', [IDGEN1$] = '||idg||
       '|Cache size of [AUDSES$]=10000, [IDGEN1$]=1000'
       as lines
  from ( select cache_size aud from dba_sequences where SEQUENCE_NAME = 'AUDSES$' )
     , ( select cache_size idg from dba_sequences where SEQUENCE_NAME = 'IDGEN1$' )
---------
union all
---------
select '>|Perf-002|' ||
       case when val1 > 10 or val2 > 10 or val3 > 10 then 'NO' else 'OK' end ||
       '|Average log switch period (Min) THREAD#1='||val1||', THREAD#2='||val2||', THREAD#3='||val3||
       '|Each log switch period < 10 mins'
       as lines
  from ( select max(case when thr = 1 then cnt else 0 end) val1
              , max(case when thr = 2 then cnt else 0 end) val2
              , max(case when thr = 3 then cnt else 0 end) val3
         from ( select thread# thr,(8*24*60)/count(*) cnt
                  from v$log_history
                 where first_time > sysdate-8
                 group by Thread# ))
---------
union all
---------
select '>|Perf-003|' ||
       case when sga/mem < 0.2 or sga/mem > 0.5 then 'NO' else 'OK' end ||
       '|Mem(mb)='||mem||', SGA(mb)='||sga||', SGA/MEM='||round(sga/mem*100,2)||
       '%|SGA/MEM between 20% and 50%'
       as lines
  from ( select round(value/1024/1024,2) mem from v$osstat where stat_name='PHYSICAL_MEMORY_BYTES' ) a
     , ( select round(sum(value)/1024/1024,2) sga from v$sga) b
---------
union all
---------
select '>|Perf-004|' ||
       case when (pga/mem < 0.1 or pga/mem > 0.4) and pga>0 then 'NO' else 'OK' end ||
       '|Mem(mb)='||mem||', PGA(mb)='||pga||', PGA/MEM='||round(pga/mem*100,2)||
       '%|PGA/MEM between 10% and 40%'
       as lines
  from ( select round(value/1024/1024,2) mem from v$osstat where stat_name='PHYSICAL_MEMORY_BYTES' )
     , ( select round(sum(value)/1024/1024,2) pga from v$parameter where name = 'pga_aggregate_target')
---------
union all
---------
select '>|Perf-005|' ||
       case when (poltm <> 0 or upper(unaff) <> 'FALSE') and &oraver between 110000 and 112999 and '&is_rac' = 'YES' then 'NO' else 'OK' end ||
       '|Parameter [_gc_policy_time]='|| poltm || ', [_gc_undo_affinity]='|| unaff ||', version='||&oraver|| ', RAC='||'&is_rac'||
       '|[11g / RAC] _gc_policy_time=0, _gc_undo_affinity=false' as lines
  from ( SELECT max(ksppstvl) poltm FROM x$ksppi a, x$ksppsv b WHERE a.indx=b.indx and ksppinm = '_gc_policy_time')
     , ( SELECT max(ksppstvl) unaff FROM x$ksppi a, x$ksppsv b WHERE a.indx=b.indx and ksppinm = '_gc_undo_affinity')
---------
union all
---------
select '>|Perf-006|' ||
       case when upper(value) <> 'TRUE' and &oraver between 110000 and 112999 and '&is_rac' = 'YES' then 'NO' else 'OK' end ||
       '|Parameter [parallel_force_local]='|| value || ', version='||&oraver|| ', RAC='||'&is_rac'||
       '|[11g / RAC] parallel_force_local=true' as lines
  from ( select max(value) value, max(name) name from v$parameter where name = 'parallel_force_local')
---------
union all
---------
select '>|Perf-007|' ||
       case when val1 > 15 or val2 > 15 or val3 > 15 then 'NO' else 'OK' end ||
       '|Average Active sessions (Cnt) Inst#1='||val1||', Inst#2='||val2||', Inst#3='||val3||
       '|Each average Active session < 15'
       as lines
  from ( select max(case when inst = 1 then asess else 0 end) val1
              , max(case when inst = 2 then asess else 0 end) val2
              , max(case when inst = 3 then asess else 0 end) val3
         from ( select instance_number inst, round(avg(average),1) asess
                  from dba_hist_sysmetric_summary
                 where begin_time > sysdate-8 and metric_name = 'Average Active Sessions'
                 group by instance_number))
---------
union all
---------
select '>|Manage-001|' ||
       case when idx > 0 or pidx > 0 or spidx > 0 then 'NO' else 'OK' end ||
       '|Unusable Index (Cnt) Index='||idx||', Partitioned Index='||pidx||', Sub partitioned index='||spidx||
       '|No need Unusable index'
       as lines
  from ( select count(*) idx from dba_indexes where status = 'UNUSABLE' )
     , ( select count(*) pidx from dba_ind_partitions where status = 'UNUSABLE' )
     , ( select count(*) spidx from dba_ind_subpartitions where status = 'UNUSABLE' )
---------
union all
---------
select '>|Manage-002|' ||
       case when seqcnt > 0 then 'NO' else 'OK' end ||
       '|Cnt of sequence (last number < 30% of max value)='||seqcnt||
       '|Last number of sequence have to be enough (>30%)'
       as lines
  from ( select count(*) seqcnt
           from dba_sequences
          where sequence_owner not in ('SYS', 'SYSTEM')
            and (max_value-last_number)*100 /(max_value-min_value)<30 and cycle_flag='N' )
;


--------------------------------------------------------------------------------
-- OS Status
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt Gathering.....[OS Status                             ]  5 / &reports
SET TERMOUT OFF

prompt [OS_STATUS_DATA]
-- dba_hist_osstat

select '<|'|| 'inst|time|' ||
       'num_cpus|num_cpu_cores|num_cpu_sockets|physical_mem_mb|load|idle%|busy%|user%|sys%|iowait%|' ||
       'idle_ms|busy_ms|user_ms|sys_ms|iowait_ms|nice_ms|vm_page_in_bytes|vm_page_out_bytes' as lines
  from dual
;

with tm as (
    select instno, time
      from ( select to_char(to_date(&time_f,'YYYYMMDD-HH24')+(level-1)/24, 'YYYYMMDD-HH24') time from dual
            connect by level <= (to_date(&time_e,'YYYYMMDD-HH24')-to_date(&time_f,'YYYYMMDD-HH24'))*24+1)
         , ( select instance_number instno from gv$instance ) -- where instance_number <= &&num_inst)
     order by 1, 2 )
select '>|'|| tm.instno ||'|'|| tm.time ||'|'||
       a01 ||'|'|| a02 ||'|'|| a03 ||'|'|| a04 ||'|'|| a05 ||'|'|| a06 ||'|'|| a07 ||'|'|| a08 ||'|'|| a09 ||'|'|| a10 ||'|'||
       a11 ||'|'|| a12 ||'|'|| a13 ||'|'|| a14 ||'|'|| a15 ||'|'|| a16 ||'|'|| a17 ||'|'|| a18 as lines
  from (
    select instance_number     instno
         , time                time
         , nvl(v01,0)          a01  -- num_cpus
         , nvl(v02,0)          a02  -- num_cpu_cores
         , nvl(v03,0)          a03  -- num_cpu_sockets
         , round(nvl(v11,0),2) a04  -- physical_memory_mb
         , round(nvl(v04,0),2) a05  -- load
         , round(100*v05/decode(v05+v06,0,null,v05+v06),2) a06  -- idle%
         , round(100*v06/decode(v05+v06,0,null,v05+v06),2) a07  -- busy%
         , round(100*v08/decode(v05+v06,0,null,v05+v06),2) a08  -- system%
         , round(100*v07/decode(v05+v06,0,null,v05+v06),2) a09  -- user%
         , round(100*v09/decode(v05+v06,0,null,v05+v06),2) a10  -- iowait%
         , nvl(v05,0)          a11
         , nvl(v06,0)          a12
         , nvl(v07,0)          a13
         , nvl(v08,0)          a14
         , nvl(v09,0)          a15
         , nvl(v10,0)          a16
         , round(nvl(v12,0),2) a17
         , round(nvl(v13,0),2) a18
      from (
         select sn.instance_number
              , to_char(begin_interval_time, 'YYYYMMDD-HH24') time
              , avg(case when stat_id =  0   then dvalue           end) v01   -- NUM_CPUS
              , avg(case when stat_id = 16   then dvalue           end) v02   -- NUM_CPU_CORES
              , avg(case when stat_id = 17   then dvalue           end) v03   -- NUM_CPU_SOCKETS
              , avg(case when stat_id = 15   then dvalue           end) v04   -- LOAD
              , sum(case when stat_id =  1   then dvalue*10        end) v05   -- IDLE_TIME_MS
              , sum(case when stat_id =  2   then dvalue*10        end) v06   -- BUSY_TIME_MS
              , sum(case when stat_id =  3   then dvalue*10        end) v07   -- USER_TIME_MS
              , sum(case when stat_id =  4   then dvalue*10        end) v08   -- SYS_TIME_MS
              , sum(case when stat_id =  5   then dvalue*10        end) v09   -- IOWAIT_TIME_MS
              , sum(case when stat_id =  6   then dvalue*10        end) v10   -- NICE_TIME_MS
              , avg(case when stat_id = 1008 then dvalue/1024/1024 end) v11   -- PHYSICAL_MEM_MB
              , sum(case when stat_id = 1009 then dvalue/1024/1024 end) v12   -- VM_PAGE_IN_MB
              , sum(case when stat_id = 1010 then dvalue/1024/1024 end) v13   -- VM_PAGE_OUT_MB
           from (
                  select
                         instance_number instno
                       , stat_id
                       , snap_id
                       , case when stat_id in (0,15,16,17,1008)
                              then value
                              else case when             stat_id = lag(stat_id) over (order by instance_number, stat_id, snap_id)
                                        then greatest(0, value   - lag(value  ) over (order by instance_number, stat_id, snap_id))
                                        end
                              end  dvalue
                    from dba_hist_osstat
                   where stat_id in (0,1,2,3,4,5,6,15,16,17,1008,1009,1010)
                     and snap_id between &snap_f and &snap_e
                     and dbid    = &dbid
                )                 df
              , dba_hist_snapshot sn
          where df.instno  = sn.instance_number
            and df.snap_id = sn.snap_id
            and sn.dbid    = &dbid
          group by sn.instance_number, to_char(begin_interval_time, 'YYYYMMDD-HH24')
       )
) a, tm
 where tm.instno = a.instno(+)
   and tm.time   = a.time(+) -- and 1 = 0
order by tm.instno, tm.time
;


--------------------------------------------------------------------------------
-- Wait class  
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt Gathering.....[Wait class                            ]  6 / &reports
SET TERMOUT OFF

prompt [WAIT_CLASS_DATA]
-- dba_hist_system_event

select '<|'|| 'inst|time|' ||
       'Appl_waits|Cluster_waits|Commit_waits|Conc_waits|Conf_waits|' ||
       'Network_waits|Other_waits|Sys_IO_waits|User_IO_waits|' ||
       'Appl_wait_ms|Cluster_wait_ms|Commit_wait_ms|Conc_wait_ms|Conf_wait_ms|' ||
       'Network_wait_ms|Other_wait_ms|Sys_IO_wait_ms|User_IO_wait_ms|' ||
       'Appl_wait%|Cluster_wait%|Commit_wait%|Conc_wait%|Conf_wait%|' ||
       'Network_wait%|Other_wait%|Sys_IO_wait%|User_IO_wait%|DB_Time|DB_CPU' as lines
  from dual
;

with tm as (
    select instno, time
      from ( select to_char(to_date(&time_f,'YYYYMMDD-HH24')+(level-1)/24, 'YYYYMMDD-HH24') time from dual
            connect by level <= (to_date(&time_e,'YYYYMMDD-HH24')-to_date(&time_f,'YYYYMMDD-HH24'))*24+1)
         , ( select instance_number instno from gv$instance ) -- where instance_number <= &&num_inst)
     order by 1, 2 )
select '>|'|| tm.instno ||'|'|| tm.time ||'|'||
       w01 ||'|'|| w02 ||'|'|| w03 ||'|'|| w04 ||'|'|| w05 ||'|'|| w06 ||'|'|| w07 ||'|'|| w08 ||'|'|| w09 ||'|'||
       t01 ||'|'|| t02 ||'|'|| t03 ||'|'|| t04 ||'|'|| t05 ||'|'|| t06 ||'|'|| t07 ||'|'|| t08 ||'|'|| t09 ||'|'||
       p01 ||'|'|| p02 ||'|'|| p03 ||'|'|| p04 ||'|'|| p05 ||'|'|| p06 ||'|'|| p07 ||'|'|| p08 ||'|'|| p09 ||'|'||
       dbt ||'|'|| dbc as lines
  from (
    select sn.instance_number instno
         , to_char(begin_interval_time, 'YYYYMMDD-HH24') time
         , nvl(sum(w01),0) w01
         , nvl(sum(w02),0) w02
         , nvl(sum(w03),0) w03
         , nvl(sum(w04),0) w04
         , nvl(sum(w05),0) w05
         , nvl(sum(w06),0) w06
         , nvl(sum(w07),0) w07
         , nvl(sum(w08),0) w08
         , nvl(sum(w09),0) w09
         , nvl(sum(t01),0) t01
         , nvl(sum(t02),0) t02
         , nvl(sum(t03),0) t03
         , nvl(sum(t04),0) t04
         , nvl(sum(t05),0) t05
         , nvl(sum(t06),0) t06
         , nvl(sum(t07),0) t07
         , nvl(sum(t08),0) t08
         , nvl(sum(t09),0) t09
         , nvl(sum(dbt),0) dbt
         , nvl(sum(dbc),0) dbc
         , nvl(round(sum(t01)/decode(sum(dbt),0,null,sum(dbt))*100,2),0) p01
         , nvl(round(sum(t02)/decode(sum(dbt),0,null,sum(dbt))*100,2),0) p02
         , nvl(round(sum(t03)/decode(sum(dbt),0,null,sum(dbt))*100,2),0) p03
         , nvl(round(sum(t04)/decode(sum(dbt),0,null,sum(dbt))*100,2),0) p04
         , nvl(round(sum(t05)/decode(sum(dbt),0,null,sum(dbt))*100,2),0) p05
         , nvl(round(sum(t06)/decode(sum(dbt),0,null,sum(dbt))*100,2),0) p06
         , nvl(round(sum(t07)/decode(sum(dbt),0,null,sum(dbt))*100,2),0) p07
         , nvl(round(sum(t08)/decode(sum(dbt),0,null,sum(dbt))*100,2),0) p08
         , nvl(round(sum(t09)/decode(sum(dbt),0,null,sum(dbt))*100,2),0) p09
      from (
         select instno
              , snap_id
              , case when instno = lag(instno) over (order by instno) then greatest(0,w01 - lag(w01) over (order by instno)) end w01
              , case when instno = lag(instno) over (order by instno) then greatest(0,w02 - lag(w02) over (order by instno)) end w02
              , case when instno = lag(instno) over (order by instno) then greatest(0,w03 - lag(w03) over (order by instno)) end w03
              , case when instno = lag(instno) over (order by instno) then greatest(0,w04 - lag(w04) over (order by instno)) end w04
              , case when instno = lag(instno) over (order by instno) then greatest(0,w05 - lag(w05) over (order by instno)) end w05
              , case when instno = lag(instno) over (order by instno) then greatest(0,w06 - lag(w06) over (order by instno)) end w06
              , case when instno = lag(instno) over (order by instno) then greatest(0,w07 - lag(w07) over (order by instno)) end w07
              , case when instno = lag(instno) over (order by instno) then greatest(0,w08 - lag(w08) over (order by instno)) end w08
              , case when instno = lag(instno) over (order by instno) then greatest(0,w09 - lag(w09) over (order by instno)) end w09
              , case when instno = lag(instno) over (order by instno) then greatest(0,t01 - lag(t01) over (order by instno)) end t01
              , case when instno = lag(instno) over (order by instno) then greatest(0,t02 - lag(t02) over (order by instno)) end t02
              , case when instno = lag(instno) over (order by instno) then greatest(0,t03 - lag(t03) over (order by instno)) end t03
              , case when instno = lag(instno) over (order by instno) then greatest(0,t04 - lag(t04) over (order by instno)) end t04
              , case when instno = lag(instno) over (order by instno) then greatest(0,t05 - lag(t05) over (order by instno)) end t05
              , case when instno = lag(instno) over (order by instno) then greatest(0,t06 - lag(t06) over (order by instno)) end t06
              , case when instno = lag(instno) over (order by instno) then greatest(0,t07 - lag(t07) over (order by instno)) end t07
              , case when instno = lag(instno) over (order by instno) then greatest(0,t08 - lag(t08) over (order by instno)) end t08
              , case when instno = lag(instno) over (order by instno) then greatest(0,t09 - lag(t09) over (order by instno)) end t09
           from ( select instance_number instno
                       , snap_id
                       , sum(case when wait_class = 'Application'    then total_waits               end) w01
                       , sum(case when wait_class = 'Cluster'        then total_waits               end) w02
                       , sum(case when wait_class = 'Commit'         then total_waits               end) w03
                       , sum(case when wait_class = 'Concurrency'    then total_waits               end) w04
                       , sum(case when wait_class = 'Configuration'  then total_waits               end) w05
                       , sum(case when wait_class = 'Network'        then total_waits               end) w06
                       , sum(case when wait_class = 'Other'          then total_waits               end) w07
                       , sum(case when wait_class = 'System I/O'     then total_waits               end) w08
                       , sum(case when wait_class = 'User I/O'       then total_waits               end) w09
                       , round(sum(case when wait_class = 'Application'   then nvl(time_waited_micro_fg,nvl(time_waited_micro,0))/1000 end),2) t01
                       , round(sum(case when wait_class = 'Cluster'       then nvl(time_waited_micro_fg,nvl(time_waited_micro,0))/1000 end),2) t02
                       , round(sum(case when wait_class = 'Commit'        then nvl(time_waited_micro_fg,nvl(time_waited_micro,0))/1000 end),2) t03
                       , round(sum(case when wait_class = 'Concurrency'   then nvl(time_waited_micro_fg,nvl(time_waited_micro,0))/1000 end),2) t04
                       , round(sum(case when wait_class = 'Configuration' then nvl(time_waited_micro_fg,nvl(time_waited_micro,0))/1000 end),2) t05
                       , round(sum(case when wait_class = 'Network'       then nvl(time_waited_micro_fg,nvl(time_waited_micro,0))/1000 end),2) t06
                       , round(sum(case when wait_class = 'Other'         then nvl(time_waited_micro_fg,nvl(time_waited_micro,0))/1000 end),2) t07
                       , round(sum(case when wait_class = 'System I/O'    then nvl(time_waited_micro_fg,nvl(time_waited_micro,0))/1000 end),2) t08
                       , round(sum(case when wait_class = 'User I/O'      then nvl(time_waited_micro_fg,nvl(time_waited_micro,0))/1000 end),2) t09
                    from dba_hist_system_event
                   where snap_id between &snap_f and &snap_e
                     and dbid = &dbid
                   group by instance_number, snap_id
                  order  by 1,2
                )
           ) se
         , (
         select instno
              , snap_id
              , round(sum(case when stat_id = 3649082374 then dvalue/1000 end),2) dbt -- DB time (ms)
              , round(sum(case when stat_id = 2748282437 then dvalue/1000 end),2) dbc -- DB CPU (ms)
           from ( select instance_number instno
                       , stat_id
                       , snap_id
                       , case when stat_id = lag(stat_id)        over (order by instance_number, stat_id, snap_id)
                              then greatest(0,value - lag(value) over (order by instance_number, stat_id, snap_id))
                              else 0 end dvalue
                    from dba_hist_sys_time_model
                   where snap_id between &snap_f and &snap_e
                     and stat_id in (3649082374, 2748282437)
                     and dbid = &dbid ) stm
          group by instno, snap_id
           ) st
         , dba_hist_snapshot sn
     where sn.instance_number  = se.instno
       and sn.snap_id          = se.snap_id
       and sn.instance_number  = st.instno
       and sn.snap_id          = st.snap_id
       and sn.dbid             = &dbid
     group by sn.instance_number, to_char(begin_interval_time, 'YYYYMMDD-HH24')
) a, tm
 where tm.instno = a.instno(+)
   and tm.time  = a.time(+) -- and 1 = 0
 order  by tm.instno, tm.time
;


--------------------------------------------------------------------------------
-- TOP wait event     
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt Gathering.....[TOP wait events                       ]  7 / &reports
SET TERMOUT OFF

prompt [TOP_WAIT_EVENT_DATA]
-- dba_hist_system_event

select '<|'|| 'inst|time|' ||
       'Rank|Wait_Class|Wait_Event|Total_Waits|Waited_ms|Waits%|Time%' as lines
  from dual
;

with tm as (
    select instno, time
      from ( select 'ALL' time from dual
              union all
             select to_char(to_date(&time_f,'YYYYMMDD-HH24')+(level-1)/24, 'YYYYMMDD-HH24') time from dual
            connect by level <= (to_date(&time_e,'YYYYMMDD-HH24')-to_date(&time_f,'YYYYMMDD-HH24'))*24+1)
         , ( select instance_number instno from gv$instance ) -- where instance_number <= &&num_inst)
     order by 1, 2 ),
     tot as (
    select instance_number instno
         , case when to_char(begin_interval_time,'YYYYMMDD-HH24') is null then 'ALL'
                else to_char(begin_interval_time,'YYYYMMDD-HH24') end time
         , sum(v01     ) t01
         , sum(v03/1000) t03
      from ( select se.instance_number
                  , se.snap_id
                  , begin_interval_time
                  , case when            event_id          = lag(event_id         ) over (order by se.instance_number, event_id, se.snap_id)
                         then greatest(0,total_waits       - lag(total_waits      ) over (order by se.instance_number, event_id, se.snap_id))
                         else 0 end v01
                  , case when            event_id          = lag(event_id         ) over (order by se.instance_number, event_id, se.snap_id)
                         then greatest(0,time_waited_micro - lag(time_waited_micro) over (order by se.instance_number, event_id, se.snap_id))
                         else 0 end v03
               from dba_hist_system_event se
                  , dba_hist_snapshot     sn
              where sn.instance_number = se.instance_number
                and sn.snap_id         = se.snap_id
                and sn.snap_id between &snap_f and &snap_e
                and wait_class <> 'Idle'
                and sn.dbid            = se.dbid
                and sn.dbid            = &dbid
           )
       where snap_id between &snap_f and &snap_e
       group by instance_number, rollup(to_char(begin_interval_time,'YYYYMMDD-HH24')) )
select '>|'||tm.instno ||'|'|| tm.time ||'|'|| rk ||'|'|| wait_class ||'|'|| event_name ||'|'||
       a01 ||'|'|| a03 ||'|'||
       case when t01 = 0 then 0 else round(100*a01/t01, 2) end ||'|'||
       case when t03 = 0 then 0 else round(100*a03/t03, 2) end  as lines
  from ( select sn.instance_number instno
              , case when to_char(sn.begin_interval_time,'YYYYMMDD-HH24') is null then 'ALL' else to_char(sn.begin_interval_time,'YYYYMMDD-HH24') end time
              , rank() over (partition by sn.instance_number, to_char(sn.begin_interval_time, 'YYYYMMDD-HH24') order by sum(v03) desc) rk
              , se.wait_class
              , se.event_name
              , sum(v01     ) a01
              , sum(v03/1000) a03
           from ( select instance_number
                       , wait_class_id, wait_class
                       , event_id, event_name
                       , snap_id
                       , case when            event_id          = lag(event_id         ) over (order by instance_number, event_id, snap_id)
                              then greatest(0,total_waits       - lag(total_waits      ) over (order by instance_number, event_id, snap_id))
                              else 0 end v01
                       , case when            event_id          = lag(event_id         ) over (order by instance_number, event_id, snap_id)
                              then greatest(0,time_waited_micro - lag(time_waited_micro) over (order by instance_number, event_id, snap_id))
                              else 0 end v03
                    from dba_hist_system_event
                   where snap_id between &snap_f and &snap_e
                     and wait_class <> 'Idle'
                     and dbid       =  &dbid
                ) se
              , dba_hist_snapshot sn
          where se.snap_id         = sn.snap_id
            and se.instance_number = sn.instance_number
            and se.snap_id between &snap_f and &snap_e
            and sn.dbid            = &dbid
          group by sn.instance_number
                 , rollup(to_char(sn.begin_interval_time, 'YYYYMMDD-HH24'))
                 , se.wait_class
                 , se.event_name
         order  by 1,2,3
       ) sub
     ,   tot
     ,   tm
 where tm.instno = tot.instno(+)
   and tm.time   = tot.time(+)
   and tm.instno = sub.instno(+)
   and tm.time   = sub.time(+) -- and 1 = 0
   and rk(+) <= 10
 order by tm.instno, tm.time, rk
;


--------------------------------------------------------------------------------
-- Time model
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt Gathering.....[Time model                            ]  8 / &reports
SET TERMOUT OFF

prompt [TIME_MODEL_DATA]
-- dba_hist_sys_time_model

select '<|'|| 'inst|time|' ||
       'DB_TIME_ms|DB_CPU_ms|sql_exec_ms|parse_ms|hparse_ms|PLSQL_exec_ms|Java_exec_ms|bg_time_ms|bg_cpu_ms|' ||
       'DB_TIME%|DB_CPU%|sql_exec%|parse%|hparse%|PLSQL_exec%|Java_exec%|bg_time%|bg_cpu%' as lines
  from dual
;

with tm as (
    select instno, time
      from ( select to_char(to_date(&time_f,'YYYYMMDD-HH24')+(level-1)/24, 'YYYYMMDD-HH24') time from dual
            connect by level <= (to_date(&time_e,'YYYYMMDD-HH24')-to_date(&time_f,'YYYYMMDD-HH24'))*24+1)
         , ( select instance_number instno from gv$instance ) -- where instance_number <= &&num_inst)
     order by 1, 2 )
select '>|'|| tm.instno ||'|'|| tm.time ||'|'||
       a01 ||'|'|| a02 ||'|'|| a03 ||'|'|| a04 ||'|'|| a05 ||'|'|| a06 ||'|'|| a07 ||'|'|| a08 ||'|'|| a09 ||'|'||
       p01 ||'|'|| p02 ||'|'|| p03 ||'|'|| p04 ||'|'|| p05 ||'|'|| p06 ||'|'|| p07 ||'|'|| p08 ||'|'|| p09 as lines
  from (
    select sn.instance_number instno
         , to_char(begin_interval_time, 'YYYYMMDD-HH24') time
         , nvl(sum(t01),0) a01
         , nvl(sum(t02),0) a02
         , nvl(sum(t03),0) a03
         , nvl(sum(t04),0) a04
         , nvl(sum(t05),0) a05
         , nvl(sum(t06),0) a06
         , nvl(sum(t07),0) a07
         , nvl(sum(t08),0) a08
         , nvl(sum(t09),0) a09
         , nvl(round(sum(t01)/decode(sum(t01),0,null,sum(t01))*100,2),0) p01
         , nvl(round(sum(t02)/decode(sum(t01),0,null,sum(t01))*100,2),0) p02
         , nvl(round(sum(t03)/decode(sum(t01),0,null,sum(t01))*100,2),0) p03
         , nvl(round(sum(t04)/decode(sum(t01),0,null,sum(t01))*100,2),0) p04
         , nvl(round(sum(t05)/decode(sum(t01),0,null,sum(t01))*100,2),0) p05
         , nvl(round(sum(t06)/decode(sum(t01),0,null,sum(t01))*100,2),0) p06
         , nvl(round(sum(t07)/decode(sum(t01),0,null,sum(t01))*100,2),0) p07
         , nvl(round(sum(t08)/decode(sum(t01),0,null,sum(t01))*100,2),0) p08
         , nvl(round(sum(t09)/decode(sum(t08),0,null,sum(t08))*100,2),0) p09
      from (
         select instno
              , snap_id
              , round(sum(case when stat_id = 3649082374 then dvalue/1000 end),2) t01 -- DB time (ms)
              , round(sum(case when stat_id = 2748282437 then dvalue/1000 end),2) t02 -- DB CPU (ms)
              , round(sum(case when stat_id = 2821698184 then dvalue/1000 end),2) t03 -- sql execute elapsed time (ms)
              , round(sum(case when stat_id = 1431595225 then dvalue/1000 end),2) t04 -- parse time elapsed (ms)
              , round(sum(case when stat_id =  372226525 then dvalue/1000 end),2) t05 -- hard parse elapsed time (ms)
              , round(sum(case when stat_id = 2643905994 then dvalue/1000 end),2) +   -- PL/SQL execution elapsed time (ms)
                round(sum(case when stat_id = 1311180441 then dvalue/1000 end),2) +   -- PL/SQL comilation elapsed time (ms)
                round(sum(case when stat_id =  290749718 then dvalue/1000 end),2) t06 -- Inbound PL/SQl rpc elapsed (ms)
              , round(sum(case when stat_id =  751169994 then dvalue/1000 end),2) t07 -- Java execution elapsed time (ms)
              , round(sum(case when stat_id = 4157170894 then dvalue/1000 end),2) t08 -- background elapsed time (ms)
              , round(sum(case when stat_id = 2451517896 then dvalue/1000 end),2) t09 -- background cpu time (ms)
           from ( select instance_number instno
                       , stat_id
                       , snap_id
                       , case when stat_id = lag(stat_id)        over (order by instance_number, stat_id, snap_id)
                              then greatest(0,value - lag(value) over (order by instance_number, stat_id, snap_id))
                              else 0 end dvalue
                    from dba_hist_sys_time_model
                   where snap_id between &snap_f and &snap_e
                     and stat_id in (3649082374, 2748282437, 4157170894, 2451517896, 4127043053, 1431595225, 372226525,
                                     2821698184, 1990024365, 268357648,  2643905994, 1311180441, 290749718,  751169994,
                                     1159091985)
                     and dbid = &dbid ) stm
          group by instno, snap_id
       ) st
     , dba_hist_snapshot sn
 where st.instno   = sn.instance_number
   and st.snap_id  = sn.snap_id
   and sn.dbid     = &dbid
 group by SN.instance_number, to_char(begin_interval_time, 'YYYYMMDD-HH24')
) a, tm
 where tm.instno = a.instno(+)
   and tm.time  = a.time(+) -- and 1 = 0
order  by tm.instno, tm.time
;



--------------------------------------------------------------------------------
-- System wait event
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt Gathering.....[System wait event                     ]  9 / &reports
SET TERMOUT OFF

prompt [SYS__EVENT_DATA]
-- dba_hist_system_event

select '<|'|| 'inst|time|' ||
       'Total_waits|Appl_Enq_w|Shared_Pool_w|Buffer_Cache_w|Conf_Enq_w|Cache_Buff_Chain_L_w]|Buff_Busy_w|' ||
       'Free_Buff_w|Dbf_seq_read_w|Dbf_scatt_read_w|Dpath_Read_Sync_w|Dbf_Parall_Read_w|Dbf_Parall_Write_w|' ||
       'Dpath_Write_w|Logfile_Parall_Write_w|Logfile_Sync_w|Read_by_Other_Sess_w|' ||
       'Total_Wait_t|Appl_Enq_t|Shared_Pool_t|Buffer_Cache_t|Conf_Enq_t|Cache_Buff_Chain_L_t|Buff_Busy_t|' ||
       'Free_Buff_t|Dbf_seq_read_t|Dbf_scatt_read_t|Dpath_Read_Sync_t|Dbf_Parall_Read_t|Dbf_Parall_Write_t|' ||
       'Dpath_Write_t|Logfile_Parall_Write_t|Logfile_Sync_t|Read_by_Other_Sess_t|' ||
       'Dbf_seq_read_l|Dbf_scatt_read_l|Dpath_Read_Sync_l|Dbf_Parall_Read_l|Dbf_Parall_Write_l|' ||
       'Dpath_Write_l|Logfile_Sync_l|Read_by_Other_Sess_l' as lines
  from dual
;

with tm as (
    select instno, time
      from ( select to_char(to_date(&time_f,'YYYYMMDD-HH24')+(level-1)/24, 'YYYYMMDD-HH24') time from dual
            connect by level <= (to_date(&time_e,'YYYYMMDD-HH24')-to_date(&time_f,'YYYYMMDD-HH24'))*24+1)
         , ( select instance_number instno from gv$instance ) -- where instance_number <= &&num_inst)
     order by 1, 2 )
select '>|'|| tm.instno ||'|'|| tm.time ||'|'||
       a01 ||'|'|| a02 ||'|'|| a03 ||'|'|| a04 ||'|'|| a05 ||'|'|| a06 ||'|'|| a07 ||'|'|| a08 ||'|'|| a09 ||'|'|| a10 ||'|'||
       a11 ||'|'|| a12 ||'|'|| a13 ||'|'|| a14 ||'|'|| a15 ||'|'|| a16 ||'|'|| a17 ||'|'||
       b01 ||'|'|| b02 ||'|'|| b03 ||'|'|| b04 ||'|'|| b05 ||'|'|| b06 ||'|'|| b07 ||'|'|| b08 ||'|'|| b09 ||'|'|| b10 ||'|'||
       b11 ||'|'|| b12 ||'|'|| b13 ||'|'|| b14 ||'|'|| b15 ||'|'|| b16 ||'|'|| b17 ||'|'||
       l09 ||'|'|| l10 ||'|'|| l11 ||'|'|| l12 ||'|'|| l13 ||'|'|| l14 ||'|'|| l16 ||'|'|| l17 as lines
  from (
    select sn.instance_number instno
         , to_char(begin_interval_time, 'YYYYMMDD-HH24') time
         , nvl(sum(w01),0)      a01  -- Total waits
         , nvl(sum(w02),0)      a02  --  Application enqueue
         , nvl(sum(w03),0)      a03  --  Waits in shared pool
         , nvl(sum(w04),0)      a04  --  Waits in buffer cache
         , nvl(sum(w05),0)      a05  --  Configuration enqueue
         , nvl(sum(w06),0)      a06  --  Wait [latch:cache buffer chains]
         , nvl(sum(w07),0)      a07  --  Wait [buffer busy wait]
         , nvl(sum(w08),0)      a08  --  Wait [free buffer wait]
         , nvl(sum(w09),0)      a09  --  Wait [db file sequential read]
         , nvl(sum(w10),0)      a10  --  Wait [db file scattered read]
         , nvl(sum(w11),0)      a11  --  Wait [direct path read/sync]
         , nvl(sum(w12),0)      a12  --  Wait [db file parallel read]
         , nvl(sum(w13),0)      a13  --  Wait [db file parallel write]
         , nvl(sum(w14),0)      a14  --  Wait [direct path write]
         , nvl(sum(w15),0)      a15  --  Wait [log file parallel write]
         , nvl(sum(w16),0)      a16  --  Wait [log file sync]
         , nvl(sum(w17),0)      a17  --  Wait [read by other session]
         , nvl(sum(t01)/1000,0) b01  -- total time waited micro (micro)
         , nvl(sum(t02)/1000,0) b02  --  Application enqueue
         , nvl(sum(t03)/1000,0) b03  --  Waits in shared pool
         , nvl(sum(t04)/1000,0) b04  --  Waits in buffer cache
         , nvl(sum(t05)/1000,0) b05  --  Configuration enqueue
         , nvl(sum(t06)/1000,0) b06  --  Wait [latch:cache buffer chains]
         , nvl(sum(t07)/1000,0) b07  --  Wait [buffer busy wait]
         , nvl(sum(t08)/1000,0) b08  --  Wait [free buffer wait]
         , nvl(sum(t09)/1000,0) b09  --  Wait [db file sequential read]
         , nvl(sum(t10)/1000,0) b10  --  Wait [db file scattered read]
         , nvl(sum(t11)/1000,0) b11  --  Wait [direct path read/sync]
         , nvl(sum(t12)/1000,0) b12  --  Wait [db file parallel read]
         , nvl(sum(t13)/1000,0) b13  --  Wait [db file parallel write]
         , nvl(sum(t14)/1000,0) b14  --  Wait [direct path write]
         , nvl(sum(t15)/1000,0) b15  --  Wait [log file parallel write]
         , nvl(sum(t16)/1000,0) b16  --  Wait [log file sync]
         , nvl(sum(t17)/1000,0) b17  --  Wait [read by other session]
         , trunc(nvl(sum(t09),0)/decode(sum(w09),0,null,sum(w09))/1000,2) l09  --  Latency [db file sequential read]
         , trunc(nvl(sum(t10),0)/decode(sum(w10),0,null,sum(w10))/1000,2) l10  --  Latency [db file scattered read]
         , trunc(nvl(sum(t11),0)/decode(sum(w11),0,null,sum(w11))/1000,2) l11  --  Latency [direct path read/sync]
         , trunc(nvl(sum(t12),0)/decode(sum(w12),0,null,sum(w12))/1000,2) l12  --  Latency [db file parallel read]
         , trunc(nvl(sum(t13),0)/decode(sum(w13),0,null,sum(w13))/1000,2) l13  --  Latency [db file parallel write]
         , trunc(nvl(sum(t14),0)/decode(sum(w14),0,null,sum(w14))/1000,2) l14  --  Latency [direct path write]
         , trunc(nvl(sum(t16),0)/decode(sum(w16),0,null,sum(w16))/1000,2) l16  --  Latency [log file sync]
         , trunc(nvl(sum(t17),0)/decode(sum(w17),0,null,sum(w17))/1000,2) l17  --  Latency [read by other session]
      from (
         select instno
              , snap_id
              , case when instno = lag(instno) over (order by instno) then greatest(0,w01 - lag(w01) over (order by instno)) end w01 -- Total waits
              , case when instno = lag(instno) over (order by instno) then greatest(0,w02 - lag(w02) over (order by instno)) end w02 --  Application enqueue
              , case when instno = lag(instno) over (order by instno) then greatest(0,w03 - lag(w03) over (order by instno)) end w03 --  Waits in shared pool
              , case when instno = lag(instno) over (order by instno) then greatest(0,w04 - lag(w04) over (order by instno)) end w04 --  Waits in buffer cache
              , case when instno = lag(instno) over (order by instno) then greatest(0,w05 - lag(w05) over (order by instno)) end w05 --  Configuration enqueue
              , case when instno = lag(instno) over (order by instno) then greatest(0,w06 - lag(w06) over (order by instno)) end w06 --  Wait [latch:cache buffer chains]
              , case when instno = lag(instno) over (order by instno) then greatest(0,w07 - lag(w07) over (order by instno)) end w07 --  Wait [buffer busy wait]
              , case when instno = lag(instno) over (order by instno) then greatest(0,w08 - lag(w08) over (order by instno)) end w08 --  Wait [free buffer wait]
              , case when instno = lag(instno) over (order by instno) then greatest(0,w09 - lag(w09) over (order by instno)) end w09 --  Wait [db file sequential read]
              , case when instno = lag(instno) over (order by instno) then greatest(0,w10 - lag(w10) over (order by instno)) end w10 --  Wait [db file scattered read]
              , case when instno = lag(instno) over (order by instno) then greatest(0,w11 - lag(w11) over (order by instno)) end w11 --  Wait [direct path read/sync]
              , case when instno = lag(instno) over (order by instno) then greatest(0,w12 - lag(w12) over (order by instno)) end w12 --  Wait [db file parallel read]
              , case when instno = lag(instno) over (order by instno) then greatest(0,w13 - lag(w13) over (order by instno)) end w13 --  Wait [db file parallel write]
              , case when instno = lag(instno) over (order by instno) then greatest(0,w14 - lag(w14) over (order by instno)) end w14 --  Wait [direct path write]
              , case when instno = lag(instno) over (order by instno) then greatest(0,w15 - lag(w15) over (order by instno)) end w15 --  Wait [log file parallel write]
              , case when instno = lag(instno) over (order by instno) then greatest(0,w16 - lag(w16) over (order by instno)) end w16 --  Wait [log file sync]
              , case when instno = lag(instno) over (order by instno) then greatest(0,w17 - lag(w17) over (order by instno)) end w17 --  Wait [read by other session]
              , case when instno = lag(instno) over (order by instno) then greatest(0,t01 - lag(t01) over (order by instno)) end t01 -- total time waited micro (micro)
              , case when instno = lag(instno) over (order by instno) then greatest(0,t02 - lag(t02) over (order by instno)) end t02 --  Application enqueue
              , case when instno = lag(instno) over (order by instno) then greatest(0,t03 - lag(t03) over (order by instno)) end t03 --  Waits in shared pool
              , case when instno = lag(instno) over (order by instno) then greatest(0,t04 - lag(t04) over (order by instno)) end t04 --  Waits in buffer cache
              , case when instno = lag(instno) over (order by instno) then greatest(0,t05 - lag(t05) over (order by instno)) end t05 --  Configuration enqueue
              , case when instno = lag(instno) over (order by instno) then greatest(0,t06 - lag(t06) over (order by instno)) end t06 --  Wait [latch:cache buffer chains]
              , case when instno = lag(instno) over (order by instno) then greatest(0,t07 - lag(t07) over (order by instno)) end t07 --  Wait [buffer busy wait]
              , case when instno = lag(instno) over (order by instno) then greatest(0,t08 - lag(t08) over (order by instno)) end t08 --  Wait [free buffer wait]
              , case when instno = lag(instno) over (order by instno) then greatest(0,t09 - lag(t09) over (order by instno)) end t09 --  Wait [db file sequential read]
              , case when instno = lag(instno) over (order by instno) then greatest(0,t10 - lag(t10) over (order by instno)) end t10 --  Wait [db file scattered read]
              , case when instno = lag(instno) over (order by instno) then greatest(0,t11 - lag(t11) over (order by instno)) end t11 --  Wait [direct path read/sync]
              , case when instno = lag(instno) over (order by instno) then greatest(0,t12 - lag(t12) over (order by instno)) end t12 --  Wait [db file parallel read]
              , case when instno = lag(instno) over (order by instno) then greatest(0,t13 - lag(t13) over (order by instno)) end t13 --  Wait [db file parallel write]
              , case when instno = lag(instno) over (order by instno) then greatest(0,t14 - lag(t14) over (order by instno)) end t14 --  Wait [direct path write]
              , case when instno = lag(instno) over (order by instno) then greatest(0,t15 - lag(t15) over (order by instno)) end t15 --  Wait [log file parallel write]
              , case when instno = lag(instno) over (order by instno) then greatest(0,t16 - lag(t16) over (order by instno)) end t16 --  Wait [log file sync]
              , case when instno = lag(instno) over (order by instno) then greatest(0,t17 - lag(t17) over (order by instno)) end t17 --  Wait [read by other session]
           from ( select instance_number instno
                       , snap_id
                       , sum(case when wait_class <>  'Idle'                          then total_waits       end) w01
                       , sum(case when wait_class =   'Application'
                                   and event_name like 'enq:%'                        then total_waits       end) w02
                       , sum(case when event_name in  ('latch: row cache objects', 'latch: shared pool',
                                                       'latch: library cache'    ,
                                                       'library cache load lock' , 'library cache lock'      ,
                                                       'library cache pin'       , 'library cache: mutex S'  ,
                                                       'library cache: mutex X'  , 'row cache lock'          ,
                                                       'row cache read')              then total_waits       end) w03
                       , sum(case when event_name in  ('buffer busy waits'       , 'latch: cache buffers chains',
                                                       'free buffer waits'       , 'latch: cache buffers lru chain',
                                                       'latch: cache buffer handles') then total_waits       end) w04
                       , sum(case when wait_class =    'Configuration'
                                   and event_name like 'enq:%'                        then total_waits       end) w05
                       , sum(case when event_name =    'latch: cache buffers chains'  then total_waits       end) w06
                       , sum(case when event_name =    'buffer busy waits'            then total_waits       end) w07
                       , sum(case when event_name =    'free buffer wait'             then total_waits       end) w08
                       , sum(case when event_name =    'db file sequential read'      then total_waits       end) w09
                       , sum(case when event_name =    'db file scattered read'       then total_waits       end) w10
                       , sum(case when event_name in  ('direct path read'        , 'direct path sync')
                                                                                      then total_waits       end) w11
                       , sum(case when event_name =    'db file parallel read'        then total_waits       end) w12
                       , sum(case when event_name =    'db file parallel write'       then total_waits       end) w13
                       , sum(case when event_name =    'direct path write'            then total_waits       end) w14
                       , sum(case when event_name =    'log file parallel write'      then total_waits       end) w15
                       , sum(case when event_name =    'log file sync'                then total_waits       end) w16
                       , sum(case when event_name =    'read by other session'        then total_waits       end) w17
                       , sum(case when wait_class <>   'Idle'                         then time_waited_micro end) t01
                       , sum(case when wait_class =    'Application'
                                   and event_name like 'enq:%'                        then time_waited_micro end) t02
                       , sum(case when event_name in  ('latch: row cache objects', 'latch: shared pool'      ,
                                                       'latch: library cache'    ,
                                                       'library cache load lock' , 'library cache lock'      ,
                                                       'library cache pin'       , 'library cache: mutex S'  ,
                                                       'library cache: mutex X'  , 'row cache lock'          ,
                                                       'row cache read')              then time_waited_micro end) t03
                       , sum(case when event_name in  ('buffer busy waits'       , 'latch: cache buffers chains',
                                                       'free buffer waits'       , 'latch: cache buffers lru chain',
                                                       'latch: cache buffer handles') then time_waited_micro end) t04
                       , sum(case when wait_class =    'Configuration'
                                   and event_name like 'enq:%'                        then time_waited_micro end) t05
                       , sum(case when event_name =    'latch: cache buffers chains'  then time_waited_micro end) t06
                       , sum(case when event_name =    'buffer busy waits'            then time_waited_micro end) t07
                       , sum(case when event_name =    'free buffer wait'             then time_waited_micro end) t08
                       , sum(case when event_name =    'db file sequential read'      then time_waited_micro end) t09
                       , sum(case when event_name =    'db file scattered read'       then time_waited_micro end) t10
                       , sum(case when event_name in  ('direct path read'        , 'direct path sync')
                                                                                      then time_waited_micro end) t11
                       , sum(case when event_name =    'db file parallel read'        then time_waited_micro end) t12
                       , sum(case when event_name =    'db file parallel write'       then time_waited_micro end) t13
                       , sum(case when event_name =    'direct path write'            then time_waited_micro end) t14
                       , sum(case when event_name =    'log file parallel write'      then time_waited_micro end) t15
                       , sum(case when event_name =    'log file sync'                then time_waited_micro end) t16
                       , sum(case when event_name =    'read by other session'        then time_waited_micro end) t17
                    from dba_hist_system_event
                   where snap_id between &snap_f and &snap_e
                     and dbid    =       &dbid
                   group by instance_number, snap_id
                )
       ) se
     , dba_hist_snapshot sn
 where sn.instance_number = se.instno
   and sn.snap_id         = se.snap_id
   and sn.dbid            = &dbid
 group by sn.instance_number, to_char(begin_interval_time, 'YYYYMMDD-HH24')
) a, tm
 where tm.instno = a.instno(+)
   and tm.time   = a.time(+)
order by tm.instno, tm.time
;


--------------------------------------------------------------------------------
-- Sysstat
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt Gathering.....[Sysstat                               ] 10 / &reports
SET TERMOUT OFF

prompt [SYS_STAT_DATA]
-- dba_hist_sysstat

select '<|'|| 'inst|time|' ||
       'redo_mb|db_block_chg|phy_reads|phy_writes|user_calls|parse_total|logons_current|execute|commits|rollbacks|logons_cumulative|' ||
       'opened_cursor_curr|db_block_gets|gc_blocks_lost|gc_cr_block_recv_time|gc_cr_block_send_time|gc_cr_block_recvd|gc_cr_block_servd|' ||
       'gc_cur_block_send_time|gc_cur_block_recv_time|gc_cur_blocks_recvd|gc_cur_blocks_servd|phy_reads_direct|phy_write_direct|' ||
       'table_scans_(long_tables)|global_enq_get_time|gcs_msg_sent|ges_msg_sent|sess_logical_reads|' ||
       'gc_CPU_used_by_this_sess|IPC_CPU_used_by_this_sess|index_fast_full_scans|sess_cursor_cache_count|global_enq_gets_sync|' ||
       'global_enq_gets_async|gc_cr_block_build_time|gc_cr_block_flush_time|gc_cur_block_flush_time|gc_cur_block_pin_time|' ||
       'phy_reads_cache|consistent_gets_from_cache' as lines
  from dual
;

with tm as (
    select instno, time
      from ( select to_char(to_date(&time_f,'YYYYMMDD-HH24')+(level-1)/24, 'YYYYMMDD-HH24') time from dual
            connect by level <= (to_date(&time_e,'YYYYMMDD-HH24')-to_date(&time_f,'YYYYMMDD-HH24'))*24+1)
         , ( select instance_number instno from gv$instance ) -- where instance_number <= &&num_inst)
     order by 1, 2 )
select '>|'|| tm.instno ||'|'|| tm.time ||'|'||
       a01 ||'|'|| a02 ||'|'|| a03 ||'|'|| a04 ||'|'|| a05 ||'|'|| a06  ||'|'|| a07  ||'|'|| a08  ||'|'|| a09  ||'|'|| a10 ||'|'||
       a11 ||'|'|| a12 ||'|'|| a13 ||'|'|| a14 ||'|'|| a15 ||'|'|| a16  ||'|'|| a17  ||'|'|| a18  ||'|'|| a19  ||'|'|| a20 ||'|'||
       a21 ||'|'|| a22 ||'|'|| a23 ||'|'|| a24 ||'|'|| a25 ||'|'|| a26  ||'|'|| a27  ||'|'|| a28  ||'|'|| a29  ||'|'|| a30 ||'|'||
       a31 ||'|'|| a32 ||'|'|| a33 ||'|'|| a34 ||'|'|| a35 ||'|'|| a36  ||'|'|| a37  ||'|'|| a38  ||'|'|| a39  ||'|'|| a40 ||'|'||
       a41 as lines
from (
select sn.instance_number instno
     , to_char(begin_interval_time, 'YYYYMMDD-HH24') time
     , round(nvl(sum(v01)/1024/1024,0),3) a01
     , nvl(sum(v02),0)     a02
     , nvl(sum(v03),0)     a03
     , nvl(sum(v04),0)     a04
     , nvl(sum(v05),0)     a05
     , nvl(sum(v06),0)     a06
     , nvl(sum(v07),0)     a07
     , nvl(sum(v08),0)     a08
     , nvl(sum(v09),0)     a09
     , nvl(sum(v10),0)     a10
     , nvl(sum(v11),0)     a11
     , nvl(sum(v12),0)     a12
     , nvl(sum(v13),0)     a13
     , nvl(sum(v14),0)     a14
     , nvl(sum(v15)/10,0)  a15
     , nvl(sum(v16)/10,0)  a16
     , nvl(sum(v17),0)     a17
     , nvl(sum(v18),0)     a18
     , nvl(sum(v19)/10,0)  a19
     , nvl(sum(v20)/10,0)  a20
     , nvl(sum(v21),0)     a21
     , nvl(sum(v22),0)     a22
     , nvl(sum(v23),0)     a23
     , nvl(sum(v24),0)     a24
     , nvl(sum(v25),0)     a25
     , nvl(sum(v26)/10,0)  a26
     , nvl(sum(v27),0)     a27
     , nvl(sum(v28),0)     a28
     , nvl(sum(v29),0)     a29
     , nvl(sum(v30)/10,0)  a30
     , nvl(sum(v31)/10,0)  a31
     , nvl(sum(v32),0)     a32
     , nvl(sum(v33),0)     a33
     , nvl(sum(v34),0)     a34
     , nvl(sum(v35),0)     a35
     , nvl(sum(v36)/10,0)  a36
     , nvl(sum(v37)/10,0)  a37
     , nvl(sum(v38)/10,0)  a38
     , nvl(sum(v39)/10,0)  a39
     , nvl(sum(v40),0)     a40
     , nvl(sum(v41),0)     a41
from   (
         select
                instno
              , snap_id
              , sum(case when stat_id = 1236385760 then dvalue end) v01 -- redo size
              , sum(case when stat_id =  916801489 then dvalue end) v02 -- db block changes
              , sum(case when stat_id = 2263124246 then dvalue end) v03 -- physical reads
              , sum(case when stat_id = 1190468109 then dvalue end) v04 -- physical writes
              , sum(case when stat_id = 2882015696 then dvalue end) v05 -- user calls
              , sum(case when stat_id =   63887964 then dvalue end) v06 -- parse count(total)
              , sum(case when stat_id = 3080465522 then dvalue end) v07 -- logons current
              , sum(case when stat_id = 2453370665 then dvalue end) v08 -- execute count
              , sum(case when stat_id =  582481098 then dvalue end) v09 -- user commits
              , sum(case when stat_id = 3671147913 then dvalue end) v10 -- user rollbacks
              , sum(case when stat_id = 2666645286 then dvalue end) v11 -- logons cumulative
              , sum(case when stat_id = 2301954928 then dvalue end) v12 -- opened cursor current
              , sum(case when stat_id = 4017839461 then dvalue end) v13 -- db block gets from cache
              , sum(case when stat_id =  500461751 then dvalue end) v14 -- gc blocks lost
              , sum(case when stat_id = 1759426133 then dvalue end) v15 -- gc cr block receive time
              , sum(case when stat_id = 2395315974 then dvalue end) v16 -- gc cr block send time
              , sum(case when stat_id = 2877738702 then dvalue end) v17 -- gc cr block received
              , sum(case when stat_id = 1075941831 then dvalue end) v18 -- gc cr blocks served
              , sum(case when stat_id = 2750158241 then dvalue end) v19 -- gc current block send time
              , sum(case when stat_id = 1388758753 then dvalue end) v20 -- gc current block receive time
              , sum(case when stat_id =  326482564 then dvalue end) v21 -- gc current blocks received
              , sum(case when stat_id =   42062110 then dvalue end) v22 -- gc current blocks served
              , sum(case when stat_id = 2589616721 then dvalue end) v23 -- physical reads direct
              , sum(case when stat_id = 2699895516 then dvalue end) v24 -- Physical write direct
              , sum(case when stat_id = 1042655239 then dvalue end) v25 -- table scans (long tables)
              , sum(case when stat_id = 3744090840 then dvalue end) v26 -- global enqueue get time
              , sum(case when stat_id = 2765451804 then dvalue end) v27 -- gcs messages sent
              , sum(case when stat_id = 1145425433 then dvalue end) v28 -- ges messages sent
              , sum(case when stat_id = 3143187968 then dvalue end) v29 -- session_logical_reads
              , sum(case when stat_id = 4093034494 then dvalue end) v30 -- gc CPU used by this session
              , sum(case when stat_id = 4247517299 then dvalue end) v31 -- IPC CPU used by this session
              , sum(case when stat_id =   12081473 then dvalue end) v32 -- index fast full scans (full)
              , sum(case when stat_id =  568260813 then dvalue end) v33 -- session cursor cache count
              , sum(case when stat_id = 1338475854 then dvalue end) v34 -- global enqueue gets sync
              , sum(case when stat_id = 2892637759 then dvalue end) v35 -- global enqueue gets async
              , sum(case when stat_id =  467525985 then dvalue end) v36 -- gc cr block build time
              , sum(case when stat_id =  552470873 then dvalue end) v37 -- gc cr block flush time
              , sum(case when stat_id = 4091964965 then dvalue end) v38 -- gc current block flush time
              , sum(case when stat_id =  324533635 then dvalue end) v39 -- gc current block pin time
              , sum(case when stat_id = 4171507801 then dvalue end) v40 -- physical reads cache
              , sum(case when stat_id = 2839918855 then dvalue end) v41 -- consistent gets from cache
         from
                (
                  select
                         instance_number instno
                       , stat_id
                       , snap_id
                       , case when stat_id = 3080465522 or stat_id = 2301954928
                              then value
                              else case when             stat_id = lag(stat_id) over (order by instance_number, stat_id, snap_id)
                                        then greatest(0, value   - lag(value)   over (order by instance_number, stat_id, snap_id))
                                        end
                              end  dvalue
                  from   dba_hist_sysstat
                  where  snap_id between &snap_f and &snap_e
                     and dbid    =  &dbid
                     and stat_id in (1236385760,  916801489, 2263124246, 1190468109, 2882015696,   63887964, 3080465522,
                                     2453370665,  582481098, 3671147913, 2666645286, 2301954928, 4017839461,  500461751,
                                     1759426133, 2395315974, 2877738702, 1075941831, 2750158241, 1388758753,  326482564,
                                       42062110, 2589616721, 2699895516, 1042655239, 3744090840, 2765451804, 1145425433,
                                     3143187968, 4093034494, 4247517299,   12081473,  568260813, 1338475854, 2892637759,
                                      467525985,  552470873, 4091964965,  324533635, 4171507801, 2839918855)
                )
         group  by instno, snap_id
       ) ss
     , dba_hist_snapshot sn
where  sn.instance_number = ss.instno
   and sn.snap_id         = ss.snap_id
   and sn.dbid            = &dbid
group  by sn.instance_number, to_char(sn.begin_interval_time, 'YYYYMMDD-HH24')
order  by 1,2
) a, tm
where  tm.instno = a.instno(+)
   and tm.time   = a.time(+)
order  by tm.instno, tm.time
;


--------------------------------------------------------------------------------
-- SGA statistics
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt Gathering.....[SGA statistics                        ] 11 / &reports
SET TERMOUT OFF

prompt [SGA_STAT_DATA]
-- dba_hist_sgastat

select '<|'|| 'inst|time|' ||
       'buffer_cache_mb|log_buffer_mb|fixed_sga_mb|shared_pool_mb|sql_area_mb|shared_free_mb|large_pool_mb|' ||
       'large_free_mb|java_pool_mb|java_free_mb' as lines
  from dual
;

with tm as (
    select instno, time
      from ( select to_char(to_date(&time_f,'YYYYMMDD-HH24')+(level-1)/24, 'YYYYMMDD-HH24') time from dual
            connect by level <= (to_date(&time_e,'YYYYMMDD-HH24')-to_date(&time_f,'YYYYMMDD-HH24'))*24+1)
         , ( select instance_number instno from gv$instance ) -- where instance_number <= &&num_inst)
     order by 1, 2 )
select '>|'|| tm.instno ||'|'|| tm.time ||'|'||
       a01 ||'|'|| a02 ||'|'|| a03 ||'|'|| a04 ||'|'|| a05 ||'|'|| a06 ||'|'|| a07 ||'|'|| a08 ||'|'|| a09 ||'|'|| a10 as lines
from (
select sn.instance_number instno
     , to_char(begin_interval_time, 'YYYYMMDD-HH24') time
     , nvl(round(avg(v01),2) ,0) a01
     , nvl(round(avg(v02),2) ,0) a02
     , nvl(round(avg(v03),2) ,0) a03
     , nvl(round(avg(v04),2) ,0) a04
     , nvl(round(avg(v05),2) ,0) a05
     , nvl(round(avg(v06),2) ,0) a06
     , nvl(round(avg(v07),2) ,0) a07
     , nvl(round(avg(v08),2) ,0) a08
     , nvl(round(avg(v09),2) ,0) a09
     , nvl(round(avg(v10),2) ,0) a10
  from (
         select
                instance_number instno
              , snap_id
              , sum(case when pool is null         and name = 'buffer_cache' then bytes/1024/1024 end) v01
              , sum(case when pool is null         and name = 'log_buffer'   then bytes/1024/1024 end) v02
              , sum(case when pool is null         and name = 'fixed_sga'    then bytes/1024/1024 end) v03
              , sum(case when pool = 'shared pool'                           then bytes/1024/1024 end) v04
              , sum(case when pool = 'shared pool' and name = 'SQLA'         then bytes/1024/1024 end) v05
              , sum(case when pool = 'shared pool' and name = 'free memory'  then bytes/1024/1024 end) v06
              , sum(case when pool = 'large pool'                            then bytes/1024/1024 end) v07
              , sum(case when pool = 'large pool'  and name = 'free memory'  then bytes/1024/1024 end) v08
              , sum(case when pool = 'java pool'                             then bytes/1024/1024 end) v09
              , sum(case when pool = 'java pool'   and name = 'free memory'  then bytes/1024/1024 end) v10
           from dba_hist_sgastat
          where snap_id between &snap_f and &snap_e
            and dbid    =       &dbid
          group by instance_number
                 , snap_id
       ) sg
     , dba_hist_snapshot sn
 where sn.instance_number = sg.instno
   and sn.snap_id         = sg.snap_id
   and sn.dbid            = &dbid
 group by sn.instance_number
        , to_char(begin_interval_time, 'YYYYMMDD-HH24')
) a, tm
 where tm.instno = a.instno(+)
   and tm.time  = a.time(+)
order  by tm.instno, tm.time
;


----------------------------------------------------------------------------------------------------------------------------------------
-- Buffer pool statistics
----------------------------------------------------------------------------------------------------------------------------------------
SET TERMOUT ON
prompt Gathering.....[Buffer pool statistics                ] 12 / &reports
SET TERMOUT OFF

prompt [BUFFER_POOL_STAT_DATA]
-- dba_hist_buffer_pool_stat

select '<|'|| 'inst|time|' ||
       'buffer_pool_sz|db_block_gets|consistent_gets|physical_reads|physical_writes|free_buffer_wait|' ||
       'write_complete_wait|buffer_busy_wait' as lines
  from dual
;

with tm as (
    select instno, time
      from ( select to_char(to_date(&time_f,'YYYYMMDD-HH24')+(level-1)/24, 'YYYYMMDD-HH24') time from dual
            connect by level <= (to_date(&time_e,'YYYYMMDD-HH24')-to_date(&time_f,'YYYYMMDD-HH24'))*24+1)
         , ( select instance_number instno from gv$instance ) -- where instance_number <= &&num_inst)
     order by 1, 2 )
select '>|'||tm.instno ||'|'|| tm.time ||'|'||
       a01 ||'|'|| a02 ||'|'|| a03 ||'|'|| a04 ||'|'|| a05 ||'|'|| a06 ||'|'|| a07 ||'|'|| a08 as tval
from (
select sn.instance_number instno
     , to_char(sn.begin_interval_time, 'YYYYMMDD-HH24') time
     , round(avg(vd1),2) a01
     , round(avg(vd2),2) a02
     , round(avg(vd3),2) a03
     , round(avg(vd4),2) a04
     , round(avg(vd5),2) a05
     , round(avg(vd6),2) a06
     , round(avg(vd7),2) a07
     , round(avg(vd8),2) a08
from   (
         select instno
              , snap_id
              , nvl(sum(case when name = 'DEFAULT' then greatest(0,v1) else 0 end),0) vd1 -- set_msize
              , nvl(sum(case when name = 'DEFAULT' then greatest(0,v2) else 0 end),0) vd2 -- db_block_gets
              , nvl(sum(case when name = 'DEFAULT' then greatest(0,v3) else 0 end),0) vd3 -- consistent_gets
              , nvl(sum(case when name = 'DEFAULT' then greatest(0,v4) else 0 end),0) vd4 -- physical_reads
              , nvl(sum(case when name = 'DEFAULT' then greatest(0,v5) else 0 end),0) vd5 -- physical_writes
              , nvl(sum(case when name = 'DEFAULT' then greatest(0,v6) else 0 end),0) vd6 -- free_buffer_wait
              , nvl(sum(case when name = 'DEFAULT' then greatest(0,v7) else 0 end),0) vd7 -- write_complete_wait
              , nvl(sum(case when name = 'DEFAULT' then greatest(0,v8) else 0 end),0) vd8 -- buffer_busy_wait
         from   (
                  select
                         instance_number instno
                       , snap_id
                       , name
                       , set_msize             v1 -- set Msize
                       , db_block_gets       - lag(db_block_gets  )     over (order by instance_number, name, snap_id) v2 -- DB block gets
                       , consistent_gets     - lag(consistent_gets)     over (order by instance_number, name, snap_id) v3 -- Consistent gets
                       , physical_reads      - lag(physical_reads )     over (order by instance_number, name, snap_id) v4 -- Physical reads
                       , physical_writes     - lag(physical_writes)     over (order by instance_number, name, snap_id) v5 -- physical writes
                       , free_buffer_wait    - lag(free_buffer_wait)    over (order by instance_number, name, snap_id) v6 -- free buffer wait
                       , write_complete_wait - lag(write_complete_wait) over (order by instance_number, name, snap_id) v7 -- write complete wait
                       , buffer_busy_wait    - lag(buffer_busy_wait)    over (order by instance_number, name, snap_id) v8 -- buffer busy wait
                  from   dba_hist_buffer_pool_stat
                  where  snap_id between &snap_f and &snap_e
                     and dbid    =       &dbid
                )
         group  by instno, snap_id
       ) sb
     , dba_hist_snapshot sn
where  sn.instance_number = sb.instno
   and sn.snap_id         = sb.snap_id
   and sn.dbid            = &dbid
group  by sn.instance_number, to_char(begin_interval_time, 'YYYYMMDD-HH24')
order  by 1,2
) a, tm
where  tm.instno = a.instno(+)
   and tm.time  = a.time(+)
order  by tm.instno, tm.time
;


--------------------------------------------------------------------------------
-- PGA statistics
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt Gathering.....[PGA statistics                        ] 13 / &reports
SET TERMOUT OFF

prompt [PGA_STAT_DATA]
-- dba_hist_pgastat

select '<|'|| 'inst|time|' ||
       'pga_aggr_target_mb|pga_aggr_auto_target_mb|max_pga_alloc_mb|total_pga_alloc_mb|total_pga_inuse_mb|' ||
       'total_pga_auto_wa_mb|total_pga_manual_wa_mb|pga_cache_hit%' as lines
  from dual
;

with tm as (
    select instno, time
      from ( select to_char(to_date(&time_f,'YYYYMMDD-HH24')+(level-1)/24, 'YYYYMMDD-HH24') time from dual
            connect by level <= (to_date(&time_e,'YYYYMMDD-HH24')-to_date(&time_f,'YYYYMMDD-HH24'))*24+1)
         , ( select instance_number instno from gv$instance ) -- where instance_number <= &&num_inst)
     order by 1, 2 )
select '>|'|| tm.instno ||'|'|| tm.time ||'|'||
       a01 ||'|'|| a02 ||'|'|| a03 ||'|'|| a04 ||'|'|| a05 ||'|'|| a06 ||'|'|| a07 ||'|'|| a08 as lines
from (
select sn.instance_number instno
     , to_char(begin_interval_time, 'YYYYMMDD-HH24') time
     , nvl(round(avg(v01),2) ,0) a01
     , nvl(round(avg(v02),2) ,0) a02
     , nvl(round(avg(v03),2) ,0) a03
     , nvl(round(avg(v04),2) ,0) a04
     , nvl(round(avg(v05),2) ,0) a05
     , nvl(round(avg(v06),2) ,0) a06
     , nvl(round(avg(v07),2) ,0) a07
     , nvl(round(avg(v08),2) ,0) a08
  from (
         select
                instance_number instno
              , snap_id
              , sum(case when name = 'aggregate PGA target parameter'      then value/1024/1024 end) v01
              , sum(case when name = 'aggregate PGA auto target'           then value/1024/1024 end) v02
              , sum(case when name = 'maximum PGA allocated'               then value/1024/1024 end) v03
              , sum(case when name = 'total PGA allocated'                 then value/1024/1024 end) v04
              , sum(case when name = 'total PGA inuse'                     then value/1024/1024 end) v05
              , sum(case when name = 'total PGA used for auto workareas'   then value/1024/1024 end) v06
              , sum(case when name = 'total PGA used for manual workareas' then value/1024/1024 end) v07
              , sum(case when name = 'cache hit percentage'                then value           end) v08
           from dba_hist_pgastat
          where snap_id between &snap_f and &snap_e
            and dbid    =       &dbid
          group by instance_number
                 , snap_id
       ) sp
     , dba_hist_snapshot sn
 where sn.instance_number = sp.instno
   and sn.snap_id         = sp.snap_id
   and sn.dbid            = &dbid
 group by sn.instance_number, to_char(begin_interval_time, 'YYYYMMDD-HH24')
) a, tm
 where tm.instno = a.instno(+)
   and tm.time  = a.time(+)
order  by tm.instno, tm.time
;


--------------------------------------------------------------------------------
-- RAC status
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt Gathering.....[RAC status                            ] 14 / &reports
SET TERMOUT OFF

prompt [RAC_STAT_DATA]
-- dba_hist_dlm_misc
-- dba_hist_cr_block_server
-- dba_hist_current_block_server

select '<|'|| 'inst|time|' ||
       'est_traffic_mb|gc_effy_local%|gc_effy_remote%|gc_effy_disk%|avg_global_enq_get_ms|' ||
       'avg_gc_cr_rcv_ms|gvg_gc_cr_build_ms|avg_gc_cr_send_ms|avg_gc_cr_flush_ms|gc_log_flush_cr_srv%|' ||
       'avg_gc_cu_rcv_ms|gvg_gc_cu_build_ms|avg_gc_cu_send_ms|avg_gc_cu_flush_ms|gc_log_flush_cu_srv%|' ||
       'direct_sent_msgs%|indirect_sent_msgs%|flow_ctrld_msgs%|' ||
       'gcs_msgs_recvd|gcs_msgs_process_ms|ges_msgs_recvd|ges_msgs_process_ms|msgs_sent_queued|msgs_sent_queue_ms|' ||
       'msgs_sent_queued_ksxp|msgs_sent_queued_ksxp_ms|msgs_recvd_queue_ms|msgs_recvd_queued|msgs_sent_direct|' ||
       'msgs_sent_indirect|msgs_flow_controlled|cr_block_flushes|cur_block_flushes' as lines
  from dual
;

with tm as (
    select instno, time
      from ( select to_char(to_date(&time_f,'YYYYMMDD-HH24')+(level-1)/24, 'YYYYMMDD-HH24') time from dual
            connect by level <= (to_date(&time_e,'YYYYMMDD-HH24')-to_date(&time_f,'YYYYMMDD-HH24'))*24+1)
         , ( select instance_number instno from gv$instance ) -- where instance_number <= &&num_inst)
     order by 1, 2 ),
     prm as (select value block_size from v$parameter where name = 'db_block_size')
select '>|'|| tm.instno ||'|'|| tm.time ||'|'|| 
       est_mb ||'|'|| efflc ||'|'|| effrc ||'|'|| effdsk ||'|'|| gegt ||'|'||
       gccrrt ||'|'|| gccrbt ||'|'|| gccrst ||'|'|| gccrft ||'|'|| gccrflp ||'|'|| 
       gccurt ||'|'|| gccupt ||'|'|| gccust ||'|'|| gccuft ||'|'|| gccuflp ||'|'|| 
       dmsdp ||'|'|| dmsip ||'|'|| dmfcp ||'|'|| 
       a01 ||'|'|| a02 ||'|'|| a03 ||'|'|| a04 ||'|'|| a05 ||'|'|| a06 ||'|'|| a07 ||'|'|| a08 ||'|'|| a09 ||'|'|| a10 ||'|'||
       a11 ||'|'|| a12 ||'|'|| a13 ||'|'|| a14 ||'|'|| a15 as lines
from (
select sn.instance_number instno
     , sn.time -- to_char(begin_interval_time, 'YYYYMMDD-HH24') time
     , round(sum((gccurv+gccrrv+gccusv+gccrsv)*prm.block_size +
                 (gcms+gems+pmrv+npmrv)*200)/1024/1024/sum(elas), 2)        est_mb  -- Estimated interconnect traffic(MB/s)
     , round(sum(glgt)*10/decode(sum(glsg+glag),0,null,sum(glsg+glag)),2)   gegt    -- Avg global enqueue get time(ms)
     , round(sum(gccrrt)*10/decode(sum(gccrrv),0,null,sum(gccrrv)),2)       gccrrt  -- Avg gc cr block receive time(ms)
     , round(sum(gccrbt)*10/decode(sum(gccrsv),0,null,sum(gccrsv)),2)       gccrbt  -- Avg gc cr block build time(ms)
     , round(sum(gccrst)*10/decode(sum(gccrsv),0,null,sum(gccrsv)),2)       gccrst  -- Avg gc cr block send time(ms)
     , round(sum(gccrft)*10/decode(sum(gccrfl),0,null,sum(gccrfl)),2)       gccrft  -- Avg gc cr block flush time(ms)
     , round(sum(gccrfl)   /decode(sum(gccrsv),0,null,sum(gccrsv))*100,2)   gccrflp -- Global cache log flushes for cr blocks served %
     , round(sum(gccurt)*10/decode(sum(gccurv),0,null,sum(gccurv)),2)       gccurt  -- Avg gc current block receive time(ms)
     , round(sum(gccupt)*10/decode(sum(gccusv),0,null,sum(gccusv)),2)       gccupt  -- Avg gc current block pin time(ms)
     , round(sum(gccust)*10/decode(sum(gccusv),0,null,sum(gccusv)),2)       gccust  -- Avg gc current block send time(ms)
     , round(sum(gccuft)*10/decode(sum(gccufl),0,null,sum(gccufl)),2)       gccuft  -- Avg gc current block flush time(ms)
     , round(sum(gccufl)   /decode(sum(gccusv),0,null,sum(gccusv))*100,2)   gccuflp -- Global cache log flushes for current blocks served %
     , round(100*(1-sum(phyrc+gccurv+gccrrv)/
                  decode(sum(cgfc+dbfc),0,null,sum(cgfc+dbfc))),2)          efflc   -- GC Efficiency : Buffer access - Local(%)
     , round(100*(sum(gccurv+gccrrv)/
                  decode(sum(cgfc+dbfc),0,null,sum(cgfc+dbfc))),2)          effrc   -- GC Efficiency : Buffer access - Remote(%)
     , round(100*(sum(phyrc)/
                  decode(sum(cgfc+dbfc),0,null,sum(cgfc+dbfc))),2)          effdsk  -- GC Efficiency : Buffer access - Disk(%)
     , round(100*sum(dmsd)/
                  decode(sum(dmsd+dmsi+dmfc),0,null,sum(dmsd+dmsi+dmfc)),2) dmsdp   -- % of direct sent messages
     , round(100*sum(dmsi)/
                  decode(sum(dmsd+dmsi+dmfc),0,null,sum(dmsd+dmsi+dmfc)),2) dmsip   -- % of indirect sent messages
     , round(100*sum(dmfc)/
                  decode(sum(dmsd+dmsi+dmfc),0,null,sum(dmsd+dmsi+dmfc)),2) dmfcp   -- % of flow controlled messages
     , nvl(sum(pmrv),0)     a01
     , nvl(sum(pmpt),0)     a02
     , nvl(sum(npmrv),0)    a03
     , nvl(sum(npmpt),0)    a04
     , nvl(sum(msgsq),0)    a05
     , nvl(sum(msgsqt),0)   a06
     , nvl(sum(msgsqk),0)   a07
     , nvl(sum(msgsqtk),0)  a08
     , nvl(sum(msgrqt),0)   a09
     , nvl(sum(msgrq),0)    a10
     , nvl(sum(dmsd),0)     a11
     , nvl(sum(dmsi),0)     a12
     , nvl(sum(dmfc),0)     a13
     , nvl(sum(gccrfl),0)   a14
     , nvl(sum(gccufl),0)   a15
  from (
         select
                instno
              , snap_id
              , sum(case when statistic# = 6  then greatest(0,dvalue) end) pmrv    -- gcs msgs received
              , sum(case when statistic# = 7  then greatest(0,dvalue) end) pmpt    -- gcs msgs process time(ms)
              , sum(case when statistic# = 8  then greatest(0,dvalue) end) npmrv   -- ges msgs received
              , sum(case when statistic# = 9  then greatest(0,dvalue) end) npmpt   -- ges msgs process time(ms)
              , sum(case when statistic# = 51 then greatest(0,dvalue) end) msgsq   -- msgs sent queued
              , sum(case when statistic# = 52 then greatest(0,dvalue) end) msgsqt  -- msgs sent queue time (ms)
              , sum(case when statistic# = 53 then greatest(0,dvalue) end) msgsqk  -- msgs sent queued on ksxp
              , sum(case when statistic# = 54 then greatest(0,dvalue) end) msgsqtk -- msgs sent queue time on ksxp (ms)
              , sum(case when statistic# = 55 then greatest(0,dvalue) end) msgrqt  -- msgs received queue time (ms)
              , sum(case when statistic# = 56 then greatest(0,dvalue) end) msgrq   -- msgs received queued
              , sum(case when statistic# = 0  then greatest(0,dvalue) end) dmsd    -- messages sent directly
              , sum(case when statistic# = 2  then greatest(0,dvalue) end) dmsi    -- messages sent indirectly
              , sum(case when statistic# = 1  then greatest(0,dvalue) end) dmfc    -- messages flow controlled
              , sum(case when statistic# = 87 then greatest(0,dvalue) end) mra     -- messages received actual
           from (
                  select
                         instance_number instno
                       , statistic#
                       , snap_id
                       , case when statistic# = lag(statistic#) over (order by instance_number, statistic#, snap_id)
                              then value      - lag(value     ) over (order by instance_number, statistic#, snap_id)
                              end  dvalue
                    from dba_hist_dlm_misc -- 'messages received actual', 'messages sent directly', 'messages sent indirectly'
                   where snap_id    between &snap_f and &snap_e
                     and statistic# in (6,7,8,9,51,52,53,54,55,56,0,2,1)
                     and dbid = &dbid
                )
          group by instno, snap_id
       ) dm
     , (
         select
                instno
              , snap_id
              , sum(case when stat_id =  326482564 then dvalue end) gccurv -- gc current blocks received
              , sum(case when stat_id = 2877738702 then dvalue end) gccrrv -- gc cr block received
              , sum(case when stat_id =   42062110 then dvalue end) gccusv -- gc current blocks served
              , sum(case when stat_id = 1075941831 then dvalue end) gccrsv -- gc cr blocks served
              , sum(case when stat_id = 4093034494 then dvalue end) gccpu  -- gc CPU used by this session
              , sum(case when stat_id = 4247517299 then dvalue end) ipccpu -- IPC CPU used by this session
              , sum(case when stat_id = 2765451804 then dvalue end) gcms   -- gcs messages sent
              , sum(case when stat_id = 1145425433 then dvalue end) gems   -- ges messages sent
              , sum(case when stat_id =  500461751 then dvalue end) gcl    -- gc blocks lost
              , sum(case when stat_id = 4171507801 then dvalue end) phyrc  -- physical reads cache
              , sum(case when stat_id = 2839918855 then dvalue end) cgfc   -- consistent gets from cache
              , sum(case when stat_id = 4017839461 then dvalue end) dbfc   -- db block gets from cache
              , sum(case when stat_id = 3744090840 then dvalue end) glgt   -- global enqueue get time
              , sum(case when stat_id = 1338475854 then dvalue end) glsg   -- global enqueue gets sync
              , sum(case when stat_id = 2892637759 then dvalue end) glag   -- global enqueue gets async
              , sum(case when stat_id = 1759426133 then dvalue end) gccrrt -- gc cr block receive time
              , sum(case when stat_id = 2395315974 then dvalue end) gccrst -- gc cr block send time
              , sum(case when stat_id =  467525985 then dvalue end) gccrbt -- gc cr block build time
              , sum(case when stat_id =  552470873 then dvalue end) gccrft -- gc cr block flush time
              , sum(case when stat_id = 1388758753 then dvalue end) gccurt -- gc current block receive time
              , sum(case when stat_id = 2750158241 then dvalue end) gccust -- gc current block send time
              , sum(case when stat_id = 4091964965 then dvalue end) gccuft -- gc current block flush time
              , sum(case when stat_id =  324533635 then dvalue end) gccupt -- gc current block pin time
         from
                (
                  select
                         instance_number instno
                       , stat_id
                       , snap_id
                       , case when           stat_id = lag(stat_id) over (order by instance_number, stat_id, snap_id)
                              then greatest(0, value - lag(value)   over (order by instance_number, stat_id, snap_id))
                              end dvalue
                  from   dba_hist_sysstat
                  where  snap_id between &snap_f and &snap_e
                     and dbid    =  &dbid
                     and stat_id in ( 326482564, 2877738702,   42062110, 1075941831, 4093034494, 4247517299, 2765451804,
                                     1145425433,  500461751, 4171507801, 2839918855, 4017839461, 3744090840, 1338475854,
                                     2892637759, 1759426133, 2395315974, 2750158241, 1388758753,  467525985,  552470873, 
                                     4091964965,  324533635 )
                )
         group  by instno, snap_id
       ) ss
     , (
         select instance_number instno
              , snap_id
              , greatest(0,flushes
                     - lag(flushes) over (order by instance_number, snap_id)) gccrfl
           from dba_hist_cr_block_server
          where snap_id between &snap_f and &snap_e
            and dbid    =       &dbid
         order  by instance_number, snap_id
       ) cr
     , (
        select instance_number instno
             , snap_id
             , greatest(0,flush1+flush1+flush100+flush1000+flush10000
                    - lag(flush1+flush1+flush100+flush1000+flush10000) over (order by instance_number, snap_id)) gccufl
          from dba_hist_current_block_server
         where snap_id between &snap_f and &snap_e
           and dbid = &dbid
        order  by instance_number, snap_id
       ) cu
     , (
        select instance_number
             , snap_id
             , dbid
             , to_char(begin_interval_time,'YYYYMMDD-HH24') time
             , sum(elas) elas 
          from (select instance_number, snap_id, dbid, begin_interval_time
                     , extract(hour   from (end_interval_time - begin_interval_time))*60*24 
                     + extract(minute from (end_interval_time - begin_interval_time))*60 
                     + extract(second from (end_interval_time - begin_interval_time)) elas
                  from dba_hist_snapshot 
                 where snap_id between &snap_f and &snap_e
                   and dbid = &dbid)
         group by instance_number, snap_id, dbid, to_char(begin_interval_time, 'YYYYMMDD-HH24')
       ) sn
     , prm
 where sn.instance_number = cr.instno
   and sn.snap_id         = cr.snap_id
   and sn.instance_number = cu.instno
   and sn.snap_id         = cu.snap_id
   and sn.instance_number = dm.instno
   and sn.snap_id         = dm.snap_id
   and sn.instance_number = ss.instno
   and sn.snap_id         = ss.snap_id
   and sn.dbid            = &dbid
 group by sn.instance_number, time -- to_char(begin_interval_time, 'YYYYMMDD-HH24')
order  by 1,2
) a, tm
 where tm.instno = a.instno(+)
   and tm.time  = a.time(+)
   and '&is_rac' = 'YES' 
order  by tm.instno, tm.time
;



--------------------------------------------------------------------------------
-- TOP-SQL by elap, cpu, iowait, buffer gets, disk reads, clster wait, exec
--------------------------------------------------------------------------------
SET TERMOUT ON
prompt Gathering.....[TOP SQL for each period               ] 15 / &reports
SET TERMOUT OFF

prompt [TOP_SQL_DATA]
-- dba_hist_sqlstat
-- SQL ordered by Elapsed Time
-- SQL ordered by CPU Time
-- SQL ordered by User I/O Time
-- SQL ordered by Buffer Gets
-- SQL ordered by Reads
-- SQL ordered by Cluster Time
-- SQL ordered by Executions

select '<|'|| 'inst|time|rk_elap|rk_cpu|rk_iow|rk_buff|rk_disk|rk_clst|rk_exe|' ||
       'sql_id|schema|planh|rows_processed|executions|elapsed_ms|cpu_time_ms|iowait_ms|clwait_ms|' ||
       'buff_gets|disk_reads|elapsed%|cpu%|iowait%|buff_gets%|disk_reads%|avg_row_processed|' ||
       'avg_elapsed_ms|avg_cpu_time_ms|avg_iowait_ms|avg_clwait_ms|avg_buff_gets|avg_disk_reads' as lines
  from dual
;

with tm as (
    select instno, time
      from ( select 'ALL' time from dual
              union all
             select to_char(to_date(&time_f,'YYYYMMDD-HH24')+(level-1)/24, 'YYYYMMDD-HH24') time from dual
            connect by level <= (to_date(&time_e,'YYYYMMDD-HH24')-to_date(&time_f,'YYYYMMDD-HH24'))*24+1)
         , ( select instance_number instno from gv$instance ) -- where instance_number <= &&num_inst)
     order by 1, 2 ),
     tot as (
    select ss.instance_number instno
         , case when to_char(sn.begin_interval_time, 'YYYYMMDD-HH24') is null then 'ALL'
                else to_char(sn.begin_interval_time, 'YYYYMMDD-HH24') end time
         , sum(elapsed_time_delta) t1
         , sum(cpu_time_delta)     t2
         , sum(iowait_delta)       t3
         , sum(buffer_gets_delta)  t4
         , sum(disk_reads_delta)   t5
      from dba_hist_sqlstat  ss
         , dba_hist_snapshot sn
     where ss.instance_number = sn.instance_number
       and ss.snap_id         = sn.snap_id
       and ss.snap_id   between &snap_f and &snap_e
       and ss.dbid            = sn.dbid
       and sn.dbid            = &dbid
     group by ss.instance_number, rollup(to_char(sn.begin_interval_time, 'YYYYMMDD-HH24')) )
select '>|'|| sub.instno ||'|'|| sub.time ||'|'|| sub.rk ||'|'|| rkc ||'|'|| rki ||'|'|| rkb ||'|'|| rkd ||'|'|| rkr ||'|'|| rkx ||'|'||
       sub.sql_id ||'|'|| sub.schema ||'|'|| sub.planh ||'|'|| a1 ||'|'|| a2 ||'|'||
       round(a3/1000,3) ||'|'|| round(a4/1000,3) ||'|'|| round(a5/1000,3) ||'|'|| round(a6 /1000,3) ||'|'|| a7 ||'|'|| a8 ||'|'||
       nvl(round(100*a3/greatest(1,t1),2),0) ||'|'|| nvl(round(100*a4/greatest(1,t2),2),0) ||'|'||
       nvl(round(100*a5/greatest(1,t3),2),0) ||'|'|| nvl(round(100*a7/greatest(1,t4),2),0) ||'|'||
       nvl(round(100*a8/greatest(1,t5),2),0) ||'|'|| round(a1 / greatest(1,a2), 2) ||'|'||
       round(a3 / greatest(1,a2) / 1000, 2)  ||'|'|| round(a4 / greatest(1,a2) / 1000, 2) ||'|'||
       round(a5 / greatest(1,a2) / 1000, 2)  ||'|'|| round(a6 / greatest(1,a2) / 1000, 2) ||'|'||
       round(a7 / greatest(1,a2), 2) ||'|'|| round(a8 / greatest(1,a2), 2) as lines
  from (
         select sn.instance_number instno
              , case when to_char(begin_interval_time,'YYYYMMDD-HH24') is null then 'ALL' else to_char(begin_interval_time,'YYYYMMDD-HH24') end time
              , rank()       over (partition by sn.instance_number, to_char(begin_interval_time, 'YYYYMMDD-HH24') order by sum(sql.elapsed_time_delta) desc) rk
              , rank()       over (partition by sn.instance_number, to_char(begin_interval_time, 'YYYYMMDD-HH24') order by sum(sql.cpu_time_delta    ) desc) rkc
              , rank()       over (partition by sn.instance_number, to_char(begin_interval_time, 'YYYYMMDD-HH24') order by sum(sql.iowait_delta      ) desc) rki
              , rank()       over (partition by sn.instance_number, to_char(begin_interval_time, 'YYYYMMDD-HH24') order by sum(sql.buffer_gets_delta ) desc) rkb
              , rank()       over (partition by sn.instance_number, to_char(begin_interval_time, 'YYYYMMDD-HH24') order by sum(sql.disk_reads_delta  ) desc) rkd
              , rank()       over (partition by sn.instance_number, to_char(begin_interval_time, 'YYYYMMDD-HH24') order by sum(sql.clwait_delta      ) desc) rkr
              , rank()       over (partition by sn.instance_number, to_char(begin_interval_time, 'YYYYMMDD-HH24') order by sum(sql.executions_delta  ) desc) rkx
              , sql.sql_id
              , parsing_schema_name schema
              , plan_hash_value     planh
              , sum(rows_processed_delta) a1
              , sum(executions_delta    ) a2
              , sum(elapsed_time_delta  ) a3
              , sum(cpu_time_delta      ) a4
              , sum(iowait_delta        ) a5
              , sum(clwait_delta        ) a6
              , sum(buffer_gets_delta   ) a7
              , sum(disk_reads_delta    ) a8
           from dba_hist_sqlstat  sql
              , dba_hist_snapshot sn
          where sql.snap_id         = sn.snap_id
            and sql.instance_number = sn.instance_number
            and sql.snap_id   between &snap_f and &snap_e
            and sql.dbid            = sn.dbid
            and sn.dbid             = &dbid
          group by sn.instance_number
                 , rollup(to_char(begin_interval_time,'YYYYMMDD-HH24'))
                 , sql.sql_id
                 , parsing_schema_name
                 , plan_hash_value
         order  by 1,2,3,4
       ) sub, tot, tm
 where tm.instno  = tot.instno(+)
   and tm.time    = tot.time(+) -- and 1 = 0
   and tm.instno  = sub.instno(+)
   and tm.time    = sub.time(+)
   and (rk <= &&top_n_sql or
        rkc <= &&top_n_sql or
        rki <= &&top_n_sql or
        rkb <= &&top_n_sql or
        rkd <= &&top_n_sql or
       (rkr <= &&top_n_sql AND '&is_rac' = 'YES') or
        rkx <= &&top_n_sql)
 order by tm.instno, tm.time, rk
;


prompt [End of documents]
select 'Complete time : '||to_char(sysdate, 'YYYY/MM/DD HH24:MI:SS') from dual;
--------------------------------------------------------------------------------
-- Spool off of Main output file
spool off

SET TERMOUT ON
prompt
prompt Data gathering completed!!!
prompt
quit

--------------------------------------------------------------------------------
