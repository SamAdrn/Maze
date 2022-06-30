require_relative "maze.rb"

# Consists of constants and methods that handle I/O processes and interactions
# with the player
# @author {https://github.com/SamAdrn Samuel Kosasih}
module MazeRunner
  include MazeData
  include MazeGenerator
  include MazeManager

  # Holds the Maze object being used in the game. Initialized to nil.
  $maze = nil

  # Displays instructions for creating a maze during the start of the game.
  # The player is able to enter specifications for the width and height of the
  # maze, in the format <h> <w>. 
  CREATE_INS =
    ["+===============================================================+\n",
     "|                       " +
     "MAZE; the game v1.0".light_red +
     "                     |\n",
     "+===============================================================+\n",
     "|                     " +
     "made by: Samuel Kosasih".light_yellow +
     "                   |\n",
     "+===============================================================+\n",
     "| Specify height and width of maze in the format <" +
     "h".light_red + "> <" + "w".light_green + ">." +
     "       |\n",
     "|                                                               |\n",
     "| (Note that heights are displayed 2x larger than widths. It is |\n",
     "| recommended that the maze be half as tall as its width)       |\n",
     "+===============================================================+\n"]

  # Displays instructions once a maze has been successfully created. The player
  # is able to choose from the following options:
  # - +<man>+   : Re-display these instructions
  # - +<play>+  : Starts the game. Calls method {#play}
  # - +<print>+ : Prints the maze as a preview to the player.
  #   Calls method {#print_maze}
  # - +<new>+   : Deletes the current maze and allows the play to
  #   create a new one.
  # - +<solve>+ : Displays the shortest path solution of the current maze.
  #   Calls method {#solve}
  # - +<quit>+  : Quits the game and exits the program
  GAME_INS =
    ["+===============================================================+\n",
     "|                       " +
     "MAZE; the game v1.0".light_red +
     "                     |\n",
     "+===============================================================+\n",
     "|                     " +
     "made by: Samuel Kosasih".light_yellow +
     "                   |\n",
     "+===============================================================+\n",
     "| Valid Commands:                                               |\n",
     "| <" + "man".light_red +
     ">   : displays this manual                                |\n",
     "| <" + "play".light_yellow +
     ">  : starts the game                                     |\n",
     "| <" + "print".light_green +
     "> : display a preview of the maze                       |\n",
     "| <" + "new".light_cyan +
     ">   : play with new maze                                  |\n",
     "| <" + "solve".light_blue +
     "> : solves the maze                                     |\n",
     "| <" + "quit".light_magenta +
     ">  : quits the game                                      |\n",
     "+===============================================================+\n"]

  # Displays instructions once player has initiated a game session through the
  # +<play>+ command. The player is able to perform the following actions
  # during the game:
  # - +<u>+ : Move up
  # - +<d>+ : Move down
  # - +<r>+ : Move right
  # - +<l>+ : Move left
  # - +<n>+ : Restart session
  # - +<q>+ : Quit the current session
  PLAY_INS =
    ["+===============================================================+\n",
     "| Alright, so here's the deal. Somewhere in the maze exists a   |\n",
     "| treasure only the best adventurers deserve to have...         |\n",
     "| That's us! Here's what we can do:                             |\n",
     "|---------------------------------------------------------------|\n",
     "| INSTRUCTIONS:                                                 |\n",
     "|                                                               |\n",
     "| Travel around the maze by entering " +
     "<" + "u".light_magenta +
     ">, <" + "d".light_magenta +
     ">, <" + "r".light_magenta +
     ">, <" + "l".light_magenta + ">.        |\n",
     "|                                                               |\n",
     "| Unfortunately, we're not strong enough to go through these    |\n",
     "| stone walls, but it's better to do it the civil way anyways.  |\n",
     "| We're explorers, not barbarians...                            |\n",
     "|                                                               |\n",
     "| If you feel lost, we can start over <" + "n".light_green +
     "> our journey by        |\n",
     "| heading back to the starting cell.                            |\n",
     "|                                                               |\n",
     "| Or you can quit <" + "q".light_red +
     "> if you feel like giving up. But I know    |\n",
     "| you're not that kind of person.                               |\n",
     "|                                                               |\n",
     "| " + "@".light_yellow.blink +
     ": Marks your current position                                |\n",
     "| *: Marks where you've been                                    |\n",
     "|---------------------------------------------------------------|\n",
     "| Let's go get that treasure!                                   |\n",
     "+===============================================================+\n"]

  # ============================================================================

  # @!group Utility Methods

  # ----------------------------------------------------------------------------

  # This method retrieves the current width of the player's terminal.
  # It is mainly used to compute the number of spaces to be printed for a string
  # to be centered within the string.
  #
  # If the terminal width retrieved is invalid, then return a default value of
  # +80+.
  #
  # @return [Integer] the width of the terminal's current viewport
  def terminal_width
    w = `tput cols`.to_i
    w == 0 ? 80 : w
  end

  # ----------------------------------------------------------------------------

  # This method is used to create a delay between statement evaluations while
  # ensuring output buffer is flushed to +STDOUT+.
  #
  # @param x [Float] number of seconds the thread should be suspended
  #
  # @return [void]
  def delay(x)
    STDOUT.flush
    sleep(x.to_f)
  end

  # ----------------------------------------------------------------------------

  # This method helps display output in a more proper format.
  #
  # Specifically, it allows any output to be centered within the terminal
  # in accordance to its width during the method call. More options allow:
  # - Specifying a delay between each line of output through calling
  #   method {#delay}.
  # - Alignment based on the first line of output.
  #
  # To accommodate these options, the output argument must be in the form of a
  # +Array<String>+, to create more explicit indications of newlines.
  #
  # @param str_arr [Array<String>] the output array to be printed
  # @param del [Float] the number of seconds delayed between each printed line
  # @param align [Boolean] an option to apply the alignment rule to the output
  #
  # @return [void]
  #
  # @see #delay
  # @see #terminal_width
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

  # ----------------------------------------------------------------------------

  # @!endgroup

  # ============================================================================

  # ============================================================================

  # @!group Command Methods

  # ----------------------------------------------------------------------------

  # This method corresponds to the +<create>+ command.
  #
  # Allows the user to create a maze using the maze generation algorithms
  # defined in {#MazeGenerator}.
  #
  # Random mazes can be generated by specifying both height and width.
  # This method will prompt the user for these +Integer+ values in order to
  # create a rectangular maze. Equal heights and widths are also permitted for
  # square mazes. The maze generation algorithm will continue to create a
  # randomized maze until it generates one that is solvable (there exists a
  # path from the starting point to the end). Once this process is complete,
  # a new {#MazeData::Maze maze} object will be created. At this point, the
  # player is able to initiate a game session.
  #
  # @return [void]
  #
  # @see #MazeGenerator
  def create
    while (true)
      # specify instructions
      puts
      f_print(CREATE_INS, 0, true)
      print "\n=> "

      # retrieve input
      inp = STDIN.gets.chomp.downcase

      # valid input
      if (inp =~ /([0-9]+)\s?([0-9]+)?/)
        puts
        f_print(["--- CREATING MAZE... ---\n"], 0, false)
        while (true)
          # create graph using randomized DFS
          $maze = Maze.new(create_rDFS($1.to_i, ($2 ? $2.to_i : $1.to_i)))

          # recreate maze if unsolvable
          if (!$maze.solvable) then next end

          # print result maze
          f_print(pretty_print($maze, nil, nil), 0.1, true)
          f_print(["--- MAZE COMPLETE... ---\n"], 0, false)

          # return to main
          return
        end
        # exit request
      elsif (inp =~ /q(uit)?/)
        return
        # invalid input
      else
        puts "hmmm, I can't understand that, try again..." +
               "or type <quit> to quit maze creation"
      end
    end
  end

  # ----------------------------------------------------------------------------

  # This method corresponds to the +<play>+ command.
  #
  # Initiates a game session where the player is able to interact with the
  # currently loaded maze.
  #
  # If the maze is unsolvable, then an option is given to the player whether to
  # continue creating a game session or quit. Otherwise, it will initiate a game
  # session by default and keep looping through it until the player either
  # solves the maze or decides to quit the session.
  #
  # Solving the maze will also provide the user with some session metrics, such
  # as the number of footsteps taken, and whether it was one of the shortest
  # posible paths around the maze.
  #
  # For every step the player makes, the maze will be printed as per usual using
  # {#pretty_print #pretty_print}, but with asterisks +*+ to denote footsteps
  # and the at symbol +@+ to denote the current location.
  #
  # Available commands during a game session (as also described by
  # {#MazeRunner::PLAY_INS}):
  # - +<u>+ : Move up
  # - +<d>+ : Move down
  # - +<r>+ : Move right
  # - +<l>+ : Move left
  # - +<n>+ : Restart session
  # - +<q>+ : Quit the current session
  #
  # @return [void]
  def play
    # determine if the maze is solvable. If not, warn the player.
    if (!$maze.solvable)
      puts "I don't think we can get solve this maze...\n" +
             "Do you want to try it anyways? "

      inp = STDIN.gets.chomp.downcase
      if (inp =~ /ye*a*/)
        puts "Alright then... But I'm telling you, this is a waste of time..."
      elsif (inp =~ /no*a*/)
        puts "Good choice! Maybe next time..."
        return
      else
        puts "Uhm... I'll take that as a no."
        return
      end
    end

    # provide instructions
    f_print(PLAY_INS, 0, true)
    sleep(1)

    # initialize tracking values
    cur = $maze.start
    pathway = [cur]

    # ------------ start the game  ------------
    while (true)
      # print the maze
      puts
      f_print(pretty_print($maze, pathway, cur), 0, true)

      # determine if player has solved the maze
      if (cur[0] == $maze.endpoint[0] && cur[1] == $maze.endpoint[1])
        puts "Noice. We got the treasure!"
        delay(1)

        # check if player got the shortest path
        if (pathway.length == $maze.shortest_p.length)
          puts "And that was a pretty short journey."
        else
          puts "But I don't think that was the shortest path."
        end
        delay(1)

        # display pathway recap
        puts "Footsteps (#{pathway.length}):"
        0.upto(pathway.length - 2) do |i|
          print "(#{pathway[i][0]}, #{pathway[i][1]}) -> "
        end
        print "(#{pathway[pathway.length - 1][0]}, " +
                "#{pathway[pathway.length - 1][0]})\n"
        delay(1.5)

        # end the game
        print "\nNow, let's go home shall we...\n"
        delay(1.5)
        break
      end

      # get player input for the direction to go
      puts
      print "Where do you want to go? "
      inp = STDIN.gets.chomp.downcase

      case inp
      # compute ending cell after moving in the desired direction
      when "u", "d", "r", "l"
        # verify whether direction is valid based on the current location
        if ($maze.graph[cur[1]][cur[0]].include?(inp))
          new_cell = [cur[0] + CALC_DIR_X[inp], cur[1] + CALC_DIR_Y[inp]]
          cur = new_cell
          pathway.push(new_cell)
        else
          puts "What are you talking about? There's no " +
                 "going through that wall!".light_red
          delay(1)
        end
        # quit game session
      when "q", "quit", "i suck"
        puts "Didn't think you were a quitter..."
        delay(1)
        return
        # restart game session
      when "s", "restart", "start over", "lost"
        puts "Yea, I don't feel good about where we are right now either.\n" +
               "Let's start over..."
        delay(1)
        # re-initialize tracking values
        cur = $maze.start
        pathway = [cur]
        next
        # invalid input
      else
        puts "I can't understand you..."
        delay(1)
        next
      end
      # -----------------------------------------
    end
  end

  # ----------------------------------------------------------------------------

  # This method corresponds to the +<print>+ command.
  #
  # Prints a preview of the current maze. The maze is printed through the
  # {#pretty_print #pretty_print} method with a little dramatic affect.
  #
  # @return [void]
  def print_maze
    f_print(["--- SCANNING MAZE... ---\n"], 0.1, false)
    f_print(pretty_print($maze, nil, nil), 0.1, true)
    f_print(["----- SCAN COMPLETE ----- "], 0.1, false)
  end

  # ----------------------------------------------------------------------------

  # This method corresponds to the +<solve>+ command.
  #
  # Prints the shortest path to solve the current maze.
  #
  # The maze is printed through the {#pretty_print #pretty_print} method as per
  # usual, but ith asterisks +*+ through the maze halls that represent a pathway
  # from the starting point to the end.
  #
  # Every {#MazeData::Maze maze} object stores its shortest pathway by default,
  # unless the maze is unsolvable. In the latter case, this method will prompt
  # the user about it.
  #
  # @return [void]
  def solve
    # determine is maze is solvable
    if (!($maze.solvable)) then puts "Maze is not solvable\n"; return end

    f_print(["--- SOLVING MAZE... ---\n"], 0.1, false)

    # print array
    f_print(pretty_print($maze, $maze.shortest_p, nil), 0.1, true)

    # create and print pathway string
    pathway = $maze.shortest_p
    f_print(["Footsteps: #{pathway.length}\n"], 0.1, false)
    puts
    f_print(["----- MAZE SOLVED ----- "], 0.1, false)
  end

  # @!endgroup

  # ============================================================================
