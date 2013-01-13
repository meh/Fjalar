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

defmodule Fjalar do
  def start do
    Process.register Process.spawn(Fjalar, :handle, [OrdDict.new]), :fjalar
  end

  def stop do
    :fjalar <- :stop
  end

  def handle(servers) do
    receive do
      { :new, name } ->
        handle OrdDict.put_new(servers, name, Fjalar.Server.new!(name))

      { :define, name, skill = Fjalar.Game.Skill[] } ->
        OrdDict.get!(servers, name).add_skill(skill)

        handle servers

      { :get, name, to } ->
        to <- servers[name]

        handle servers

      :stop -> :ok
    end
  end

  def load_server(name, path) when is_list path do
    Enum.each path, fn(path) ->
      load_server(name, path)
    end
  end

  def load_server(name, path) do
    :fjalar <- { :new, name }

    Enum.each File.wildcard("#{path}/**/*.exs"), fn(file) ->
      case File.read(file) do
        { :ok, content } ->
          IO.write "Loading #{file}..."

          try do
            Code.compile_string "import Fjalar.Game.DSL; __SERVER__ = #{inspect name, raw: true}; " <> content, file

            IO.puts " done"
          catch kind, reason ->
            IO.puts " error\n"

            :erlang.raise(kind, reason, System.stacktrace)
          end

        { :error, reason } ->
          IO.puts "Error while loading #{file}: #{reason}"
      end
    end
  end

  def set_skill(server, skill) do
    :fjalar <- { :define, server, skill }

    skill
  end

  def get_skill(server, name) do
    :fjalar <- { :get, server, Process.self }

    receive do
      server = Fjalar.Server[name: ^server] ->
        server.get_skill(name)
    end
  end
end
