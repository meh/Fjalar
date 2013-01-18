# Copyleft (ɔ) meh. - http://meh.schizofreni.co
#
# This file is part of Fjalar - https://github.com/meh/Fjalar
#
# Fjalar is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Fjalar is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fjalar. If not, see <http://www.gnu.org/licenses/>.

defrecord Fjalar.Game.Skill, name: nil, id: nil, code: nil,
                             max: [],
                             range: [],
                             target: [],
                             hits: 0,
                             knockback: 0,
                             type: :none,
                             element: :neutral,
                             defense_reduction: 0,
                             cast: [],
                             forbidden: [],
                             requirements: [],
                             attributes: [],
                             events: [] do
  @attributes [
    :passive, :target_enemy, :target_place, :target_self, :target_friend,
    :interruptible, :no_damage, :splash_damage, :split_damage, :ignore_damage_cards,
    :ignore_elements, :ignore_defense, :ignore_flee, :ignore_defense_cards, :quest,
    :npc, :wedding, :spirit, :guild, :song, :dance, :ensemble, :trap, :chorus,
    :target_others, :target_party, :target_guild, :target_enemy_explicitly,
    :ignore_land_protector
  ]


  defmodule DSL do
    def expand(name, do: block) do
      expand(name, [], do: block)
    end

    def expand(name, values, do: block) do
      quote do
        import unquote(__MODULE__)

        skill = Fjalar.Game.Skill.new([{:name, unquote(name)} | unquote(values)])
        unquote(block)

        Fjalar.set_skill var!(__SERVER__), skill
      end
    end

    defmacro id(value) do
      quote do
        skill = skill.id(unquote(value))
      end
    end

    defmacro code(value) do
      quote do
        skill = skill.code(unquote(value))
      end
    end

    defmacro max(values) when is_list values do
      quote do
        skill = skill.max(unquote(values))
      end
    end

    defmacro max(value) do
      max(level: value)
    end

    defmacro range(values) when is_list values do
      quote do
        skill = skill.range(unquote(values))
      end
    end

    defmacro range(value) do
      range(target: value)
    end

    defmacro target(values) when is_list values do
      quote do
        skill = skill.target(values)
      end
    end

    defmacro target(value) do
      target([value])
    end

    defmacro forbidden(values) when is_list values do
      quote do
        skill = skill.forbidden(values)
      end
    end

    defmacro forbidden(value) do
      forbidden([value])
    end

    defmacro hits(values) do
      quote do
        skill = skill.hits(unquote(values))
      end
    end

    defmacro knockback(value) do
      quote do
        skill = skill.knockback(unquote(value))
      end
    end

    defmacro type(value) do
      quote do
        skill = skill.type(unquote(value))
      end
    end

    defmacro element(value) do
      quote do
        skill = skill.element(unquote(value))
      end
    end

    defmacro defense_reduction(value) do
      quote do
        skill = skill.defense_reduction(unquote(value))
      end
    end

    defmacro on(event, do: block) do
      quote do
        skill = skill.update_events(Dict.put(&1, unquote(event), fn(var!(self)) -> unquote(block) end))
      end
    end
  end
end
