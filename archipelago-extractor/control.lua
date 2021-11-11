function dumpGameInfo()
    -- dump Game Information that the Archipelago Randomizer needs.
    local data_collection = {}
    local force = game.forces["player"]
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
        game.print("Exported Tech Data")
    end
    data_collection = {}
    for recipe_name, recipe in pairs(force.recipes) do
        if recipe.enabled then
            local recipe_data = {}
            recipe_data["ingredients"] = {}
            recipe_data["products"] = {}
            recipe_data["category"] = recipe.category
            recipe_data["energy"] = recipe.energy
            for _, ingredient in pairs(recipe.ingredients) do
                recipe_data["ingredients"][ingredient.name] = ingredient.amount
            end
            for _, product in pairs(recipe.products) do
                recipe_data["products"][product.name] = product.amount
            end
            data_collection[recipe_name] = recipe_data
        end
    end
    game.write_file("recipes.json", game.table_to_json(data_collection), false)
    game.print("Exported Recipe Data")
    data_collection = {}
    for _, proto in pairs(game.entity_prototypes) do
        if proto.crafting_categories or proto.resource_categories then
            data_collection[proto.name] = {}
            if proto.crafting_categories then
                data_collection[proto.name]["crafting"] = {}
                data_collection[proto.name]["crafting"]["speed"] = proto.crafting_speed
                data_collection[proto.name]["crafting"]["categories"] = proto.crafting_categories
            end
            if proto.resource_categories then
                data_collection[proto.name]["mining"] = {}
                data_collection[proto.name]["mining"]["categories"] = proto.resource_categories
                data_collection[proto.name]["mining"]["speed"] = proto.mining_speed
                data_collection[proto.name]["mining"]["radius"] = proto.mining_drill_radius
            end
        end
    end
    game.write_file("machines.json", game.table_to_json(data_collection), false)
    game.print("Exported Machine Data")
    
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
                resource["products"][product.name]["type"] = product.type
                resource["products"][product.name]["name"] = product.name
                resource["products"][product.name]["amount"] = product.amount
                resource["products"][product.name]["amount_min"] = product.amount_min
                resource["products"][product.name]["amount_max"] = product.amount_max
                resource["products"][product.name]["probability"] = product.probability
                resource["products"][product.name]["catalyst_amount"] = product.catalyst_amount
                if product.type == "fluid" then
                    resource["products"][product.name]["temperature"] = product.temperature
                end
            end
            data_collection[proto.name] = resource
        end
    end
    game.write_file("resources.json", game.table_to_json(data_collection), false)
    game.print("Exported Minable Resource Data")
end

commands.add_command("ap-get-info-dump", "Dump Game Info, used by Archipelago.", function(call)
    dumpGameInfo()
end)
