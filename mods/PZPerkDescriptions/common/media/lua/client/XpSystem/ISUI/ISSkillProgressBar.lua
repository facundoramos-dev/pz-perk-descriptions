require "ISUI/ISPanel"

ISSkillProgressBar = ISPanel:derive("ISSkillProgressBar");
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local SKILL_POINT_HGT = math.floor((FONT_HGT_SMALL + 6)/2)
local SKILL_POINT_SPACING = getCore():getOptionFontSizeReal()

--Good Highlight Color for newly acquired skills
local GHCr = getCore():getGoodHighlitedColor():getR()
local GHCg = getCore():getGoodHighlitedColor():getG()
local GHCb = getCore():getGoodHighlitedColor():getB()

--Target Color for already acquired skills
local TARr = 1
local TARg = 0.89
local TARb = 0.38

ISSkillProgressBar.alpha = 0.0;
ISSkillProgressBar.upAlpha = true;


function ISSkillProgressBar:initialise()
	ISPanel.initialise(self);
end

function ISSkillProgressBar:render()
	self:renderPerkRect();
	if (self.tooltip ~= nil) and (self.tooltip:isMouseOver() or not self:isMouseOver()) then
        -- This is to handle the parent panel scrolling via the mouse wheel.
        self:removeTooltip()
    end
	if self.message ~= nil then
		if self.tooltip == nil then
			self.tooltip = ISToolTip:new();
			self.tooltip:initialise();
			self.tooltip:addToUIManager();
			self.tooltip:setOwner(self)
		end
		self.tooltip.description = self.message;
		self.tooltip:setDesiredPosition(self:getAbsoluteX(), self:getAbsoluteY() + self:getHeight() + 8)
	end
end

-- when you click on an available skill
function ISSkillProgressBar:onMouseUp(x, y)
	-- our selected lvl
	local lvlSelected = math.floor(self:getMouseX()/(SKILL_POINT_HGT+SKILL_POINT_SPACING));
	-- if you have skill pts and the skill is ready to evolve and if you clicked on the right lvl
	if self.xp >= self.xpForLvl and self.level == lvlSelected and not self.perk:isPassiv() then
		self.char:LevelPerk(self.perk:getType());
		-- recalcul some stats
		-- our current perk lvl
		self.level = self.char:getPerkLevel(self.perk:getType());
		-- how much xp we need for the next lvl
		self.xpForLvl = ISSkillProgressBar.getXpForLvl(self.perk, self.level);
		-- reset the tooltip
        self:removeTooltip()
	end
end

-- ---------------------------------------------------------------------------
-- Perk descriptions (PZPerkDescriptions)
--
-- The engine builds the description key by concatenating the TRANSLATED skill
-- name, "IGUI_perks_Carpinteria_Description", but the game only ships the
-- descriptions under the ENGLISH name,
-- "IGUI_perks_Carpentry_Description". In any language the key the engine looks
-- for does not exist, so the tooltip ends up showing the raw text.
--
-- This patch inverts the name: it translates every skill id with the game
-- translator and compares it with the name the tooltip shows, to find the
-- right key. A single file covers every language, and the descriptions shown
-- are the game's own, not a copy.
-- ---------------------------------------------------------------------------

-- internal id -> english name (the one used by the description key)
local ENGLISH_NAMES = {
	Axe = "Axe",
	Blunt = "Long Blunt",
	SmallBlunt = "Short Blunt",
	LongBlade = "Long Blade",
	SmallBlade = "Short Blade",
	Spear = "Spear",
	Maintenance = "Maintenance",
	Aiming = "Aiming",
	Reloading = "Reloading",
	Carpentry = "Carpentry",
	Carving = "Carving",
	Cooking = "Cooking",
	Electricity = "Electrical",
	Doctor = "First Aid",
	Glassmaking = "Glassmaking",
	FlintKnapping = "Knapping",
	Masonry = "Masonry",
	Blacksmith = "Blacksmithing",
	Mechanics = "Mechanics",
	Pottery = "Pottery",
	Tailoring = "Tailoring",
	MetalWelding = "Welding",
	Fishing = "Fishing",
	Foraging = "Foraging",
	Tracking = "Tracking",
	Trapping = "Trapping",
	Fitness = "Fitness",
	Strength = "Strength",
	Lightfooted = "Lightfooted",
	Nimble = "Nimble",
	Sprinting = "Running",
	Sneaking = "Sneaking",
	Husbandry = "Animal Care",
	Butchering = "Butchering",
	Farming = "Agriculture",
}

