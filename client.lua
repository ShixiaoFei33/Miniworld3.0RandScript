local Script = {}

--属性定义
Script.propertys = {
    varNum = {
        type = Mini.Number,
        default = 0, --默认值
        displayName = "数值",
    },
}
local Data = {}
local id_ui = {
    "7539166734192441147-24959_8",
    "7539166734192441147-24959_9",
    "7539166734192441147-24959_10",
    "7539166734192441147-24959_11",
    "7539166734192441147-24959_12",
    "7539166734192441147-24959_13",
    "7539166734192441147-24959_14",
}

local beat_ui = {
    "7539166734192441147-24959_15",
    "7539166734192441147-24959_16",
    "7539166734192441147-24959_17",
    "7539166734192441147-24959_18",
    "7539166734192441147-24959_19",
    "7539166734192441147-24959_20",
    "7539166734192441147-24959_21",
}

local close_ui = "7539166734192441147-24959_2"
local open_ui = "7539166734192441147-24959_22"
local page_ui = {
    "7539166734192441147-24959_6", --左翻
    "7539166734192441147-24959_7", --右翻
    "7539166734192441147-24959_5", --当前页
}

local page = 1
local pagesize = 7



function Script:LeftPage(e)
    if e.uielement == page_ui[1] then
        if page > 1 then
            page = page - 1
            self:Render(e.eventobjid)
        else
            local result = Player:NotifyGameInfo2Self(e.eventobjid, "已经是第一页了！")
        end
    end
end

function Script:RightPage(e)
    if e.uielement == page_ui[2] then
        if page < math.ceil(#Data / pagesize) then
            page = page + 1
            self:Render(e.eventobjid)
        else
            local result = Player:NotifyGameInfo2Self(e.eventobjid, "没有更多啦！")
        end
    end
end

function Script:Render(eventobjid)
    local startIndex = (page - 1) * pagesize + 1
    local endIndex = math.min(page * pagesize, #Data.Data)
    for k, v in ipairs(id_ui) do
        local isSuccess = CustomUI:SetText(eventobjid, "7539166734192441147-24959", v, Data.Data[startIndex + k - 1].id or "")
    end
    for index, value in ipairs(beat_ui) do
        local isSuccess = CustomUI:SetText(eventobjid, "7539166734192441147-24959", value, Data.Data[startIndex + index - 1].data.value or "")
    end
end

function Script:OnOpenUI(e)
    if e.uielement == open_ui then
        local isSuccess = CustomUI:ShowElement(e.eventobjid, "7539166734192441147-24959", "7539166734192441147-24959_1")
        Data = cmp:GetData()
        print(Data.Data)
        self:Render(e.eventobjid)
    end
end

function Script:OnCloseUI(e)
    if e.uielement == close_ui then
        local isSuccess = CustomUI:HideElement(e.eventobjid, "7539166734192441147-24959", "7539166734192441147-24959_1")
    end
end

-- 组件启动时调用
function Script:OnStart()
    world = GetWorld()
    cmp = world:GetComponent("c7538876690755974971103659")
    self:AddTriggerEvent(TriggerEvent.UIButtonClick, self.OnOpenUI)
    self:AddTriggerEvent(TriggerEvent.UIButtonClick, self.OnCloseUI)
    self:AddTriggerEvent(TriggerEvent.UIButtonClick, self.LeftPage)
    self:AddTriggerEvent(TriggerEvent.UIButtonClick, self.RightPage)
end

-- 组件销毁时调用
function Script:OnDestroy()

end

return Script
