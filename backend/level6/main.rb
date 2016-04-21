require "json"
require 'date'

data = File.read('data.json')
data_hash = JSON.parse(data)

class Rental_data
	attr_reader :original_actions, :modified_rentals, :modified_actions, :rentals, :delta
	def initialize(data_hash)
		@rentals = data_hash["rentals"]
		@cars = data_hash["cars"]
		@modifications = data_hash["rental_modifications"]
		@original_actions = rental_actions(@rentals)
		@modified_rentals = modify_rentals(@rentals, @modifications)
		@modified_actions = rental_actions(@modified_rentals)
		@delta = calculate_delta(@original_actions, @modified_actions)
	end
	
	def calculate_delta (original_actions, modified_actions)
		delta = {"rental_modifications": []}
		@modifications.each do |mod|
			rental_id = mod["rental_id"]
			new = {}
			new[:id] = mod["id"]
			new[:rental_id] = rental_id
			new[:actions] = []
			(0..4).each do |i|
				oldaction = original_actions[:rentals][rental_id-1]["actions"][i]
				newaction = modified_actions[:rentals][rental_id-1]["actions"][i]
				who = oldaction[:who]
				amount = (newaction[:amount] - oldaction[:amount])
				type = oldaction[:type]
				if amount < 0 then
					type == "credit" ? type = "debit" : type = "credit"
				end
				amount = amount.abs
				addaction = {"who": who, "type": type, "amount": amount}
				new[:actions].push(addaction)
			end
				delta[:rental_modifications].push(new)
		end
		return delta
	end

	def modify_rentals(rental_list, modifications)
		new_rentals = Marshal.load( Marshal.dump(rental_list) )
			modifications.each do |mod|
			updates = mod.keys.clone
			updates.delete("id")
			updates.delete("rental_id")
			updates.each do |update|
			new_rentals[mod["rental_id"] -1 ][update]=mod[update]
			end
		end
		return new_rentals
	end

	def rental_actions(rental_list)
		rental_actions = {"rentals": []}
		rental_list.each do |rental|
			id = rental["id"]
			car_id = rental["car_id"]
			distance = rental["distance"]
			start_date =  DateTime.parse(rental["start_date"]).to_date
			end_date =  DateTime.parse(rental["end_date"]).to_date

			period = (end_date - start_date + 1).to_i
			ppd = @cars[car_id -1]["price_per_day"]
			ppk = @cars[car_id -1]["price_per_km"]
			rental_fee = ppk * distance
			if period == 1 then
				rental_fee += period * ppd
			elsif period > 1 and period <=4 then
				rental_fee += ppd * (1 + (period-1) * 0.9 )
			elsif period > 4 and period <= 10 then
				rental_fee += ppd * (1 + 3 * 0.9 + (period - 4) * 0.7 )
			elsif period > 10 then
				rental_fee += ppd * (1 + 3 * 0.9 + 6 * 0.7 + (period -10) * 0.5 )
			end

			total_commission = rental_fee * 0.3
			insurance = total_commission/2
			assistance = 100 * period
			drivy_fee = total_commission - insurance - assistance
			deductible_amount = 0
			deductible_amount += period * 400 if rental["deductible_reduction"]
			drivy_credit = drivy_fee + deductible_amount
			driver_pays = rental_fee + deductible_amount

			credits = [["owner", rental_fee - total_commission ], ["insurance", insurance], ["assistance", assistance], ["drivy", drivy_credit]]

			actions = [{"who": "driver", "type": "debit", "amount": driver_pays.round.to_i}]

			credits.each do |actor|
				action = {"who": actor[0], "type": "credit", "amount": actor[1].round.to_i}
				actions.push(action)
			end
			
			new = {}
			new["id"] = id 
			new["actions"] = actions
			rental_actions[:rentals].push(new)

		end
		return rental_actions
	end
end

rental_data = Rental_data.new(data_hash)

out = rental_data.delta

out = JSON.pretty_generate out

f = File.new("output.json", "w+")

f.write(out)
