#此函数已废弃
#用于解析telnet返回结果中表格形式的输出值：
#  Slot Shelf Type    Port  HardVer          SoftVer          Status      
#----------------------------------------------------------------------
#  1    1     V24B    24    090201           V1.0.0P4T3       Inservice   
#  2    1     MSEBA   24    090201           V1.0.0P4T3       Inservice   
#  3    1     GNI     2     090201           V1.0.0P4T3       Inservice   
#----------------------------------------------------------------------
#
#解析后的结果按数组返回，数组的第一项为表格的表头，后项为对应的数据，如：
# ['slot', 'shelf', 'Port', 'HardVer', 'SoftVer', 'Status']
# ['1', '1', 'v24B', '24', '090201', 'v1.0.0P4T3', 'Inservice']
# ['2', '1', 'MSEBA', '24', '090201', 'V1.0.0P4T3', 'Inservice']
#
def retrieve_table_info(input_str, seperator = /-{30,}/)
  result,table_title, table_data, sep_line_num = [], [], [],[]
  lines = input_str.split("\n")
  0.upto(lines.length - 1){ |v| sep_line_num << v if lines[v] =~ seperator}
  return nil if sep_line_num.empty?
  table_title = lines[sep_line_num[0] - 1].split(' ')
  (sep_line_num[0]+1).upto(sep_line_num[1]-1) { |i| table_data << lines[i].split(' ')   }
  result << table_title << table_data
end


#
#用于解析telnet返回的结果中使用seperator分隔形式的输出：
#AdminStatus                            : enable
#TrapControl                            : disable
#LinkStatus                             : down
#IngressFilter                          : discard
#MaxMacLearn                            : unlimited
#
#默认的分隔符设置为":"
#解析后的结果将会以hash的形式返回，如：
#result['AdminStatus'] = 'enable'
#result['TrapControl'] = 'disable'
#
def retrieve_pair_info(input_str, seperator = ':')
  result = {}
  input_str.each_line do |line|
    if line=~/:/
      pair = line.split(':').each{|v| v.strip!}
      result[pair[0]] = pair[1]
    end
  end
  result
end

#
#用于处理一行中包含多个seperator的情况
#如：
#Dynamic-profile       Index:    -      Name: -
#如应解析成 
# [ Dynamic-profile Index  =>  - ,
#   Dynamic-profile Name   =>  - ]
def retrieve_multi_pair(str, seperator=':')
  result = {}
  str.strip!
  return result if str.count(seperator) < 1
  return retrieve_pair_info(str, seperator) if str.count(seperator) == 1

  header = str.split(' ')[0]
  tail =  str.split(header)[1].strip
  pairs = tail.split(/\s{2,}/).collect{ |t| "#{header} #{t}"  }
  
  pairs.each{ |pair| result.update(retrieve_pair_info(pair))  }
  result
end

