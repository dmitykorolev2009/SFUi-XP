local Window = class("Window", SFUi.component)

function Window:initialize(pos, size, title, draggable, closehides, callback)
    SFUi.component.initialize(self, nil, pos, size)
    self.title = title or "Window"
    self.draggable = draggable ~= nil and draggable or true
    self.closehides = closehides
    self.callback = callback
    self.barheight = 0
    self.barheight = 0
    self.dragging = false
    self.extrahover = {
        bar = false,
        close = false
    }

end

function Window:updateHover(cursor)
    SFUi.component.updateHover(self, cursor)
    self.extrahover.bar = self.hover and cursor.y < self.mins.y + self.barheight or false
    self.extrahover.close = (self.closehides ~= nil and self.extrahover.bar) and cursor.x > self.maxs.x - self.barheight or false
end

function Window:render(cursor, action)
    self.barheight = select(2, render.getTextSize(self.title))

    if not self.hold_resize then self.hold_resize = false end
    if not self.maximum_size then self.maximum_size = Vector(1024, 768) - Vector(0,45) end
    if not self.minimum_size then self.minimum_size = self.size end

    if not self.pos_before_maximise then self.pos_before_maximise = self.pos end
    if not self.size_before_maximise then self.size_before_maximise = self.size - Vector(0,45) end
    if not self.can_maximise then self.can_maximise = true end
    if not self.is_maximised then self.is_maximised = 0 end

    if cursor and self.hover then
        self.resize_hover = cursor:withinAABox(self.maxs - Vector(self.barheight,self.barheight), self.maxs)
        self.maximise_hover = cursor:withinAABox(Vector(self.mins.x + self.size.x - self.barheight*2, self.mins.y), Vector(self.mins.x + self.size.x - self.barheight*2, self.mins.y) + Vector(self.barheight,self.barheight))
    end

    if self.action.click then
        if self.resize_hover and self.resizable then
            self.hold_at = self.size - cursor / Vector(1, self.aspectRatio)
            self.hold_resize = true
        end

        if self.can_maximise and self.resizable and self.maximise_hover then
            self.is_maximised = self.is_maximised + 1
            if self.is_maximised > 1 then self.is_maximised = 0 end
            
            if self.is_maximised == 1 then
                self.pos_before_maximise = self.pos
                self.size_before_maximise = self.size
                self.size = Vector(1024, 768) - Vector(0,45)
                self.pos = Vector(0,0)
            elseif self.is_maximised == 0 then
                self.size = self.size_before_maximise
                self.pos = self.pos_before_maximise
                
            end
        end

        if self.extrahover.close then
            if self.callback then
                self.callback(self)
            end
            if self.closehides then
                self.visible = false
            end
        elseif self.extrahover.bar and self.draggable and self.maximise_hover == false then
            self.dragging = true
        end
    elseif not self.action.held then
        self.dragging = false
        self.hold_resize = false
    end

    if self.resizable then
        if self.hold_resize and cursor then self.size = cursor / Vector(1, self.aspectRatio) + self.hold_at end
    end
    self.size.x = math.clamp(self.size.x,self.minimum_size.x,self.maximum_size.x)
    self.size.y = math.clamp(self.size.y,self.minimum_size.y,self.maximum_size.y)

    if type(self.paint) == "function" then
        self.paint(self)
    else
        if type(self.override_design) == "function" then
            self.override_design(self)
        else
            render.setColor(self.palette.background)
            render.drawRectFast(self.mins.x, self.mins.y, self.size.x, self.size.y * self.aspectRatio)

            render.setColor((self.focus.allowed or self.dragging) and self.palette.hover or self.palette.component)
            render.drawRectOutline(self.mins.x, self.mins.y, self.size.x, self.size.y * self.aspectRatio, 3)

            render.setColor((self.focus.allowed or self.dragging) and self.palette.hover or self.palette.component)
            render.drawRectFast(self.mins.x, self.mins.y, self.size.x, self.barheight * self.aspectRatio)

            render.setColor(self.palette.WindowTitle)
            render.drawSimpleText(self.mins.x + 5, self.mins.y, self.title, TEXT_ALIGN.LEFT, TEXT_ALIGN.TOP)

            //close
            if self.closehides then
                render.setColor(Color())
                render.setMaterial(self.materials.WindowCloseMat)
                render.drawTexturedRect(self.mins.x + self.size.x - self.barheight, self.mins.y, self.barheight, self.barheight * self.aspectRatio)
            end
            //
    
            //maximise
            if self.can_maximise and self.resizable then
        
                render.setColor(Color(255,255,255))

                render.drawRoundedBox(5, self.mins.x + self.size.x - self.barheight*2, self.mins.y, self.barheight, self.barheight * self.aspectRatio)

                render.setColor((self.focus.allowed or self.dragging) and self.palette.hover or self.palette.component)

                render.drawRoundedBox(5, self.mins.x + self.size.x - self.barheight*2 + 1, self.mins.y + 1, self.barheight - 2, (self.barheight - 2) * self.aspectRatio)

                render.setColor(Color(255,255,255))

                render.drawRect(self.mins.x + self.size.x - self.barheight*2 + 4, self.mins.y + 5, self.barheight - 8, 3)
                render.drawRectOutline(self.mins.x + self.size.x - self.barheight*2 + 4, self.mins.y + 5, self.barheight - 8, (self.barheight - 8) * self.aspectRatio, 1)
            end
            //
        end
    end
    
    if self.dragging and self.drag.delta then
        self.pos = self.pos + self.drag.delta
    end

    SFUi.component.render(self, cursor, action)
end

SFUi.static.window = Window