-----------------------------------------------------------------------------------------

-- main.lua


-----------------------------------------------------------------------------------------

local widget = require("widget")


local background = display.newImage("Images/Title_Screen.png", 1280, 720)
        background.x = display.contentCenterX
        background.y = display.contentCenterY

local btn =widget.newButton {
    width = 289,
    height = 40,
    left = 240,
    top = 630,
    defaultFile = "Images/new_game.png",
}

local btn =widget.newButton {
    width = 289,
    height = 40,
    left = 240,
    top = 670,
    defaultFile = "Images/load_game.png",
}

local btn =widget.newButton {
    width = 289,
    height = 40,
    left = 240,
    top = 710,
    defaultFile = "Images/options.png",
}

local btn =widget.newButton {
    width = 289,
    height = 40,
    left = 240,
    top = 750,
    defaultFile = "Images/quit_game.png",
}







