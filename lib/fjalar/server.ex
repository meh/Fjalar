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

defrecord Fjalar.Server, [:name, :skills, :mobs, :items] do
  @ets_options [keypos: 2, read_concurrency: true]

  def new!(name) do
    new(name: name,
        skills: :ets.new(:skills, @ets_options),
        mobs:   :ets.new(:mobs, @ets_options),
        items:  :ets.new(:items, @ets_options))
  end

  def add_skill(skill, self) do
    :ets.insert(self.skills, { String.downcase(skill.name), skill.id, skill })
  end

  def get_skill(name, self) do
    case :ets.lookup(self.skills, String.downcase(name)) do
      [{ _, _, skill }] -> skill
      _                 -> nil
    end
  end

  def get_skill_by(what, thing, self) do
    case (case what do
      :id   -> :ets.match_object(self.skills, { :_, thing, :_ })
      :name -> :ets.match_object(self.skills, { String.downcase(thing), :_, :_ })
    end) do
      [{ _, _, skill }] -> skill
      _                 -> nil
    end
  end
end
