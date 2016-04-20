require "json"
require 'date'

data = File.read('data.json')
data_hash = JSON.parse(data)

out = {"rentals": []}
rentals = data_hash["rentals"]
cars = data_hash["cars"]

rentals.each do |rental|
	id = rental["id"]
	car_id = rental["car_id"]
	distance = rental["distance"]
	start_date =  DateTime.parse(rental["start_date"]).to_date
	end_date =  DateTime.parse(rental["end_date"]).to_date

	period = (end_date - start_date + 1).to_i
	ppd = cars[car_id -1]["price_per_day"]
	ppk = cars[car_id -1]["price_per_km"]
	price = period * ppd + distance * ppk

	new = {}
	new["id"] = id 
	new["price"] = price
	out[:rentals].push(new)

end

out = JSON.pretty_generate out

f = File.new("output.json", "w+")

f.write(out)
