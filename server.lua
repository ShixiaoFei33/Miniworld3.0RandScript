local Script = {}

Script.openFnArgs = {
    GetData = true,
}

local localData = {}
local cloudData = {}
local targetData = {}
local sortData = {}
-- 获取当前时间戳
function getTimestamp()
    return os.time()
end

-- 初始化数据(Diff必须用这个)
-- 数据模型
--[[
{
    id是迷你号
    id = {
        value = 排序值,
        timestamp = 时间戳
    },
    id = {
        value = 排序值,
        timestamp = 时间戳
    },
}
--]]
function initData(v)
    return {
        value = v,
        timestamp = getTimestamp()
    }
end

----------这个地方是Diff的代码分界线----------
-- Diff核心函数
function getDiff(oldData, newData)
    local diff = {
        add = {},
        update = {},
    }

    -- 增改处理
    for k, newItem in pairs(newData) do
        local oldItem = oldData[k]

        if not oldItem then
            diff.add[k] = newItem
        else
            if newItem.timestamp > oldItem.timestamp then
                diff.update[k] = newItem
            end
        end
    end

    return diff
end

-- 应用Diff内容到目标表
function applyDiff(diff, Data)
    local target = {}
    -- 初始化
    for k, v in pairs(Data) do
        target[k] = v
    end
    -- 增加处理
    for k, v in pairs(diff.add) do
        target[k] = v
    end

    -- 更新处理
    for k, v in pairs(diff.update) do
        target[k] = v
    end

    return target
end

----------这个地方是Diff的代码分界线----------

----------这里是排序的分界线----------
-- 格式解码函数(排序、渲染的格式)
function GetDecodeArrayInfo(infos)
    local arr = {}
    for id, data in pairs(infos) do
        table.insert(arr, {
            id = id,
            data = data
        })
    end
    return arr
end

-- 排序使用函数     降序
function PlaySort(arr)
    table.sort(arr, function(a, b)
        return a.data.value > b.data.value
    end)
    return arr
end

----------这里是排序的分界线----------

-- 初始化
function Script:InitServer(callback)
    local Data = {}
    local completed = 0
    local total = 3

    -- 判断是否所有操作都完成
    local function onComplete()
        completed = completed + 1
        if completed == total then
            callback(Data)
        end
    end

    CloudSever:GetDataListByKey("datalist_1755364599", 'ServerID', function(code, key, data)
        Data.ServerID = data or ""
        onComplete()
    end)
    CloudSever:GetDataListByKey("datalist_1755364599", 'Time', function(code, key, data)
        Data.Time = data or 0
        onComplete()
    end)
    CloudSever:GetDataListByKey("datalist_1755364599", 'Data', function(code, key, data)
        Data.Data = data or {}
        onComplete()
    end)
end

-- 上传数据
function Script:PushServer()
    -- 这个地方有优化空间的
    -- 可以只拉取时间戳和云服ID
    -- else后面的那个才是真正用到pull的
    self:PullServer(function(loadedData)
        cloudData = loadedData
        if math.abs(localData.Time - cloudData.Time) ~= 0 then
            if cloudData.ServerID == localData.ServerID then
                sortData.Data = PlaySort(GetDecodeArrayInfo(localData.Data))
                sortData.ServerID = localData.ServerID
                sortData.Time = localData.Time
                local result = CloudSever:SetDataListBykey("datalist_1755364599", "ServerID", localData.ServerID)
                local result = CloudSever:SetDataListBykey("datalist_1755364599", "Time", localData.Time)
                local result = CloudSever:SetDataListBykey("datalist_1755364599", "Data", localData.Data)
            else
                local diff = getDiff(localData.Data, cloudData.Data)
                targetData.Data = applyDiff(diff, localData.Data)
                targetData.ServerID = CloudSever:GetRoomID()
                targetData.Time = localData.Time
                sortData.Data = PlaySort(GetDecodeArrayInfo(targetData.Data))
                sortData.ServerID = targetData.ServerID
                sortData.Time = targetData.Time
                local result = CloudSever:SetDataListBykey("datalist_1755364599", "ServerID", targetData.ServerID)
                local result = CloudSever:SetDataListBykey("datalist_1755364599", "Time", targetData.Time)
                local result = CloudSever:SetDataListBykey("datalist_1755364599", "Data", targetData.Data)
            end
        else
            if not cloudData.Data or next(cloudData.Data) == nil then
                local result = CloudSever:SetDataListBykey("datalist_1755364599", "ServerID", localData.ServerID)
                local result = CloudSever:SetDataListBykey("datalist_1755364599", "Time", localData.Time)
                local result = CloudSever:SetDataListBykey("datalist_1755364599", "Data", localData.Data)
            end
        end
    end)
end

-- 下载数据
function Script:PullServer(callback)
    local Data = {}
    local completed = 0
    local total = 3

    -- 判断是否所有操作都完成
    local function onComplete()
        completed = completed + 1
        if completed == total then
            callback(Data)
        end
    end

    CloudSever:GetDataListByKey("datalist_1755364599", 'ServerID', function(code, key, data)
        Data.ServerID = data or ""
        onComplete()
    end)
    CloudSever:GetDataListByKey("datalist_1755364599", 'Time', function(code, key, data)
        Data.Time = data or 0
        onComplete()
    end)
    CloudSever:GetDataListByKey("datalist_1755364599", 'Data', function(code, key, data)
        Data.Data = data or {}
        onComplete()
    end)
end

function Script:PlayerBeat(e)
    localData.Time = getTimestamp()
    local value = Data:GetValue("v7538884159704102715103663", e.eventobjid)
    local code = Data:SetValue("v7538884159704102715103663", e.eventobjid, value+1)
    local data = initData(value)
    localData.Data[e.eventobjid] = data
end

function Script:GetData()
    return sortData
end

-- 组件启动时调用
function Script:OnStart()
    self:InitServer(function(loadedData)
        localData.Data = loadedData.Data
        localData.ServerID = CloudSever:GetRoomID()
        localData.Time = getTimestamp()
        sortData.Data = PlaySort(GetDecodeArrayInfo(localData.Data))
        local task = self:DoPeriodicTask(self.PushServer, 10)
        self:AddTriggerEvent(TriggerEvent.PlayerAttackHit, self.PlayerBeat)
    end)
end

-- 组件销毁时调用
function Script:OnDestroy()
    self:ClearAllTask()
end

return Script
