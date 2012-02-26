#! ruby -Eutf-8
# -*- mode:ruby; coding:utf-8 -*-

#  Freemind class library for Ruby 1.9
#
# Ver, 1.00 2012/02/14 : Designed by Mt.Trail (Renewal for Ruby 1.9 with nokogiri)
#
# Ruby 1.9系とNokogiriを使って書き直しました。
# UTF8環境で使用してください。
# Freemind用のクラス'Freemind'とNokogiriにFreemind用の機能を拡張する'Freemind_Extension'モジュールで
# 構成されます。
#
# memo : rdoc -N -S -c utf-8 -t Freemind freemind.rb
#
#= 使用例
#
#  Freemindのファイル名samplet.mmとします。
# ------------------------------------------------------------------
# #! ruby -EWindows-31J
# # -*- mode:ruby; coding:Windows-31J -*-
# 
# require './freemind'
# 
# def dump_node(node,level)
#   print "#{level}node: #{node.fme_get_text} #{node.fme_get_xml_attr('id')} "
#   print ", RichContent" if node.fme_get_richcontent('NODE')
#   print ", NOTE" if node.fme_get_richcontent('NOTE')
#   print "\n"
#   
#   level += '  '
#   if t = node.fme_get_remind
#     print "#{level}Remind: #{t}\n"
#   end
#   
#   node.fme_attributes.each do |name,value|
#     case name
#     when 'arrowlink'
#       value.each{|dt| print "#{level}ArrowLink to #{dt[1]}, color=#{dt[2]}\n"}
#     when 'attribute'
#       value.each{|dt| print "#{level}Attribute [ #{dt[1]} = #{dt[2]} ]\n"}
#     when 'icon'
#       value.each{|dt| print "#{level}#{name}      [ #{dt[1]} ]\n"}
#     when 'hook'
#       value.each do |dt|
#         if dt[1] !~ /TimeManagementReminder/i
#           print "#{level}#{name}      [ #{dt[1]} ]\n"
#         end
#       end
#     else
#       print "#{level}unknown #{name}\n"
#     end
#   end
#   # print node.fme_get_richcontent('NODE')
#   # print node.fme_get_richcontent('NOTE')
# 
#   node.fme_children.each do |cnode|
#     dump_node(cnode,level)
#   end
# end
# 
# file_name = 'sample.mm'
# File.delete(file_name) if File.exist?(file_name)
# 
# # ファイルが無ければrootノードだけを持つ初期状態としてopenされる。
# Freemind.open(file_name) do |fm,root|
#   c1 = root.fme_add_child('Child1')
#   c2 = root.fme_add_child('Child2')
#   c2.fme_add_icon('idea')
#   c2_1 = c2.fme_add_child('')
#   c2_1.fme_set_richcontent('NODE','<html><head /><body><p>RichContent Node</p><table border="1"><tr><td><p>1</p></td><td><p>2</p></td></tr></table></body></html>')
#   c2_1.fme_set_richcontent('NOTE','<html><head /><body><p>test code</p><table border="1"><tr><td><p>x</p></td><td><p>y</p></td></tr></table></body></html>')
#   c2_1.fme_add_icon('button_ok')
#   c2_1.fme_add_remind(Time.new(2012,1,1,9,0,0))
#   c2_1.fme_add_attribute('x','1')
#   c1.fme_add_arrowlink(c2,'#ff0000')
#   
#   dump_node(root,'')
#   root.search("//node/icon[@BUILTIN='idea']/..").each do |node|
#     if [] == node.fme_attribute?('HasIdea')
#       node.fme_add_attribute('HasIdea','Yes') 
#     end
#     print "#{node.fme_get_text} has Idea icon ,HasIdea attribute = #{node.fme_attribute?('HasIdea')}\n"
#   end
#   fm.save
# end
# 
# 
#

require 'rubygems'
require 'nokogiri'

$debug = false

