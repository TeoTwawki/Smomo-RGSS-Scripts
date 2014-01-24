#==============================================================================
# ■ 保存地图状态
#  作者：影月千秋
#  版本：V 1.0
#  最近更新：2014.01.22
#  适用：VA
#------------------------------------------------------------------------------
# ● 简介
#  在离开一个地图的时候，保存它的状态，包括事件、载具的各属性（位置等）
#==============================================================================
# ● 使用方法
#   将此脚本插入到其他脚本以下，Main以上
#   可以设定不保存状态的特殊地图
#==============================================================================
# ● 更新
#   V 1.0 2014.01.22 新建
#==============================================================================
# ● 声明
#   本脚本来自【影月千秋】，使用、修改和转载请保留此信息
#==============================================================================
 
#==============================================================================
# ■ Smomo::SaveMapStatus
#==============================================================================
module Smomo
  module SaveMapStatus
    NoSaveEvents = [3,7,5]
    # 在哪些地图不保存事件状态
     
    NoSaveVehicles = [7,11]
    # 在哪些地图不保存载具状态
#=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+#
#------------------------------------------------------------------------------#
#                               请勿跨过这块区域                                #
#------------------------------------------------------------------------------#
#+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=#
  end
end
#==============================================================================
# ■ Game_Map
#==============================================================================
class Game_Map
  attr_accessor :mo_events_status
  attr_accessor :mo_vehicles_status
  #--------------------------------------------------------------------------
  # ● 保存状态
  #--------------------------------------------------------------------------
  alias :mo_save_status_setup :setup
  def setup(map_id)
    @mo_events_status ||= {}
    @mo_vehicles_status ||= {}
    @mo_events_status[@map_id] = @events.clone unless
    Smomo::SaveMapStatus::NoSaveEvents.include?(@map_id)
    @mo_vehicles_status[@map_id] = @vehicles.clone unless
    Smomo::SaveMapStatus::NoSaveVehicles.include?(@map_id)
    mo_save_status_setup(map_id)
    @events = @mo_events_status[@map_id].clone unless
    @mo_events_status[@map_id].nil? 
    @vehicles = @mo_vehicles_status[@map_id].clone unless
    @mo_vehicles_status[@map_id].nil?
  end
end
#==============================================================================#
#=====                        =================================================#
           "■ 脚 本 尾"
#=====                        =================================================#
#==============================================================================#
