module MazeData
  class Cell
    attr_accessor :cur, :dirs

    def initialize(dirs)
      @dirs = dirs
      @cur = false
    end

    def to_s
      out = "["
      dirs.each { |d| out += "#{d}" }
      return out + "]"
    end
  end

  class Maze
    attr_reader :graph, :arr

    def initialize(data)
      @graph = data[0]
      @arr = init_arr
    end

    def init_arr
      # initialize array
      arr_h = ((@graph.length) * 2) + 1
      arr_w = ((@graph[0].length) * 2) + 1
      arr = []
      0.upto(arr_h - 1) { |i| arr[i] = Array.new(arr_w, 0) }

      # --------------- process maze ---------------
      0.upto(@graph.length - 1) do |y|
        0.upto(@graph[0].length - 1) do |x|
          @graph[y][x].dirs.each do |d|
            case d
            when "u"
              arr[(y * 2)][(x * 2) + 1] = 1
            when "d"
              arr[(y * 2) + 2][(x * 2) + 1] = 1
            when "r"
              arr[(y * 2) + 1][(x * 2) + 2] = 1
            when "l"
              arr[(y * 2) + 1][(x * 2)] = 1
            end
          end
        end
      end
      # --------------------------------------------

      return arr
    end
  end
end

module MazeManager
  def pretty_print(maze)
    # retrieve maze array
    arr = maze.arr

    # initialize return array
    ret = []

    # --------------- process array ---------------
    0.upto(arr.length - 1) do |y|
      line = ""
      0.upto(arr[0].length - 1) do |x|
        if (y % 2 == 0) # y value is even
          if (x % 2 == 0) # x value is even (junctions)
            line += "+"
          else # x value is odd (horizontal walls)
            # if 0 then path is closed
            if (arr[y][x] == 0) then line += "-" else line += " " end
          end
        else
          if (x % 2 == 0) # x value is even (vertical walls)
            # if 0 path is closed
            if (arr[y][x] == 0) then line += "|" else line += " " end
          else # x value is odd (path)
            line += " "
          end
        end
      end
      # add generated line to array
      line += "\n"
      ret.append(line)
    end
    # ---------------------------------------------
    return ret
  end
end

module MazeGenerator
  A_DIRS = ["u", "d", "l", "r"]
  OP_DIRS = { "u" => "d", "d" => "u", "l" => "r", "r" => "l" }
  CALC_DIR_X = { "u" => 0, "d" => 0, "l" => -1, "r" => 1 }
  CALC_DIR_Y = { "u" => -1, "d" => 1, "l" => 0, "r" => 0 }

  def create_rDFS(h, w)
    # initialize maze with all walls
    graph = []
    0.upto(h - 1) { |i| graph[i] = Array.new(w) { Cell.new([]) } }

    # initialize starting cell
    sx = rand(w / 2)
    sy = rand(h / 2)

    # initialize stack and visited array and add starting cell
    stack = [[sx, sy]]
    visited = [[sx, sy]]

    # ---------- begin DFS ----------
    while (!stack.empty?)
      cur = stack.pop

      # check for unvisited neighbours
      unvis = []
      A_DIRS.each do |dir|
        nx = cur[0] + CALC_DIR_X[dir]
        ny = cur[1] + CALC_DIR_Y[dir]
        if ((nx >= 0) && (nx < w) && (ny >= 0) && (ny < h) &&
            !visited.include?([nx, ny]))
          unvis << dir
        end
      end

      # if current cell has no unvisited neighbours, skip iteration
      if (unvis.empty?) then next end

      # push current cell back to stack for backtracking
      stack.push(cur)

      # obtain a random direction and add edge from cur -> neighbour
      dir = unvis.sample
      nx = cur[0] + CALC_DIR_X[dir]
      ny = cur[1] + CALC_DIR_Y[dir]
      graph[cur[1]][cur[0]].dirs << dir
      graph[ny][nx].dirs << OP_DIRS[dir]

      # mark chosen cell as visited and push to stack
      visited << [nx, ny]
      stack.push([nx, ny])
    end

    # initialize ending point
    ex = rand((w / 2)..(w - 1))
    ey = rand((h / 2)..(h - 1))

    return [graph, [sx, sy], [ex, ey]]
  end

  def debug_maze_dirs(graph)
    0.upto(graph.length - 1) do |row|
      0.upto(graph[row].length - 1) do |col|
        puts "(#{row}, #{col})"
        puts graph[row][col]
        puts
      end
    end
  end

  def debug_arr(arr)
    0.upto(arr.length - 1) do |row|
      0.upto(arr[row].length - 1) do |col|
        print "#{arr[row][col]} "
      end
      puts
    end
  end
end
