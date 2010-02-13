local CreateDkpTable;
do
	local Update = function( self )
		result = {}
		
		local total = GetNumGuildMembers( true );
		for current = 1, total do
			local name, _, _, _, class, _, _, officernote, _, _, classFileName = GetGuildRosterInfo( current );
			
			local currentDkp, totalDkp = strmatch( officernote, "Net:(%d+) Tot:(%d+)" ) -- Hrs:%d+
			if ( currentDkp ~= nil and totalDkp ~= nil ) then
				tinsert( result, { name = name, class = class, classFileName = classFileName, currentDkp = tonumber( currentDkp ), totalDkp = tonumber( totalDkp ) } );
			end
		end
		
		self.table = result
	end

	local SetSortColumn = function( self, column )
		self.sortColumn = column;
	end
	
	local GetSortColumn = function( self )
		return self.sortColumn;
	end
	
	local SetSortDirection = function( self, descending )
		self.sortDirection = descending;
	end
	
	local GetSortDirection = function( self )
		return self.sortDirection;
	end
	
	local Sort = function( self )
		local column = self.sortColumn;
		local direction = self.sortDirection;
	
		local sorted;
		repeat
			sorted = true;
			for key, value in pairs( self.table ) do
				local nextKey = key + 1;
				local nextValue = self.table[ nextKey ];
				if ( nextValue == nil ) then break; end
				
				if ( ( direction and value[ column ] < nextValue[ column ] ) or ( not direction and value[ column ] > nextValue[ column ] ) ) then
					self.table[ key ] = nextValue;
					self.table[ nextKey ] = value;
					sorted = false;
				end				
			end			
		until ( sorted == true )
	end
	
	local Get = function( self )
		return self.table;
	end
	
	CreateDkpTable = function()
		local result = { Sort = Sort, Update = Update, Get = Get, SetSortColumn = SetSortColumn, GetSortColumn = GetSortColumn, SetSortDirection = SetSortDirection, GetSortDirection = GetSortDirection };
		result:SetSortColumn( "name" );
		result:SetSortDirection( false );
		result:Update();
		result:Sort();
		return result;
	end
end

