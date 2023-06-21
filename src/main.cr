require "kemal"
require "../config/config"
require "json"

class Travel
  include JSON::Serializable
  property travel_stops : Array(Int32)

end

post "/api/travel-plans" do |env|
  travel = Travel.from_json env.request.body.not_nil!

  json_data = (travel.travel_stops).to_json
  puts travel.travel_stops
   travel_plan = TravelPlans.new({
    :travel_stops => json_data
  })
 
  travel_plan.save

  
  { travel: travel_plan }.to_json
end




get "/api/travel-plans" do |env|
  travels = TravelPlans.all.where{_id > 1}
  env.response.puts travels.to_json
end
get "/api/travel-plans/:id" do |env|
  id = env.params.url["id"]?
  travel = TravelPlans.all.where{_id == id}
  env.response.puts travel.to_json
end
put "/api/travel-plans/:id" do |env|
  id = env.params.url["id"]?
  updatedTravel = Travel.from_json env.request.body.not_nil!
  updatedTravelJson = (updatedTravel.travel_stops).to_json
  travel = TravelPlans.all.where{_id == id}.update{ { :travel_stops => updatedTravelJson } }
  travelUpdated = TravelPlans.all.where{_id == id}
  env.response.puts travelUpdated.to_json
end
delete "/api/travel-plans/:id" do |env|
  id = env.params.url["id"]?
  travelToDelete = TravelPlans.delete(id)
end
Kemal.run