defrecord Fjalar.Server, [:name, :skills, :mobs, :items] do
  @ets_options [keypos: 2, read_concurrency: true]

  def new!(name) do
    new(name: name,
        skills: :ets.new(:skills, @ets_options),
        mobs:   :ets.new(:mobs, @ets_options),
        items:  :ets.new(:items, @ets_options))
  end

  def add_skill(skill, self) do
    :ets.insert(self.skills, skill)
  end

  def get_skill(name, self) do
    Enum.first(:ets.lookup(self.skills, name))
  end
end
