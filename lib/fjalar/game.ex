defmodule Fjalar.Game do
  defmodule DSL do
    defmacro skill(name, do: block) do
      Fjalar.Game.Skill.DSL.expand(name, do: block)
    end
  end
end
