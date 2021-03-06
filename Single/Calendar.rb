#==============================================================================
# ** 虚拟日历
#  作者：影月千秋
#  适用：VA
#  要求：Smomo脚本核心 1.0+
#------------------------------------------------------------------------------
# * 简介：
#  模拟时间流逝，并在地图（菜单）进行显示
#  可以自定义计时规则和显示效果
#  请为本脚本准备变量和开关，在下方进行设定
#  本脚本需要Smomo脚本核心，请到此下载：http://tinyurl.com/l9kvg2p
#  如果链接失效，请到rm.66rpg.com，@余烬之中 或 @影月千秋
#------------------------------------------------------------------------------
# * 使用方法：
#  将此脚本插入到其他脚本以下，Main以上，在下面给出的设定区进行设定后即可
#  在事件中操作指定的变量和开关，便可以获取和改变时间
#  也可以通过事件脚本进行操作
#  允许的脚本呼叫：
#    Smomo.calendar(type) 取得日历的内部数据
#   参数说明：type 想要获得的数据名
#       【:all】 获取所有数据的数组 依次为：时段 色调 刷新标志 周期历时 周期序号
#       【:zone】获取当前时段的名称（如："早晨"）
#       【:tone】不常用，获取当前色调（Tone色调类的实例）
#       【:need_change】没有任何实用意义，不常用，可以获取需要刷新的标志
#       【:period】当前周期经过的时间（如：1366）
#       【:prd】当前周期的序号，对应在周期名字（如:3）
#       【:pname】当前周期的名字，与prd是对应的（如:周三）
#   例：【Smomo.calendar(:zone)】获取时段名
#  对于插件脚本：
#   可以使用【Smomo::Calendar.routine.push(某方法)】来向列表中添加新方法
#   例：【Smomo::Calendar.routine.push(lambda{ puts "一天过去了" })】
#   列表中的方法会在一个时段周期结束时被调用
#   有关时段周期，请参阅112行及以下
#  更多内容，示例工程，请来发布帖查看：
#   http://rm.66rpg.com/thread-330684-1-1.html
#------------------------------------------------------------------------------
# * 版本
#   V 3.4 2016.08.01 增加了一个人性化的报错提示: 未设置 Speed 对应变量
#   V 3.3 2014.09.30 解决了时段计时与时间在变量干涉下不同步的问题
#   V 3.2 2014.09.07 添加了公共接口routine
#   V 3.1 2014.09.07 优化了室内地图的标记方式 修正了暂停计时时色调的转换问题
#   V 3.0 2014.07.31 修正了2.7以为成功实际上未修正成功的问题 并做了一些其他调整
#   V 2.9 2014.07.28 修正了Map不能为:none从2.3版延续过来的傻逼错误
#   V 2.8 2014.07.26 对2.7的小修正 并修改了自定义提示语
#   V 2.7 2014.07.24 修正了事件推进时不刷新周期的问题
#   V 2.6 2014.05.24 修正了日期出现0的BUG
#   V 2.5 2014.04.06 规范化脚本 消除冗余 重建逻辑结构 需要依赖Smomo脚本核心
#   V 2.4 2014.01.31 修正读档时报错的BUG
#   V 2.3 2014.01.29 可以自定义地图窗体的位置
#   V 2.2 2013.12.27 修正Window_MoVMe的错误
#   V 2.1 2013.12.15 修正过卡的BUG
#   V 2.0 2013.10.04 基本重写
#   V 1.0 2013.08.31 公开
#------------------------------------------------------------------------------
# * 声明：
#   本脚本由来自【影月千秋】，使用和转载请保留此信息
#==============================================================================

if $smomo["Core"].nil? || $smomo["Core"] < 1.0
  msgbox "请先安装Smomo脚本核心！"; %x!start http://tinyurl.com/l9kvg2p!
elsif $smomo["Calendar"].nil?
$smomo["Calendar"] = true

