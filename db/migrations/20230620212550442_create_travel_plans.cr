class CreateTravelPlans < Jennifer::Migration::Base
  def up
    create_table :travel_plans do |t|
      t.json :travel_stops, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :travel_plans if table_exists? :travel_plans
  end
end
