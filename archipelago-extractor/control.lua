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
            tech_data["has_effects"] = false
            for tech_requirement, _ in pairs(tech.prerequisites) do
                table.insert(requires, tech_requirement)
            end
            for _, modifier in pairs(tech.effects) do
                if modifier.type == "unlock-recipe" then
                    table.insert(unlocks, modifier.recipe)
                else
                    tech_data["has_effects"] = true
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
        if proto.crafting_categories then
            data_collection[proto.name] = proto.crafting_categories
        end
    end

    game.write_file("machines.json", game.table_to_json(data_collection), false)
    game.print("Exported Machine Data")
end

commands.add_command("ap-get-info-dump", "Dump Game Info, used by Archipelago.", function(call)
    dumpGameInfo()
end)