#==============================================================================
# ** Smomo::Calendar
#==============================================================================
module Smomo::Calendar
  Menu = true
  # 是否在菜单内显示日历
   # true 使用  false 不使用
   # 如果预设不能满足要求 请自行在下方自定义区更改
  
  Map = :bottom
  # 是否在地图上显示日历
   # :top 顶部  :bottom 底部  :none 不使用
   # 如果预设不能满足要求 请自行在下方自定义区更改
  
  Use = 16
  # 设定占用开关，只有当此开关打开时，才会计时
   # ！打开开关前 请确保下方Speed对应的变量不为0！
  
  Var = 81
  # 设定占用变量的起始编号 会占用以这个号码为开端的连续几个号码对应的游戏变量
  
  # 继续设置需要了解的事实：
  #  脚本内部用一个数字累加计时 然后依次推进到下一单位 把最开始的数字叫计时变量
  
  Speed = 100
  # 设定游戏时间进行速度占用变量，代表经过多少帧后游戏内部计时变量增加一
   # 一般情况下 1秒60帧
   # 再打开Use对应的开关前 请确保这个常量不为0
   # 请确保这个常量不与上面Var的常量（及其包括的范围内的变量）重合

  System = [
    # ["单位", 满多少进一（比最大值大一）, 是否以零起始（true/false）],
    ["分", 60, true],
    ["时", 24, true],
    ["日", 30],
    ["月", 12],
    ["年", 9999],
  ]
  # 设定计时制，最后一个数据的单位与计时变量的单位统一
   # 可以突破公元历法的限制
    # 比如：636号时间线3145纪6887年6月4日 21:39:44:03
   # ！这里有几项 上面的Var就会占用几个变量！
   # ！从上往下！ 单位由小到大 如：分-->时-->日-->月-->年
   # 有的单位允许以0为值 比如 3:00 有的不行 比如 3月1日
    # 默认不允许0值 如果需要允许 请将“以零起始”填为【true】
  
  Start = [23, 9, 1, 8, 2016]
  # 设置游戏起始时间 与上面的单位从上到下依次对应
  
  PeriodName = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
  # 日期的别名 每经过一个周期都会自动推进并显示下一个名字
   # 别名列表长度不固定 可以自行添加或缩短
   
  Start_PeriodName = 6
  # 确定游戏起始时的那个周期的别名是什么 0为第一个别名
   # 一定要用数字来指代 不要用"字符串"
  
  TimeZone = true
  # 是否启用时段功能， 即一个周期内是否有各时段的区分（如：凌晨-中午-黄昏-黑夜）
  
  Zone = [
  # [时段长度, Tone.new(红, 绿, 蓝, 灰), "名称"],
    [120, Tone.new( -75,-100,   0,  75), "夜晚"], # 0...120
    [120, Tone.new(-125,-125, -10, 125), "深夜"], # 120...240
    [120, Tone.new( -75,-100,   0,  75), "黎明"], # 240...360
    [300, Tone.new(   0,   0,   0,   0), "上午"], # 360...660
    [240, Tone.new(  50,  50,  10, -30), "中午"], # 660...900
    [120, Tone.new(   0,   0,   0,   0), "下午"], # 900...1020
    [120, Tone.new(  34, -34, -68, 170), "黄昏"], # 1020...1140
    [300, Tone.new( -75,-100,   0,  75), "夜晚"], # 1140...1440 则1440为周期长度
  ]
  # 设置时段周期内各时段的长度、色调及名称
   # 时段长度以计时变量的单位为单位
  # 到达对应时段时 会自动改变画面的色调
   # 【所有时段的长度加起来就是周期长度！】
   # 【所以，就算不需要使用时段功能，也一定要保证时段长度之和是一个合适的值！】
  # 当一次时段轮回完毕 就会推移到下一个周期（如：周三-->周四）
  
  IndoorMap = /<IndoorMap>/i
  # 用于匹配室内地图备注的正则式
   # 默认为/<IndoorMap>/i
   # 在地图的备注上写【<IndoorMap>】就可以标记其为室内地图
   # 不区分大小写
  # 处于室内地图时，不会受到时段色调的影响
  
  Format = {
    # 菜单用的格式
    menu: %W!
            <4年>.<2月>.<2日>
            \\I[234]___<Period>
            <2时>:<2分>_<Zone>
          !,
    # 地图用的格式
    map:  %W!
            \\I[234]公元<4年>年<2月>月<2日>日___<Period>___<Zone>_<2时>:<2分>
          !
  }
  # 输出格式 此处写多少行 游戏内就会依次对应输出多少行
   # 每一行的内部不要使用空格（ ），空格用下划线（_）代替
   # 尽量不要使用英文感叹号(!)，如果一定要用请在之前加上反斜杠（\!）
   # 使用【<符号>】的形式来代替指定的数据 其他的文字用于修饰
   # 可用的符号
    # 在上面计时制中设定的单位 可以加上一个数字来代表格式化位数
     # 如：<2时>:<2分> 显示 09:33 <时>:<分> 显示 9:33 
    # <Period> 当前周期的名字（如：星期三）
    # <Zone>   当前时段的名字（如：早晨）
   # 两个符号必须用两对<>分别括起来 不能写在同一对<>内
    # 允许使用转义字符 但是必须有两个反斜杠
     # 如 显示图标 \I[3] 应写成 \\I[3]
