local Button = class("Button", SFUi.component)

function Button:initialize(parent, pos, size, text, callback)
    SFUi.component.initialize(self, parent, pos, size)
    self.text = text
    self.callback = callback
end

function Button:render(cursor, action)

    render.setColor(self.hover and self.palette.contrast or self.palette.hover)
    render.drawRoundedBox(5, self.mins.x, self.mins.y, self.size.x, self.size.y * self.aspectRatio)

    render.setColor(Color(230, 230, 230))
    render.drawRoundedBox(5, self.mins.x + 3, self.mins.y + 3 * self.aspectRatio, self.size.x - 6, (self.size.y - 6) * self.aspectRatio)

    render.setColor(Color(0, 0, 0))
    render.drawSimpleText(self.center.x, self.center.y, self.text, TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)

    if self.action.click and self.callback then
        self.callback()
    end

    SFUi.component.render(self, cursor, action)
end

SFUi.static.button = Button