local CreateDkpFrame
do
	local CreateScrollFrame;
	do
		local CreateLine;
		do
			local Set = function( self, dkpRow )
				local color = RAID_CLASS_COLORS[ dkpRow.classFileName ];
				if ( color ~= nil ) then
					color = string.format( "|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255 );
				else
					color = "";
				end
			
				self.nameText:SetText( color .. dkpRow.name );
				self.classText:SetText( color .. dkpRow.class );
				self.currentDkpText:SetText( color .. dkpRow.currentDkp );
				self.totalDkpText:SetText( color .. dkpRow.totalDkp );
			end
		
			CreateLine = function( parent )
				local result = CreateFrame( "Frame", nil, parent );
				result:SetWidth( 450 );
				result:SetHeight( 15 );
				
				local nameText = result:CreateFontString( nil, nil, "GameFontNormalSmall" );
				nameText:SetPoint( "TOPLEFT", result, "TOPLEFT" );
				nameText:SetWidth( 100 );
				nameText:SetHeight( 30 );
				
				local classText = result:CreateFontString( nil, nil, "GameFontNormalSmall" );
				classText:SetPoint( "TOPLEFT", nameText, "TOPRIGHT" );
				classText:SetWidth( 100 );
				classText:SetHeight( 30 );
				
				local currentDkpText = result:CreateFontString( nil, nil, "GameFontNormalSmall" );
				currentDkpText:SetPoint( "TOPLEFT", classText, "TOPRIGHT" );
				currentDkpText:SetWidth( 100 );
				currentDkpText:SetHeight( 30 );
				
				local totalDkpText = result:CreateFontString( nil, nil, "GameFontNormalSmall" );
				totalDkpText:SetPoint( "TOPLEFT", currentDkpText, "TOPRIGHT" );
				totalDkpText:SetWidth( 100 );
				totalDkpText:SetHeight( 30 );
							
				result.nameText = nameText;
				result.classText = classText;
				result.currentDkpText = currentDkpText;
				result.totalDkpText = totalDkpText;
				
				result.Set = Set;
				
				return result;
			end
		end
	
		local SetLine = function( self, index, dkpRow )
			local line = self.lines[ index ]
			if ( line == nil ) then
				line = CreateLine( self );
				tinsert( self.lines, index, line );
				line:Set( dkpRow );
			end	
			line:Set( dkpRow );	
			line:Show();
		end

		local Reset = function( self )
			for _, v in pairs( self.lines ) do
				v:Hide();
			end
		end

		local Render = function( self )
			local count = 0;
			local prev;
			for _, v in pairs( self.lines ) do
				if ( v:IsShown() ) then
					if ( prev == nil ) then
						v:SetPoint( "TOPLEFT", self, "TOPLEFT" );
					else
						v:SetPoint( "TOPLEFT", prev, "BOTTOMLEFT" );
					end
					count = count + 1;
					prev = v;
				end
			end
			if ( prev ~= nil ) then
				self:SetHeight( count * prev:GetHeight() );
			end
		end
	
		CreateScrollFrame = function( parent )
			local result = CreateFrame( "Frame", nil, parent );
			result.SetLine = SetLine;
			result.Reset = Reset;
			result.Render = Render;
			result.lines = {};
			return result;
		end
	end
	
	local SetDataSource = function( self, dataSource )
		self.dataSource = dataSource;
	end
	
	local GetDataSource = function( self )
		return self.dataSource;
	end
	
	local Update = function( self )
		self.dataSource:Update();
		self.dataSource:Sort();	

		local scrollFrame = self.scrollFrame;
		scrollFrame:Reset();
		for k, v in pairs( self.dataSource:Get() ) do
			scrollFrame:SetLine( k, v );
		end
		scrollFrame:Render();
	end
	
	local HeaderClick = function( frame, column )
		local dataSource = frame:GetDataSource();
		if ( dataSource:GetSortColumn() == column ) then
			dataSource:SetSortDirection( not dataSource:GetSortDirection() );
		else
			dataSource:SetSortColumn( column );
			dataSource:SetSortDirection( false );
		end
		frame:Update();
	end
	
	CreateDkpFrame = function()	
		local result = CreateFrame( "Frame", "DkpFrame", UIParent );
		--[[
		result:SetBackdrop( {
			bgFile = "Interface\\AddOns\\Tukui\\media\\WHITE64X64", 
			edgeFile = "Interface\\AddOns\\Tukui\\media\\WHITE64X64",    
			edgeSize = 1, 
			insets = { top = -1, left = -1, bottom = -1, right = -1 },
		} );
		]]--
		result:SetBackdrop( {
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
			tile = true, tileSize = 16, edgeSize = 16, 
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		} );
		result:SetBackdropColor( .1, .1, .1 );
		result:SetWidth( 450 );
		result:SetHeight( 400 );
		result:SetScale( 1 );
		result:SetPoint( "CENTER", UIParent, "CENTER" )
		result:SetFrameStrata( "DIALOG" )
		result:EnableMouse( true );
		result:Hide();
		result:SetScript( "OnShow", function( self )
			self:Update();
		end );

		local nameHeader = CreateFrame( "Button", nil, result, "UIPanelButtonTemplate" );
		nameHeader:SetPoint( "TOPLEFT", result, "TOPLEFT", 18, -6 );
		nameHeader:SetWidth( 80 );
		nameHeader:SetHeight( 22 );
		nameHeader:SetText( "Name" );
		nameHeader:SetScript( "OnClick", function( self )
			HeaderClick( result, "name" );
		end );
		
		local classHeader = CreateFrame( "Button", nil, result, "UIPanelButtonTemplate" );
		classHeader:SetPoint( "TOPLEFT", nameHeader, "TOPRIGHT", 20, 0 );
		classHeader:SetWidth( 80 );
		classHeader:SetHeight( 22 );
		classHeader:SetText( "Class" );
		classHeader:SetScript( "OnClick", function( self )
			HeaderClick( result, "class" );
		end );
		
		local currentDkpHeader = CreateFrame( "Button", nil, result, "UIPanelButtonTemplate" );
		currentDkpHeader:SetPoint( "TOPLEFT", classHeader, "TOPRIGHT", 20, 0 );
		currentDkpHeader:SetWidth( 80 );
		currentDkpHeader:SetHeight( 22 );
		currentDkpHeader:SetText( "Current dkp" );
		currentDkpHeader:SetScript( "OnClick", function( self )
			HeaderClick( result, "currentDkp" );
		end );
		
		local totalDkpHeader = CreateFrame( "Button", nil, result, "UIPanelButtonTemplate" );
		totalDkpHeader:SetPoint( "TOPLEFT", currentDkpHeader, "TOPRIGHT", 20, 0 );
		totalDkpHeader:SetWidth( 80 );
		totalDkpHeader:SetHeight( 22 );
		totalDkpHeader:SetText( "Total dkp" );
		totalDkpHeader:SetScript( "OnClick", function( self )
			HeaderClick( result, "totalDkp" );
		end );
		
		local closeButton = CreateFrame( "Button", nil, result, "UIPanelCloseButton" );
		closeButton:SetPoint( "TOPRIGHT", result, "TOPRIGHT" );
		
		local scrollFrame = CreateScrollFrame( result );
		scrollFrame:SetWidth( result:GetWidth() );
		
		local scrollArea = CreateFrame( "ScrollFrame", "DkpScroll", result, "UIPanelScrollFrameTemplate" );
		scrollArea:SetPoint( "TOPLEFT", result, "TOPLEFT", 8, -30 );
		scrollArea:SetPoint( "BOTTOMRIGHT", result, "BOTTOMRIGHT", -30, 8 );
		scrollArea:SetScrollChild( scrollFrame )
		
		result.closeButton = closeButton;
		result.scrollFrame = scrollFrame;
		result.scrollArea = scrollArea;

		result.SetDataSource = SetDataSource;
		result.GetDataSource = GetDataSource;
		result.Update = Update;
		
		return result;
	end
end

local frame = CreateDkpFrame();
local dkpTable = CreateDkpTable();
frame:SetDataSource( dkpTable );

SLASH_DKPR1 = "/dkpr";
SlashCmdList[ "DKPR" ] = function() 
	if ( frame:IsShown() ) then
		frame:Hide();
	else
		frame:Show();
	end
end