end

#==============================================================================
# 如果你懂脚本，可以在下面调整时间窗口的显示方式
#==============================================================================

#============================================================================
# ** Window_MoMenuCalendar 菜单画面中，显示当前游戏内部虚拟日历的窗口
#============================================================================
class Window_MoMenuCalendar < Window_Base
  include Smomo::Calendar
  
  def initialize(gold_window)
    unless $game_switches[Use]
      super(0, 0, 1, 1)
      self.opacity = 0
      return
    end
    Smomo::Calendar.ensure_time_legal
    Smomo::Calendar.check_period_and_zone
    height = Format[:menu].size * 30 + 20
    super(0, gold_window.y - height, gold_window.width, height)
    format = Smomo.deep_clone(Format[:menu])
    format.each_with_index do |t, l|
      t.gsub!(/_/){" "}
      System.each_with_index do |(u, m), i|
        t.gsub!(/<(\d*)#{u}>/){
          format("%0#{$1 ? $1.to_i : nil}d", $game_variables[Var + i])
        }
      end
      t.gsub!(/<Period>/){"#{PeriodName[Smomo::Calendar.prd]}"}
      t.gsub!(/<Zone>/){"#{Smomo::Calendar.zone}"}
      draw_text_ex(0, l * 30, t)
    end
  end
end
#============================================================================
# ** Window_MoMapCalendar 地图画面中，显示当前游戏内部虚拟日历的窗口
#                         但本质上是一个精灵
#============================================================================
class Window_MoMapCalendar < Window_Base
  include Smomo::Calendar
  
  def initialize
    height = Format[:map].size * 30 + 10
    @sprite = Sprite.new
    @sprite.y = Smomo::Calendar::Map == :top ? 0 : Graphics.height - height
    @sprite.bitmap = Bitmap.new Graphics.width, height
    @use = true
    update
    refresh
  end
  
  def update
    unless @use == $game_switches[Use]
      @use = $game_switches[Use]
      @sprite.x = @use ? 0 : Graphics.width
      refresh
    else
      if @use && $game_variables[Speed].zero?
        raise "请先将 Speed 对应变量设为非零值!"
      end
      refresh if @use && Graphics.frame_count % $game_variables[Speed] == 0 ||
      $game_map.need_refresh
    end
  end
  
  def dispose
    @sprite.bitmap.dispose if @sprite.bitmap
    @sprite.dispose
  end
  
  def refresh
    Smomo::Calendar.ensure_time_legal
    Smomo::Calendar.check_period_and_zone
    contents.clear
    contents.gradient_fill_rect(0, 0, @sprite.width, @sprite.height,
    Color.new(30, 30, 30), Color.new(0, 0, 0, 0))
    format = Smomo.deep_clone(Format[:map])
    format.each_with_index do |t, l|
      t.gsub!(/_/){" "}
      System.each_with_index do |(u, m), i|
        t.gsub!(/<(\d*)#{u}>/){
          format("%0#{$1 ? $1.to_i : nil}d", $game_variables[Var + i])
        }
      end
      t.gsub!(/<Period>/){"#{PeriodName[Smomo::Calendar.prd]}"}
      t.gsub!(/<Zone>/){"#{Smomo::Calendar.zone}"}
      draw_text_ex(0, l * 30 + 5, t)
    end
  end
  #------------------------------------------------------------------------
  # * 偷梁换柱 如果不明白这段的意义 请勿随意删除
  #------------------------------------------------------------------------
  def contents
    @sprite.bitmap
  end
  def windowskin
    Cache.system "Window"
  end