#
# Nokogiri用 Freemind拡張モジュール
#
module Freemind_Extension

  
  #
  # fme_time_stamp: 現在の時刻を秒+msの文字列で返す
  def fme_time_stamp
    fme_time_stamp_at(Time.now)
  end
  
  #
  # fme_make_id: オブジェクトIDを乱数で作成する
  def fme_make_id
    'ID_'+rand(10000000000).to_s
  end

  #
  # fme_node_info: ノードの管理情報を返す
  def fme_node_info
    t = fme_time_stamp
    id = fme_make_id
    "CREATED='#{t}' ID='#{id}' MODIFIED='#{t}'"
  end
  
  #
  # fme_children: 子ノードを取り出す
  # 戻り値は子ノートオブジェクトの配列
  def fme_children
    self.search("./node")
  end
  
  #
  # fme_attributes: 属性を取り出す
  # 戻り値はNokogiriオブジェクトを含む配列の配列のハッシュ
  # 属性nodeを含む配列は種別ごとに出現順となる
  #* ret[:arrowlink] = [[node,接続先ID,色], ...]
  #* ret[:attribute] = [[node,名前,値], ...]
  #* ret[:icon]      = [[node,icon名], ...]
  #* ret[その他]     = [[node], ...]
  # マインドマップの子ノードとノート部分は無視する。
  # またXMLとして評価しているので改行が余計なtextノードとして出てくるのも無視する。
  def fme_attributes
    cn = {}
    ['arrowlink','attribute','hook','icon'].each {|x| cn[x] = []}
    
    self.children.each do |node|
      name = node.name.downcase
      case name
      when 'node','richcontent','text'
        next
      when 'arrowlink'
        cn['arrowlink'] << [node,node.fme_get_xml_attr('destination'),node.fme_get_xml_attr('color')]
      when 'attribute'
        cn['attribute'] << [node,node.fme_get_xml_attr('name'),node.fme_get_xml_attr('value')]
      when 'hook'
        cn['hook'] << [node,node.fme_get_xml_attr('name')]
      when 'icon'
        cn['icon'] << [node,node.fme_get_xml_attr('builtin')]
      else
        cn[name]=[] if !cn.key?(name)
        cn[name] << [node]
      end
    end
    cn
  end
  
  #
  # fme_set_xml_attr: XMLベースの属性値を設定する。
  # 大文字小文字の区別がされるため属性名を大文字小文字で調べて入れる、混在は無視する。
  def fme_set_xml_attr(name,value)
    if self[name.upcase]
      self[name.upcase] = value
    else
      self[name.downcase] = value
    end
  end
  
  #
  # fme_get_xml_attr: XMLベースの属性値を返す。
  # 大文字小文字の区別がされるため属性名を全て大文字または全て小文字で調べて取り出す、混在は無視する。
  def fme_get_xml_attr(name)
    return self[name.upcase] if self[name.upcase]
    self[name.downcase]
  end
  
  #
  # fme_delete_xml_attr: XMLベースの属性値を削除する。
  # 大文字小文字の区別がされるため属性名を全て大文字または全て小文字で調べて削除する、混在は無視する。
  def fme_delete_xml_attr(name)
    return self.delete(name.upcase) if self[name.upcase]
    self.delete(name.downcase)
  end
  
  
  #
  # fme_set_text: nodeのテキスト値を設定する
  def fme_set_text(str)
    fme_set_xml_attr('text',str)
  end
  
  #
  # fme_get_text: nodeのテキスト値を返す、無ければnilが返される。
  def fme_get_text
    fme_get_xml_attr('text')
  end

  #
  # fme_have_text?: ノードにテキストが有るか検査、無い場合にはNODEタイプのリッチコンテントが有ると思われる。
  # 無ければnil、有ればtext値が返される。
  def fme_have_text?
    fme_get_xml_attr('text')
  end
  
  #
  # fme_set_richcontent: nodeのリッチコンテント値を設定する
  # type1は'NODE'または'NOTE'
  def fme_set_richcontent(type,html)
    self.search("./richcontent[@TYPE='#{type}']").each do |node|
      node.remove
    end
    
    self.delete('TEXT') if type == 'NODE'
    add_child("<richcontent TYPE='#{type}'>#{html}</richcontent>").first
  end
  
  #
  # fme_get_text: nodeのリッチコンテント値を返す
  # type1は'NODE'または'NOTE'
  def fme_get_richcontent(type)
    html = nil
    t = self.search("./richcontent[@TYPE='#{type}']").first
    html = t.inner_html if t
    html
  end
  
  #
  # fme_remove: 要素の削除(node,icon,attribute,etc.)
  # 注意　ノードタイプのrichcontentの削除時はテキスト値を設定する事
  def fme_remove
    remove()
  end
  
  #
  # fme_add_child: 子ノードの追加
  # テキストを指定して追加、またはノードオブジェクトを指定して追加する
  def fme_add_child(str)
    node = nil
    if str.class.to_s == 'String'
      node = add_child("<node #{fme_node_info} TEXT='#{str.encode('UTF-8')}'></node>").first
    else
      node = add_child(str).first
      if node[0] == 'CREATED'
        node = str
      else
        node = nil
      end
    end
    node
  end

  #
  # fme_have_child?: 子ノードが有るか検査、無ければnilを返す、有れば先頭の子ノードオブジェクトを返す。
  def fme_have_child?
    self.search("./node").first
  end
  
  #
  # fme_add_icon: アイコン追加、アイコン名での追加のみをサポート
  # 追加したアイコンノードを返す、追加できなければnilを返す。
  def fme_add_icon(icon_name)
    add_child("<icon BUILTIN='#{icon_name.encode('UTF-8')}' />").first
  end

  #
  # fme_have_icon?: 指定したiconが有るか検査(大文字小文字を別のものとして扱う)
  # 無ければnilを返す、有れば先頭のiconノードオブジェクトを返す
  def fme_have_icon?(name)
    self.search("./icon[@BUILTIN='#{name}']").first
  end
  
  #
  # fme_add_attribute: 属性追加
  # 追加した属性ノードを返す、追加できなければnilを返す。
  def fme_add_attribute(name,value)
    add_child("<attribute NAME='#{name.to_s.encode('UTF-8')}' VALUE='#{value.to_s.encode('UTF-8')}' />").first
  end
  
  #
  # fme_attribute?: 指定した属性を取り出す。
  # 同じ名前の物が複数存在可能なので取り出した値は配列で返す
  def fme_attribute?(name)
    self.search("./attribute[@NAME='#{name}']").map{|x| x.fme_get_xml_attr('VALUE')}
  end
  
  #
  # fme_make_arrow_id: 矢印用のIDを返す
  def fme_make_arrow_id
    'Arrow_'+fme_make_id
  end
  
  #
  # fme_add_arrowlink: 矢印リンクを追加する。
  # 追加した矢印リンクノードを返す、追加できなければnilを返す。
  # 色以外の属性はサポートしないので必要なら別途自分で操作して下さい。
  def fme_add_arrowlink(to_mm,color)
    add_child("<arrowlink COLOR='#{color}' DESTINATION='#{to_mm.fme_get_xml_attr('id')}' ENDARROW='Default' ENDINCLINATION='30;0;' ID='#{fme_make_arrow_id}' STARTARROW='None' STARTINCLINATION='30;0;'/>").first
  end
  
  #
  # fme_arrowlinks: 矢印を取り出す。
  # 矢印リンクノードの配列を返す。無ければサイズ0の配列となる。
  def fme_arrowlinks
    self.search("./arrowlink")
  end
  
  #
  # fme_time_stamp_at: 指定された時刻をあらわす数値を返す
  def fme_time_stamp_at(time)
    sprintf("%010d%03d",time.tv_sec,time.tv_usec/1000)
  end
  
  #
  # fme_add_remind: 指定された時刻をリマインドに設定する。
  def fme_add_remind( time )
    done = false
    self.search("./hook[@NAME='plugins/TimeManagementReminder.xml']").each do |node|
      node.search("./Parameters").each do |p|
        p.fme_set_xml_attr('REMINDUSERAT',fme_time_stamp_at(time))
      end
    end
    if !done
      self.add_child("<hook NAME='plugins/TimeManagementReminder.xml'>
<Parameters REMINDUSERAT='#{fme_time_stamp_at(time)}' />
</hook>")
    end
  end
  
  #
  # fme_stamp_timeは数値化された文字列の時刻をTimeオブジェクトに変換したものを返す。
  def fme_stamp_time(str)
    Time.at(str[0..9].to_i,(str[10..12]+'000').to_i)
  end
  
  #
  # fme_get_remind: リマインドが指定されていれば時刻を返す。
  # 指定されていなければnilを返す。
  def fme_get_remind
    t = nil
    self.search("./hook[@NAME='plugins/TimeManagementReminder.xml']/Parameters").each do |p|
      t = fme_stamp_time(p.fme_get_xml_attr('REMINDUSERAT'))
    end
    t
  end

end

class Nokogiri::XML::Element
  include Freemind_Extension
end



#
# Freemind操作用クラス
#
class Freemind

  # @mm_file_nameはFreemindのファイル名
  attr_accessor :mm_file_name
  
  # @mmはFreemindをNokogiriで解析したオブジェクト
  attr_accessor :mm
  
  # @rootはルートノードオブジェクト
  attr_accessor :root

  # 初期化 : 特に何もしない
  def initialize()
  end

  # Freemindの初期ファイルを生成する
  def create_new_mm
    mm = <<EOF_TEXT
<map version="0.9.0">
</map>
EOF_TEXT
    @mm = Nokogiri::XML(mm)
    @mm.search("/map").first.fme_add_child('root')
  end
  
  #
  # Freemind.open : 
  #   ファイルが指定されればそのファイルを開いてNokogiriで解析する。
  #   指定ファイルが無ければ新規ファイルと見なして初期ファイルを生成してNokogiriで解析する。
  #   ただし、openでは書込みを実行しないのでsaveを実行するまでファイルは生成されない。
  #   ファイル名が指定されなければ初期ファイルを生成してNokogiriで解析する。
  def Freemind.open(mm_file_name = nil)
    fm = self.new
    p mm_file_name if $debug
    fm.mm_file_name = mm_file_name
    if mm_file_name.class.to_s == 'String'
      if File.exist?(mm_file_name)
        File.open(mm_file_name) do |f|
          fm.mm = Nokogiri::XML(f)
        end
      else
        fm.create_new_mm()
      end
    else
      fm.create_new_mm()
    end
    fm.root = fm.mm.search("/map/node").first
    
    if block_given?
      yield fm,fm.root
    end
    fm
  end

  #
  # to_xml: 標準のXMLからFreemindで使っていない部分を削除する。
  def to_xml
    @mm.to_xml.sub(/^<\?xml version="1.0"\?>\n/,'')
  end

  #
  # save: 
  #  指定されたファイル名でFreemindのファイルとして書き出す。
  #  ファイル名が指定されなかった場合、open時に指定されていればその名前で上書きする。
  #  open時にも指定されていなければエラーメッセージを出すだけで、書込みは実施しない。
  def save(mm_file_name=nil)
    @mm_file_name = mm_file_name if mm_file_name
    if (@mm_file_name == nil) or (@mm_file_name =~ /^\s*$/)
      print "File name is not given\n"
      return nil
    else
      File.open(@mm_file_name,'w'){|f| f << to_xml }
    end
    @mm_file_name
  end

  def dump
    print "----- Freemind data dump -----\n"
    p @mm
    print "------------------------------\n\n"
  end
end

 