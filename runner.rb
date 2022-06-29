require_relative "maze.rb"

include MazeData
include MazeGenerator
include MazeManager

def terminal_width
    w = `tput cols`.to_i
    w == 0 ? 80 : w
  end

def delay(x)
  STDOUT.flush
  sleep(x.to_f)
end

def f_print(str_arr, del, align)
  w = terminal_width
  # if align, set a fixed number of spaces based on the first line
  if (align) then fixed_spacing = (w - str_arr[0].length) / 2 end
  str_arr.each do |line|
    1.upto(align ? fixed_spacing : (w - line.length) / 2) { print " " }
    print line
    delay(del.to_f)
  end
end

maze = Maze.new(create_rDFS(5, 5))
debug_maze_dirs(maze.graph)
debug_arr(maze.arr)

f_print(pretty_print(maze), 0, false)
