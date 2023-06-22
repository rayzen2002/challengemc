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
def fetchMultipleDataFromApi(ids : Array(Int32)) : Array(RandM)
  results = [] of RandM

  ids.each do |id|
    url = "https://rickandmortyapi.com/api/location/#{id}"
    response = HTTP::Client.get(url)
    response_json = JSON.parse(response.body.to_s)
    results << RandM.from_json(response_json.to_json)
  end

  results
end

post "/api/travel-plans" do |env|
  travel = Travel.from_json env.request.body.not_nil!

  json_data = (travel.travel_stops).to_json
  puts travel.travel_stops
   travel_plan = TravelPlans.new({
    :travel_stops => json_data
  })
 
  travel_plan.save

  
  # { travel: travel_plan }.to_json
  env.response.puts travel_plan.to_json(only: %w[id travel_stops])
end

get "/api/travel-plans" do |env|
  ids = [] of Int32
  counter = 0
  travels = TravelPlans.all.where{_id > 1}
  expand   = env.params.query["expand"]? == "true"
  optimize = env.params.query["optimize"]? == "true"
  
  lastTravel = travels.last
  
  if expand
    if lastTravel
      id = lastTravel.id
      if id
        while counter < id
          counter += 1
          ids << counter
        end
      end
      randm = fetchMultipleDataFromApi(ids)
      env.response.puts randm.to_json
    else
      env.response.puts "{}" # Return empty JSON object if lastTravel is Nil
    end
  else
  env.response.puts travels.to_json(only: %w[id travel_stops])
  end
end




get "/api/travel-plans/:id" do |env|
  id = env.params.url["id"]?
  optimize = env.params.url["optimize"]?
  expand   = env.params.query["expand"]? == "true"
  
  randm = fetchDataFromApi(id)
 

  travel = TravelPlans.all.where{_id == id}
  if expand
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
  env.response.puts travel.to_json(only: %w[id travel_stops])
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