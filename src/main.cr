require "kemal"
require "../config/config"
require "json"

class Travel
  include JSON::Serializable
  property travel_stops : Array(Int32)
end

class RandM
  include JSON::Serializable

  property id : Int32 = 0
  property name : String = ""
  property type : String = ""
  property dimension : String = ""
end


def fetchDataFromApi(id) : RandM
  url = "https://rickandmortyapi.com/api/location/#{id}"
  response = HTTP::Client.get(url)
  response_json = JSON.parse(response.body.to_s)
  return RandM.from_json(response_json.to_json)
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
  optimize = env.params.url["optimize"]?
  expand = env.params.url["expand"]?
  
  # randm = fetchDataFromApi(id)
  # puts randm.to_json




  env.response.puts travels.to_json
end
get "/api/travel-plans/:id" do |env|
  id = env.params.url["id"]?
  optimize = env.params.url["optimize"]?
  expand = env.params.url["expand"]?
  
  randm = fetchDataFromApi(id)
  puts randm.to_json

  travel = TravelPlans.all.where{_id == id}
  expandedTravel = {
    id: randm.id,
    travel_stops:{
      id: randm.id,
      name: randm.name,
      type: randm.type,
      dimension: randm.dimension
    }
  }
 
  env.response.puts expandedTravel.to_json
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