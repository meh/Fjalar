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

defmodule Fjalar.Game do
  defmodule DSL do
    defmacro skill(name, do: block) do
      Fjalar.Game.Skill.DSL.expand(name, do: block)
    end
  end
end
