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

defmodule Mix.Tasks.Athena do
  defmodule Skills do
    use    Mix.Task
    import Fjalar.Mixfile.Helpers

    defp hit(value) do
      if value == 6 do
        :single
      else
        :repeated
      end
    end

    def inf(value) do
      [{0, :passive}, {1, :enemy}, {2, :place}, {4, :self}, {16, :friend}, {32, :trap}][value]
    end

    def element(value) do
      elements = [{0, :neutral}, {1, :water}, {2, :earth}, {3, :fire}, {4, :wind}, {5, :poison},
                  {6, :holy}, {7, :dark}, {8, :ghost}, {9, :undead}, {-1, :weapon}, {-2, :endowed},
                  {-3, :random}]

      if List.member?(String.codepoints(value), ":") do
        Enum.reduce String.split(value, ":"), [], fn(num, acc) ->
          [elements[binary_to_integer(num)] | acc]
        end
      else
        elements[binary_to_integer(value)]
      end
    end

    def nk(value) do
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

    def inf2(value) do
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
          list = [_|_] ->  IO.puts "05| Elements: #{Enum.join(list, " ")}"
          element      ->  IO.puts "05| Element: #{element}"
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

        IO.puts "---"
      end
    end
  end
end
