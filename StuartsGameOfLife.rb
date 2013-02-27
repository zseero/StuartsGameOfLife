#packaging:
#ocra --windows --chdir-first --icon "IconStuartsGameOfLife.ico" StuartsGameOfLife.rb blank.png blackBackground.jpg SquareStart.jpg SymmetryStart.jpg
###################################################################################################################################################
#download:
#https://www.dropbox.com/s/x26ba8igkk2komj/StuartsGameOfLife.exe

require 'rubygems'
require 'gosu'

$white = 0xffffffff
$colors = [
  0xffff0000,#red
  0xffff8800,#orange
  0xffffff00,#yellow
  0xff00ff00,#green
  0xff00ffff,#aqua
  0xff0000ff,#blue
  0xffff00ff #purple
]

module Layers
  Background, Cells, Help = *0..2
end

def randomColor
  Random.rand(0...($colors.length))
end

class Window < Gosu::Window
  def initialize(world)
    @imageWidth = 14

    super(world.size * @imageWidth, world.size * @imageWidth, false, 0)
    self.caption = "Stuart\'s Game of Life"

    @background = Gosu::Image.new(self, "blackBackground.jpg", false)
    @majorityBox = Gosu::Font.new(self, Gosu::default_font_name, 16)
    @infoBox = Gosu::Font.new(self, Gosu::default_font_name, 16)
    @helpBox = Gosu::Font.new(self, Gosu::default_font_name, 16)

    @game = Game.new(self, world)
    @play = false
    @help = false
    @freezeFrame = true
    helpBoxSetup
  end

  def helpBoxSetup
    helpText = "Controls:
Press Space to start/pause.
While paused, click the screen to place a cell.
While paused, press the Right Arrow Key to go to make time advance by 1 frame.
Press Escape to clear the screen.
Press the number keys to enable the Color-based Evolutionary Process, and make the
corresponding color the \"fittest\". (1 = Red, 2 = Orange, etc.)
Press the 0 key to disable the Color-based Evolutionary Process.

About:
This is my version of Conway\'s Game of Life. In my version, I\'ve added colors.
Colors represent the genetics that a cell may have. When a new cell is created, it takes on the
color of the average of it\'s parents\' colors. This shows families of cells, and helps
distinguish organisms.
I conducted an experiment, to see if by \"saving\" cells of a certain color, if I could make
the majority of the cells evolve to that color. This is a simplified verison of the Survival of
the Fittest. I\m doing exactly that by \"saving\" cells with the fittest color that would have
otherwised died. My experiment worked, and over a small period of time, the majority of the cells
will all evolve to become the fittest color. Unfortunately though, the new set of evolutionary
rules create a cancer like effect, and the cells grow more unnaturally. However, the evolution
still works, and the cells do still turn to become the fittest color.
It was also discovered that the cells don\'t always evolve to become the fittest color. Sometimes
the cells evolve to a color very close. For example, if the fittest is red, the cells often all
evolve to be an orange color, and then do not continue to evolve to red. This is because the
orange color (when red is the fittest) also shares some of the \"saving\" benefits that a red
cell would receive. 

Here are a few examples for patterns you can start with:"
    @helpScreenBoxTexts = helpText.split("\n")
    @helpScreenBox = Gosu::Font.new(self, Gosu::default_font_name, 16)
    @helpImages = []
    @helpImages << Gosu::Image.new(self, "SquareStart.jpg", false)
    @helpImages << Gosu::Image.new(self, "SymmetryStart.jpg", false)
  end

  def helpBoxDraw
    imgY = 0
    for i in 0...@helpScreenBoxTexts.length
      myY = 10 + i * @helpScreenBox.height
      imgY = 10 + myY + @helpScreenBox.height
      @helpScreenBox.draw(@helpScreenBoxTexts[i], 10, myY, Layers::Help, 1, 1, $white)
    end
    square = 100
    for i in 0...@helpImages.length do
      img = @helpImages[i]
      widthFactor = square.to_f / img.width.to_f
      heightFactor = square.to_f / img.height.to_f
      imgX = 10 + i * square
      img.draw(imgX, imgY, Layers::Help, widthFactor, heightFactor)
    end
  end

  def update
    if (@play || @next) && !@freezeFrame
      @next = false
      @game.update
    end
    @freezeFrame = false if @freezeFrame
  end

  def draw
    xFactor = (self.width.to_f / @background.width.to_f)
    yFactor = (self.height.to_f / @background.height.to_f)
    @background.draw(0, 0, Layers::Background, xFactor, yFactor)
    majority = @game.statistics.index(@game.statistics.max)
    percentage = ((@game.statistics[majority].to_f / @game.population.to_f) * 100).round if @game.population > 0
    percentage = 0 if @game.population == 0
    majorityText = "Majority of #{percentage}%"
    infoText = "Population: #{@game.population}, Time: #{@game.time}, SavedCells: #{@game.savedCells}"
    helpText = "Press the H key for help"
    color = $colors[@game.fittest] if @game.fittest != -1
    color = $white if color.nil?
    majorityColor = $colors[majority] if @game.statistics[majority] > 0
    majorityColor = $white if majorityColor.nil?
    helpBoxDraw if @help
    padding = 10
    @majorityBox.draw(majorityText, padding, self.height - @majorityBox.height - @infoBox.height - @helpBox.height - padding, Layers::Help, 1, 1, majorityColor)
    @infoBox.draw(infoText, padding, self.height - @infoBox.height - @helpBox.height - padding, Layers::Help, 1, 1, color)
    @helpBox.draw(helpText, padding, self.height - @helpBox.height - padding, Layers::Help, 1, 1, color)
    @game.draw(@imageWidth)
  end

  def button_down(id)
    if id == Gosu::KbEscape
      @game = Game.new(self, World.new(@game.world.size))
      @play = false
    end
    if id == Gosu::KbH
      @help = !@help
    end
    if id == Gosu::KbSpace
      @play = !@play
    end
    if id == Gosu::KbRight
      @next = true
    end
    if id == Gosu::MsLeft
      @freezeFrame = true
      x = self.mouse_x
      y = self.mouse_y
      x = (x / @imageWidth).to_i
      y = (y / @imageWidth).to_i
      cell = @game.world.getCell(Coord.new(x, y))
      cell.color = randomColor
      cell.nextState = !cell.nextState
    end
    c = button_id_to_char(id)
    i = c.to_i
    if i.to_s == c
      i -= 1
      if color = $colors[i]
        @game.fittest = i
      end
    end
  end

  def needs_cursor?
    true
  end
