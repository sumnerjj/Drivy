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
	price = ppk * distance
	if period == 1 then
		price += period * ppd
	elsif period > 1 and period <=4 then
		price += ppd * (1 + (period-1) * 0.9 )
	elsif period > 4 and period <= 10 then
		price += ppd * (1 + 3 * 0.9 + (period - 4) * 0.7 )
	elsif period > 10 then
		price += ppd * (1 + 3 * 0.9 + 6 * 0.7 + (period -10) * 0.5 )
	end

	new = {}
	new["id"] = id 
	new["price"] = price.round.to_i
	out[:rentals].push(new)

end

out = JSON.pretty_generate out

f = File.new("output.json", "w+")

f.write(out)
