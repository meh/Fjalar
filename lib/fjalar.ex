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
        handle [{name, Fjalar.Server.new!(name)} | servers]

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

  def load_server(name, path) do
    :fjalar <- { :new, name }

    Enum.each File.wildcard("#{path}/**/*.exs"), fn(file) ->
      { :ok, content } = File.read file

      Code.eval content, [__SERVER__: name], [
        file: file,
        line: 1,

        requires: [Fjalar.Game.DSL, Kernel],
        macros:   [{Fjalar.Game.DSL, [{:skill, 2}]}]
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
      server = Fjalar.Server[name: ^server, skills: skills] ->
        server.get_skill(name)
    end
  end
end
