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
    Process.register Process.spawn(Fjalar, :handle, [[]]), :fjalar
  end

  def stop do
    :fjalar <- :stop
  end

  def handle(servers) do
    receive do
      { :new, name } ->
        handle OrdDict.put_new(servers, name, Fjalar.Server.new!(name))

      { :define, name, skill = Fjalar.Game.Skill[] } ->
        server = servers[name]
        table  = server.add_skill(skill)

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

          Code.eval content, [__SERVER__: name], [
            file: file,
            line: 1,

            requires: [Fjalar.Game.DSL, Kernel],
            macros:   [{Fjalar.Game.DSL, [skill: 2]}]
          ]

          IO.puts " done"

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
