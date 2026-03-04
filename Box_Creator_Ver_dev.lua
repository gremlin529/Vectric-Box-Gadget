-- VECTRIC LUA SCRIPT
-------------------------------------------------------------------------------------------------------------------------------------------
-- Gadgets are an entirely optional software add-in to Vectric's core software products. 
-- They are provided 'as-is', without any express or implied warranty, and you make use of them entirely at your own risk.
-- In no event will Vectric Ltd. be held liable for any damages arising from their use.

-- Modification and re-use of the gadget source may or may not be allowed by the gadget author. Please read carefully any copyright notices -- included in the gadget source.

-- The notice at the head of the gadget source files may not be removed or altered from any source distribution.
-------------------------------------------------------------------------------------------------------------------------------------------
-- Added Disclaimer Information Above                                                                   -- by Sharkcutup 11/10/2023
-- Added "Allowance" to the Registry Load and Save Dialog                                               -- by Sharkcutup 11/10/2023
-- Changed the Select Tool (in .html file) to where tool info shows next to button instead of under it. -- by Sharkcutup 11/10/2023
-- Added Images Folder put all Images in it and Updated .html file to recognize them.                   -- by Sharkcutup 11/10/2023 
-- Changed Version to 1.5                                                                               -- by Sharkcutup 11/10/2023
-- Added Notes at appropriate lines marked by Sharkcutup (line numbers change with revisions)           -- by Sharkcutup 11/11/2023
-- Changed Joint Type Names to "Finger Joint" and "Dovetail Joint" also added to Joint Width:--(Centre to Centre)-- by Sharkcutup 09/09/2025
-- Added User-defined Material Edge Distance for parts Location applied to Material Sheet               -- by Sharkcutup 11/4/2025
-- Added some error-trapping into the gadget too                                                        -- by Sharkcutup 11/4/2025
-- Changed Warning Messaage when not enough Material for Parts.                                         -- by Sharkcutup 11/14/2025
-- Changed up the User Interface a bit by colorizing and defining lines of images                       -- by Sharkcutup 11/23/2025
-- Added a separate field for the width of the bottom tabs vs side tabs                                 -- by Gremlin 2/27/2026
-------------------------------------------------------------------------------------------------------------------------------------------
-- It is provided 'as-is' with changes made, without any express or implied warranty, and you make use of them entirely at your own risk.
-- In no event will "Sharkcutup" be held liable for any damages arising from this gadgets use.
-- In no event will "Gremlin" be held liable for any damages arising from this gadgets use.

-------------------------- Sharkcutup is NOT The Origianl Owner/Writer of this Gadget 11/23/2025  -----------------------------------------
---------------------------- Gremlin is NOT The Origianl Owner/Writer of this Gadget 2/272026  --------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------

-- require("mobdebug").start()

g_version = "dev"                                                    -- Changed by Gremlin
g_title = "Box Creator"
g_width = 1025
g_height = 1000                                                      -- Changed by Sharkcutup
g_html_file = "Box_Creator_Ver_" .. g_version .. ".html"             -- Changed by Gremlin

-- ---------- VALIDATION HELPERS ----------
local function _is_pos(x) return type(x)=="number" and x>0 end
local function _is_nonneg(x) return type(x)=="number" and x>=0 end

local function _tool_ok(tool)
  if not tool then return false end
  local blk = MaterialBlock()
  local dia = ConvertUnitsFrom(tool.ToolDia or 0, tool, blk)
  return (dia or 0) > 0
end

function Face(contour, dovetails, tabs, name)
	local obj ={}
	obj.contour = contour
	obj.dovetail_list = dovetails
	obj.name = name
	obj.tabs = tabs
  obj.is_lid = false
  return obj
end

function Lid(outer_contour, inner_contour, dovetails, tabs, name)
  local obj = {}
  obj.contour = outer_contour
  obj.is_lid = true
  obj.inner_contour = inner_contour
  obj.tabs = tabs
  obj.name = name
  obj.dovetail_list = dovetails
  return obj
end

function TransformFace(face, xform)
	face.contour:Transform(xform)

	if (face.is_lid) then
		face.inner_contour:Transform(xform)
	end

	-- Transform dovetail markers
	local dovetails = face.dovetail_list
	for i=1,#dovetails do
		local marker = dovetails[i]
		marker:Transform(xform)
	end
  
  -- Transform the tabs
  local tabs = face.tabs
  for i=1,#tabs do
    face.tabs[i] =  xform * face.tabs[i]
  end
end

function CloneFace(face)
	local clone = {}
	clone.contour = face.contour:Clone()
	clone.dovetail_list = face.dovetail_list
	clone.tabs = face.tabs
	clone.is_lid = face.is_lid
	if (clone.is_lid) then
		clone.inner_contour = face.inner_contour:Clone()
	end
	return clone
end

function GetAllProfileContours(faces)
	local contour_group = ContourGroup(true)
	for i=1,#faces do
		contour_group:AddTail(faces[i].contour:Clone())
	end
	return contour_group
end

function GetAllProfileCadContours(faces)
	local cad_object_list = CadObjectList(true)	
	for i=1,#faces do
		local cur_face = faces[i]
		local cad_contour = MakeCadAndAddTabs(cur_face.contour, cur_face.tabs)
		cad_object_list:AddTail(cad_contour)
	end
	return cad_object_list
end

