-- SFUi by itisluiz
-- https://github.com/itisluiz/SFUi/
-- Version 0.3

local function RayPlaneIntersection( Start, Dir, Pos, Normal )

    local A = Normal:dot(Dir)

    -- Check if the ray is aiming towards the plane (fail if it origin behind the plane, but that is checked later)
    if (A < 0) then

        local B = Normal:dot(Pos-Start)

        -- Check if the ray origin in front of plane
        if (B < 0) then
            return (Start + Dir * (B/A))
        end

    -- Check if the ray is parallel to the plane
    elseif (A == 0) then

        -- Check if the ray origin inside the plane
        if (Normal:dot(Pos-Start) == 0) then
            return Start
        end

    end
    return false
end

local function RayFaceIntersection( Start, Dir, Pos, Normal, Size, Rotation )

    local hitPos = RayPlaneIntersection( Start, Dir, Pos, Normal )

    if (hitPos) then

        faceAngle = Normal:getAngle()+Angle(0,0,Rotation)

        local localHitPos = worldToLocal( hitPos, Angle(0,0,0), Pos, faceAngle )

        local min = Size/-2
        local max = Size/2
        
        if (localHitPos.z >= min.x and localHitPos.z <= max.x) then
            if (localHitPos.y >= min.y and localHitPos.y <= max.y) then

                return hitPos

            end
        end

    end
    return false
end

SFUi = class("SFUi")

SFUi.static.palette = {
    foreground = Color(255, 255, 255),
    background = Color(30, 30, 30),
    hover = Color(75, 75, 75),
    component = Color(45, 45, 45),
    contrast = Color(60, 60, 60),
    highlight = Color(10, 255, 0)
}

function SFUi:initialize(scaling, screenEntity, screenSizeX, screenSizeY)
    scaling = scaling or {}
    
    self.scaling = {
        designHeight = scaling.designHeight,
        designFontSize = scaling.designFontSize,
        componentAttenuation = scaling.componentAttenuation or 0,
        fontAttenuation = scaling.fontAttenuation or 0.6,
        fontName = scaling.fontName or "Default",
        fonts = {},
        curScale = 1,
        lastHeight = nil
    }

    self.screenSizeX = screenSizeX
    self.screenSizeY = screenSizeY
    self.screenEntity = ScreenEntity
    self.aspectRatio = screenSizeX / screenSizeY
    self.components = {}
    self.preventClick = false
    self.preventType = false
end

function SFUi:addComponent(component)
    for i = 1, #self.components do
        if self.components[i] == component then
            return
        end
    end
    table.insert(self.components, component)
end

function SFUi:removeComponent(component)
    for i = 1, #self.components do
        if self.components[i] == component then
            table.remove(self.components, i)
            break
        end
    end
end

function SFUi:orderTopmost()
    table.sortByMember(self.components, "lastclicked")
end

function SFUi:hoveredComponent(cursor)
    if not cursor then
        return nil
    end

    for index, component in ipairs(self.components) do
        if component.visible and cursor:withinAABox(component.mins, component.maxs) then
            return component
        end
    end

    return nil
end

function SFUi:render()
    local isHUD = not render.getScreenEntity()
    local cursor = nil
    local action = {click = false, held = false, typing = 0}
    local height = select(2, render.getResolution())
    local scale_pending = nil

    local CGPos = RayFaceIntersection( player():getShootPos(), player():getAimVector(), self.screenEntity:getPos(), self.screenEntity:getUp(), Vector(self.screenSizeX, self.screenSizeY, 0.02), 0 )
    local cursorSource = self.screenEntity:worldToLocal(CGPos) / Vector(self.screenSizeX, self.screenSizeY, 0.02) + Vector(0.5)
    if cursorSource[1] and cursorSource[2] then
        cursor = Vector(cursorSource[2], cursorSource[1])
    end

    local playerTyping = player():isTyping()
    if playerTyping then
        if not self.preventType then
            action.typing = 1
            self.preventType = true
        else
            action.typing = 2
        end
    else
        action.typing = 0
        self.preventType = false
    end

    action.held = (action.typing == 0 and input.isKeyDown(KEY.E)) or input.isMouseDown(MOUSE.LEFT)
    if action.held and not self.preventClick then
        action.click = true
        self.preventClick = true
    elseif not action.held then
        self.preventClick = false
    end

    if self.scaling.lastHeight ~= height then
        local designHeight = self.scaling.designHeight or height
        local scale = height / designHeight
        local scale_components = (scale + (1 - scale) * self.scaling.componentAttenuation) / self.scaling.curScale

        if self.scaling.designFontSize then
            local scale_font = scale + (1 - scale) * self.scaling.fontAttenuation
            local fontSize = math.round(scale_font * self.scaling.designFontSize)

            if not self.scaling.fonts[fontSize] then
                self.scaling.fonts[fontSize] = render.createFont(self.scaling.fontName, fontSize)
            end
            
            render.setFont(self.scaling.fonts[fontSize])
        end 

        scale_pending = scale_components
        self.scaling.curScale = self.scaling.curScale * scale_components
        self.scaling.lastHeight = height
    end

    self:orderTopmost()
    local hovered = self:hoveredComponent(cursor)
    for index, component in ipairs(table.reverse(self.components)) do
        if scale_pending then
            component:scale(scale_pending)
        end
        if component.visible then
            component.focus.allowed = component == hovered
            component:render(cursor, action)
        end
    end
end