end
#==============================================================================
# ** Scene_Menu 建立菜单场景的窗口
#==============================================================================
class Scene_Menu
  _def_ :start do |*args|
    return unless Smomo::Calendar::Menu
    # 在下面添加自定义内容
    @mocalendar_window = Window_MoMenuCalendar.new(@gold_window)
  end
end
#==============================================================================
# ** Scene_Map 建立地图场景的窗口
#==============================================================================
class Scene_Map
  _def_ :create_all_windows do |*args|
    return if Smomo::Calendar::Map == :none
    # 在下面添加自定义内容
    @mocalendar_window = Window_MoMapCalendar.new 
  end
end
#=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+#
#------------------------------------------------------------------------------#
                               "请勿跨过这块区域"
#------------------------------------------------------------------------------#
#+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=#

#==============================================================================
# ** Smomo::Calendar
#==============================================================================
module Smomo::Calendar
  # 预处理
  PeriodSize = Zone.inject(0){|s, (l)| s + l}
  Zone.each_with_index{|z, i| z[0] += i == 0 ? 0 : Zone[i - 1][0]}
  _ = Smomo.deep_clone(Zone)
  _.each_with_index{|z, i| Zone[i][0] = (i == 0 ? 0 : _[i - 1][0])...z[0]}
  class << self
    attr_reader :zone, :prd, :ticking
    attr_accessor :period, :routine
    define_method(:data){[@zone, @tone, @need_change, @period, @prd]}
    define_method(:data=){|d| @zone, @tone, @need_change, @period, @prd = d}
    define_method(:function){|type| type == :all ? data : eval(type.to_s)}
    # 获知周期名
    def pname
      PeriodName[@prd]
    end
    # 初始化
    def ini
      @ticking = true
      System.each_index{|i| $game_variables[Var + i] = Start[i]}
      @ticking = false
      @zone = ""
      @tone = Tone.new 0, 0, 0, 0
      @need_change = false
      @period = init_period
      @prd = Start_PeriodName
      check_period_and_zone
    end
    # 初始化周期
    def init_period
      sta = Start.reverse
      sta.each_with_index do |n, i|
        next if i == sta.size - 1
        sta[i + 1] += n * System.reverse[i + 1][1]
      end
      sta.reverse[0] % PeriodSize
    end
    # 重置周期
    def reset_period
      sta = System.each_index.map{|i| $game_variables[Var + i]}.reverse
      sta.each_with_index do |n, i|
        next if i == sta.size - 1
        sta[i + 1] += n * System.reverse[i + 1][1]
      end
      @period = sta.reverse[0] % PeriodSize
    end
    # 计时
    def i_look_into_the_sky_as_time_passes_by
      return unless $game_switches[Use]
      return if $game_message.visible
      if $game_variables[Speed].zero?
        raise "请先将 Speed 对应变量设为非零值!"
      end
      return unless Graphics.frame_count % $game_variables[Speed] == 0
      @ticking = true
      $game_variables[Var] += 1
      @period += 1
      ensure_time_legal
      ensure_period_legal
      check_period_and_zone
      change_tone if TimeZone
      @ticking = false
    end
    # 确保变量在范围内
    def ensure_time_legal
      @ticking = true
      System.each_with_index do |(u, m, o), i|
        while $game_variables[Var + i] > m - (o ? 1 : 0)
          $game_variables[Var + i] -= m
          $game_variables[Var + i + 1] += 1
        end
        while $game_variables[Var + i] < 1 - (o ? 1 : 0)
          $game_variables[Var + i] += m
          $game_variables[Var + i + 1] -= 1
        end
      end
      @ticking = false
    end
    # 确保时段在范围内
    def ensure_period_legal
      [@routine.each(&:call), @prd += 1, @period = 0] if @period >= PeriodSize
      @prd = 0 if @prd >= PeriodName.size
    end
    # 检查周期别名和时段
    def check_period_and_zone
      tone, @zone = Zone.find{|(r, t, n)| r.include?(@period)}[1, 2]
      @tone == tone ? nil : [@tone = tone, @need_change = true]
    end
    # 改变画面色调
    def change_tone im = false, reset = false
      return unless @need_change || im
      @need_change = false
      if indoor? || !$game_switches[Use] && reset
        $game_map.screen.start_tone_change Tone.new(0, 0, 0, 0), 0
      else
        return unless $game_switches[Use]
        $game_map.screen.start_tone_change @tone, im ? 0 : 60
      end
    end
    # 是否是室内地图
    def indoor?
      $game_map.instance_exec{ @map }.note =~ IndoorMap
    end
  end
  Smomo::Calendar.routine = Array.new
