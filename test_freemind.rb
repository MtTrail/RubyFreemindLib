#! ruby -Ku -EUTF-8
# -*- mode:ruby; coding:utf-8 -*-

require 'rubygems'
require 'minitest/unit'
require './freemind'

class String
  def s
    self.encode('Windows-31J')
  end
end

MiniTest::Unit.autorun
class TestFreemind < MiniTest::Unit::TestCase

  FILE_WI = 'test_with_name.mm'
  FILE_WO = 'test_without_name.mm'
  FILE_SP = '  '

  
  def remove_test_files
    File.delete(FILE_WI) if File.exist?(FILE_WI)
    File.delete(FILE_WO) if File.exist?(FILE_WO)
  end
  
  def setup
    remove_test_files
  end
  
  def teardown
    remove_test_files
  end
  
  def test_open_and_save_without_filename
    fm = Freemind.open()
    assert((fm != nil),"ファイル名なしでのopen失敗".s)
    assert_instance_of(Freemind,fm,"ファイル名なしでのopenの戻り値がFreemindオブジェクトでない".s)
    assert((fm.mm_file_name == nil),"ファイル名なしでのopenで内部ファイル名が空でない".s)
    assert((fm.root.fme_get_text == "root"),"初期化時のルートノードのTEXT値がrootでない".s)
    f_name = fm.save(FILE_WO)
    assert((f_name == FILE_WO),"saveで返された書込みファイル名が異なる".s)
    assert(File.exist?(FILE_WO),"saveでファイルが作られていない".s)
  end

  def test_open_and_save_with_filename
    fm = Freemind.open(FILE_WI)
    assert((fm != nil),"ファイル名有りでの新規open失敗".s)
    assert_instance_of(Freemind,fm,"ファイル名ありでのopenの戻り値がFreemindオブジェクトでない".s)
    assert((fm.mm_file_name == FILE_WI),"ファイル名ありでのopenで内部ファイル名が指定値でない".s)
    assert((fm.root.fme_get_text == "root"),"初期化時のルートノードのTEXT値がrootでない".s)
    f_name = fm.save()
    assert((f_name == FILE_WI),"saveで返された書込みファイル名が異なる".s)
    assert(File.exist?(FILE_WI),"saveでファイルが作られていない".s)
    t1 = fm.root.fme_get_xml_attr("created")
    assert((t1 != nil),"生成時刻が無い".s)
    fm = Freemind.open(FILE_WI)
    t2 = fm.root.fme_get_xml_attr("created")
    print "#{t1} --> #{t2}\n"
    assert((fm != nil),"ファイル名有りでの既存open失敗".s)
    assert((t1 == t2),"ファイル名有りでの既存openで生成時刻が変化している".s)
  end

  def test_open_and_save_with_block
    t1 = ""
    Freemind.open(FILE_WI) do |fm,root|
      assert((fm != nil),"ファイル名有りでの新規open失敗".s)
      assert_instance_of(Freemind,fm,"ファイル名ありでのopenの戻り値がFreemindオブジェクトでない".s)
      assert((fm.mm_file_name == FILE_WI),"ファイル名ありでのopenで内部ファイル名が指定値でない".s)
      assert((root.fme_get_text == "root"),"初期化時のルートノードのTEXT値がrootでない".s)
      f_name = fm.save()
      assert((f_name == FILE_WI),"saveで返された書込みファイル名が異なる".s)
      assert(File.exist?(FILE_WI),"saveでファイルが作られていない".s)
      t1 = root.fme_get_xml_attr("created")
      assert((t1 != nil),"生成時刻が無い".s)
    end
    
    Freemind.open(FILE_WI) do |fm,root|
      t2 = root.fme_get_xml_attr("created")
      print "#{t1} --> #{t2}\n"
      assert((fm != nil),"ファイル名有りでの既存open失敗".s)
      assert((t1 == t2),"ファイル名有りでの既存openで生成時刻が変化している".s)
    end
  end

  def test_open_and_save_with_space_filename
    fm = Freemind.open(FILE_SP)
    assert((fm != nil),"ファイル名有りでの新規open失敗".s)
    assert_instance_of(Freemind,fm,"ファイル名ありでのopenの戻り値がFreemindオブジェクトでない".s)
    assert((fm.mm_file_name == FILE_SP),"ファイル名ありでのopenで内部ファイル名が指定値でない".s)
    f_name = fm.save()
    assert((f_name == nil),"空白のファイル名でsaveしてしまった".s)
    assert(!File.exist?(FILE_SP),"saveで空白ファイル名のファイルが作られてしまった".s)
    f_name = fm.save(FILE_WI)
    assert(File.exist?(FILE_WI),"再saveでファイルが作られていない".s)
  end
  
  def test_node_operation
    fm = Freemind.open()
    c1 = fm.root.fme_add_child("Child1")
    assert((c1 != nil),"子ノードの追加が失敗した".s)
    assert((c1.fme_get_text == "Child1"),"生成されたノード名が異なる".s)
    c1_1 = c1.fme_add_child("Child1_1")
    assert((c1_1 != nil),"子ノードの追加が失敗した".s)
    assert((c1_1.fme_get_text == "Child1_1"),"生成されたノード名が異なる".s)
    assert((fm.mm.search("//node/node/node").first.fme_get_text == 'Child1_1'),"nodeのリンクが正しくない".s)

    c2 = fm.root.fme_add_child("Child2")
    assert((c2 != nil),"子ノードの追加が失敗した".s)
    assert((c2.fme_get_text == "Child2"),"生成されたノード名が異なる".s)
    c2_1 = c2.fme_add_child("Child2_1")
    assert((c2_1 != nil),"子ノードの追加が失敗した".s)
    assert((c2_1.fme_get_text == "Child2_1"),"生成されたノード名が異なる".s)
    assert((fm.mm.search("//node/node/node")[1].fme_get_text == "Child2_1"),"nodeのリンクが正しくない".s)
    c1.fme_add_icon("stop")
    c1.fme_add_icon("yes")
    c2.fme_add_icon("yes")
    c1.fme_add_arrowlink(c2,"#ff0000")
    fm.root.children.each do |node|
      attr = node.fme_attributes
      case node.fme_get_text
      when "Child1"
        assert(attr['icon'].grep("yes"),"icon未登録".s)
        assert(attr['icon'].grep("stop"),"icon未登録".s)
        assert((attr['arrowlink'][0][2] == "#ff0000"),"arrowlinkの色が違う".s)
      when "Child2"
        assert(attr['icon'].grep("yes"),"icon未登録".s)
      end
    end
  end

  def test_node_operation_with_block
    Freemind.open do |fm,root|
      c1 = root.fme_add_child("Child1")
      assert((c1 != nil),"子ノードの追加が失敗した".s)
      assert((c1.fme_get_text == "Child1"),"生成されたノード名が異なる".s)
      c1_1 = c1.fme_add_child("Child1_1")
      assert((c1_1 != nil),"子ノードの追加が失敗した".s)
      assert((c1_1.fme_get_text == "Child1_1"),"生成されたノード名が異なる".s)
      assert((root.search("//node/node/node").first.fme_get_text == 'Child1_1'),"nodeのリンクが正しくない".s)

      c2 = root.fme_add_child("Child2")
      assert((c2 != nil),"子ノードの追加が失敗した".s)
      assert((c2.fme_get_text == "Child2"),"生成されたノード名が異なる".s)
      c2_1 = c2.fme_add_child("Child2_1")
      assert((c2_1 != nil),"子ノードの追加が失敗した".s)
      assert((c2_1.fme_get_text == "Child2_1"),"生成されたノード名が異なる".s)
      assert((root.search("//node/node/node")[1].fme_get_text == "Child2_1"),"nodeのリンクが正しくない".s)
      c1.fme_add_icon("stop")
      c1.fme_add_icon("yes")
      c2.fme_add_icon("yes")
      c1.fme_add_arrowlink(c2,"#ff0000")
      root.children.each do |node|
        attr = node.fme_attributes
        case node.fme_get_text
        when "Child1"
          assert(attr['icon'].grep("yes"),"Child1 icon(yes)未登録".s)
          assert(attr['icon'].grep("stop"),"Child1 icon(stop)未登録".s)
          assert((attr['arrowlink'][0][2] == "#ff0000"),"Chaild1 arrowlinkの色が違う".s)
        when "Child2"
          assert(attr['icon'].grep("yes"),"Child2 icon(yes)未登録".s)
        end
      end
    end
  end

  def test_each_procedure
    Freemind.open do |fm,root|
      # ------------------------
      # 初期状態で生成されている
      # ------------------------
      # fme_have_child?  
      # fme_add_child   
      # fme_children   
      # fme_remove  
      # fme_get_text  
      assert((root.fme_have_child? == nil),'fm_have_child? が子ノード無しのときにnilを返さなかった'.s)
      c1 = root.fme_add_child('Child1')
      assert((c1 != nil),'fme_add_childで子ノードがテキスト指定で作れなかった'.s)
      assert((root.fme_have_child? != nil),'fm_have_child? が子ノードが有る時にnilを返した'.s)
      assert((c1.fme_get_text == 'Child1'),'fme_add_childでテキスト指定で作った c1 子ノードのテキスト値が正しくない'.s)
      c2 = root.fme_add_child('Child2')
      assert((c2 != nil),'fme_add_childでrootの下に2個目の子ノードがテキスト指定で作れなかった'.s)
      assert((root.fme_children.size == 2),'fme_childrenが返す子ノードの数が間違っている'.s)
      c2.fme_remove
      assert((root.fme_children.size == 1),'fme_removeで c2 子ノードが消せなかった'.s)
      c1.fme_remove
      assert((root.fme_children.size == 0),'fme_removeで c1 子ノードが消せなかった'.s)
      cc1 = root.fme_add_child(c1)
      
      cc2 = root.fme_add_child(c2)
      assert((c1 != nil),'fme_add_childで子ノードがノードオブジェクト指定で作れなかった'.s)
      assert((cc1.fme_get_text == 'Child1'),'fme_add_childでノード指定で作った cc1 子ノードのテキスト値が変わっている'.s)
      assert((cc2.fme_get_text == 'Child2'),'fme_add_childでノード指定で作った cc2 子ノードのテキスト値が変わっている'.s)
      
      
      # ------------------------
      # rootの下に子ノード2個の状態
      # ------------------------
      # fme_add_icon   
      # fme_have_icon?  
      # fme_remove  
      assert((c1.fme_have_icon?('yes') == nil),'fme_have_icon? がアイコン無しの時にnilを返さない'.s)
      icon1 = c1.fme_add_icon('yes')
      assert((icon1 != nil),'fme_add_iconで c1に yesアイコンが登録できなかった'.s)
      assert((c1.fme_have_icon?('yes') != nil),'fme_have_icon? がアイコンありの時にnilを返した'.s)

      assert((c2.fme_have_icon?('idea') == nil),'fme_have_icon? がアイコン無しの時にnilを返さない'.s)
      icon2 = c2.fme_add_icon('idea')
      assert((icon2 != nil),'fme_add_iconで c2に ideaアイコンが登録できなかった'.s)
      assert((c2.fme_have_icon?('idea') != nil),'fme_have_icon? がアイコンありの時にnilを返した'.s)
      
      icon2.fme_remove
      assert((c2.fme_have_icon?('idea') == nil),'fme_remove でアイコンが消せない'.s)
      
      # fme_add_attribute   
      # fme_attribute?   
      # fme_remove  
      assert((c2.fme_attribute?('x').size == 0),'fme_attribute? が指定した属性無しの時に空でない配列を返す'.s)
      attr1 = c2.fme_add_attribute('x','1')
      assert((attr1 != nil),'fme_add_attribute で x 属性が登録できない'.s)
      attr2 = c2.fme_add_attribute('x','2')
      assert((attr2 != nil),'fme_add_attribute で2個目の x 属性が登録できない'.s)
      x = c2.fme_attribute?('x')
      assert((x.size == 2),'fme_attribute? 登録した属性 x の数が正しくない'.s)
      assert((x[0] == '1'),'fme_attribute? 登録した属性 x[0] の値が正しくない、または順序が異なる'.s)
      assert((x[1] == '2'),'fme_attribute? 登録した属性 x[1] の値が正しくない、または順序が異なる'.s)
      attr2.fme_remove
      assert((c2.fme_attribute?('x').size == 1),'fme_remove 登録した属性 x を削除できない'.s)
      
      # fme_add_arrowlink
      # fme_arrowlinks   
      # fme_remove  
      assert((c1.fme_arrowlinks.size == 0),'fme_arrowlinksの返す矢印リンク数が正しくない c1:0'.s)
      c3 = root.fme_add_child('Child3')
      arrow1 = c1.fme_add_arrowlink(c2,'#FF0000')
      assert((arrow1 != nil),'fme_add_arrowlink で c1->c2に 矢印リンクが追加できない'.s)
      arrow2 = c1.fme_add_arrowlink(c3,'#000000')
      assert((arrow2 != nil),'fme_add_arrowlink で c1->c3に 矢印リンクが追加できない'.s)
      arrow3 = c3.fme_add_arrowlink(c2,'#000000')
      assert((arrow3 != nil),'fme_add_arrowlink で c3->c2に 矢印リンクが追加できない'.s)
      assert((c1.fme_arrowlinks.size == 2),'fme_arrowlinksの返す矢印リンク数が正しくない c1:2'.s)
      assert((c2.fme_arrowlinks.size == 0),'fme_arrowlinksの返す矢印リンク数が正しくない c2:0'.s)
      assert((c3.fme_arrowlinks.size == 1),'fme_arrowlinksの返す矢印リンク数が正しくない c3:1'.s)
      arrow2.fme_remove
      assert((c1.fme_arrowlinks.size == 1),'fme_removeで矢印リンクが消せない'.s)


      # fme_add_remind   
      # fme_get_remind  
      t1 = Time.new(2012,1,1,0,1,2)
      c1.fme_add_remind(t1)
      assert((c1.fme_get_remind == t1),'fme_add_remind / fme_get_remind リマインドの設定が正しくない'.s)
      t2 = Time.new(2020,1,1,10,11,12)
      puts t2.to_s
      c1.fme_add_remind(t2)
      assert((c1.fme_get_remind == t2),'fme_add_remind / fme_get_remind リマインドの上書き設定が正しくない'.s)

      # fme_set_text  
      # fme_get_text  
      # fme_have_text?  
      # fme_set_richcontent  
      # fme_get_richcontent  
      c3.fme_set_text('Child3-replaced')
      assert((c3.fme_get_text == 'Child3-replaced'),'fme_set_text/fme_get_text 置き換えが正しくない'.s)
      assert((c3.fme_have_text? != nil),'fme_have_text? テキストが有るのにnilを返した'.s)
      r1 = c3.fme_set_richcontent('NODE','<html><head /><body><p>RichContent Node</p><table border="1"><tr><td><p>1</p></td><td><p>2</p></td></tr></table></body></html>')
      assert((r1 != nil),'fme_set_richcontentでNODE設定できなかった'.s)
      assert((c3.fme_have_text? == nil),'fme_set_richcontentでの設定時にテキスト値が消されていない'.s)
      html = c3.fme_get_richcontent('NODE')
      assert((html =~ /RichContent Node/),'fme_get_richcontentで正しいNODE値が取れなかった'.s)

      r2 = c3.fme_set_richcontent('NOTE','<html><head /><body><p>RichContent Note</p><table border="1"><tr><td><p>a</p></td><td><p>b</p></td></tr></table></body></html>')
      assert((r2 != nil),'fme_set_richcontentでNOTE 設定できなかった'.s)
      html = c3.fme_get_richcontent('NOTE')
      assert((html =~ /RichContent Note/),'fme_get_richcontentで正しいNOTE値が取れなかった'.s)

      # fme_attributes   
      attrs = c1.fme_attributes
      

      # ------------------
      # 以下は内部的に使われているので個別にはテストしない
      # ------------------
      # fme_set_xml_attr  
      # fme_get_xml_attr  
      # fme_delete_xml_attr   
      # fme_make_arrow_id  
      # fme_make_id  
      # fme_node_info  
      # fme_stamp_time  
      # fme_time_stamp  
      # fme_time_stamp_at   
      
      fm.save('sample2.mm')
      
    end
  end
  
end


 