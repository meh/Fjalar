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
        handle [{name, Fjalar.Server.new!(name: name)} | servers]

      { :define, name, skill = Fjalar.Skill[] } ->
        IO.puts "wat"

        server = servers[name]
        table  = server[:skills]

        IO.puts "LOL"
        :ets.insert(table, skill)
        IO.puts "WUT"

        handle servers

      { :get, name, to } ->
        to <- servers[name]

        handle servers

      :stop -> :ok
    end
  end

  def load_server(name, path) do
    :fjalar <- { :new, name }

    Enum.each File.wildcard("#{path}/**/*.exs"), fn(file) ->
      { :ok, content } = File.read file

      Code.eval content, [__SERVER__: name], [
        file: file,
        line: 0,

        requires: [Fjalar.Game.Skill],
        macros:   [{Fjalar.Game.Skill, [{:skill, 1}, {:skill, 2}]}]
      ]
    end
  end

  def set_skill(server, skill) do
    :fjalar <- { :define, server, skill }

    skill
  end

  def get_skill(server, name) do
    :fjalar <- { :get, server, Process.self }

    receive do
      Fjalar.Server[name: ^server, skills: skills] ->
        Enum.first(:ets.lookup(skills, name))
    end
  end
end
