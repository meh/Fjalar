defrecord Fjalar.Skill, [:name, :id] do
  def apply(block, skill) do
    IO.inspect block

    skill
  end

  def no_damage?(skill) do
  end
end