-- internal id -> english text. Fallback for the languages The Indie Stone has
-- not translated yet (today only Ukrainian, with 6 of the 35).
local ENGLISH_TEXTS = {
	Axe = "Increases attack speed and damage when using axe-type weapons, and reduces their muscle strain.",
	Blunt = "Increases attack speed and damage when using long blunt weapons, and reduces their muscle strain.",
	SmallBlunt = "Increases attack speed and damage when using short blunt weapons, and reduces their muscle strain.",
	LongBlade = "Increases attack speed and damage when using long blade weapons, and reduces their muscle strain.",
	SmallBlade = "Increases attack speed and damage when using short blade weapons, and reduces their muscle strain.",
	Spear = "Increases attack speed and damage when using spear-type weapons, and reduces their muscle strain.",
	Maintenance = "Decreases the chance of melee weapons being damaged. Trained through melee combat.",
	Aiming = "Increases your chance of hitting a target with firearms, and of doing extra damage.",
	Reloading = "Increases the speed you reload firearms and magazines. Trained by reloading firearms.",
	Carpentry = "Allows the building of wooden constructions.",
	Carving = "Allows the creation of small wooden objects.",
	Cooking = "Allows the creation of more nutritious and delicious food.",
	Electricity = "Allows the creation and maintenance of electrical devices.",
	Doctor = "Increases the available information for injuries, and the quality of medical treatments.",
	Glassmaking = "Allows the creation of glass and glass objects.",
	FlintKnapping = "Allows the creation of small stone objects.",
	Masonry = "Allows the creation of better and stronger brick and stone constructions.",
	Blacksmith = "Allows the creation of metal items and objects.",
	Mechanics = "Increases the effectiveness of vehicle repairs.",
	Pottery = "Allows the creation of clay and pottery objects.",
	Tailoring = "Increases the quality of clothing repairs, and defensive padding of clothes.",
	MetalWelding = "Allows the building of crude metal barricades and objects.",
	Fishing = "Increases your chance of catching a fish, the quality of your catches, and makes your fishing equipment less likely to break.",
	Foraging = "Increases the quality of items found using Search Mode, available search categories, and the search radius.",
	Tracking = "Increases the available information on wild animal clues found in Search Mode, and allows smaller clues to be found.",
	Trapping = "Increases the chances of catching an animal in a trap, and allows better traps to be crafted.",
	Fitness = "Increases melee attack speed, and speed and success chance of climbing. Decreases exhaustion rate.",
	Strength = "Increases melee attack damage and knockback and your inventory encumbrance limit. Reduces muscle strain.",
	Lightfooted = "Decreases the noise of your footsteps, whether running, walking, or crouching.",
	Nimble = "Increases how quickly you move when in a \"combat stance\", and decreases footstep noise.",
	Sprinting = "Increases how quickly you move when running.",
	Sneaking = "Decreases the distance at which zombies spot you and the sound of your footsteps while crouching.",
	Husbandry = "Increases the available information for animals and the number of resources harvested from them.",
	Butchering = "Increases the quality of meat harvested from animals.",
	Farming = "Increases the available information for crops. Trained by harvesting crops planted yourself.",
}

local indexCache = nil

local function descriptionIndex()
	if indexCache ~= nil then
		return indexCache
	end
	local index = {}
	for id, _ in pairs(ENGLISH_NAMES) do
		local name = getTextOrNull("IGUI_perks_" .. id)
		if name ~= nil and name ~= "" then
			index[name] = id
		end
	end
	indexCache = index
	return index
