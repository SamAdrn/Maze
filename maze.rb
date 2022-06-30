require "colorize"

# Consists of methods that handle generating new mazes
# @author {https://github.com/SamAdrn Samuel Kosasih}
module MazeGenerator

  # An +Array<String>+ array of strings that represents the available
  # directions to traverse to
  A_DIRS = ["u", "d", "l", "r"]

  # A +Hash<String, String>+ hash of strings mapped to strings that represent
  # the opposite directions of all available directions {A_DIRS}
  OP_DIRS = { "u" => "d", "d" => "u", "l" => "r", "r" => "l" }

  # A +Hash<String, Integer>+ hash of strings mapped to integers that represent
  # the x-values in order to traverse a specific direction
  CALC_DIR_X = { "u" => 0, "d" => 0, "l" => -1, "r" => 1 }

  # A +Hash<String, Integer>+ hash of strings mapped to integers that represent
  # the y-values in order to traverse a specific direction
  CALC_DIR_Y = { "u" => -1, "d" => 1, "l" => 0, "r" => 0 }

  # Creates a new maze using Randomized Depth-First Search
  #
  # The algorithm generates a new maze by traversing through the edges of
  # graph while generating pathways that open up between cells.
  #
  # The graph is first initialized based on the height +h+ and width +w+
  # specified by the parameters and with no pathways available. Then, it
  # initializes a random cell, somewhere in the fourth quadrant, to be
  # the *starting* *point*. From this cell, it randomly chooses between
  # unvisited neighbours and generates a path towards it. Once it finds itself
  # with no more neighbours to visit, it backtracks to a cell that still has
  # unvisited neighbours, up to the point when all cells have been visited.
  # When this happens, the maze is complete, and it will initialize another
  # random cell, somewhere in the second quadrant, to be the *ending* *point*.
  #
  # Due to the depth-first search nature of this algorithm, the maze may have
  # low branching factors. This is due to its characteristic of traversing as
  # far as it can through a single branch before backtracking. As a result,
  # there will not be many unvisited cells left to process at the point it
  # starts to backtrack, creating many short dead ends.
  #
  # Rather than enlarging a potentially limited number of stack frames, this
  # algorithm maintains an explicit stack. This allows tracking more cells
  # without the anxiety of running into a stack overflow error.
  #
  # @param h [Integer] the height of the maze
  # @param w [Integer] the width of the maze
  #
  # @return [graph, starting point, ending point] an array consisting of the
  #   following values:
  #   1. graph +Array<Array<Array<Integer>>>+: an adjacency matrix representing
  #      the graph structure of the maze, as described by {#MazeData::Maze}
  #   2. starting point +Array(Integer, Integer)+: the start point of the maze
  #   3. ending point +Array(Integer, Integer)+: the end point of the maze
  #
  # @see https://en.wikipedia.org/wiki/Maze_generation_algorithm#Randomized_depth-first_search
  #   Reference to DFS algorithm (wikipedia)
  def create_rDFS(h, w)
    # initialize maze with all walls
    graph = Array.new(h) { Array.new(w) { [] } }

    # initialize starting cell
    sx, sy = rand(w / 2), rand(h / 2)

    # initialize stack and visited array and add starting cell
    stack = [[sx, sy]]
    visited = [[sx, sy]]

    # ---------- begin DFS ----------
    while (!stack.empty?)
      cur = stack.pop

      # check for unvisited neighbours
      unvis = []
      A_DIRS.each do |dir|
        nx, ny = cur[0] + CALC_DIR_X[dir], cur[1] + CALC_DIR_Y[dir]
        if ((nx >= 0) && (nx < w) && (ny >= 0) && (ny < h) &&
            !visited.include?([nx, ny]))
          unvis << [nx, ny, dir]
        end
      end

      # if current cell has no unvisited neighbours, skip iteration
      if (unvis.empty?) then next end

      # push current cell back to stack for backtracking
      stack.push(cur)

      # obtain a random direction and add edge from cur -> neighbour
      n = unvis.sample
      graph[cur[1]][cur[0]] << n[2]
      graph[n[1]][n[0]] << OP_DIRS[n[2]]

      # mark chosen cell as visited and push to stack
      visited << [n[0], n[1]]
      stack.push([n[0], n[1]])
    end

    # initialize ending point
    ex, ey = rand((w / 2)..(w - 1)), rand((h / 2)..(h - 1))

    return graph, [sx, sy], [ex, ey]
  end

  # Creates a new maze using Randomized Kruskal's Algorithm
  #
  # The algorithm generates a new maze by generating a minimum spanning forest
  # within the maze.
  #
  # The graph is first initialized based on the height +h+ and width +w+
  # specified by the parameters and with no pathways available. When traversing
  # through the vertices, it treats every cell in the maze as a root of a tree,
  # joining them together with its surrounding neighbours. If two roots are not
  # part of the same tree, then the wall between them is removed and they
  # connect to become part of the same minimum spanning tree. Otherwise, we 
  # should not process the vertex since we do not want to create cycles (since 
  # they will not be a minimum spanning tree in that case). At the point in
  # which all vertices are processed, the maze will have a bunch of minimum
  # spanning trees that represent pathways. It will then initialize a random 
  # cell, somewhere in the fourth quadrant, to be the *starting* *point*, and
  # another cell, somewhere in the second quadrant, to be the *ending* *point*.
  #
  # The trees are maintained by a +buckets+ hash, which maps the root of the
  # tree to an array of its descending nodes. However, note that every vertex is
  # treated as a root, so multiple keys may correspond to the same tree.
  #
  # Since this algorithm randomly creates MSTs from various points, mazes
  # generated generally have a *high* *branching* *factor*. There would be a lot 
  # places to move around from one cell, but this also means that it has a low
  # river factor, and will tend to have a lot of dead ends. Some areas may not 
  # even be accessible from the starting point. 
  #
  # @param h [Integer] the height of the maze
  # @param w [Integer] the width of the maze
  #
  # @return [graph, starting point, ending point] an array consisting of the
  #   following values:
  #   1. graph +Array<Array<Array<Integer>>>+: an adjacency matrix representing
  #      the graph structure of the maze, as described by {#MazeData::Maze}
  #   2. starting point +Array(Integer, Integer)+: the start point of the maze
  #   3. ending point +Array(Integer, Integer)+: the end point of the maze
  #
  # @see https://en.wikipedia.org/wiki/Maze_generation_algorithm#Randomized_kruskal\'s_algorithm
  #   Reference to Kruskal's algorithm (wikipedia)
  def create_rKruskal(h, w)
    # initialize maze with all walls, buckets for every vertex, and an array
    # of vertices to process
    graph, buckets, vertices = [], {}, []
    # buckets = {}
    # vertices = []
    0.upto(h - 1) do |y|
      graph[y] = Array.new(w) { [] }
      0.upto(w - 1) do |x|
        buckets[[x, y]] = []
        vertices << [x, y]
      end
    end

    while (!vertices.empty?)
      # retrieve a random vertex and remove it to prevent double processing
      cur = vertices.sample
      vertices.delete(cur)

      # retrieve available neighbours
      unvis = []
      A_DIRS.each do |dir|
        nx = cur[0] + CALC_DIR_X[dir]
        ny = cur[1] + CALC_DIR_Y[dir]
        if ((nx >= 0) && (nx < w) && (ny >= 0) && (ny < h) &&
            !graph[cur[1]][cur[0]].include?(dir))
          unvis << [nx, ny, dir]
        end
      end

      # check if there are valid neighbours
      if (!unvis.empty?)
        # retrieve a random neighbour, and check if it is connected to cur
        n = unvis.sample
        if (!buckets[[n[0], n[1]]].include?(cur))
          # connect cells in maze
          graph[cur[1]][cur[0]] << n[2]
          graph[n[1]][n[0]] << OP_DIRS[n[2]]

          # connect both buckets
          buckets[cur] << [n[0], n[1]]
          buckets[[n[0], n[1]]] << cur
        end
      end
    end

    # initialize starting and ending cell
    sx, sy = rand(w / 2), rand(h / 2)
    ex, ey = rand((w / 2)..(w - 1)), rand((h / 2)..(h - 1))

    return graph, [sx, sy], [ex, ey]
  end

  private

  # Debugger method to display the contents of the graph
  #
  # @param graph [Array<Array<Array<Integer>>>]
  #
  # @return [void]
  def debug_maze_dirs(graph)
    0.upto(graph.length - 1) do |row|
      0.upto(graph[row].length - 1) do |col|
        puts "(#{row}, #{col})"
        puts graph[row][col]
        puts
      end
    end
  end

  # Debugger method to display the contents of a 2D array
  #
  # @param arr [Array<Array<Integer>>]
  #
  # @return [void]
  def debug_arr(arr)
    0.upto(arr.length - 1) do |row|
      0.upto(arr[row].length - 1) do |col|
        print "#{arr[row][col]} "
      end
      puts
    end
  end

  # Debugger method to display the contents of a pathway array
  #
  # @param path [Array<Array(Integer, Integer)>]
  #
  # @return [void]
  def debug_path(path)
    path.each { |p| print "(#{p[0]}, #{p[1]}) " }
    puts
  end

  # Debugger method to display the contents of an array
  #
  # @param arr [Array<Array>, Array]
  #
  # @return [void]
  def debug_norm_arr(arr)
    arr.each { |e|
      if (e.is_a?(Array))
        e.each { |e2| print "#{e2} " }
        puts
      else print "#{e} "       end
    }
    puts
  end
