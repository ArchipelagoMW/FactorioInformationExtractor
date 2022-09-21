function dumpModInfo()
	game.write_file("mods.json", game.table_to_json(game.active_mods), false)
	game.print("Exported Mod List")
end

recipe_data_collection = {}

function dumpRecipe(recipe, unlocked_at_start)
	if recipe_data_collection[recipe] ~= nil then
		-- recipe is already known.
		return
	end
	local recipe_data = {}
	recipe_data["ingredients"] = {}
	recipe_data["products"] = {}
	recipe_data["category"] = recipe.category
	recipe_data["energy"] = recipe.energy
	recipe_data["unlocked_at_start"] = unlocked_at_start
	for _, ingredient in pairs(recipe.ingredients) do
		recipe_data["ingredients"][ingredient.name] = ingredient.amount
	end
	for _, product in pairs(recipe.products) do
		recipe_data["products"][product.name] = product.amount
	end
	recipe_data_collection[recipe.name] = recipe_data
end

function dumpRecipeInfo(force)
    data_collection = {}
    for recipe_name, recipe in pairs(force.recipes) do
        if recipe.enabled then
            dumpRecipe(recipe, true)
        end
    end
    game.print("Exported Unlocked Recipe Data")
end

function dumpTechInfo(force)
    local data_collection = {}

    for tech_name, tech in pairs(force.technologies) do
        if tech.enabled and tech.research_unit_count_formula == nil then
            local tech_data = {}
            local unlocks = {}
            tech_data["unlocks"] = unlocks
            local requires = {}
            tech_data["requires"] = requires
            local ingredients = {}
            tech_data["ingredients"] = ingredients
            tech_data["has_modifier"] = false
            for tech_requirement, _ in pairs(tech.prerequisites) do
                table.insert(requires, tech_requirement)
            end
            for _, modifier in pairs(tech.effects) do
                if modifier.type == "unlock-recipe" then
                    table.insert(unlocks, modifier.recipe)
					dumpRecipe(force.recipes[modifier.recipe], false)
                else
                    tech_data["has_modifier"] = true
                end
            end
            for _, ingredient in pairs(tech.research_unit_ingredients) do
                table.insert(ingredients, ingredient.name)
            end
            data_collection[tech_name] = tech_data
            tech.researched = true -- enable all available recipes
        end
        game.write_file("techs.json", game.table_to_json(data_collection), false)
		game.write_file("recipes.json", game.table_to_json(recipe_data_collection), false)
        game.print("Exported Tech and Recipe Data")
    end
end

function dumpMachineInfo()
    data_collection = {}
    for _, proto in pairs(game.entity_prototypes) do
		if proto.crafting_categories or proto.type == "character" then
			data_collection[proto.name] = {}
			data_collection[proto.name]["crafting"] = {} 
			data_collection[proto.name]["crafting"]["type"] = proto.type
			data_collection[proto.name]["crafting"]["speed"] = proto.crafting_speed or 1
			data_collection[proto.name]["crafting"]["categories"] = proto.crafting_categories
			data_collection[proto.name]["crafting"]["fixed_recipe"] = proto.fixed_recipe
			data_collection[proto.name]["crafting"]["input_fluid_box"] = 0
			data_collection[proto.name]["crafting"]["output_fluid_box"] = 0
			for _, fluid_box in pairs(proto.fluidbox_prototypes) do
				for _, connection in pairs(fluid_box.pipe_connections) do
					if connection.type == "input" then
						data_collection[proto.name]["crafting"]["input_fluid_box"] = data_collection[proto.name]["crafting"]["input_fluid_box"] + 1
					end
					if connection.type == "output" then
						data_collection[proto.name]["crafting"]["output_fluid_box"] = data_collection[proto.name]["crafting"]["output_fluid_box"] + 1
					end
				end
			end
		end
		if proto.resource_categories then
			data_collection[proto.name] = data_collection[proto.name] or {}
			data_collection[proto.name]["mining"] = {}
			data_collection[proto.name]["mining"]["type"] = proto.type
			data_collection[proto.name]["mining"]["categories"] = proto.resource_categories
			data_collection[proto.name]["mining"]["speed"] = proto.mining_speed
			data_collection[proto.name]["mining"]["input_fluid_box"] = false
			data_collection[proto.name]["mining"]["output_fluid_box"] = false
			for _, fluid_box in pairs(proto.fluidbox_prototypes) do
				for _, connection in pairs(fluid_box.pipe_connections) do
					if connection.type == "input-output" or connection.type == "input" then
						data_collection[proto.name]["mining"]["input_fluid_box"] = true
					end
					if connection.type == "output" then
						data_collection[proto.name]["mining"]["output_fluid_box"] = true
					end
				end
			end
		end
		if proto.lab_inputs then
			data_collection[proto.name] = {}
			data_collection[proto.name]["lab"] = {}
			data_collection[proto.name]["lab"]["inputs"] = proto.lab_inputs
		end
		if proto.fluid then
			data_collection[proto.name] = {}
			data_collection[proto.name]["offshore-pump"] = {}
			data_collection[proto.name]["offshore-pump"]["type"] = proto.type
			data_collection[proto.name]["offshore-pump"]["fluid"] = proto.fluid.name
			data_collection[proto.name]["offshore-pump"]["speed"] = proto.pumping_speed
		end
		if proto.type == "boiler" then
			local input_fluid = nil
			local output_fluid = nil
			for _, fluid_box in pairs(proto.fluidbox_prototypes) do
				if fluid_box.production_type == "input-output" or fluid_box.production_type == "input" then
					input_fluid = fluid_box
				end
				if fluid_box.production_type == "output" then
					output_fluid = fluid_box
				end
			end
			if input_fluid and output_fluid  then
				data_collection[proto.name] = {}
				data_collection[proto.name]["boiler"] = {}
				data_collection[proto.name]["boiler"]["type"] = proto.type
				data_collection[proto.name]["boiler"]["input_fluid"] = input_fluid.filter.name
				data_collection[proto.name]["boiler"]["output_fluid"] = output_fluid.filter.name
				data_collection[proto.name]["boiler"]["target_temperature"] = proto.target_temperature
				data_collection[proto.name]["boiler"]["energy_usage"] = proto.max_energy_usage
			end
		end
		if proto.burner_prototype and proto.burner_prototype.burnt_inventory_size > 0 then
			-- Only really care about burners that have at least one slot to store the burnt result.
			data_collection[proto.name] = data_collection[proto.name] or {}
			data_collection[proto.name]["fuel_burner"] = {}
			data_collection[proto.name]["fuel_burner"]["type"] = proto.type
			data_collection[proto.name]["fuel_burner"]["categories"] = proto.burner_prototype.fuel_categories
			data_collection[proto.name]["fuel_burner"]["energy_usage"] = proto.max_energy_usage			
		end
    end
    game.write_file("machines.json", game.table_to_json(data_collection), false)
    game.print("Exported Machine Data")