end

-- Returns (description in the player language, base key), or (nil, nil) for the
-- skills that are not in the table, like the ones added by other mods.
local function perkDescription(perk)
	local id = descriptionIndex()[perk:getName()]
	if id == nil then
		return nil, nil
	end
	local key = "IGUI_perks_" .. ENGLISH_NAMES[id] .. "_Description"
	local text = getTextOrNull(key)
	if text == nil or text == "" then
		text = ENGLISH_TEXTS[id]
	end
	return text, key
end

function ISSkillProgressBar:updateTooltip(lvlSelected)
	-- we display the correct message
	self.message = self.perk:getName() .. " " .. xpSystemText.lvl .. " " .. lvlSelected + 1;
	-- first if the lvl is unlocked
	if lvlSelected < self.level then
		self.message = self.message .. " <LINE> " .. xpSystemText.unlocked;
	-- if we selected the level wich is in progress, we display the xp we already got / xp needed for lvl
	elseif self.level == lvlSelected then
		self.message = self.message .. " <LINE> " .. getText("IGUI_XP_tooltipxp", round(self.xp, 2), self.xpForLvl);
		-- if we got a multiplier, we show it
		local multiplier = self.char:getXp():getMultiplier(self.perk:getType());
		if multiplier > 0 then
			self.message = self.message .. " <LINE> " .. getText("IGUI_skills_Multiplier", round(multiplier, 2));
		end
	else
		self.message = self.message .. " <LINE> " .. xpSystemText.locked;
    end
	local description, descriptionKey = perkDescription(self.perk)
	if description ~= nil then
		self.message = self.message .. " <LINE><LINE> " .. description
	else
		-- skills outside the table (the ones from other mods): original behaviour
		self.message = self.message .. " <LINE><LINE> " .. getText("IGUI_perks_"..self.perk:getName().."_Description")
	end
	if descriptionKey ~= nil then
		local levelText = getTextOrNull(descriptionKey..lvlSelected+1)
		if levelText ~= nil and levelText ~= "" then
			self.message = self.message .. " <LINE><LINE> " .. levelText
		end
	end
    local xpBoost = self.char:getXp():getPerkBoost(self.perk:getType());
    local percentage = nil;
    if xpBoost == 1 then
        percentage = "75%";
    elseif xpBoost == 2 then
        percentage = "100%";
    elseif xpBoost == 3 then
        percentage = "125%";
    end

    if percentage then
        self.message = self.message .. " <LINE> " .. getText("IGUI_XP_tooltipxpboost", percentage);
    end
end

function ISSkillProgressBar:onMouseMove(dx, dy)
	if not self:isMouseOver() then -- handle other windows in front
		self:onMouseMoveOutside(dx, dy)
		return
	end
	-- display the tooltip
	-- first we get the square the mouse is on
	local lvlSelected = math.floor(self:getMouseX()/(SKILL_POINT_HGT+SKILL_POINT_SPACING));
	if lvlSelected > 9 then
		return;
	end
	self:updateTooltip(lvlSelected)
end

function ISSkillProgressBar:onMouseMoveOutside(dx, dy)
    self:removeTooltip()
end

function ISSkillProgressBar:removeTooltip()
	self.message = nil;
	if self.tooltip ~= nil then
		self.tooltip:setVisible(false);
		self.tooltip:removeFromUIManager();
		self.tooltip = nil;
	end
end

function ISSkillProgressBar:activate()
end

function ISSkillProgressBar:renderPerkRect()
	local x = 0;
	local y = 0;

	-- perks level up automatically, update the UI
	if self.level ~= self.char:getPerkLevel(self.perk:getType()) then
		self.level = self.char:getPerkLevel(self.perk:getType())
		self.xpForLvl = ISSkillProgressBar.getXpForLvl(self.perk, self.level)
		self.parent.lastLeveledUpPerk = self.perk
		self.parent.lastLevelUpTime = 1
	end
	
	-- how much xp we already acquire for this perk
	self.xp = ISSkillProgressBar.getPerkXp(self);

	if self.xp > self.xpForLvl then
		self.xp = self.xpForLvl;
	end

	-- we start to render our first rect : all the lvl we already got, we render them in a simple white rect
	-- ex : if we're lvl 3, we gonna render 2 (lvl 1 and 2) white rect
	for i=0,self.level - 1 do