end

# Consists of methods and structures needed to represent a maze
# @author {https://github.com/SamAdrn Samuel Kosasih}
module MazeData
  include MazeGenerator

  # This class represents a maze object used to store the necessary attributes
  # that makes it functional. These attributes are documented below.
  class Maze

    # Holds the graph representation of the maze.
    # This +Array<Array<Array<String>>>+ graph is an adjacency matrix, where
    # each vertex is a +(x, y)+ point on a maze plane. The vertex rows
    # represent +y+-values, and the vertex columns represent +x+-values.
    # Instead of integers, each edge within the matrix holds an array of
    # directions, represented with the string +"u"+, +"d"+, +"l"+, or +"r"+,
    # that indicates the possible traversing directions for a cell +(x, y)+.
    #
    # @example if a cell +(x, y)+ could go in the direction +"u"+ and +"l"+:
    #   graph[y][x] => ["u", "l"]
    #
    # @see MazeGeneration
    attr_reader :graph

    # Holds the array representation of the maze.
    # This +Array<Array<Integer>>+ array of +Integer+ arrays are used to
    # represent data to print the maze.
    #
    # @see init_arr
    attr_reader :arr

    # Holds the starting point of the maze.
    # This starting point is represented as an +Array(Integer, Integer)+, where
    # the first element is the x-coordinate, and the second is the y-coordinate.
    #
    # @example an example starting point (where x and y are +Integer+s)
    #   [x, y]
    attr_reader :start

    # Holds the ending point of the maze.
    # This ending point is represented as an +Array(Integer, Integer)+, where
    # the first element is the x-coordinate, and the second is the y-coordinate.
    #
    # @example an example ending point (where x and y are +Integer+s)
    #   [x, y]
    attr_reader :endpoint

    # Holds a +Boolean+ value indicating whether there is a solution for this
    # maze.
    attr_reader :solvable

    # Holds the shortest pathway solution to the maze.
    # This +Array<Array(Integer, Integer)>+ array of +Integer+ pairs holds a
    # pathway of cells that leads from the starting point to the ending point.
    # Each pair is a valid cell representing a coordinate point +(x, y)+ within
    # the maze plane.
    #
    # @see dijsktra
    attr_reader :shortest_p

    # Constructor. Returns a new instance of a {#MazeData::Maze Maze}.
    #
    # Using the +data+ param, it will initialize the basic maze information,
    # namely its graph representation and its start and ending points. The
    # constructor will also take care of building an array representation,
    # figuring out the shortest path solution, and determine if the maze is
    # solvable.
    #
    # @param data [graph, starting point, ending point] an array consisting of
    #   the following values:
    #   1. graph +Array<Array<Array<Integer>>>+: an adjacency matrix
    #      representing the graph structure of the maze.
    #   2. starting point +Array(Integer, Integer)+: the start point of the maze
    #   3. ending point +Array(Integer, Integer)+: the end point of the maze
    #
    # @return [Maze] a new instance of a Maze
    #
    # @see #MazeGenerator
    # @see init_arr
    # @see dijkstra
    def initialize(data)
      @graph, @start, @endpoint = data
      @arr = init_arr
      @solvable, @shortest_p = dijkstra()
    end

    # Initializes the maze's array representation.
    #
    # Using the graph structure, it checks for every possible direction within a
    # cell and build an array representation out of it. The values stored within
    # the array are described as follows:
    # - +0+: Closed Paths
    # - +1+: Open Paths
    # - +2+: Starting Point
    # - +3+: Ending Point
    def init_arr
      # initialize array
      arr_h, arr_w = ((@graph.length) * 2) + 1, ((@graph[0].length) * 2) + 1
      arr = Array.new(arr_h) { Array.new(arr_w) { 0 } }

      # --------------- process maze ---------------
      0.upto(@graph.length - 1) do |y|
        0.upto(@graph[0].length - 1) do |x|
          @graph[y][x].each do |d|
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

      # add starting and ending point
      arr[(@start[1] * 2) + 1][(@start[0] * 2) + 1] = 2
      arr[(@endpoint[1] * 2) + 1][(@endpoint[0] * 2) + 1] = 3

      return arr
    end
  end

  # Finds the shortest path solution between the starting point and the
  # ending point of the maze.
  #
  # The greedy algorithm implements a queue structure to keep track of cells
  # while traversing through every path within the maze. It also keeps a track
  # of distances from the starting point to every cell within the maze. If it
  # finds that there is a shorter path to get from the starting point to a
  # specific cell, it will update its distance value to the shorter distance,
  # and update its predecessor to become the currently-tracked cell. By the time
  # this algorithm is complete, the +predecessors+ hash will be useful in
  # retrieving the shortest pathway. Since we only care about its path from the
  # starting point to the end, the two hash structures (+distances+ and
  # +predecessors+) are garbage-collected.
  #
  # The queue structure here is treated as a priority queue, which represents
  # a min-heap using the distances from the starting point as the priority
  # values. However, it is not exactly a priority queue since it simply
  # traverses through the +distances+ hash to find the cell with the lowest
  # distance value.
  # @todo implement a priority queue into this algorithm
  #
  # @return [Boolean, Array<Array(Integer, Integer)>] an array consisting of
  #   the following values:
  #   1. solvable +Boolean+: indicates whether the maze is solvable
  #   2. shortest_p +Array<Array(Integer, Integer)>+: an array of +Integer+
  #      pairs, where each pair represents a valid cell within the maze, and
  #      the pairs are sorted in pathway-like order from the starting point to
  #      the ending point
  def dijkstra
    # initialize data structures
    distances, predecessors, queue = {}, {}, []
    # initialize data structures
    0.upto(@graph.length - 1) do |y|
      0.upto(@graph[0].length - 1) do |x|
        distances[[x, y]] = 1 / 0.0     # 1 / 0.0 => Infinity
        predecessors[[x, y]] = "X"
        queue.unshift([x, y])
      end
    end
    distances[@start] = 0           # mark starting cell distance
    predecessors[@start] = nil      # mark starting cell predecessor

    # ------------- process each cell -------------
    while (!queue.empty?)
      # retrieve cell with shortest distance that still needs to be processed
      cur = queue.min_by { |c| distances[c] }
      queue.delete(cur)     # mark cur as processed

      # retrieve neighbour nodes
      neighbours = []
      @graph[cur[1]][cur[0]].each do |d|
        neighbours << [cur[0] + CALC_DIR_X[d], cur[1] + CALC_DIR_Y[d]]
      end

      # --------- process each neighbour ---------
      neighbours.each do |n|
        # if neighbour is already processed, skip it
        if (queue.include?(n))
          # calculate distance from start to n through cur
          temp = distances[cur] + 1
          # if distance is shorter, replace the existing distance
          # and update predecessor
          if (temp < distances[n])
            distances[n] = temp
            predecessors[n] = cur
          end
        end
      end
      # ------------------------------------------
    end
    # ----------------------------------------------

    # determine if maze is solvable
    solvable = predecessors[@endpoint] != "X"

    # retrieve shortest path
    shortest_p = nil
    if (solvable)
      # initialize shortest_p array and path variable
      shortest_p = [@endpoint]
      path = predecessors[@endpoint]
      # fill array with shortest path
      while (path != nil)
        shortest_p.unshift(path)
        path = predecessors[path]
      end
    end

    return solvable, shortest_p
  end
