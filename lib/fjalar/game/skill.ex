defmodule Fjalar.Game.Skill do
  defp unfold({ :__block__, _line, blocks }) do
    { :__block__, _line, Enum.map(blocks, function(unfold/1)) }
  end

  defp unfold({ :id, _, [number] }) do
    quote do
      var!(__SKILL__) = var!(__SKILL__).update_id(fn(_) -> unquote(number) end)
    end
  end

  defmacro skill(name) do
    quote do
      Fjalar.get_skill var!(__SERVER__), unquote(name)
    end
  end

  defmacro skill(name, do: block) do
    quote do
      var!(__SKILL__) = Fjalar.Skill.new(name: unquote(name))

      unquote(unfold(block))

      Fjalar.set_skill var!(__SERVER__), var!(__SKILL__)
    end
  end
end
