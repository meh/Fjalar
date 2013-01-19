defmodule Fjalar.Mixfile do
  use Mix.Project

  def project do
    [ app: :fjalar,
      version: "0.0.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    []
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [{ :ecsv, "1", github: "refuge/ecsv" }]
  end
end

defmodule Mix.Tasks.Athena do
  def csv(path, func) do
    :ecsv.process_csv_string_with(binary_to_list(Regex.replace(%r{//.*$}gm, File.read!(path), "")),
      function do
        ({_, [[]]}, _) -> nil
        ({:eof}, _)    -> nil

        ({:newline, data}, _) ->
          func.(Enum.map(data, function(list_to_binary/1)))
        end)
  end

  def csv_with(path, func) do
    csv_with(path, nil, func)
  end

  def csv_with(path, acc, func) do
    :ecsv.process_csv_string_with(binary_to_list(Regex.replace(%r{//.*$}gm, File.read!(path), "")),
      function do
        ({_, [[]]}, acc) -> acc
        ({:eof}, acc)    -> acc

        ({:newline, data}, acc) ->
          func.(Enum.map(data, function(list_to_binary/1)), acc)
        end, acc)
  end

  def by_level(collection) do
    {result, _} = Enum.map_reduce collection, 1, fn(element, level) ->
      {{level, element}, level + 1}
    end

    result
  end
end

defmodule Mix.Tasks.Athena.Skill do
  use    Mix.Task
  import Mix.Tasks.Athena

  defp hit(value) do
    if value == 6 do
      :single
    else
      :repeated
    end
  end

  defp inf(value) do
    [{0, :passive}, {1, :enemy}, {2, :place}, {4, :self}, {16, :friend}, {32, :trap}][value]
  end

  defp element(value) do
    elements = [{0, :neutral}, {1, :water}, {2, :earth}, {3, :fire}, {4, :wind}, {5, :poison},
                {6, :holy}, {7, :dark}, {8, :ghost}, {9, :undead}, {-1, :weapon}, {-2, :endowed},
                {-3, :random}]

    if List.member?(String.graphemes(value), ":") do
      Enum.map String.split(value, ":"), fn(num) ->
        elements[binary_to_integer(num)]
      end
    else
      elements[binary_to_integer(value)]
    end
  end

  defp nk(value) do
    use Bitwise

    Enum.reduce [{0x01, :none}, {0x02, :splash}, {0x04, :split}, {0x08, :ignore_damage_cards},
                 {0x10, :ignore_elements}, {0x20, :ignore_defense}, {0x40, :ignore_flee},
                 {0x80, :ignore_defense_cards}], [],
      fn({bit, name}, acc) ->
        if value &&& bit != 0 do
          [name | acc]
        else
          acc
        end
      end
  end

  defp inf2(value) do
    use Bitwise

    Enum.reduce [{0x0001, :quest}, {0x0002, :npc}, {0x0003, :wedding}, {0x0008, :spirit},
                 {0x0010, :guild}, {0x0020, :song}, {0x0040, :ensemble}, {0x0080, :trap},
                 {0x0100, :self}, {0x0200, :not_self}, {0x0400, :party}, {0x0800, :guild},
                 {0x1000, :no_enemies}, {0x2000, :ignore_land_protecto}, {0x4000, :chorus}], [],
      fn({bit, name}, acc) ->
        if value &&& bit != 0 do
          [name | acc]
        else
          acc
        end
      end
  end

  def run([path]) do
    csv path, fn(data) ->
      IO.puts "#{Enum.at! data, 16} > #{String.strip(Enum.at!(data, 15))}"
      IO.puts "01| ID: #{Enum.at! data, 0}"
      IO.puts "02| Range: #{Enum.at! data, 1}"
      IO.puts "03| Hit: #{hit(binary_to_integer(Enum.at!(data, 2)))}"
      IO.puts "04| Inf: #{inf(binary_to_integer(Enum.at!(data, 3)))}"

      case element(Enum.at!(data, 4)) do
        list = [_|_] ->
          IO.puts "05| Elements: #{Enum.join Enum.map(by_level(list), fn({level, element}) ->
              "#{level}[#{element}]"
            end), " "}"

        element -> IO.puts "05| Element: #{element}"
      end

      IO.puts "06| Skill Damage: #{Enum.join nk(binary_to_integer(String.replace(Enum.at!(data, 5), "0x", ""), 16)), " "}"
      IO.puts "07| Effect Range: #{Enum.at!(data, 6)}"
      IO.puts "08| Max Level: #{Enum.at!(data, 7)}"
      IO.puts "09| Hits: #{Enum.at!(data, 8)}"
      IO.puts "10| Cast Interruptible: #{Enum.at!(data, 9)}"
      IO.puts "11| Defense Reduction: #{Enum.at!(data, 10)}"
      IO.puts "12| Inf2: #{Enum.join inf2(binary_to_integer(String.replace(Enum.at!(data, 11), "0x", ""), 16)), " "}"
      IO.puts "13| Max Count: #{Enum.at!(data, 12)}"
      IO.puts "14| Type: #{Enum.at!(data, 13)}"
      IO.puts "15| Knockback: #{Enum.at!(data, 14)}"

      IO.puts ""
    end
  end
end

defmodule Mix.Tasks.Athena.Skill.Cast do
  use    Mix.Task
  import Mix.Tasks.Athena

  defp prepare(value) do
    if List.member?(String.graphemes(value), ":") do
      Enum.map String.split(value, ":"), fn(num) ->
        binary_to_integer(String.strip(num))
      end
    else
      binary_to_integer(String.strip(value))
    end
  end

  def run([path, db]) do
    {:ok, names} = csv_with db, [], fn(data, acc) ->
      [{Enum.at!(data, 0), {Enum.at!(data, 16), String.strip(Enum.at!(data, 15))}} | acc]
    end

    csv path, fn(data) ->
      if names[Enum.at!(data, 0)] do
        IO.puts "#{elem names[Enum.at!(data, 0)], 0} > #{elem names[Enum.at!(data, 0)], 1}"
        IO.puts "01| ID: #{Enum.at!(data, 0)}"

        case prepare(Enum.at!(data, 1)) do
          list = [_|_] ->
            IO.puts "02| Casting Time: #{Enum.join Enum.map(by_level(list), fn({level, time}) ->
              "#{level}[#{time}]"
            end), " "}"

          time -> IO.puts "02| Casting Time: #{time}"
        end

        case prepare(Enum.at!(data, 2)) do
          list = [_|_] ->
            IO.puts "03| After Cast Act Delay: #{Enum.join Enum.map(by_level(list), fn({level, time}) ->
              "#{level}[#{time}]"
            end), " "}"

          time -> IO.puts "03| After Cast Act Delay: #{time}"
        end

        case prepare(Enum.at!(data, 3)) do
          list = [_|_] ->
            IO.puts "04| After Cast Walk Delay: #{Enum.join Enum.map(by_level(list), fn({level, time}) ->
              "#{level}[#{time}]"
            end), " "}"

          time -> IO.puts "04| After Cast Walk Delay: #{time}"
        end

        case prepare(Enum.at!(data, 4)) do
          list = [_|_] ->
            IO.puts "05| Duration1: #{Enum.join Enum.map(by_level(list), fn({level, time}) ->
              "#{level}[#{time}]"
            end), " "}"

          time -> IO.puts "05| Duration1: #{time}"
        end

        case prepare(Enum.at!(data, 5)) do
          list = [_|_] ->
            IO.puts "06| Duration2: #{Enum.join Enum.map(by_level(list), fn({level, time}) ->
              "#{level}[#{time}]"
            end), " "}"

          time -> IO.puts "06| Duration2: #{time}"
        end

        case prepare(Enum.at!(data, 6)) do
          list = [_|_] ->
            IO.puts "07| Cooldown: #{Enum.join Enum.map(by_level(list), fn({level, time}) ->
              "#{level}[#{time}]"
            end), " "}"

          time -> IO.puts "07| Cooldown: #{time}"
        end

        case prepare(Enum.at!(data, 7)) do
          list = [_|_] ->
            IO.puts "08| Fixed Casting Time: #{Enum.join Enum.map(by_level(list), fn({level, time}) ->
              "#{level}[#{time}]"
            end), " "}"

          time -> IO.puts "08| Fixed Casting Time: #{time}"
        end

        IO.puts ""
      end
    end
  end