end

class Array
  def eachCell
    map! do |miniCells|
      miniCells.map! do |cell|
        yield(cell)
      end
      miniCells
    end
  end
end

class Coord
  attr_accessor :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def validate(size)
    @x = mod(@x, size)
    @y = mod(@y, size)
  end

  def mod(num, size)
    if num >= size
      num -= size
    elsif num < 0
      num += size
    end
    num
  end

  def equals?(coord)
    (@x == coord.x && @y == coord.y)
  end
end

class Cell
  attr_accessor :prevState, :nextState, :color
  attr_reader :coord

  def initialize(coord, state = false, color = randomColor)
    @coord = coord
    @prevState = state
    @nextState = state
    @color = color
  end
end

class World
  attr_accessor :cells
  attr_reader :size

  def initialize(size = 10, starterCells = [])
    @size = size
    @cells = []
    for x in 0...size
      miniCells = []
      for y in 0...size
        cell = Cell.new(Coord.new(x, y))
        for starterCell in starterCells do
          if starterCell.coord.equals?(cell.coord)
            cell = starterCell
          end
        end
        miniCells << cell
      end
      @cells << miniCells
    end
  end

  def getCell(coord)
    if miniCells = @cells[coord.x]
      miniCells[coord.y]
    end
  end

  def getAllNeighbors(thing)
    coord = thing if thing.is_a?(Coord)
    coord = thing.coord if thing.is_a?(Cell)
    neighbors = []
    xs = [-1, 0, 1]
    ys = [-1, 0, 1]
    for xChange in xs do
      for yChange in ys do
        if xChange != 0 || yChange != 0
          neighborCoord = Coord.new(coord.x + xChange, coord.y + yChange)
          if neighborCoord.validate(@size)
            neighbors << getCell(neighborCoord)
          end
        end
      end
    end
    neighbors
  end

  def getLivingNeighbors(thing)
    neighbors = getAllNeighbors(thing)
    livingNeighbors = []
    for neighbor in neighbors do
      livingNeighbors << neighbor if neighbor.prevState
    end
    livingNeighbors
  end
end

class Game
  attr_reader :time, :population, :savedCells, :statistics
  attr_accessor :world, :fittest
  def initialize(screen, world, fittest = -1)
    @fittest = fittest
    @screen = screen
    @world = world
    @time = 0
    @population = 0
    @savedCells = 0
    @statistics = [0]
    @alive = Gosu::Image.new(screen, "blank.png", true)
  end

  def update
    @time += 1
    @savedCells = 0
    @world.cells.eachCell do |cell|
      neighbors = @world.getLivingNeighbors(cell)
      amt = neighbors.length
      livingPossibilities = {0..1 => false, 2..3 => true, 4..8 => false}
      deadPossibilities = {3..3 => true, [0, 1, 2, 4, 5, 6, 7, 8] => false}
      if cell.prevState
        livingPossibilities.each do |key, value|
          if key.include?(amt)
            #saving of a cell
            if !value && @fittest != -1
              diff = (@fittest - cell.color).abs
              otherDiff = (@fittest - (cell.color + $colors.length)).abs
              diff = otherDiff if otherDiff < diff
              diff *= 15
              diff += 5
              value = true if Random.rand(0..(diff)) == 0
              @savedCells += 1 if value
            end
            #applying the result
            cell.nextState = value
          end
        end
      else
        deadPossibilities.each do |key, value|
          if key.include?(amt)
            #changing color of the cell
            if value
              cell.color = neighbors[Random.rand(0...neighbors.length)].color
              cell.color += Random.rand((-1)..(1)) if Random.rand(1..10) == 1
              cell.color -= $colors.length if cell.color >= $colors.length
              cell.color += $colors.length if cell.color < 0
            end
            #applying the result
            cell.nextState = value
          end
        end
      end
      if cell.nextState
      end
      cell
    end
  end

  def draw(imageWidth)
    @statistics = []
    $colors.length.times do @statistics << 0 end
    @population = 0
    @world.cells.eachCell do |cell|
      cell.prevState = cell.nextState
      if cell.prevState
        @population += 1
        image = @alive
        xFactor = (imageWidth.to_f / image.width.to_f)
        yFactor = (imageWidth.to_f / image.height.to_f)
        @statistics[cell.color] += 1
        color = $colors[cell.color]
        image.draw(cell.coord.x * imageWidth, cell.coord.y * imageWidth, Layers::Cells, xFactor, yFactor, color)
      end
      cell
    end
  end
end

#cellNums = [1, 1, 2, 1, 3, 1, 5, 1, 1, 2, 4, 3, 5, 3, 2, 4, 3, 4, 5, 4, 1, 5, 3, 5, 5, 5]
cellNums = []
cells = []
i = 0
while i < cellNums.length
  cells << Cell.new(Coord.new(cellNums[i], cellNums[i + 1]), true)
  i += 2
end

world = World.new(50, cells)
window = Window.new(world)
window.show