function GetAllMarkers(faces)
	local markers = {}
	for i=1,#faces do
		local cur_markers = faces[i].dovetail_list
		for j=1,#cur_markers do
			markers[#markers+1] = cur_markers[j]
		end
	end
	return markers;
end

function CreateLidPocketToolpath(job, options, faces, tool, layer_name)
  
  if not _tool_ok(tool) then
  DisplayMessageBox("Pocket toolpath: Please Select a Valid Tool Before Continuing.")
  return false
end

	-- first we must create cad contours from any face which has a lid and select all on that layer
	local cad_object_list = CadObjectList(true)
	for i=1,#faces do
		local cur_face = faces[i]
		if cur_face.is_lid then
			local inner = CreateCadContour(cur_face.inner_contour)
			local outer = CreateCadContour(cur_face.contour)
			cad_object_list:AddTail(inner)
			cad_object_list:AddTail(outer)
		end
	end

	AddCadListToJob(job, cad_object_list, layer_name)
	local layer = job.LayerManager:FindLayerWithName(layer_name)
	local selection = job.Selection
	selection:Clear()
	SelectVectorsOnLayer(layer, selection, true, true, true)

	local pos_data = ToolpathPosData()
	local pocket_data = PocketParameterData()
	pocket_data.start_depth = 0
	pocket_data.CutDepth = 0.5*options.thickness
	pocket_data.Allowance = -options.allowance
	pocket_data.DoRaster = false
	pocket_data.DoRamping = true
	pocket_data.RampDistance = 0.3*options.height

	local geometry_selector = GeometrySelector()

	local area_clear_tool = nil

	local toolpath_manager = ToolpathManager()
	toolpath_manager:CreatePocketingToolpath(
		"Pocket",
		tool,
		area_clear_tool,
		pocket_data,
		pos_data,
		geometry_selector,
		true,
		true)
end

--[[  -------------- AddGroupToJob --------------------------------------------------  
|
|  Adds a group of contours to a job
|
]]
function AddGroupToJob(vectric_job, group, layer_name, create_group)

   --  create a CadObject to represent the  group 
   local layer = vectric_job.LayerManager:GetLayerWithName(layer_name)
   if create_group then
    local cad_object = CreateCadGroup(group);   -- and add our object to it
    layer:AddObject(cad_object, true)
    return
   end
  
   local cad_contour
   local contour
   local pos = group:GetHeadPosition()
   while pos ~= nil do
     contour, pos = group:GetNext(pos)
     cad_contour = CreateCadContour(contour)
     layer:AddObject(cad_contour, true)
   end

end

--[[  -------------- AddCadContourToJob --------------------------------------------------  
|
|  Adds a group of contours to a job
|
]]
function AddCadContourToJob(vectric_job, cad_contour, layer_name)

	--  create a CadObject to represent the group
	local layer = vectric_job.LayerManager:GetLayerWithName(layer_name)
	if cad_contour and layer then
		layer:AddObject(cad_contour, true)
	end
end   

--[[  -------------- AddCadContourToJob --------------------------------------------------  
|
|  Adds a group of contours to a job
|
]]
function AddCadListToJob(vectric_job, cad_list, layer_name)

	--  create a CadObject to represent the group
	local pos = cad_list:GetHeadPosition()
	local layer = vectric_job.LayerManager:GetLayerWithName(layer_name)
	while (pos) do
		local obj
		obj, pos = cad_list:GetNext(pos)
		layer:AddObject(obj:Clone(), true)
	end
end

--[[  -------------- MakeBottomFace --------------------------------------------------  
|
|  Make the bottom face of the box
|  Returns the contour for the profile and a list of dovetails
|
]]
function MakeBottomFaceContour(width, height, thickness, start_point, dovetail, use_dovetails,name)

	local dovetail_markers = {}
	local tablist = {}
	local outer_blc = start_point
	local outer_brc = start_point  + width*Vector2D(1,0)
	local outer_trc = outer_brc + height*Vector2D(0,1)
	local outer_tlc = start_point + height*Vector2D(0, 1)

	-- // Width and height of interior rectangle
	local inner_width = width - 2*thickness
	local inner_height = height - 2*thickness

	-- Calculate number of flaps needed. In this case
	-- then each "flap" represents a piece of the outer 
	-- contour then goes inwards
	local num_flaps_w = math.floor((0.5*inner_width) / dovetail.min_width )
	local num_flaps_h = math.floor((0.5*inner_height) / dovetail.min_width)

	local tab_space_w = (inner_width - num_flaps_w*dovetail.min_width)/ (num_flaps_w + 1)
	local tab_space_h = (inner_height - num_flaps_h*dovetail.min_width)/ (num_flaps_h + 1)

	-- Create the contour
	local contour = Contour(0.0)
	contour:AppendPoint(start_point)

	-- Create blc -> brc
	-- Create the internal flaps. 

	local unit_x = Vector2D(1,0)
	local unit_y = Vector2D(0,1)

	-- line to first
	LineToVector(contour, (thickness + tab_space_w)*unit_x)
	AddMiddleOfLastSpanToList(contour, tablist)
	AddFemaleDoveTailsAlongLine(thickness, dovetail, unit_x, unit_y, contour, num_flaps_w, tab_space_w, dovetail_markers)
	contour:LineTo(outer_brc)
	AddMiddleOfLastSpanToList(contour, tablist)


	-- Create brc -> trc
	LineToVector(contour, (thickness + tab_space_h)*unit_y)
	AddMiddleOfLastSpanToList(contour, tablist)
	AddFemaleDoveTailsAlongLine(thickness, dovetail, unit_y, -unit_x, contour, num_flaps_h, tab_space_h, dovetail_markers)
	contour:LineTo(outer_trc)
	AddMiddleOfLastSpanToList(contour, tablist)

	-- Create trc -> tlc
	LineToVector(contour, (thickness + tab_space_w)*(-unit_x))
	AddMiddleOfLastSpanToList(contour, tablist)
	AddFemaleDoveTailsAlongLine(thickness, dovetail, -unit_x, -unit_y, contour, num_flaps_w, tab_space_w, dovetail_markers)
	contour:LineTo(outer_tlc)
	AddMiddleOfLastSpanToList(contour, tablist)

	-- Create tlc -> blc
	LineToVector(contour, (thickness + tab_space_h)*(-unit_y))
	AddMiddleOfLastSpanToList(contour, tablist)
	AddFemaleDoveTailsAlongLine(thickness, dovetail, -unit_y, unit_x, contour, num_flaps_h, tab_space_h, dovetail_markers)
	contour:LineTo(outer_blc)
	AddMiddleOfLastSpanToList(contour, tablist)

	return Face(contour, dovetail_markers, tablist, name)
end

-- Make the side faces
-- Gremlin added bottomdovetail seperation from side which is just dovetail
function MakeSideFace(width, height, thickness, start_point, dovetail, bottomdovetail, with_tails, flat_lid, name)

	local dovetail_markers = {}
	local tablist = {}
	local inner_start_point = start_point + Vector2D(thickness, thickness)
	local inner_width  = width - 2*thickness
	local inner_height = height - 2*thickness
	-- DisplayMessageBox("inner_width " .. inner_width)

	local unit_x = Vector2D(1,0)
	local unit_y = Vector2D(0,1)

	local inner_blc = inner_start_point
	local inner_brc = inner_start_point + inner_width * unit_x
	local inner_trc = inner_brc + inner_height*unit_y
	local inner_tlc = inner_blc + inner_height*unit_y

  -- Gremlin added bottomdovetail seperation from side which is just dovetail
  -- in this case the _w is the width of the side and _h is the height so 
  -- we use bottomdovetail across wthe width
	local num_flaps_w = math.floor((0.5*inner_width) / bottomdovetail.min_width )
	local num_flaps_h = math.floor((0.5*inner_height) / dovetail.min_width)

	local tab_space_w = (inner_width - num_flaps_w*bottomdovetail.min_width)/ (num_flaps_w + 1)
	local tab_space_h = (inner_height - num_flaps_h*dovetail.min_width)/ (num_flaps_h + 1)


	-- Create the contour
	local contour = Contour(0.0)
	contour:AppendPoint(inner_start_point)

	--  blc ->brc
	LineToVector(contour, tab_space_w*unit_x)
	AddMiddleOfLastSpanToList(contour, tablist)
	if (with_tails) then
		AddMaleDoveTailsAlongLine(thickness, bottomdovetail, unit_x, -unit_y, contour,  num_flaps_w, tab_space_w)
	else
		AddFlapsAlongLine(thickness, bottomdovetail.min_width, tab_space_w, unit_x, -unit_y, contour, num_flaps_w)
	end
	contour:LineTo(inner_brc)
	AddMiddleOfLastSpanToList(contour, tablist)

	-- -- brc -> trc
	LineToVector(contour, tab_space_h*unit_y)
	AddMiddleOfLastSpanToList(contour, tablist)
	if with_tails then
		AddMaleDoveTailsAlongLine(thickness, dovetail, unit_y, unit_x, contour, num_flaps_h, tab_space_h )
	else
		AddFlapsAlongLine(thickness, dovetail.min_width, tab_space_h, unit_y, unit_x, contour, num_flaps_h)
	end
	contour:LineTo(inner_trc)
	AddMiddleOfLastSpanToList(contour, tablist)

	-- trc -> tlc (top line so has flaps for lid)
  if flat_lid then
    LineToVector(contour, 0.5*thickness*unit_y)
    LineToVector(contour, -inner_width*unit_x)
    AddMiddleOfLastSpanToList(contour, tablist)
    contour:LineTo(inner_tlc)
  else 
    LineToVector(contour, -tab_space_w*unit_x)
    AddMiddleOfLastSpanToList(contour, tablist)
    AddFlapsAlongLine(thickness, bottomdovetail.min_width, tab_space_w, -unit_x, unit_y, contour, num_flaps_w)
    contour:LineTo(inner_tlc)
    AddMiddleOfLastSpanToList(contour, tablist)
  end

	-- tlc -> blc
	LineToVector(contour, -tab_space_h*unit_y)
	AddMiddleOfLastSpanToList(contour, tablist)
	if (with_tails) then
		AddMaleDoveTailsAlongLine(thickness, dovetail, -unit_y, -unit_x, contour, num_flaps_h, tab_space_h)
	else
		AddFlapsAlongLine(thickness, dovetail.min_width, tab_space_h, -unit_y, -unit_x, contour, num_flaps_h)
	end

	contour:LineTo(inner_blc)
	AddMiddleOfLastSpanToList(contour, tablist)

	return Face(contour, dovetail_markers, tablist, name)
end

-- Make an end face
-- Gremlin added bottomdovetail seperation from side which is just dovetail
function MakeEndFace(width, height, thickness, start_point, dovetail, bottomdovetail, with_tails, flat_lid, name)

	local tablist = {}
	local dovetail_markers = {}
	local unit_x = Vector2D(1,0)
	local unit_y = Vector2D(0,1)
	local inner_start_point = start_point + thickness*unit_y
	local inner_width = width - 2*thickness;
	local inner_height  = height - 2*thickness


	local inner_blc = inner_start_point
	local inner_brc = inner_start_point + width * unit_x
	local inner_trc = inner_brc + inner_height*unit_y
	local inner_tlc = inner_blc + inner_height*unit_y

  -- Gremlin added bottomdovetail seperation from side which is just dovetail
  -- in this case the _w is the width of the side and _h is the height so 
  -- we use bottomdovetail across wthe width
	local num_flaps_w = math.floor((0.5*inner_width)/ bottomdovetail.min_width)
	local num_flaps_h = math.floor((0.5*inner_height) / dovetail.min_width)

	local tab_space_w = (inner_width - num_flaps_w*bottomdovetail.min_width) / (num_flaps_w + 1)
	local tab_space_h = (inner_height - num_flaps_h*dovetail.min_width) / (num_flaps_h + 1)

	local contour = Contour(0.0)
	contour:AppendPoint(inner_start_point)

	-- blc --> brc
	LineToVector(contour, (tab_space_w + thickness)*unit_x)
	AddMiddleOfLastSpanToList(contour, tablist)
	if (with_tails) then
		AddMaleDoveTailsAlongLine(thickness, bottomdovetail, unit_x, -unit_y, contour, num_flaps_w, tab_space_w)
	else
		AddFlapsAlongLine(thickness, bottomdovetail.min_width, tab_space_w, unit_x, -unit_y, contour, num_flaps_w)
	end
	contour:LineTo(inner_brc)
	AddMiddleOfLastSpanToList(contour, tablist)

	-- brc --> trc
	LineToVector(contour,  tab_space_h*unit_y)
	AddMiddleOfLastSpanToList(contour, tablist)
	AddFemaleDoveTailsAlongLine(thickness, dovetail, unit_y, -unit_x, contour, num_flaps_h, tab_space_h, dovetail_markers)
	contour:LineTo(inner_trc)
	AddMiddleOfLastSpanToList(contour, tablist)

	-- if the lid is flat then we go up by half thickness and then across
	if flat_lid then
		LineToVector(contour, (0.5*thickness) * (unit_y));
		LineToVector(contour, (width)*(-unit_x))
		AddMiddleOfLastSpanToList(contour, tablist)
		contour:LineTo(inner_tlc)
	else
		-- trc -> tlc (top line so has flaps for lid)
		LineToVector(contour, (tab_space_w + thickness) * (-unit_x))
		AddMiddleOfLastSpanToList(contour, tablist)
		AddFlapsAlongLine(thickness, bottomdovetail.min_width, tab_space_w, -unit_x, unit_y, contour, num_flaps_w)
		-- AddMaleDoveTailsAlongLine(thickness, dovetail, -unit_x, unit_y, contour, num_flaps_w, tab_space_w)
		contour:LineTo(inner_tlc)
		AddMiddleOfLastSpanToList(contour, tablist)
	end

	-- tlc -> brc
	LineToVector(contour, (tab_space_h*-unit_y))
	AddMiddleOfLastSpanToList(contour, tablist)
	AddFemaleDoveTailsAlongLine(thickness, dovetail, -unit_y, unit_x, contour, num_flaps_h, tab_space_h, dovetail_markers)
	AddMiddleOfLastSpanToList(contour, tablist)

	return Face(contour, dovetail_markers, tablist, name)
end

function AddFemaleDoveTailsAlongLine(thickness, dovetail, along, out, contour, num_tails, space_dist, markers)
	for i=1,num_tails do
		local start_pos = contour.EndPoint2D
		AddFemaleDoveTail(thickness, dovetail.min_width, out, along, contour)
		if (markers) then
			markers[#markers + 1] = MakeLine(start_pos, contour.EndPoint2D) 
		end
		LineToVector(contour, space_dist*along)
	end
end

-- Add male dovetails along this line
function AddMaleDoveTailsAlongLine(thickness, dovetail, along, out, contour, num_tails, space_dist)
	for i=1,num_tails do
		AddMaleDoveTail(thickness, dovetail.max_width, out, along, dovetail.angle, contour)
		LineToVector(contour, space_dist*along)
	end

end

function AddFlapsAlongLine(flap_height, flap_width, space_dist, along, out, contour, num_flaps)
	for i=1,num_flaps do
		AddFemaleDoveTail(flap_height, flap_width, out, along, contour)
		LineToVector(contour, space_dist*along)
	end
end

function AddMaleDoveTail(thickness, max_dovetail_width, out, along, angle, contour)
	local along_dist  = (thickness/ math.tan(angle))
	local diag_vector = (-along_dist)*along + thickness*out
	LineToVector(contour, diag_vector)
	LineToVector(contour, max_dovetail_width*along)
	local and_back = (-along_dist)*along  - thickness*out
	LineToVector(contour, and_back)
end

-- Extend the end point of the contour by the given vector
function LineToVector(contour, vector)
	local current_pos = contour.EndPoint2D
	contour:LineTo(current_pos + vector)
end

-- Add a flap
function AddFemaleDoveTail(thickness, tab_width, perp_vec, along_vec, contour)
	LineToVector(contour, thickness*perp_vec)
	LineToVector(contour, tab_width*along_vec)
	LineToVector(contour, thickness*(-perp_vec))
end

function MakeLid(width, height, thickness, tab_width, start_point, flat_lid, name)

	local tablist = {}
	local unit_x = Vector2D(1,0)
	local unit_y = Vector2D(0,1)
	local inner_width = width - 2*thickness
	local inner_height = height - 2*thickness

	local inner_start_point = start_point + Vector2D(thickness, thickness)

	-- Get corners of box
	local outer_blc = start_point
	local outer_brc = start_point + width*unit_x
	local outer_trc = start_point + width*unit_x + height* unit_y
	local outer_tlc = start_point + height*unit_y

	-- Get the corners of the box offset by the thickness
	local inner_blc = inner_start_point
	local inner_brc = inner_start_point + inner_width*unit_x
	local inner_trc = inner_start_point + inner_height*unit_y + inner_width*unit_x
	local inner_tlc = inner_start_point + inner_height*unit_y

	local num_flaps_w = math.floor( (0.5*inner_width)/tab_width)
	local num_flaps_h = math.floor( (0.5*inner_height)/tab_width)

	local tab_space_w = (inner_width - num_flaps_w*tab_width) / (num_flaps_w + 1)
	local tab_space_h = (inner_height - num_flaps_h*tab_width) / (num_flaps_h + 1)

	local contour = Contour(0.0)
	if (not flat_lid) then
		contour:AppendPoint(start_point)

		--- blc -> brc
		LineToVector(contour, (thickness + tab_space_w)*unit_x)
		AddMiddleOfLastSpanToList(contour, tablist)
		AddFlapsAlongLine(thickness, tab_width, tab_space_w, unit_x, unit_y, contour, num_flaps_w)
		contour:LineTo(outer_brc)
		AddMiddleOfLastSpanToList(contour, tablist)

		-- brc --> trc
		LineToVector(contour, (thickness + tab_space_h) * unit_y)
		AddMiddleOfLastSpanToList(contour, tablist)
		AddFlapsAlongLine(thickness, tab_width, tab_space_h, unit_y, -unit_x, contour, num_flaps_h)
		contour:LineTo(outer_trc)
		AddMiddleOfLastSpanToList(contour, tablist)

		-- trc --> tlc
		LineToVector(contour, (thickness + tab_space_w)*-unit_x)
		AddMiddleOfLastSpanToList(contour, tablist)
		AddFlapsAlongLine(thickness, tab_width, tab_space_w, -unit_x, -unit_y, contour, num_flaps_w)
		contour:LineTo(outer_tlc)
		AddMiddleOfLastSpanToList(contour, tablist)

		-- tlc --> trc
		LineToVector(contour, (thickness + tab_space_h)* -unit_y)
		AddMiddleOfLastSpanToList(contour, tablist)
		AddFlapsAlongLine(thickness, tab_width, tab_space_h, -unit_y, unit_x, contour, num_flaps_h)
		contour:LineTo(outer_blc)
		AddMiddleOfLastSpanToList(contour, tablist)

	else -- No tabs so just create outer profile contour
		contour:AppendPoint(start_point)
		LineToVector(contour, width*unit_x)
		AddMiddleOfLastSpanToList(contour, tablist)
		LineToVector(contour, height*unit_y)
		AddMiddleOfLastSpanToList(contour, tablist)
		LineToVector(contour, -width*unit_x)
		AddMiddleOfLastSpanToList(contour, tablist)
		LineToVector(contour, -height*unit_y)
		AddMiddleOfLastSpanToList(contour, tablist)
	end

	local inner_contour = Contour(0.0)
	inner_contour:AppendPoint(inner_blc)
	inner_contour:LineTo(inner_brc)
	inner_contour:LineTo(inner_trc)
	inner_contour:LineTo(inner_tlc)
	inner_contour:LineTo(inner_blc)

	return Lid(contour, inner_contour, {}, tablist, name)
end

function MakeLidPocketContours(width, height, thickness, start_point)
-- local cad_object_list = CadObjectList(true)

	local unit_x = Vector2D(1,0)
	local unit_y = Vector2D(0,1)

	local inner_width = width - 2*thickness
	local inner_height = height - 2*thickness
	local inner_start_point = start_point + Vector2D(thickness, thickness)

	-- Get corners of box
	local outer_blc = start_point
	local outer_brc = start_point + width*unit_x
	local outer_trc = start_point + width*unit_x + height* unit_y
	local outer_tlc = start_point + height*unit_y

	-- Get the corners of the box offset by the thickness
	local inner_blc = inner_start_point
	local inner_brc = inner_start_point + inner_width*unit_x
	local inner_trc = inner_start_point + inner_height*unit_y + inner_width*unit_x
	local inner_tlc = inner_start_point + inner_height*unit_y

	local cad_object_list = CadObjectList(true);
	local outer_contour = Contour(0.0)
	outer_contour:AppendPoint(outer_blc)
	outer_contour:LineTo(outer_brc)
	outer_contour:LineTo(outer_trc)
	outer_contour:LineTo(outer_tlc)
	outer_contour:LineTo(outer_blc)

	local inner_contour = Contour(0.0)
	inner_contour:AppendPoint(inner_blc)
	inner_contour:LineTo(inner_brc)
	inner_contour:LineTo(inner_trc)
	inner_contour:LineTo(inner_tlc)
	inner_contour:LineTo(inner_blc)

	local outer_cad_contour = CreateCadContour(outer_contour)
	cad_object_list:AddTail(outer_cad_contour)
	local inner_cad_contour = CreateCadContour(inner_contour)
	cad_object_list:AddTail(inner_cad_contour)

	return cad_object_list
end

--[[  -------------- ArrangeContours --------------------------------------------------  
|
| Arrange the contours
| NEW: Always lays out ALL faces, even if they extend beyond the
|      current job size. This lets the user adjust the job size
|      afterwards instead of aborting with an error.
|
]]
function ArrangeContours(faces, clearance_gap, job_width, job_height, edge_margin)

  local transformed_faces = {}

  if #faces == 0 then
    return transformed_faces
  end

  -- Simple row/column layout
  local x_cursor   = edge_margin
  local y_cursor   = edge_margin
  local row_height = 0

  for i = 1, #faces do
    local face   = faces[i]
    local bounds = face.contour.BoundingBox2D
    local width  = bounds.XLength
    local height = bounds.YLength

    -- If we would run past the row width, wrap to a new row.
    -- NOTE: we do NOT abort if we run past the job height; vectors
    --       are still created, even if they extend outside the material.
    if (x_cursor > edge_margin)
       and (x_cursor + width + clearance_gap) > (job_width - edge_margin) then
      x_cursor   = edge_margin
      y_cursor   = y_cursor + row_height + clearance_gap
      row_height = 0
    end

    -- Position so the face's lower-left corner sits at (x_cursor, y_cursor)
    local dx = x_cursor - bounds.MinX
    local dy = y_cursor - bounds.MinY
    local xform = TranslationMatrix2D(Vector2D(dx, dy))
    TransformFace(face, xform)

    transformed_faces[#transformed_faces + 1] = face

    x_cursor   = x_cursor + width + clearance_gap
    if height > row_height then
      row_height = height
    end
  end

  return transformed_faces
end
 
--[[  -------------- ComputeDogBones --------------------------------------------------  
|
| Compute the markers for where dog bones should be placed on preradiused contours
|
]]
function ComputeDogBones(contour_group, radius, do_ccw)
  circles = {}
  line_markers = {}
  local ctr_pos = contour_group:GetHeadPosition()
  local contour
  while ctr_pos ~= nil do
    contour, ctr_pos = contour_group:GetNext(ctr_pos)
    if (contour.IsCCW == do_ccw) then
      local span
      local span_pos = contour:GetHeadPosition()
      local prev_span = contour:GetLastSpan()
      while span_pos ~= nil do
        span, span_pos = contour:GetNext(span_pos)
        
        if (SpanIsArc(span, radius)) then
            local centre = Point3D()
            local arc_span = CastSpanToArcSpan(span)
            arc_span:RadiusAndCentre(centre)
            circles[#circles + 1]  = centre
            local span_out_end = GetEndPointArcBisector(arc_span, radius, centre, arc_span:ArcMidPoint() )
            line_markers[#line_markers + 1] = MakeLine(centre, span_out_end)
        end
        prev_span = span
      end
    end
  end
  
  return circles, line_markers
end

--[[  -------------- CreateDogboneProfile --------------------------------------------------  
|
| Create the dogboned profile
| offset_radius = tool_radius - allowance
]]
function CreateDogboneProfile(contour_group, offset_radius)

  local rounded_contours = OffsetOutIn(contour_group, offset_radius)
  local circles, markers = ComputeDogBones(rounded_contours, offset_radius, true)

  -- Fill bins with markers
  local bounding_box = rounded_contours.BoundingBox2D
  local box_xlength = bounding_box.XLength
  local min_x  = bounding_box.MinX - 0.1*box_xlength
  local max_x =  bounding_box.MaxX  + 0.1*box_xlength
  box_xlength = max_x - min_x

  local box_ylength = bounding_box.YLength
  local min_y  = bounding_box.MinY - 0.1*box_ylength
  local max_y =  bounding_box.MaxY  + 0.1*box_ylength
  box_ylength = max_y - min_y


  local bin_data = {}
  bin_data.min_x = min_x
  bin_data.min_y = min_y
  bin_data.dim = math.ceil(math.sqrt(#markers))
  bin_data.grid_x = box_xlength / bin_data.dim
  bin_data.grid_y = box_ylength /bin_data.dim
  local bin_array = InitializeBins(bin_data.dim)
  FillBins(markers, bin_data, bin_array)

  -- Offset the contours out
  local offset_contours = contour_group:Offset(offset_radius, offset_radius, 1, true)
  local filleted_contour_group = ContourGroup(true)
  local current_contour
  local pos = offset_contours:GetHeadPosition()
  while pos~= nil do
  	current_contour, pos = offset_contours:GetNext(pos)
  	local filleted_contour = AddFillets(current_contour, markers, offset_radius, bin_array, bin_data, true)
  	if filleted_contour ~= nil then
  		filleted_contour_group:AddTail(filleted_contour)
  	end
  end

  return filleted_contour_group
end

--[[  -------------- BinKey --------------------------------------------------  
|
| Return which bin the point should be in
|
]]
function BinKey(point,bin_data)
  local i = math.floor((point.x - bin_data.min_x) / bin_data.grid_x)
  local j = math.floor((point.y - bin_data.min_y) / bin_data.grid_y)

  if ( (i+1 > bin_data.dim) or  (j+1 > bin_data.dim)) then
    return nil
  end
  return i + 1, j + 1 -- We add 1 because using lua-style 0 index matrices 
end

--[[  -------------- InitializeBins --------------------------------------------------  
|
| Initialize the bins
|
]]
function InitializeBins(dim)
  local mt = {}
  for i = 1, dim do
    mt[i] = {}
    for j = 1, dim do
      mt[i][j] = {}
    end
  end
  return mt
end

--[[  -------------- PlaceMarkerInbin --------------------------------------------------  
|
| Place a marker in its rightful bin
|
]]
function PlaceMarkerInBin(marker, bin_data, bin_array)
  local i, j = BinKey(marker.StartPoint2D, bin_data)
  if i ~= nil and j ~= nil then
    (bin_array[i][j])[#(bin_array[i][j]) + 1] = marker
  end
end

--[[  -------------- FillBins --------------------------------------------------  
|
| Fill all bins
|
]]
function FillBins(markers, bin_data, bin_array)
  for i= 1, #markers do
    if IsSpan(markers[i]) then
      PlaceMarkerInBin(markers[i], bin_data, bin_array)
    end
  end
end

--[[  -------------- HasMatchingMarker --------------------------------------------------  
|
| Has matching marker
|
]]
function HasMatchingMarker(point, bin_data, bin_array)
  local i,j = BinKey(point, bin_data)
  if (i == nil) then
    return nil
  end
  local this_bin = bin_array[i][j] 
  if this_bin == nil then 
    return nil
  end

  for m = 1, #this_bin do
    local marker = this_bin[m]
    if marker.StartPoint2D:IsCoincident(point, 0.01) then
      return marker
    end
  end
  return nil
end

--[[  -------------- MakeLine --------------------------------------------------  
|
|  Make a straight line contour between two points
|
]]
function MakeLine
  (
  start_pt, -- start point
  end_pt    -- end point
  )
  local contour = Contour(0.0)
  contour:AppendPoint(start_pt)
  contour:LineTo(end_pt)
  return contour
end

--[[  -------------- OffsetOutIn --------------------------------------------------  
|
| Return the result of offsetting the contour group out and then back in again
|
]]
function OffsetOutIn(contour_group, radius)
  local out_group = contour_group:Offset(radius, radius, 1, true)
  local in_group = out_group:Offset(-radius, -radius, 1, true)
  return in_group
end

--[[  -------------- SpanIsArc --------------------------------------------------  
|
| Return true if span is arc
|
]]
function SpanIsArc(span, radius)
  if not span.IsArcType then
    return false
  end
  local centre = Point3D()
  local arc_span = CastSpanToArcSpan(span)
  local span_radius = arc_span:RadiusAndCentre(centre)
  if math.abs(span_radius - radius) > 0.005 then
    return false
  end
  return true
end

--[[  -------------- utAngleRad2d --------------------------------------------------  
|
| utility function computing angle swept out by rays 
|
]]
 function utAngleRad2d( x1, y1, x2, y2, x3, y3)
  local value;
  local x = ( x1 - x2 ) * ( x3 - x2 ) + ( y1 - y2 ) * ( y3 - y2 )
  local y = ( x1 - x2 ) * ( y3 - y2 ) - ( y1 - y2 ) * ( x3 - x2 )

  if ( x == 0.0 and y == 0.0 ) then
     value = 0.0
  else
     value = math.atan2 ( y, x )
     if ( value < 0.0 ) then
        value = value + 2.0 * math.pi
     end
  end 
  return value;
end

--[[  -------------- GetInternalAngleArc --------------------------------------------------  
|
| Get the internal angle arc
|
]]
function GetInternalAngleArc(arc_span, arc_centre)

  local start_pt = arc_span.StartPoint2D
  local end_pt   = arc_span.EndPoint2D

  -- get included angle of arc, function assumes CCW arc so reverse direction if CW ...
  local  arc_angle
  if arc_span.IsClockwise then
     arc_angle = utAngleRad2d(end_pt.x,end_pt.y, arc_centre.x, arc_centre.y,start_pt.x, start_pt.y)
  else
     arc_angle = utAngleRad2d(start_pt.x,start_pt.y, arc_centre.x, arc_centre.y, end_pt.x, end_pt.y)
  end

  return arc_angle
end

--[[  -------------- GetEndPointArcBisector --------------------------------------------------  
|
| Get the end point of the bisector which cuts arc in half and meets at point on tangents
|
]]
function GetEndPointArcBisector(arc_span, radius, start_point, mid_point)
  local internal_angle = GetInternalAngleArc(arc_span, start_point)
  local corner_angle =  math.pi - internal_angle 
  local offset_distance = (radius / math.sin(0.5*corner_angle)) - radius
  local offset_vector = mid_point - start_point
  offset_vector:Normalize()
  
  local offset_point = start_point  + offset_distance*offset_vector
  return offset_point
end

--[[  -------------- IsSpan --------------------------------------------------  
|
| Return true if the contour is just a single line span
|
]]
  function IsSpan(ctr)
    if (ctr.Count == 1) and ctr:GetFirstSpan().IsLineType then
      return true
    else
      return false
    end
  end
  
 --[[  -------------- CloneSpan --------------------------------------------------  
|
| Clone the given span
|
]] 
function CloneSpan(span)
  if span.IsLineType then
    return LineSpan(span.StartPoint2D, span.EndPoint2D)
  elseif span.IsArcType then
    local arc_span = CastSpanToArcSpan(span)
    return ArcSpan(span.StartPoint2D, span.EndPoint2D, arc_span.Bulge)
  elseif span.IsBezierType then
    local bspan = CastSpanToBezierSpan(span)
    return BezierSpan(bspan.StartPoint2D, 
                      bspan.EndPoint2D, 
                      span:GetControlPointPosition(0), 
                      span:GetControlPointPosition(1))
  end
end

--[[  -------------- AddFillets --------------------------------------------------  
|
| Add filletes to the given contour
|
]]
function AddFillets(contour, markers, radius, bin_array, bin_data, is_ccw)
  if contour.IsCCW == is_ccw then
    local return_contour = Contour(0.0)
    local span_pos = contour:GetHeadPosition()
    local span
    while span_pos ~= nil do
      span, span_pos = contour:GetNext(span_pos)
      return_contour:AppendSpan(CloneSpan(span))
      local marker_line  = HasMatchingMarker(span.EndPoint2D, bin_data, bin_array)
      if marker_line ~= nil then
        return_contour:LineTo(marker_line.EndPoint2D)
        return_contour:LineTo(marker_line.StartPoint2D)    
      end
        
    end
    return return_contour
  else
    return nil
  end
  
end

-- Transfer tabs from one cad contour to another
-- Only want to do this if for example have offset
-- one cad contour from another
function TransferTabs(cad_contour_a, cad_contour_b)
  -- clone because problem with constness on tabs

	local tabs_a = cad_contour_a:GetToolpathTabs()
	local contour_a = cad_contour_a:GetContour()
	local pos = tabs_a:GetHeadPosition()
	while pos do
		local tab
		tab, pos = tabs_a:GetNext(pos)
		local point = tab:Position(contour_a)
		cad_contour_b:InsertToolpathTabAtPoint(point)
	end
end

function AddMiddleOfLastSpanToList(contour, pt_list)
	local last_span = contour:GetLastSpan()
	pt_list[#pt_list + 1] = last_span.StartPoint2D + 0.5*(last_span.EndPoint2D - last_span.StartPoint2D)
end

function AddTabsToContour(cad_contour, pt_list)
	if (pt_list) then
		for i=1,#pt_list do
			cad_contour:InsertToolpathTabAtPoint(pt_list[i])
		end
	else
		DisplayMessageBox("No tabs to Add")
	end
end

function MakeCadAndAddTabs(contour, tab_list)
	local cad_contour = CreateCadContour(contour)
	AddTabsToContour(cad_contour, tab_list)
	return cad_contour
end

function GetContours(cad_object_list)
	local vdcontours = ContourGroup(true)
	local pos, obj
	pos = cad_object_list:GetHeadPosition()
	while (pos) do
		obj, pos = cad_object_list:GetNext(pos)
		local ctr = obj:GetContour()
		if ctr then
			vdcontours:AddTail(ctr:Clone())
		end
	end
	return vdcontours
end

-- Create tabbed versions of the vdcontours by creating 
-- a cad contour version of each contour and transferring all
-- tabs
function CreateTabbedCadContours(vdcontours, cadcontours)
	local cad_obj_list = CadObjectList(true)
	local pos, vdctr, cdctr
	vcpos = cadcontours:GetHeadPosition()
	while vcpos do
		vcctr, vcpos = cadcontours:GetNext(vcpos)
		local vcbox = vcctr:GetBoundingBox()

		-- find the vd contour whose bounding centre is nearest ours
		vdpos = vdcontours:GetHeadPosition()
		while vdpos do
			vdctr, vdpos = vdcontours:GetNext(vdpos)
			local vdbox = vdctr.BoundingBox2D
			if (vdbox:IsInside(vcbox)) then
				local cad_ctr = CreateCadContour(vdctr)
				TransferTabs(CastCadObjectToCadContour(vcctr), cad_ctr)
				cad_obj_list:AddTail(cad_ctr)
			end
		end

	end
	return cad_obj_list
end

function AddToSelection(cadobjlist, job)
	local selection_list = job.Selection
	selection_list:Clear()
	local pos = cadobjlist:GetHeadPosition()
	local obj
	while (pos) do
		obj, pos = cadobjlist:GetNext(pos)
		selection_list:Add(obj, true, false)
	end
end

--[[  ---------------- SelectVectorsOnLayer ----------------  
|
|   Add all the vectors on the layer to the selection
|     layer,            -- layer we are selecting vectors on
|     selection         -- selection object
|     select_closed     -- if true  select closed objects
|     select_open       -- if true  select open objects
|     select_groups     -- if true select grouped vectors (irrespective of open / closed state of member objects)
|  Return Values:
|     true if selected one or more vectors
|
]]
function SelectVectorsOnLayer(layer, selection, select_closed, select_open, select_groups)
    
   local objects_selected = false
   local warning_displayed = false
   
   local pos = layer:GetHeadPosition()
      while pos ~= nil do
	     local object
         object, pos = layer:GetNext(pos)
         local contour = object:GetContour()
         if contour == nil then
            if (object.ClassName == "vcCadObjectGroup") and select_groups then
               selection:Add(object, true, true)
               objects_selected = true
            else 
               if not warning_displayed then
                  local message = "Object(s) without contour information found on layer - ignoring"
                  if not select_groups then
                     message = message .. 
                               "\r\n\r\n" .. 
                               "If layer contains grouped vectors these must be ungrouped for this script"
                  end
                  DisplayMessageBox(message)
                  warning_displayed = true
               end   
            end
         else  -- contour was NOT nil, test if Open or Closed
            if contour.IsOpen and select_open then
               selection:Add(object, true, true)
               objects_selected = true
            else if select_closed then
               selection:Add(object, true, true)
               objects_selected = true
            end            
         end
         end
      end  
   -- to avoid excessive redrawing etc  we added vectors to the selection in 'batch' mode
   -- tell selection we have now finished updating
   if objects_selected then
      selection:GroupSelectionFinished()
   end   
   return objects_selected   
end   

function CreateCutoutToolpath(cad_contours, tool, job, thickness, tab_length, layer_name)
  
  if not _tool_ok(tool) then
  DisplayMessageBox("Cutout Toolpath: Please select a Valid Tool before continuing.")
  return false
end

	local profile_data = ProfileParameterData()
	profile_data.CutDepth = thickness
	profile_data.StartDepth = 0.0
	profile_data.ProfileSide = ProfileParameterData.PROFILE_ON
	profile_data.UseTabs = false                                       --- Changed true to false markjones
	profile_data.TabThickness = math.min(0.25*thickness, 0.25)
	profile_data.TabLength = tab_length

	local ramping_data = RampingData()
	ramping_data.DoRamping = false                                     --- Changed true to false markjones
	ramping_data.RampAngle = 30.0
	ramping_data.RampConstaint = RampingData.CONSTRAIN_ANGLE

	local lead_data = LeadInOutData()

	local pos_data = ToolpathPosData()

	local geometry_selector = GeometrySelector()

	-- AddToSelection(cad_contours, job)
  
  -- Select all on a layer
  local selection = job.Selection
  selection:Clear()
  local layer = job.LayerManager:FindLayerWithName(layer_name)
  SelectVectorsOnLayer(layer, selection, true, true, true)

  local toolpath_manager = ToolpathManager()
	local toolpath = toolpath_manager:CreateProfilingToolpath(
		"Cut Out",
		tool,
		profile_data,
		ramping_data,
		lead_data,
		pos_data,
		geometry_selector,
		true,
		true
		)

	if toolpath == nil then
		DisplayMessageBox("Error Creating toolpath")
	end
end

--[[  -------------- CalculateRails --------------------------------------------------  
|
|  Calculate a list of rails along which we will run our tool
|  Returns a ContourGroup corresponding to this rail
|
]]
function CalculateRails
    (
    side_rail,   -- contour which represents side of dovetial
    angle,       -- angle
    on_left,     -- if true then we create rails to left of side_rail
    offset,      -- Allowance
    tool,        -- tool used
    start_z,     -- depth start cutting
    cut_z        -- depth finish cutting 
    )
  local is_dodgy = false
  if side_rail.StartPoint2D:IsCoincident(Point2D(53, 25), 1) then
    is_dodgy = true
  end
  local side_length = side_rail.Length
  local blk_material = MaterialBlock()
  local converted_Stepover = ConvertUnitsFrom(tool.Stepover,tool,blk_material)
  local num_stripes = math.ceil(side_length/ converted_Stepover )
  local stripe_shift = (side_length) / num_stripes
  local horizontal_distance = (math.abs(start_z - cut_z) / math.tan(angle))
  local along_rail = (side_rail.EndPoint2D - side_rail.StartPoint2D):Normalize()
  local contours = {}
  
  -- The normal vector points along the direction we expect
  local normal_vec = (side_rail.EndPoint2D - side_rail.StartPoint2D):NormalTo()
  normal_vec:Normalize()
  normal_vec = (horizontal_distance)*normal_vec
  if (on_left) then
    normal_vec = -normal_vec
  end
  
  -- iterate over the stripes getting start and end points
  local contour_group = ContourGroup(true)
  for i = 1, num_stripes do
    local start_pt = Point3D(side_rail.StartPoint2D  + (i - 1)*stripe_shift*along_rail, start_z)
    local end_pt = Point3D(start_pt.x + normal_vec.x, start_pt.y + normal_vec.y, cut_z)
    local contour = MakeLine(start_pt, end_pt)
    contour_group:AddTail(contour)
  end

  return contour_group
end

--[[  -------------- CalculateToolpathContour --------------------------------------------------  
|
|  From a list of rails calculate the toolpath contour
|
]]
function CalculateToolpathContour
  (
  rails,        -- a contour group corresponding to one set of rails
  rad_angle,    -- angle in radians
  z_depth,      -- z height of cut depth
  pos_data
  )
  
  local toolpath_contour = Contour(0.0)

  if rails.IsEmpty then 
    return
  end

  -- Add start point at safe z height above start point of first rail
  local start_pt = Point3D(rails:GetHead().StartPoint2D, pos_data.SafeZ)
  local lift_z = rails:GetHead().StartPoint3D.z + pos_data.StartZGap
  toolpath_contour:AppendPoint(start_pt)

  local do_backwards = false
  local contour_pos = rails:GetHeadPosition()
  local rail
  while contour_pos ~= nil do
    rail, contour_pos = rails:GetNext(contour_pos)

    if do_backwards then
      toolpath_contour:LineTo(rail.EndPoint3D)
      toolpath_contour:LineTo(rail.StartPoint3D)
    else
      toolpath_contour:LineTo(rail.StartPoint3D)
      toolpath_contour:LineTo(rail.EndPoint3D)
    end
    do_backwards = not do_backwards
  end

-- lift to safe z
  local current_pos = toolpath_contour.EndPoint2D
  toolpath_contour:LineTo(Point3D(current_pos, pos_data.SafeZ))

  return toolpath_contour
end

--[[  -------------- CalculateSideRails --------------------------------------------------  
|
|  Calculate the side rails of our contours
|
]]
function CalculateSideRails
  (
  vectors,    -- vectors for which we hope to construct side rails
  depth,      -- depth of the dovetial
  side_rails, -- side rails
  is_on_left,  -- list indexing whether a given side rail has its dove tail on its right
  tool_diam,
  rad_angle,
  thickness,
  allowance
 )

  for i=1, #vectors do
    local contour = vectors[i]
    local right_contour_normal = contour:GetFirstSpan():StartVector(true):NormalTo()
    local contour_vec = contour:GetFirstSpan():StartVector(true)
    local horizontal_offset = thickness/ math.tan(rad_angle)

    
    local start_start_point = vectors[i].StartPoint2D 
                              - (horizontal_offset + allowance)*contour_vec + 
                              0.5*tool_diam*contour_vec 
                              + allowance*right_contour_normal
                              
    local start_end_point = start_start_point  - (depth+ 2*allowance)*right_contour_normal
    local start_contour = Contour(0.0)
    start_contour:AppendPoint(start_start_point)
    start_contour:LineTo(start_end_point)
    side_rails[#side_rails + 1] = start_contour
    is_on_left[#is_on_left +1] = false -- the start side rail has its dove tail on its right
    
    local end_start_point = vectors[i].EndPoint2D 
                            - 0.5*tool_diam*contour_vec 
                            + (horizontal_offset + allowance)*contour_vec +
                            allowance*right_contour_normal
    local end_end_point = end_start_point - (depth + 2*allowance)*right_contour_normal
    local end_contour = Contour(0.0)
    end_contour:AppendPoint(end_start_point)
    end_contour:LineTo(end_end_point)
    side_rails[#side_rails + 1] = end_contour
    is_on_left[#is_on_left +1] = true -- the end side rail has its dove tail on its left  
  end
 
 end

function ConvertUnitsFrom(value, tool, blockmaterial)

  if (tool.InMM == blockmaterial.InMM) then
     return value
  end
     
  if (tool.InMM) then
     return value / 25.4  -- caller is in mm but we want inches   
  end
  
  return value * 25.4     -- caller is in inches but we want mm   
end

function CreateDoveTailToolpath(markers, dovetail, tool, allowance, warn_user)
  
  if not _tool_ok(tool) then
  DisplayMessageBox("Dovetail toolpath: please select a valid tool before continuing.")
  return false
end
  
  -- Calculate side rails
  local side_rails = {}
  local is_on_left = {}

  -- Convert tool diameter using the tool passed in (no global 'options'!)
  local mtl_block = MaterialBlock()
  local dia = ConvertUnitsFrom(tool.ToolDia, tool, mtl_block)

  CalculateSideRails(
    markers,
    dovetail.depth,
    side_rails,
    is_on_left,
    dia,
    dovetail.angle,
    math.abs(dovetail.cut_z - dovetail.start_z),
    allowance
  )

  if #side_rails == 0 then
    DisplayMessageBox("Unable to create dovetails")
    return false
  end

  -- Build the toolpath contour from rails
  local contour_group = ContourGroup(true)
  local pos_data = ToolpathPosData()

  for i = 1, #side_rails do
    local rails = CalculateRails(
      side_rails[i],
      dovetail.angle,
      is_on_left[i],
      allowance,
      tool,
      dovetail.start_z,
      dovetail.cut_z
    )

    local contour = CalculateToolpathContour(
      rails,
      dovetail.angle,
      dovetail.cut_z,
      pos_data
    )

    if contour ~= nil then
      contour_group:AddTail(contour)
    end
  end

  -- Emit external toolpath
  if contour_group.IsEmpty then
    DisplayMessageBox("No dove tails created")
    return false
  end

  local toolpath_options = ExternalToolpathOptions()
  toolpath_options.StartDepth = dovetail.start_z
  toolpath_options.CreatePreview = true

  -- Name the toolpath clearly
local tp_name = "Dovetail (External)"

local toolpath = ExternalToolpath(
  tp_name,
  tool,
  pos_data,
  toolpath_options,
  contour_group
)

if toolpath:Error() then
  DisplayMessageBox("Error Creating Toolpath")
  return true
end

local toolpath_manager = ToolpathManager()
toolpath_manager:AddExternalToolpath(toolpath)

-- *** NEW: warning message ***
-- Show the warning only if requested
if warn_user then
DisplayMessageBox(
  "Dovetail Toolpath Notice:\n\n"
  .. "This Dovetail Toolpath is Created as an *External Toolpath* by the Gadget.\n"
  .. "External Toolpaths CANNOT be Recalculated in VCarve/Aspire.\n\n"
  .. "If User Moves the Vectors (e.g., center on material) and Needs this Toolpath Again:\n"
  .. "  • The User will Need to Re-Run this Gadget after Proper Planning is Achieved.\n\n"
  .. "Tip: Plan Vector Placement Before Running the Box Creator Gadget."
)
  end
end

-- MotazA 16/9/2020 check if job Exists 
function main(script_path)
	local job = VectricJob()
	local mtl_block = MaterialBlock()

	if not job.Exists then
       DisplayMessageBox("No job loaded.")
       return false
    end
 
 ------------------------------------------- Geometry Options Default Settings ----------------------------------------------------------
 ------------------------------ Added this blocked off and the line descriptions by Sharkcutup
 
	local options = {}
	options.width = 18                        --- width  default               
	options.height = 12                       --- height default              
	options.depth = 14                        --- depth default                      
	options.start_point = Point2D(0,0)
	options.thickness = mtl_block.Thickness;
	options.tabwidth = 0.3                    --- joint width default      
  options.tabwidthbottom = 1.0              --- joint width for the bottom (as a separate value)   
	options.cut_layer_name  = "CutOut"        --- layer name default          
	options.allowance = 0.0                   --- allowance default 
  options.edge_margin = 0.75                 --- edge margin default
  options.warn_dovetail = true   -- show dovetail warning after create
	options.cut_dovetails = false
	options.flat_lid = true
	options.window_width = g_width
	options.window_height = g_height

	options.make_lid = true                   --- lid checkbox default       
	options.make_bottom = true                --- bottom checkbox default     
	options.make_side1 = true                 --- side 1 checkbox default    
	options.make_side2 = true                 --- side 2 checkbox default     
	options.make_end1 =  true                 --- end 1 checkbox default      
	options.make_end2 = true                  --- end 2 checkbox default      

-----------------------------------------------------------------------------------------------------------------------------------------

	local dovetails = ContourGroup(true)
	
  local dovetail = {}
	dovetail.angle = math.rad(60)
	dovetail.min_width = 1.5
	dovetail.depth = options.thickness

  -- added by Gremlin to allow for separate widths on bottom vs side tabs
  local bottomdovetail = {}   
  bottomdovetail.angle = math.rad(60)
	bottomdovetail.min_width = 1.5
	bottomdovetail.depth = options.thickness

	LoadDefaults(options, dovetail, bottomdovetail)

	local tool = Tool("0.25 Inch End Mill", Tool.END_MILL)
	tool.ToolDia = 0.25
	tool.InMM = false

	options.tool = tool

  -- Gremlin added bottomdovetail seperation from side which is just dovetail
	local dialog_displayed = DisplayDialog(script_path, options, dovetail, bottomdovetail)
	if (not dialog_displayed) then 
		return false
	end
	dovetail.depth = options.thickness
	dovetail.start_z = mtl_block:CalcAbsoluteZFromDepth(0)
	dovetail.start_depth = 0
	dovetail.cut_z = mtl_block:CalcAbsoluteZFromDepth(options.thickness)

-- Make the bottom face
	local cad_list = CadObjectList(true)
-- local dovetail_markers = {}
	local faces = {}

	if options.make_bottom then
    -- Gremlin added bottomdovetail seperation from side which is just dovetail
    -- the bottom face is only the bottom so we didn't need to add
    -- a separate value to it, just pass it the bottom value
		local bottom_face = MakeBottomFaceContour(options.width, 
													options.depth, 
													options.thickness, 
													options.start_point, 
													bottomdovetail, 
													options.cut_dovetails,  -- if true then create dovetails
													"BottomFace" )
		faces[#faces + 1] = bottom_face
	end

	-- -- -- Make sides
	if options.make_side1 then
    -- Gremlin added bottomdovetail seperation from side which is just dovetail
		local sideface1 = MakeSideFace(options.width,
									  options.height, 
									  options.thickness, 
									  options.start_point, 
									  dovetail, 
                    bottomdovetail,
									  options.cut_dovetails, 
									  options.flat_lid,
									  "SideFace1")
		faces[#faces + 1] = sideface1
	end

	if options.make_side2 then
    -- Gremlin added bottomdovetail seperation from side which is just dovetail
		local sideface2 = MakeSideFace(options.width,
									  options.height, 
									  options.thickness, 
									  options.start_point, 
									  dovetail, 
                    bottomdovetail,
									  options.cut_dovetails, 
									  options.flat_lid,
									  "SideFace2")
		faces[#faces + 1] = sideface2
	end

	-- -- -- Make ends
	if options.make_end1 then
    -- Gremlin added bottomdovetail seperation from side which is just dovetail
		local endface1 = MakeEndFace(options.depth, 
											   options.height, 
											   options.thickness,
											   options.start_point, 
											   dovetail,
                         bottomdovetail,
											   options.cut_dovetails, 
											   options.flat_lid,
											   "EndFace1")
		faces[#faces + 1] = endface1
	end

	if options.make_end2 then
    -- Gremlin added bottomdovetail seperation from side which is just dovetail
		local endface2 = MakeEndFace(options.depth, 
											   options.height, 
											   options.thickness,
											   options.start_point, 
											   dovetail,
                         bottomdovetail,
											   options.cut_dovetails, 
											   options.flat_lid,
											   "EndFace2")
		faces[#faces + 1] = endface2
	end

	-- Make lid
	if options.make_lid then
		local lid = MakeLid(options.width,
												   options.depth,
												   options.thickness,
												   dovetail.min_width,
												   options.start_point,
												   options.flat_lid,
												   "Lid"
	                       )
		faces[#faces + 1] = lid
	end

	-- Arrange the contours
  local mtl_block = MaterialBlock()
  local converted_tool_diameter = ConvertUnitsFrom(options.tool.ToolDia, options.tool, mtl_block)
  local part_gap    = 2 * converted_tool_diameter
  local edge_margin = math.max(options.edge_margin or 0.0, 0.75)
  faces = ArrangeContours(faces, part_gap, job.XLength, job.YLength, edge_margin)

	-- Get at the actual contours and dogbone them. Then transfer the tabs
	local vdcontours = GetAllProfileContours(faces)
	local cdcontours = GetAllProfileCadContours(faces)
  
	local offset_radius = 0.5* converted_tool_diameter - options.allowance
	local dogboned_contours = CreateDogboneProfile(vdcontours, offset_radius)
	local dogboned_cadcontours = CreateTabbedCadContours(dogboned_contours, cdcontours)

	-- -- AddCadContourToJob(job, cad_contour, "Box")
  -- These extra vectors represent the actual output
  -- so you can place extra details on them if you wish
	AddCadListToJob(job, cdcontours, "Box")
	AddCadListToJob(job, dogboned_cadcontours, options.cut_layer_name)

	if options.make_lid then
		if options.flat_lid then 
			CreateLidPocketToolpath(job, options, faces, options.tool, "Pockets" )
		end
	end

    -- if we are doing dovetails make toolpath for them
	local dovetail_markers = GetAllMarkers(faces)
	if options.cut_dovetails and (#dovetail_markers > 0) then
		CreateDoveTailToolpath(dovetail_markers, dovetail, options.tool, options.allowance, options.warn_dovetail)
	end

	CreateCutoutToolpath(dogboned_cadcontours, options.tool, job, options.thickness, options.tabwidth, options.cut_layer_name)
	SaveDefaults(options, dovetail)
	job:Refresh2DView()
	return true

end

-- Gremlin added bottomdovetail seperation from side which is just dovetail 
function DisplayDialog(script_path, options, dovetail, bottomdovetail)
	local html_path = "file:" .. script_path .. "\\" .. g_html_file
	local dialog = HTML_Dialog(false, html_path, options.window_width, options.window_height, string.format("%s - Version %s", g_title, g_version))
  

	dialog:AddLabelField("GadgetTitle", g_title)
	dialog:AddLabelField("GadgetVersion", g_version)

	-- Add Geometry fields
	dialog:AddDoubleField("WidthField", options.width)
	dialog:AddDoubleField("DepthField", options.depth)
	dialog:AddDoubleField("HeightField", options.height)
	dialog:AddDoubleField("TabWidthField", dovetail.min_width)
  -- Gremlin added bottomdovetail seperation from side which is just dovetail
  dialog:AddDoubleField("BottomTabWidthField", bottomdovetail.min_width)
	dialog:AddDoubleField("AllowanceField", options.allowance)
  dialog:AddDoubleField("EdgeField", options.edge_margin)
  
  dialog:AddCheckBox("WarnDovetail", options.warn_dovetail)

	-- dialog:AddDoubleField("DovetailAngleField", dovetail.angle)
  
	dialog:AddCheckBox("MakeLid", options.make_lid)
	dialog:AddCheckBox("MakeBottom", options.make_bottom)
	dialog:AddCheckBox("MakeSide1", options.make_side1)
	dialog:AddCheckBox("MakeSide2", options.make_side2)
	dialog:AddCheckBox("MakeEnd1", options.make_end1)
	dialog:AddCheckBox("MakeEnd2", options.make_end2)
  
	-- Add Tool picker
	-- Add toolpath name field
  dialog:AddLabelField("ToolNameField", "")
	dialog:AddToolPicker("ToolChooseButton", "ToolNameField", options.default_toolid)
	dialog:AddToolPickerValidToolType("ToolChooseButton", Tool.END_MILL)
 
-- Tab Type: 1 = Finger Joint, 2 = Dovetail Joint
local tab_default_index
if options.cut_dovetails then
  tab_default_index = 2  -- last time user chose dovetails
else
  tab_default_index = 1  -- last time user chose finger joints
end
dialog:AddRadioGroup("TabTypeRadio", tab_default_index)

-- Lid Type: 1 = Flat Lid, 2 = Tabbed Lid
local lid_default_index
if options.flat_lid then
  lid_default_index = 1  -- last time user chose flat lid
else
  lid_default_index = 2  -- last time user chose tabbed lid
end
dialog:AddRadioGroup("LidTypeRadio", lid_default_index)


	-- Add units label
	local units_string = "Inches"
	if options.tool.InMM then
		units_string = "MM"
	end

	dialog:AddTextField("UnitsLabel", units_string)

  local validator = function(dialog)
    -- Gremlin added bottomdovetail seperation from side which is just dovetail
    ReadOptions(dialog, options, dovetail, bottomdovetail)
    local double_thickness = options.thickness * 2
    if options.width <= double_thickness then
      DisplayMessageBox(string.format("The box width %f is too small for material thickness %f", options.width, options.thickness))
      return false
    end
    if options.depth <= double_thickness then
      DisplayMessageBox(string.format("The box depth %f is too small for material thickness %f", options.depth, options.thickness))
      return false
    end
    if options.height <= double_thickness then
      DisplayMessageBox(string.format("The box height %f is too small for material thickness %f", options.height, options.thickness))
      return false
    end
    
    -- Tool must be chosen and valid
  if not _tool_ok(options.tool) then
    DisplayMessageBox("No tool selected or tool diameter is invalid.\n\nClick 'Select Tool' and pick a valid end mill.")
    return false
  end

  -- At least one face must be selected
  local at_least_one =
    options.make_lid or options.make_bottom or options.make_side1 or
    options.make_side2 or options.make_end1 or options.make_end2
  if not at_least_one then
    DisplayMessageBox("Select at least one face to create (Lid / Bottom / Sides / Ends).")
    return false
  end

  -- Edge margin must be non-negative
  if not _is_nonneg(options.edge_margin) then
    DisplayMessageBox("Edge Margin must be ≥ 0.")
    return false
  end

    local inner_width = options.width - double_thickness
    local inner_depth = options.depth - double_thickness
    local inner_height = options.height - double_thickness
    -- Gremlin added bottomdovetail seperation from side which is just dovetail
    local num_flaps_w = math.floor((0.5*inner_width) / bottomdovetail.min_width)
    local total_tab_space_w = (inner_width - num_flaps_w*bottomdovetail.min_width)
    local num_flaps_d = math.floor((0.5*inner_depth) / bottomdovetail.min_width)
    local total_tab_space_d = (inner_depth - num_flaps_d*bottomdovetail.min_width)
    local num_flaps_h = math.floor((0.5*inner_height) / dovetail.min_width)
    local total_tab_space_h = (inner_height - num_flaps_h*dovetail.min_width)
    if (num_flaps_w < 1) or (total_tab_space_w < 0) then
      DisplayMessageBox(string.format("The bottom joint width %f is too big given box inner width is %f", dovetail.min_width, inner_width))
      return false
    end
    if (num_flaps_d < 1) or (total_tab_space_d < 0) then
      DisplayMessageBox(string.format("The bottom joint width %f is too big given box inner depth is %f", dovetail.min_width, inner_depth))
      return false
    end
    if (num_flaps_h < 1) or (total_tab_space_h < 0) then
      DisplayMessageBox(string.format("The joint width %f is too big given box inner height is %f", dovetail.min_width, inner_height))
      return false
    end
    
    -- Check if tool will fit
    local tab_space_w = total_tab_space_w / (num_flaps_w + 1)
    local tab_space_d = total_tab_space_d / (num_flaps_d + 1)
    local tab_space_h = total_tab_space_h / (num_flaps_h + 1)
    local mtl_block = MaterialBlock()
    local converted_tool_diameter = ConvertUnitsFrom(options.tool.ToolDia, options.tool, mtl_block) ;

    local dia = converted_tool_diameter
    if options.allowance > 0 then
      dia = dia - 2 * options.allowance
    end
      
    if options.cut_dovetails then
      local min_space = dovetail.max_width - dovetail.min_width
      -- Gremlin added bottomdovetail seperation from side which is just dovetail
      local bottom_min_space = bottomdovetail.max_width - bottomdovetail.min_width

      -- make sure dovetails don't overlap
      if (tab_space_w <= bottom_min_space) or (tab_space_d <= bottom_min_space) or (tab_space_h <= min_space) then        
        DisplayMessageBox("The joint width is too small")
        return false
      end      

      min_space = min_space + dia
      if (tab_space_w <= bottom_min_space) or (tab_space_d <= bottom_min_space) or (tab_space_h <= min_space) then        
        DisplayMessageBox("The selected tool will not fit between the joints")
        return false
      end  
    else
      -- Gremlin added bottomdovetail seperation from side which is just dovetail
      tab_space_w = math.min(tab_space_w, bottomdovetail.min_width)
      tab_space_d = math.min(tab_space_d, bottomdovetail.min_width)
      tab_space_h = math.min(tab_space_h, dovetail.min_width)
      if (tab_space_w <= dia) or (tab_space_d <= dia) or (tab_space_h <= dia) then        
        DisplayMessageBox("The selected tool will not fit between the joints")
        return false
      end
    end
    
    return true
  end

  if GetBuildVersion() >= 9.513 then
    dialog:OnValidate(validator)  
    local success = dialog:ShowDialog()

    if not success then
      return false
    end
  else  
    repeat
      local success = dialog:ShowDialog()

      if not success then
        return false
      end
    until validator(dialog)    
  end

  -- Gremlin added bottomdovetail seperation from side which is just dovetail
  ReadOptions(dialog, options, dovetail, bottomdovetail)

	return true

end

function OnLuaButton_TabTypeRadio1()
  return true
end

function OnLuaButton_TabTypeRadio2()
  return true
end

function OnLuaButton_LidTypeRadio2()
  return true
end

function OnLuaButton_LidTypeRadio1()
  return true
end

function OnLuaButton_MakeLid()
  return true
end

function OnLuaButton_MakeBottom()
  return true
end

function OnLuaButton_MakeSide1()
  return true
end

function OnLuaButton_MakeSide2()
  return true
end

function OnLuaButton_MakeEnd1()
  return true
end

function OnLuaButton_MakeEnd2()
  return true
end

function OnLuaButton_WarnDovetail()
  return true
end

-- Gremlin added bottomdovetail seperation from side which is just dovetail
function ReadOptions(dialog, options, dovetail, bottomdovetail)
  -- Read back data from the form
  options.width     = dialog:GetDoubleField("WidthField")
  options.depth     = dialog:GetDoubleField("DepthField")
  options.height    = dialog:GetDoubleField("HeightField")
  options.tabwidth  = dialog:GetDoubleField("TabWidthField")
  dovetail.min_width = options.tabwidth
  -- Gremlin added bottomdovetail seperation from side which is just dovetail
  options.bottomtabwidth = dialog:GetDoubleField("BottomTabWidthField")
  bottomdovetail.min_width = options.bottomtabwidth

  options.allowance   = dialog:GetDoubleField("AllowanceField")
  options.edge_margin = dialog:GetDoubleField("EdgeField")
  if not options.edge_margin or options.edge_margin <= 0 then
    options.edge_margin = 0.75
  end

  options.warn_dovetail = dialog:GetCheckBox("WarnDovetail")
  options.make_lid      = dialog:GetCheckBox("MakeLid")
  options.make_bottom   = dialog:GetCheckBox("MakeBottom")
  options.make_side1    = dialog:GetCheckBox("MakeSide1")
  options.make_side2    = dialog:GetCheckBox("MakeSide2")
  options.make_end1     = dialog:GetCheckBox("MakeEnd1")
  options.make_end2     = dialog:GetCheckBox("MakeEnd2")
  

  -- dovetail.angle = dialog:GetDoubleField("DovetailAngleField")
  dovetail.max_width = dovetail.min_width + (2 * options.thickness / math.tan(dovetail.angle))
  -- Gremlin added bottomdovetail seperation from side which is just dovetail
  bottomdovetail.max_width = bottomdovetail.min_width + (2* options.thickness/ math.tan(bottomdovetail.angle))

  local tab_index = dialog:GetRadioIndex("TabTypeRadio")
  if tab_index == 1 then
    options.cut_dovetails = false   -- Finger joints
  else
    options.cut_dovetails = true    -- Dovetail joints
  end

  local lid_index = dialog:GetRadioIndex("LidTypeRadio")
  if lid_index == 1 then
    options.flat_lid = true
  else
    options.flat_lid = false
  end

  -- Get from tool picker
  options.tool = dialog:GetTool("ToolChooseButton")

  ------------------------------------------------------------------
  -- NEW: clamp Joint Width (TabWidthField) to
  --      max(existing_width, calculated_min_for_tool)
  ------------------------------------------------------------------
  if _tool_ok(options.tool) then
    local mtl_block = MaterialBlock()
    local raw_dia   = ConvertUnitsFrom(options.tool.ToolDia or 0, options.tool, mtl_block)

    -- Apply Allowance the same way as in your validator
    local effective_dia = raw_dia
    if options.allowance and options.allowance > 0 then
      effective_dia = effective_dia - 2 * options.allowance
      if effective_dia < 0 then
        effective_dia = 0
      end
    end

    -- This is the "calculated minimum" joint width for this tool
    local calculated_min = effective_dia

    if calculated_min and calculated_min > 0 then
      local current_width = options.tabwidth or dovetail.min_width
      local new_width     = math.max(current_width, calculated_min)

      if new_width ~= current_width then
        options.tabwidth   = new_width
        dovetail.min_width = new_width

        -- Push it back into the dialog so user sees the update
        if dialog.SetDoubleField ~= nil then
          dialog:SetDoubleField("TabWidthField", new_width)
        end
      end
    end
  end
  ------------------------------------------------------------------

  options.window_width  = dialog.WindowWidth
  options.window_height = dialog.WindowHeight
end

function SaveDefaults(options, dovetail)
  local registry = Registry("BoxCreator_" .. g_version)
  registry:SetDouble("WindowWidth", options.window_width)
  registry:SetDouble("WindowHeight", options.window_height)

  registry:SetDouble("Width", options.width)
  registry:SetDouble("Height", options.height)
  registry:SetDouble("Depth", options.depth)
  registry:SetDouble("JointWidth", options.tabwidth)
  registry:SetDouble("BottomJointWidth", options.bottomtabwidth)     -- Added by Gremlin
  registry:SetDouble("Allowance", options.allowance)                 -- Added by Sharkcutup
  registry:SetDouble("EdgeMargin", options.edge_margin)              -- Added by Sharkcutup
  registry:SetBool("CutDovetails", options.cut_dovetails)
  registry:SetBool("FlatLid", options.flat_lid)
  registry:SetDouble("DoveTailWidth", dovetail.min_width)
  if options.tool ~= nil then
   options.tool.ToolDBId:SaveDefaults("BoxCreator_5.6", "")
  end

  registry:SetBool("WarnDovetail", options.warn_dovetail)

  registry:SetBool("MakeLid", options.make_lid)
  registry:SetBool("MakeBottom", options.make_bottom)
  registry:SetBool("MakeSide1", options.make_side1)
  registry:SetBool("MakeSide2", options.make_side2)
  registry:SetBool("MakeEnd1", options.make_end1)
  registry:SetBool("MakeEnd2", options.make_end2)

end

-- Gremlin added bottomdovetail seperation from side which is just dovetail
function LoadDefaults(options, dovetail, bottomdovetail)
  local registry =  Registry("BoxCreator_" .. g_version)

  options.window_width = registry:GetDouble("WindowWidth", options.window_width)
  options.window_height = registry:GetDouble("WindowHeight", options.window_height)

  options.width = registry:GetDouble("Width", options.width)
  options.height = registry:GetDouble("Height", options.height)
  options.depth = registry:GetDouble("Depth", options.depth)
  options.tabwidth = registry:GetDouble("JointWidth", options.tabwidth)
  options.bottomtabwidth = registry:GetDouble("BottomJointWidth", options.tabwidth)  --Added by Gremlin
  options.allowance = registry:GetDouble("Allowance", options.allowance)     -- Added by Sharkcutup
  options.edge_margin = registry:GetDouble("EdgeMargin", options.edge_margin)      -- Added by Sherkcutup
  dovetail.min_width = options.tabwidth
  bottomdovetail.min_width = options.bottomtabwidth -- Added by Gremlin
  options.cut_dovetails = registry:GetBool("CutDovetails", options.cut_dovetails)
  options.flat_lid = registry:GetBool("FlatLid", options.flat_lid)
  options.default_toolid = ToolDBId("BoxCreator_5.6", "")
  
  options.warn_dovetail = registry:GetBool("WarnDovetail", true) -- default ON

  options.make_lid = registry:GetBool("MakeLid", options.make_lid)
  options.make_bottom = registry:GetBool("MakeBottom", options.make_bottom)
  options.make_side1 = registry:GetBool("MakeSide1", options.make_side1)
  options.make_side2 = registry:GetBool("MakeSide2", options.make_side2)
  options.make_end1 = registry:GetBool("MakeEnd1", options.make_end1)
  options.make_end2 = registry:GetBool("MakeEnd2", options.make_end2)
end