end

# Consists of methods that handle processes with mazes.
# @author {https://github.com/SamAdrn Samuel Kosasih}
module MazeManager

  # Prints the maze in a proper format.
  #
  # The method simply accesses the maze's stored array representation and uses
  # the information to display the maze which allows the player to interact with
  # it. Since the array stores +Integer+ values in them, they are easily
  # converted into their respective symbols.
  #
  # The printed maze will use the following symbols, ordered by their
  # precedence:
  # - +: represents junctions  (value +0+)
  # - |: represents vertical walls (value +0+)
  # - -: represents horizontal walls (value +0+)
  # - S: represents the starting point (value +2+)
  # - E: represents the ending point (value +3+)
  # - @: represents the player's current location (enabled by the +cur+
  #   parameter)
  # - *: represents pathways/footsteps (enabled by the +pathway+ parameter)
  # - Empty cells represent open paths (value +1+)
  #
  # These symbols will then be collated together into a proper string format
  # stored and returned as an array, where each line is an element of the array.
  #
  # Some parameters can also enable added features to the printed maze
  # representation. Aside from the +maze+ parameter, the +pathway+ and +cur+
  # parameters are optional. They are described below:
  #
  # @example printing a maze
  #   pretty_print(maze, nil, nil)
  #
  # @example printing a maze with pathways
  #   pretty_print(maze, maze.shortest_p, nil)
  #
  # @example printing a maze with pathways and a current location
  #   pretty_print(maze, pathway, [0, 1])
  #
  # @param maze [Maze] a Maze object to retrieve its array representation
  # @param pathway [Array<Array(Integer, Integer)>, nil] an array of Integer
  #   tuples that represents a pathway within the maze. If a pathway consists of
  #   a cell that is not within the maze, it will simply be ignored
  #   (if +nil+, no pathway is printed).
  # @param cur [Array(Integer, Integer), nil] a pair of +Integers+ representing
  #   the player's current location. If the current location is not within the
  #   maze, it will simply be ignored (if +nil+, no current location is printed)
  #
  # @return [Array<Array<String>>] an array of +String+ arrays, where each
  #   element represents the whole row of the maze
  def pretty_print(maze, pathway, cur)
    arr = maze.arr    # retrieve maze array
    ret = []          # initialize return array

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
            if (cur && ((cur[0] * 2) + 1) == x && ((cur[1] * 2) + 1) == y)
              line += "@".light_yellow.blink  # current cell
            elsif (arr[y][x] == 2)
              line += "S".cyan # starting cell
            elsif (arr[y][x] == 3)
              line += "E".green # ending cell
            elsif (pathway && pathway.find { |p|
              ((p[0] * 2) + 1) == x &&
                ((p[1] * 2) + 1) == y
            })
              line += "*" # footstep
            else
              line += " "
            end
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