end

include MazeRunner

# Main entry point of the game.
#
# As the game starts, the player must first create a maze. Once a maze object 
# is created, more commands are presented to the player that allows them to 
# interact with it.
#
# @return [void]
def main
  inp = "man"
  while (true)
    if ($maze.nil?)                         # create a maze
      create()
      if ($maze.nil?)                       # quit game during maze creation
        puts "but we barely got to know each other :("
        return
      else                                  # maze creation successful
        delay(1)
        puts
        f_print(GAME_INS, 0, true)
      end
    else
      case inp
      when "man"                            # <man>: show manual
        puts
        f_print(GAME_INS, 0, true)
      when "play"                           # <play>: initiate game session
        play()
        puts
        f_print(GAME_INS, 0, true)
      when "new"                            # <new>: create a new maze
        $maze = nil
        next
      when "print"                          # <print>: prints preview of maze
        puts
        print_maze
        puts
      when "solve"                          # <solve>: prints solution of maze
        puts
        solve
        puts
      when "quit"                           # <quit> quits game
        puts "bye bye. see you again soon :D\n\n"
        return
      else                                  # invalid input
        puts "oops, command not found. " +
               "type <man> to know more about valid commands"
      end
    end

    # retrieve input from user
    puts
    print "Enter your command: "
    inp = STDIN.gets.chomp.downcase
  end
end

main()
