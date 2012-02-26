#! ruby -EWindows-31J
# -*- mode:ruby; coding:Windows-31J -*-

require './freemind'

def dump_node(node,level)
  print "#{level}node: #{node.fme_get_text} #{node.fme_get_xml_attr('id')} "
  print ", RichContent" if node.fme_get_richcontent('NODE')
  print ", NOTE" if node.fme_get_richcontent('NOTE')
  print "\n"
  
  level += '  '
  if t = node.fme_get_remind
    print "#{level}Remind: #{t}\n"
  end
  
  node.fme_attributes.each do |name,value|
    case name
    when 'arrowlink'
      value.each{|dt| print "#{level}ArrowLink to #{dt[1]}, color=#{dt[2]}\n"}
    when 'attribute'
      value.each{|dt| print "#{level}Attribute [ #{dt[1]} = #{dt[2]} ]\n"}
    when 'icon'
      value.each{|dt| print "#{level}#{name}      [ #{dt[1]} ]\n"}
    when 'hook'
      value.each do |dt|
        if dt[1] !~ /TimeManagementReminder/i
          print "#{level}#{name}      [ #{dt[1]} ]\n"
        end
      end
    else
      print "#{level}unknown #{name}\n"
    end
  end
  # print node.fme_get_richcontent('NODE')
  # print node.fme_get_richcontent('NOTE')

  node.fme_children.each do |cnode|
    dump_node(cnode,level)
  end
end

file_name = 'sample.mm'
File.delete(file_name) if File.exist?(file_name)

# ファイルが無ければrootノードだけを持つ初期状態としてopenされる。
Freemind.open(file_name) do |fm,root|
  c1 = root.fme_add_child('Child1')
  c2 = root.fme_add_child('Child2')
  c2.fme_add_icon('idea')
  c2_1 = c2.fme_add_child('')
  c2_1.fme_set_richcontent('NODE','<html><head /><body><p>RichContent Node</p><table border="1"><tr><td><p>1</p></td><td><p>2</p></td></tr></table></body></html>')
  c2_1.fme_set_richcontent('NOTE','<html><head /><body><p>test code</p><table border="1"><tr><td><p>x</p></td><td><p>y</p></td></tr></table></body></html>')
  c2_1.fme_add_icon('button_ok')
  c2_1.fme_add_remind(Time.new(2012,1,1,9,0,0))
  c2_1.fme_add_attribute('x','1')
  c1.fme_add_arrowlink(c2,'#ff0000')
  
  dump_node(root,'')
  root.search("//node/icon[@BUILTIN='idea']/..").each do |node|
    if [] == node.fme_attribute?('HasIdea')
      node.fme_add_attribute('HasIdea','Yes') 
    end
    print "#{node.fme_get_text} has Idea icon ,HasIdea attribute = #{node.fme_attribute?('HasIdea')}\n"
  end
  fm.save
end
