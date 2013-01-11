defrecord Fjalar.Game.Skill, [:name, :id, {:on, []}] do
  def no_damage?(skill) do
    !skill
  end

  defmodule DSL do
    def expand(name, do: block) do
      quote do
        import unquote(__MODULE__)

        skill = Fjalar.Game.Skill.new(name: unquote(name))
        unquote(block)

        Fjalar.set_skill var!(__SERVER__), skill
      end
    end

    defmacro id(value) do
      quote do
        skill = skill.id(unquote(value))
      end
    end

    defmacro on(event, do: block) do
      quote do
        skill = skill.update_on(Dict.put(&1, unquote(event), fn(var!(self)) -> unquote(block) end))
      end
    end
  end
end
