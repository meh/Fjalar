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

defrecord Fjalar.Game.Skill, name: nil, id: nil,
                             max_level: 0,
                             range: 0,
                             effect_range: 0,
                             hits: 0,
                             knockback: 0,
                             max_placement: 0,
                             type: :none,
                             element: :neutral,
                             defense_reduction: 0,
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

  def melee?(self) do
    self.range >= -1 && self.range < 5
  end

  def ranged?(self) do
    self.range >= 5
  end

  def screen_wide?(self) do
    self.range < 0
  end

  def single_hit?(self) do
    !self.passive? && self.hits == 1
  end

  def repeated_hit?(self) do
    !self.passive? && !self.single_hit?
  end

  def hits_for(level, self) do
    if is_list self.hits do
      Enum.find_value self.hits, fn({levels, hits}) ->
        if List.member?(levels, level), do: hits
      end
    else
      self.hits
    end
  end

  Enum.each @attributes, fn(name) ->
    def :"#{name}?", quote(do: [self]), [], do: (quote do
      :ordsets.is_element(unquote(name), self.attributes)
    end)
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

    defmacro max_level(value) do
      quote do
        skill = skill.max_level(unquote(value))
      end
    end

    defmacro range(value) do
      if value == :melee do
        quote do
          skill = skill.range(-1)
        end
      else
        quote do
          skill = skill.range(unquote(value))
        end
      end
    end

    defmacro effect_range(value) do
      if value == :screen do
        quote do
          skill = skill.effect_range(-1)
        end
      else
        quote do
          skill = skill.effect_range(unquote(value))
        end
      end
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

    defmacro max_placement(value) do
      quote do
        skill = skill.max_placement(unquote(value))
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

    Enum.each Module.get_attribute(Fjalar.Game.Skill, :attributes), fn(name) ->
      defmacro :"#{name}!", [], [], do: (quote do
        quote do
          skill = skill.update_attributes(fn(attributes) ->
            :ordsets.add_element(unquote(name), attributes)
          end)
        end
      end)
    end

    defmacro on(event, do: block) do
      quote do
        skill = skill.update_events(Dict.put(&1, unquote(event), fn(var!(self)) -> unquote(block) end))
      end
    end
  end
end
