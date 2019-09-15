ChatFilter = LibStub("AceAddon-3.0"):NewAddon("GinasChatFilter", "AceConsole-3.0", "AceEvent-3.0");
LibStub("AceConfigRegistry-3.0"):NotifyChange("GinasChatFilter");

local function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local configOptions = {
	type = "group",
	args = {
		add = {
			name = "Add",
			desc = "Add a rule.",
			type = "input",
			usage = "cf add RFK",
			set = function (info, msg)
				for term in (msg .. ' '):gmatch('([^ ]*) ') do
					print ('Adding term: |cffffff00' .. term);
					ChatFilter:AddWhiteListItem(term);
				end;
			end
		},
		enable = {
			name = "Enable",
			desc = "Enable / disable the addon.",
			type = "toggle",
			set = function (info, val)
				ChatFilter:ToggleEnabled();
			end,
			get = function (info) return ChatFilter.db.profile.enableFilter; end
		},
		list = {
			name = "list",
			desc = "List filters.",
			type = "execute",
			func = function (info)
				--for i, value in ipairs(ChatFilter.db.profile.whiteList) do
				--	print ('|cffffff00' .. value);
				--end
				ChatFilter:ListRules();
			end
		},
		remove = {
			name = "remove",
			desc = "Remove a rule.",
			type = "input",
			usage = "cf remove RFK",
			set = function (info, msg)
				for term in (msg .. ' '):gmatch('([^ ]*) ') do
					print ('Removing term: |cffffff00' .. term);
					ChatFilter:RemoveWhiteListItem(term);
				end;
			end
		}
	}
};

local AceConfig = LibStub("AceConfig-3.0")
AceConfig:RegisterOptionsTable("GinasChatFilter", configOptions, {"cf"})

local defaults = {
	profile = {
		enableFilter = false,
		whiteList = {}
	}
}

function ChatFilter:AddWhiteListItem(item)
	self.db.profile.whiteList[#self.db.profile.whiteList + 1] = string.upper(item);
	self:DeDuplicateRules();
	self:SortRules();
end

function ChatFilter:DeDuplicateRules()
	local found = {};
	local whiteList = {};
	
	for i, term in ipairs(self.db.profile.whiteList) do
		if not found[term] then
			found[term] = true;
			table.insert(whiteList, term);
		end
	end
	
	self.db.profile.whiteList = whiteList;
end

function ChatFilter:ListRules()
	print ('----');
	for i, term in ipairs(self.db.profile.whiteList) do
		print ('|cffffff00' .. term);
	end
	print ('----');
end

function ChatFilter:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("GinasChatFilter", defaults, "Default");
	self:DeDuplicateRules();
	self:SortRules();
end;

function ChatFilter:RemoveWhiteListItem(item)
	item = string.upper(item);
	
	for i, term in ipairs(self.db.profile.whiteList) do
		if string.upper(term) == item then
			table.remove(self.db.profile.whiteList, i);
			return;
		end
	end
end

function ChatFilter:SortRules()
	local whiteList = self.db.profile.whiteList;
	local newWhiteList = {};
	for key, value in spairs(whiteList, function (t, a, b) return t[b] > t[a] end) do
		table.insert(whiteList, value);
	end
	self.db.profile.whiteList = whiteList;
end

function ChatFilter:ToggleEnabled()
	self.db.profile.enableFilter = not self.db.profile.enableFilter;
	print ('Chat filter is ' .. (self.db.profile.enableFilter and 'enabled' or 'disabled'));
end

function onChatMessage(self, event, msg, person, arg2, channel, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15) 
	if event == 'CHAT_MSG_CHANNEL' and string.match(channel, 'LookingForGroup') then
		-- print ('Got chat message: ' .. msg);
		
		local message = msg;
		message = string.upper(msg);
		
		local valid = false;
		
		for i, term in ipairs(ChatFilter.db.profile.whiteList) do
			if (string.find(message, term)) then
				valid = true;
				break;
			end
		end;
		
		if valid == true then
			return false, msg, person, arg2, channel, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15;
		else
			if ChatFilter.db.profile.enableFilter then
				return true;
			else
				msg = '|cff555555' .. msg;
				return false, msg, person, arg2, channel, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15;
			end
		end
	end;
	
	return false, msg, person, arg2, channel, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15;
end;

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", onChatMessage);

local startUp = CreateFrame("Frame");
startUp:RegisterEvent("PLAYER_LOGIN");

startUp:SetScript("OnEvent", function(self, event, ...)
	print("|cffffff00Gina's Chat Filter|r|cff3498db v1.00|cffecf0f1 - type in '/cf' for options.");
end);