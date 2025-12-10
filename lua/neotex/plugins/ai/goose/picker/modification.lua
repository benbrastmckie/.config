local M = {}

function M.add_description(recipe_path)
    -- Get the recipe name from the path for the prompt
    local recipe_name = recipe_path:match("([^/]+)%.yml$") or recipe_path

    vim.ui.input({ prompt = "Enter description for " .. recipe_name .. ":" }, function(input)
        if input == nil or input == "" then
            vim.notify("Description update cancelled.", vim.log.levels.INFO)
            return
        end

        local file_content, err = vim.fn.readfile(recipe_path)
        if err or file_content == nil then
            vim.notify("Error reading file: " .. tostring(err), vim.log.levels.ERROR)
            return
        end
        file_content = table.concat(file_content, "\n")

        local new_description = "description: " .. input
        local updated_content
        local found = false

        -- Check if description exists and replace it
        updated_content = file_content:gsub("description:.*", function(match)
            found = true
            return new_description
        end, 1)

        -- If description was not found, add it after the 'name' field
        if not found then
            updated_content = updated_content:gsub("(name:.*)", "%1\n" .. new_description, 1)
        end

        local write_err = vim.fn.writefile(vim.split(updated_content, "\n"), recipe_path)
        if write_err ~= 0 then
            vim.notify("Error writing to file: " .. recipe_path, vim.log.levels.ERROR)
        else
            vim.notify("Description updated for " .. recipe_name, vim.log.levels.INFO)
        end
    end)
end

return M