end
#==============================================================================
# ** Smomo.calendar(*a, &b)
#==============================================================================
def Smomo.calendar *a, &b
  Smomo::Calendar.function *a, &b
end
#==============================================================================
# ** Game_Switches
#==============================================================================
class Game_Switches
  _def_ :on_change do
    Smomo::Calendar.change_tone true, true
  end
end
#==============================================================================
# ** Game_Variables
#==============================================================================
class Game_Variables
  _def_ :[]=, :c do |old, variable_id, value|
    if Smomo::Calendar.ticking
      old.call variable_id, value
    else
      min = Smomo::Calendar::Var
      max = min + Smomo::Calendar::System.size - 1
      if variable_id.between? min, max
        Smomo::Calendar.period += value - @data[variable_id]
        old.call variable_id, value
        Smomo::Calendar.ensure_time_legal
        Smomo::Calendar.ensure_period_legal
        Smomo::Calendar.check_period_and_zone
        Smomo::Calendar.change_tone
        Smomo::Calendar.reset_period
      else
        old.call variable_id, value
      end
    end
  end
end
#==============================================================================
# ** Scene_Map
#==============================================================================
class Scene_Map
  _def_ :update do |*args|
    Smomo::Calendar.i_look_into_the_sky_as_time_passes_by
  end
  _def_ :post_transfer, :b do |*args| Smomo::Calendar.change_tone(true) end
end
#==============================================================================
# ** DataManager
#==============================================================================
class << DataManager
  _def_ :setup_new_game do Smomo::Calendar.ini end
  _def_ :make_save_contents, :v do |contents, *args|
    contents[:mocalendar] = Smomo::Calendar.data
    contents
  end
  _def_ :extract_save_contents do |contents, *args|
    Smomo::Calendar.data = contents[:mocalendar]
  end
end

else # if $smomo
  msgbox "请不要重复加载此脚本 : )\n【虚拟日历】"
end
#==============================================================================#
#=====                        =================================================#
            "脚 本 尾"
#=====                        =================================================#
#==============================================================================#