end

function dumpResourceInfo()
    data_collection = {}
    for _, proto in pairs(game.autoplace_control_prototypes) do
        if proto.category == "resource" then
            local r_proto = game.entity_prototypes[proto.name]
            local minable = r_proto.mineable_properties
            local resource = {}
            resource["minable"] = minable.minable
            resource["infinite"] = r_proto.infinite_resource
            if r_proto.infinite_resource then
                resource["infinite_depletion"] = r_proto.infinite_depletion_resource_amount
            end
            resource["category"] = r_proto.resource_category
            resource["mining_time"] = minable.mining_time
            resource["required_fluid"] = minable.required_fluid
            resource["fluid_amount"] = minable.fluid_amount
            resource["products"] = {}
            for _, product in pairs(minable.products) do
                resource["products"][product.name] = {}
                -- resource["products"][product.name]["type"] = product.type
                resource["products"][product.name]["name"] = product.name
                if product.amount then
                    resource["products"][product.name]["amount"] = product.amount
                else
                    resource["products"][product.name]["amount"] = product.probability * (product.amount_min+product.amount_max)/2
                end
                resource["products"][product.name]["catalyst_amount"] = product.catalyst_amount
                -- hopefully don't need this
                -- if product.type == "fluid" then
                --     resource["products"][product.name]["temperature"] = product.temperature
                -- end
            end
            data_collection[proto.name] = resource
        end
    end
    game.write_file("resources.json", game.table_to_json(data_collection), false)
    game.print("Exported Minable Resource Data")
end

function dumpItemInfo()
    data_collection = {}
    for _, item in pairs(game.item_prototypes) do
        data_collection[item.name] = {}
		data_collection[item.name]["stack_size"] = item.stack_size
		if item.burnt_result then
			data_collection[item.name]["fuel_value"] = item.fuel_value
			data_collection[item.name]["fuel_category"] = item.fuel_category
			data_collection[item.name]["burnt_result"] = item.burnt_result.name
		end
		for _, launch_product in pairs(item.rocket_launch_products) do
			data_collection[item.name]["rocket_launch_products"] = data_collection[item.name]["rocket_launch_products"] or {}
			if launch_product.amount then
				data_collection[item.name]["rocket_launch_products"][launch_product.name] = launch_product.amount
			else
				amount =  math.max(((launch_product.amount_min + launch_product.amount_max) / 2) * launch_product.probablility, 1)
				data_collection[item.name]["rocket_launch_products"][launch_product.name] = amount
			end
		end
		--stackable property incorrectly reports true for "spidertron-remote"
		data_collection[item.name]["stackable"] = item.stackable
		if item.type == "spidertron-remote" then
			data_collection[item.name]["stackable"] = false
		end
		if item.place_result then
			data_collection[item.name]["place_result"] = item.place_result.name
		end
    end

    game.write_file("items.json", game.table_to_json(data_collection), false)
    game.print("Exported Item Data")
end

function dumpFluidInfo()
    data_collection = {}
    for _, item in pairs(game.fluid_prototypes) do
		fluid = {}
		fluid["default_temperature"] = item.default_temperature
		fluid["max_temperature"] = item.max_temperature
		fluid["heat_capacity"] = item.heat_capacity
        data_collection[item.name] = fluid
    end

    game.write_file("fluids.json", game.table_to_json(data_collection), false)
    game.print("Exported Fluid Data")
end

function mod_is_AP(str)
    -- lua string.match is way more restrictive than regex. Regex would be "^AP-W?\d{20}-P[1-9]\d*-.+$"
	local result = string.match(str, "^AP%-W?%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%-P[1-9]%d-%-.+$")
	if result ~= nil then
		log("Archipelago Mod: " .. result .. " is loaded.")
	end
	return result ~= nil
end

function dumpGameInfo()
	-- Verify that Archipelago is NOT running before dumping the info.
	for name, _ in pairs(game.active_mods) do
		if mod_is_AP(name) then
			game.print("ERROR: Archipelago is running. Can't dump info")
			return
		end
	end

    -- dump Game Information that the Archipelago Randomizer needs.
    local force = game.forces["player"]
	dumpModInfo()
	dumpRecipeInfo(force)
    dumpTechInfo(force)
    dumpResourceInfo()
    dumpMachineInfo()
    dumpItemInfo()
    dumpFluidInfo()
end

commands.add_command("ap-get-info-dump", "Dump Game Info, used by Archipelago.", function(call)
    dumpGameInfo()
end)