--~ 		self:drawRect(x, y, 19, 19, 1.0, 1.0, 1.0, 1.0);
		if self.parent.lastLeveledUpPerk == self.perk then
			--this fades over time to return to the original colour

			local lastLevelUpTime = self.parent.lastLevelUpTime
			local OneMinus = 1-lastLevelUpTime
			local lerpR = TARr*OneMinus + GHCr*lastLevelUpTime
			local lerpG = TARg*OneMinus + GHCg*lastLevelUpTime
			local lerpB = TARb*OneMinus + GHCb*lastLevelUpTime


			--a * (1-t) + b * t

			self:drawTextureScaled(self.SkillUnitFilled, x, y, SKILL_POINT_HGT, SKILL_POINT_HGT, 1,lerpR,lerpG,lerpB);
			self:drawTextureScaled(self.SkillUnitBorder, x, y, SKILL_POINT_HGT, SKILL_POINT_HGT, 1,lerpR,lerpG,lerpB);
		else
			self:drawTextureScaled(self.SkillUnitFilled, x, y, SKILL_POINT_HGT, SKILL_POINT_HGT, 1,TARr,TARg,TARb);
			self:drawTextureScaled(self.SkillUnitBorder, x, y, SKILL_POINT_HGT, SKILL_POINT_HGT, 1,TARr,TARg,TARb);
		end
		x = x + SKILL_POINT_HGT+SKILL_POINT_SPACING;
	end
	-- the most important square : the one in progress !
	-- for this one we got multiple choice :
	-- * In progress : light grey rect filled with light grey depending on the progress
	-- * In faster progress : if you read a book 'bout this skill or if a npc trained you, it's a light blue/filled with light blue too
	-- * Finished but no skills pts available : a white rect full filled with light grey
	-- * Finished and ready to take : a white rect that glow filled with light grey
	if self.level < 10 then
		-- we gonna fill with light grey our rect, depending on the progress of our lvl (50% xp mean a rect filled at 50%)
		-- this width correspond to 1% xp progress
		local sliceWidth = (SKILL_POINT_HGT) / 100;
		-- our progress into the current lvl in %
		local percentProgress = (self.xp / self.xpForLvl) * 100;
		if percentProgress < 0 then percentProgress = 0 end
		-- we now draw our rect with the correct width
		-- our border, a bit darker than the filled rect or if the skill is rdy to unlock it's a white border
		if percentProgress == 100 then
			if self.perk:isPassiv() then
				self:drawTextureScaled(self.SkillUnitFilled, x, y, SKILL_POINT_HGT, SKILL_POINT_HGT, 1,TARr,TARg,TARb);
			else -- the skill is ready to be trained but no skill pts available, we set up just a white border
					self:drawTextureScaled(self.SkillUnitFilled, x, y, SKILL_POINT_HGT, SKILL_POINT_HGT, 1,TARr,TARg,TARb);
				self:drawTextureScaled(self.SkillUnitBorder, x, y, SKILL_POINT_HGT, SKILL_POINT_HGT, 1, 1, 1, 1);
			end
		else -- skill is in progress, we set up a grey rect and fill it depending on the skill progress
			self:drawTextureScaled(self.SkillUnitBorder, x, y, SKILL_POINT_HGT, SKILL_POINT_HGT, 1, 0.4, 0.4, 0.4);
			self:drawTextureScaled(self.SkillUnitFilled, x, y, sliceWidth * percentProgress, SKILL_POINT_HGT, 1,0.4,0.4,0.4);
		end
		x = x + SKILL_POINT_HGT+SKILL_POINT_SPACING;
	end

	-- our last square : the no available ones, this is just an empty dark grey rect
	for i=self.level + 1, 9 do
