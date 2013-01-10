defrecord Fjalar.Server, [:name, :skills, :mobs, :items] do
  def new!(name) do
    new(name: name,
        skills: :ets.new(:skills, []),
        mobs:   :ets.new(:mobs, []),
        items:  :ets.new(:items, []))
  end
end
