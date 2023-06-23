require "kemal"
require "../config/config"
require "json"


class Travel
  include JSON::Serializable
  property travel_stops : Array(Int32)
end
class TupleResponse
  include JSON::Serializable
  property id : Int32 
  property travel_stops : Array(RandM)

  def initialize(@id : Int32 = 0, @travel_stops : Array(RandM) = [] of RandM)
  end
end
class RandM
  include JSON::Serializable

  property id : Int32 = 0
  property name : String = ""
  property type : String = ""
  property dimension : String = ""
end

class AllExpandedTravels
  include JSON::Serializable
  property id : Int32
  property travel_stops : Array(RandM)
end

def fetchDataFromApi(id) : Array(RandM)
  counter = 0
  results = [] of RandM
  travel = TravelPlans.all.where{_id == id}
  puts typeof(travel)
  puts travel.to_json
  travelStopsString = travel.to_json(only: %w[travel_stops])
  puts travelStopsString
  numbers = travelStopsString.scan(/\d+/).map { |match| match.to_a }
  puts numbers
  while counter < numbers.size
    url = "https://rickandmortyapi.com/api/location/#{numbers[counter][0]}"
    puts url
    response = HTTP::Client.get(url)
    response_json = JSON.parse(response.body.to_s)
    results << RandM.from_json(response_json.to_json)
    counter += 1
  end
  
   return results
end
def fetchMultipleDataFromApi(ids : Array(Int32)) : Array(TupleResponse)
 
  expandedTravels = Array(TupleResponse).new
  allResults = Array(Array(RandM)).new
  counter = 0
  counterW = 0
  

  ids.each do |id|
    travelTuple = TupleResponse.new
    results = Array(RandM).new
    travel = TravelPlans.all.where{_id == id}
    travelStopsString = travel.to_json(only: %w[travel_stops])
    numbers = travelStopsString.scan(/\d+/).map { |match| match.to_a }
    counterW = 0

    while counterW < numbers.size
      url = "https://rickandmortyapi.com/api/location/#{numbers[counterW][0]}"
      response = HTTP::Client.get(url)
      response_json = JSON.parse(response.body.to_s)
      results << RandM.from_json(response_json.to_json)
      counterW += 1
    end
    travelTuple.id = id
    travelTuple.travel_stops = results
    expandedTravels << travelTuple
    allResults << results
    counter += 1
  end
  counter = 0

  return expandedTravels
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
  countW = 0
  countK = 0
  travels = TravelPlans.all.where{_id > 0}
  expand   = env.params.query["expand"]? == "true"
  optimize = env.params.query["optimize"]? == "true"
  # expandedTravels = AllExpandedTravels.from_json
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
  id : String = env.params.url["id"]
  optimize = env.params.url["optimize"]?
  expand   = env.params.query["expand"]? 
  
  randm = fetchDataFromApi(id)
 

  travels = TravelPlans.all.where{_id == id}
  if expand
  exandedResponse = {
    id: id.to_i,
    travel_stops: randm
  }
    env.response.puts exandedResponse.to_json
  else
    env.response.puts travels.to_json(only: %w[id travel_stops])
    end
  
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