--~ 		self:drawRect(x, y, 19, 19, 0.5, 0.41, 0.41, 0.41);
		self:drawTextureScaled(self.SkillUnitBorder, x, y, SKILL_POINT_HGT, SKILL_POINT_HGT, 1, 0.2, 0.2, 0.2);
		x = x + SKILL_POINT_HGT+SKILL_POINT_SPACING;
	end
end

function ISSkillProgressBar.updateAlpha()
	if ISSkillProgressBar.upAlpha then
		ISSkillProgressBar.alpha = ISSkillProgressBar.alpha + 0.1 * (30 / getPerformance():getUIRenderFPS());
		if ISSkillProgressBar.alpha > 1.0 then
			ISSkillProgressBar.alpha = 1.0;
			ISSkillProgressBar.upAlpha = false;
		end
	else
		ISSkillProgressBar.alpha = ISSkillProgressBar.alpha - 0.1 * (30 / getPerformance():getUIRenderFPS());
		if ISSkillProgressBar.alpha < 0 then
			ISSkillProgressBar.alpha = 0;
			ISSkillProgressBar.upAlpha = true;
		end
	end
end

function ISSkillProgressBar:new (x, y, width, height, playerNum, perk, parent)
	local o = {};
	o = ISPanel:new(x, y, (SKILL_POINT_HGT+SKILL_POINT_SPACING)*10, SKILL_POINT_HGT);
	setmetatable(o, self);
	self.__index = self;
	o.playerNum = playerNum
	o.char = getSpecificPlayer(playerNum)
	o.perk = perk;
	o.parent = parent;
	o.xp = 0;
	o.message = nil;
	o.tooltip = nil;
	o:noBackground();
	-- our current perk lvl
	o.level = o.char:getPerkLevel(perk:getType());
	-- how much xp we need for the next lvl
	o.xpForLvl = ISSkillProgressBar.getXpForLvl(perk, o.level);
	o.SkillUnitFilled = getTexture("media/ui/SkillPanel/SkillUnit_Fill.png")
	o.SkillUnitBorder = getTexture("media/ui/SkillPanel/SkillUnit_Border.png")
	--o.AddSkillBtn = getTexture("media/ui/XpSystemUI/AddSkillBtn.png")
	--o.SkillBtnEmptyBig = getTexture("media/ui/XpSystemUI/SkillBtnEmptyBig.png")
	--o.ProgressSkill = getTexture("media/ui/XpSystemUI/ProgressSkill.png")
	--o.SkillBtnEmptWhitey = getTexture("media/ui/XpSystemUI/SkillBtnEmptWhitey.png")
	return o;
end

ISSkillProgressBar.getXpForLvl = function(perk, level)
	return perk:getXpForLevel(level + 1)
end

ISSkillProgressBar.getPreviousXpLvl = function(perk, level)
	if level == 0 then
		return 0;
	end
	level = level - 1;
	local previousXp = perk:getXp1();
	if level >= 1 then
		previousXp = previousXp + perk:getXp2();
	end
	if level >= 2 then
		previousXp = previousXp + perk:getXp3();
	end
	if level >= 3 then
		previousXp = previousXp + perk:getXp4();
	end
	if level >= 4 then
		previousXp = previousXp + perk:getXp5();
    end
    if level >= 5 then
        previousXp = previousXp + perk:getXp6();
    end
    if level >= 6 then
        previousXp = previousXp + perk:getXp7();
    end
    if level >= 7 then
        previousXp = previousXp + perk:getXp8();
    end
    if level >= 8 then
        previousXp = previousXp + perk:getXp9();
    end
    if level >= 9 then
        previousXp = previousXp + perk:getXp10();
    end
	return previousXp;
end

ISSkillProgressBar.getPerkXp = function(self)
	return self.char:getXp():getXP(self.perk:getType()) - ISSkillProgressBar.getPreviousXpLvl(self.perk, self.level);
end