end

defmodule Mix.Tasks.Athena.Skill.Require do
  use    Mix.Task
  import Mix.Tasks.Athena

  defp prepare(value) do
    if List.member?(String.graphemes(value), ":") do
      Enum.map String.split(value, ":"), fn(num) ->
        binary_to_integer(String.strip(num))
      end
    else
      binary_to_integer(String.strip(value))
    end
  end

  defp required_weapons(value) do
    types = [{0, :unarmed}, {1, :dagger}, {2, :one_handed_sword}, {3, :two_handed_sword},
             {4, :one_handed_spear}, {5, :two_handed_spear}, {6, :one_handed_axe},
             {7, :two_handed_axe}, {8, :mace}, {10, :stave}, {11, :bow}, {12, :knuckles},
             {13, :musical_instrument}, {14, :whip}, {15, :book}, {16, :katar}, {17, :revolver},
             {18, :rifle}, {19, :gatling}, {20, :shotgun}, {21, :grenade_launcher}, {22, :shuriken}]

    Enum.map String.split(value, ":"), fn(num) ->
      types[binary_to_integer(num)]
    end
  end

  defp required_ammo(value) do
    types = [{1, :arrow}, {2, :throwable_dagger}, {3, :bullet}, {4, :shell}, {5, :grenade},
             {6, :shuriken}, {7, :kunai}, {8, :cannonball}, {9, :throwable_item}]

    Enum.map String.split(value, ":"), fn(num) ->
      types[binary_to_integer(num)]
    end
  end


  def run([path, db]) do
    {:ok, names} = csv_with db, [], fn(data, acc) ->
      [{Enum.at!(data, 0), {Enum.at!(data, 16), String.strip(Enum.at!(data, 15))}} | acc]
    end

    csv path, fn(data) ->
      if names[Enum.at!(data, 0)] do
        IO.puts "#{elem names[Enum.at!(data, 0)], 0} > #{elem names[Enum.at!(data, 0)], 1}"
        IO.puts "01| ID: #{Enum.at!(data, 0)}"

        case prepare(Enum.at!(data, 1)) do
          list = [_|_] ->
            IO.puts "02| HP Cost: #{Enum.join Enum.map(by_level(list), fn({level, cost}) ->
              "#{level}[#{cost}]"
            end), " "}"

          cost -> IO.puts "02| HP Cost: #{cost}"
        end

        IO.puts "03| Max HP Trigger: #{Enum.at!(data, 2)}"

        case prepare(Enum.at!(data, 3)) do
          list = [_|_] ->
            IO.puts "04| SP Cost: #{Enum.join Enum.map(by_level(list), fn({level, cost}) ->
              "#{level}[#{cost}]"
            end), " "}"

          cost -> IO.puts "04| SP Cost: #{cost}"
        end

        case prepare(Enum.at!(data, 4)) do
          list = [_|_] ->
            IO.puts "05| HP Rate Cost: #{Enum.join Enum.map(by_level(list), fn({level, cost}) ->
              "#{level}[#{cost}]"
            end), " "}"

          cost -> IO.puts "05| HP Rate Cost: #{cost}"
        end

        case prepare(Enum.at!(data, 5)) do
          list = [_|_] ->
            IO.puts "06| SP Rate Cost: #{Enum.join Enum.map(by_level(list), fn({level, cost}) ->
              "#{level}[#{cost}]"
            end), " "}"

          cost -> IO.puts "06| SP Rate Cost: #{cost}"
        end

        case prepare(Enum.at!(data, 6)) do
          list = [_|_] ->
            IO.puts "07| Zeny Cost: #{Enum.join Enum.map(by_level(list), fn({level, cost}) ->
              "#{level}[#{cost}]"
            end), " "}"

          cost -> IO.puts "07| Zeny Cost: #{cost}"
        end

        IO.puts "08| Required Weapons: #{Enum.join required_weapons(Enum.at!(data, 7)), " "}"
        IO.puts "09| Required Ammo Types: #{Enum.join required_ammo(Enum.at!(data, 8)), " "}"

        case prepare(Enum.at!(data, 9)) do
          list = [_|_] ->
            IO.puts "10| Required Ammo Amount: #{Enum.join Enum.map(by_level(list), fn({level, cost}) ->
              "#{level}[#{cost}]"
            end), " "}"

          cost -> IO.puts "10| Required Ammo Amount: #{cost}"
        end

        IO.puts "11| Required State: #{Enum.at!(data, 10)}"

        case prepare(Enum.at!(data, 11)) do
          list = [_|_] ->
            IO.puts "12| Spirit Sphere Cost: #{Enum.join Enum.map(by_level(list), fn({level, cost}) ->
              "#{level}[#{cost}]"
            end), " "}"

          cost -> IO.puts "12| Spirit Sphere Cost: #{cost}"
        end

        IO.puts "13| Required Item: #{Enum.at!(data, 12)} #{Enum.at!(data, 13)}"
        IO.puts "15| Required Item: #{Enum.at!(data, 14)} #{Enum.at!(data, 15)}"
        IO.puts "17| Required Item: #{Enum.at!(data, 16)} #{Enum.at!(data, 17)}"
        IO.puts "19| Required Item: #{Enum.at!(data, 18)} #{Enum.at!(data, 19)}"
        IO.puts "21| Required Item: #{Enum.at!(data, 20)} #{Enum.at!(data, 21)}"
        IO.puts "23| Required Item: #{Enum.at!(data, 22)} #{Enum.at!(data, 23)}"
        IO.puts "25| Required Item: #{Enum.at!(data, 24)} #{Enum.at!(data, 25)}"
        IO.puts "27| Required Item: #{Enum.at!(data, 26)} #{Enum.at!(data, 27)}"
        IO.puts "29| Required Item: #{Enum.at!(data, 28)} #{Enum.at!(data, 29)}"
        IO.puts "31| Required Item: #{Enum.at!(data, 30)} #{Enum.at!(data, 31)}"


        IO.puts ""
      end
    end
  end
end
