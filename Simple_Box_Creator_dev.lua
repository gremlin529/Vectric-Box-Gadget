-- VECTRIC LUA SCRIPT
-------------------------------------------------------------------------------------------------------------------------------------------
-- Gadgets are an entirely optional software add-in to Vectric's core software products. 
-- They are provided 'as-is', without any express or implied warranty, and you make use of them entirely at your own risk.
-- In no event will Vectric Ltd. be held liable for any damages arising from their use.

-- Modification and re-use of the gadget source may or may not be allowed by the gadget author. Please read carefully any copyright notices -- included in the gadget source.

-- The notice at the head of the gadget source files may not be removed or altered from any source distribution.
-------------------------------------------------------------------------------------------------------------------------------------------
-- 
-- Want to Contribue to this gadget or learn more about it? 
--
--                       
-- █▀▀ █ ▀█▀ █░█ █░█ █▄▄       https://github.com/gremlin529/Vectric-Box-Gadget
-- █▄█ █ ░█░ █▀█ █▄█ █▄█
--
-- this repository contains the latest version of the gadget, and is where you can submit issues or pull requests to contribute to the project.
-- also includes the readme file on how to contribute to the project and how to build the gadget from source.
--
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
-- Renamed the Gadget and stopping the upkeep of these comments as we're in GitHub now and the history is preserved there.    2/27/2026     
-- June 21st, just to give proper credit Gremlin ported Sharkcutup's amazing fluting dovetail code to the project, per github history (see above)
-------------------------------------------------------------------------------------------------------------------------------------------
-- It is provided 'as-is' with changes made, without any express or implied warranty, and you make use of them entirely at your own risk.
-- In no event will "Sharkcutup" be held liable for any damages arising from this gadgets use.
-- In no event will "Gremlin" be held liable for any damages arising from this gadgets use.

-------------------------- Sharkcutup is NOT The Origianl Owner/Writer of this Gadget 11/23/2025  -----------------------------------------
---------------------------- Gremlin is NOT The Origianl Owner/Writer of this Gadget 2/272026  --------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------

-- remove this line before shipping it's to use the ZeroBrane studio debugger per https://www.jimandi.com/SDK/index.php/ZeroBrane_Studio_Setup
-- require("mobdebug").start()
-- want to turn this on but there's several bits of code that 
-- need addressing first
-- require("strict")

g_version = "dev"                                                 
g_subVersion = "development"                                      
g_title = "Simple Box"
g_width = 890
g_height = 962                                               
g_html_file = "Simple_Box_Creator_" .. g_version .. ".html"       
g_finger_side_layer_name = "Finger Roundover"
g_box_layer_name = "Box"
g_labels_layer_name = "Labels"
g_cutout_layer_name = "CutOut"
g_doveTailAngleDegrees = 60

local librayModule

-- MotazA 16/9/2020 check if job Exists 
---
--- Main Function for Gadget 
---
---@param script_path any
function main(script_path)
  libraryModule = assert(loadfile(script_path .. "\\Helpers.xlua"))(libraryModule)
  libraryModule = assert(loadfile(script_path .. "\\Dovetails.xlua"))(libraryModule)
  libraryModule = assert(loadfile(script_path .. "\\SheetArrangement.xlua"))(libraryModule)
  libraryModule = assert(loadfile(script_path .. "\\CreateFaces.xlua"))(libraryModule)
  libraryModule = assert(loadfile(script_path .. "\\DisplayDialog.xlua"))(libraryModule)

  local job = VectricJob()
  local mtl_block = MaterialBlock()

  if not job.Exists then
    DisplayMessageBox("No job loaded.")
    return false
  end

  ----------------------- Gadget Options Default Settings --------------------------------
  local options = {}

  options.width = 18                        --- width  default               
  options.height = 12                       --- height default              
  options.depth = 14                        --- depth default   
  options.InMM = false                      --- These are in mm or inches

  options.start_point = Point2D(0,0)
  options.thickness = mtl_block.Thickness;

  options.useAllJointWidths = false         --- show all joint width options (if false then only show one joint width option and use it for all joints)
  options.sideOrAllTabWidth = 0.3                --- all or side widths depending on the above
  options.bottomTabWidth = 1.0              --- joint width for the bottom (as a separate value)   
  options.lidTabWidth = 1.0                 --- joint width for the top (as a separate value)

  options.allowance = 0.0                   --- allowance default 
  options.partSpacing = 0.0                 --- spacing between parts
  options.clampingMargin = 0.75             --- edge margin default

  options.dovetailJoint = false             --- if false means we're making box joints, true dovetails
  options.lidType = FaceJointType.Inset -- default lid type is inset
  options.bottomType = FaceJointType.Fingers -- default bottom type is tabbed
  options.label_faces   = true        --- default to labelling face vectors
  options.no_toolpath = false
  options.create_dogbones = true
  options.useSingleSheet = false --- if true, pack everything onto one sheet and let non-fitting pieces overhang instead of creating new sheets
  options.roundover_cut_depth = 0.125      --- cut depth for the finger roundover tool (box joints, no dogbones only)

  options.ZoomLevel = "Auto"
  options.dark_mode     = true        --- default to dark mode on


  options.window_width = g_width
  options.window_height = g_height

  options.facesToMake = {}

  options.facesToMake.lid = true                   --- lid checkbox default       
  options.facesToMake.bottom = true                --- bottom checkbox default     
  options.facesToMake.side1 = true                 --- side 1 checkbox default    
  options.facesToMake.side2 = true                 --- side 2 checkbox default     
  options.facesToMake.end1 =  true                 --- end 1 checkbox default      
  options.facesToMake.end2 = true                  --- end 2 checkbox default      
  options.create_tabs_for_missing_faces = true  --- create tabs for missing faces (if false then dont create the tabs on edges for faces not selected)

-----------------------------------------------------------------------------------------------------------------------------------------

  local dovetails = ContourGroup(true)

  local sideDoveTail = {}
  sideDoveTail.angle = math.rad(g_doveTailAngleDegrees)
  sideDoveTail.min_width = 1.5 -- not sure why this is called min_width it's actually the width of the dovetail.
  sideDoveTail.depth = options.thickness

  -- added by Gremlin to allow for separate widths on bottom vs side tabs
  local bottomDoveTail = {}   
  bottomDoveTail.angle = math.rad(g_doveTailAngleDegrees)
  bottomDoveTail.min_width = 1.5
  bottomDoveTail.depth = options.thickness

  local lidDoveTail = {}   
  lidDoveTail.angle = math.rad(g_doveTailAngleDegrees)
  lidDoveTail.min_width = 1.5
  lidDoveTail.depth = options.thickness

  LoadDefaultsFromRegistry(options, sideDoveTail, bottomDoveTail, lidDoveTail)

  -- Check to see if the previous set of dimensions were in Inches and now we're in mm or viceversa
  -- and do the appropriate conversions if needed so we display reasonable values
  if (options.InMM ~= job.InMM) then
    local multiplier = job.InMM and 25.4 or (1/25.4)
    options.width = truncate(options.width * multiplier, 2)
    options.height = truncate(options.height * multiplier, 2)
    options.depth = truncate(options.depth * multiplier, 2)
    options.sideOrAllTabWidth = truncate(options.sideOrAllTabWidth * multiplier, 2)
    options.bottomTabWidth = truncate(options.bottomTabWidth * multiplier, 2)
    options.lidTabWidth = truncate(options.lidTabWidth * multiplier, 2)
    options.allowance = truncate(options.allowance * multiplier, 2)
    options.clampingMargin = truncate(options.clampingMargin * multiplier, 2)
    options.partSpacing = truncate(options.partSpacing * multiplier, 2)
    options.roundover_cut_depth = truncate(options.roundover_cut_depth * multiplier, 2)
    options.InMM = job.InMM
  end

  local tool = Tool("0.25 Inch End Mill", Tool.END_MILL)
  tool.ToolDia = 0.25
  tool.InMM = false

  options.tool = tool

  local roundover_tool = Tool("0.125 Inch Round Over", Tool.FORM_TOOL)
  roundover_tool.ToolDia = 0.125
  roundover_tool.InMM = false

  options.roundover_tool = roundover_tool

  -- Gremlin added bottomDoveTail seperation from side which is just sideDoveTail
  local dialog_displayed = DisplayDialog(script_path, options, sideDoveTail, bottomDoveTail, lidDoveTail)
  if (not dialog_displayed) then 
    return false
  end

  -- Gremlin added extra dovetail parameters for bottom and top which are the same as the side dovetail except for 
  -- the depth which is just the thickness of the material since we are only cutting one face for those
  sideDoveTail.depth = options.thickness
  sideDoveTail.start_z = mtl_block:CalcAbsoluteZFromDepth(0)
  sideDoveTail.start_depth = 0
  sideDoveTail.cut_z = mtl_block:CalcAbsoluteZFromDepth(options.thickness)

  bottomDoveTail.depth = options.thickness
  bottomDoveTail.start_z = mtl_block:CalcAbsoluteZFromDepth(0)
  bottomDoveTail.start_depth = 0
  bottomDoveTail.cut_z = mtl_block:CalcAbsoluteZFromDepth(options.thickness)

  lidDoveTail.depth = options.thickness
  lidDoveTail.start_z = mtl_block:CalcAbsoluteZFromDepth(0)
  lidDoveTail.start_depth = 0
  lidDoveTail.cut_z = mtl_block:CalcAbsoluteZFromDepth(options.thickness) 

  -- based on options we need a local version of some of the options
  -- if there's no lid or bottom made, we should make the face no
  -- matter what the boxes says, nor should we machine the edges for it so count that
  -- as flat

  -- need to shallow copy these as we're overwriting them
  local computedFacesToMake = {}
  computedFacesToMake.lid = options.facesToMake.lid
  computedFacesToMake.bottom = options.facesToMake.bottom
  computedFacesToMake.side1 = options.facesToMake.side1
  computedFacesToMake.side2 = options.facesToMake.side2
  computedFacesToMake.end1 = options.facesToMake.end1
  computedFacesToMake.end2 = options.facesToMake.end2

  if options.lidType == FaceJointType.None then
    -- if we aren't making a lid then we shouldn't make tabs for the lid since there won't be a lid to fit them
    computedFacesToMake.lid = false
  end

  if options.bottomType == FaceJointType.None then
    -- if we aren't making a bottom then we shouldn't make tabs for the bottom since there won't be a bottom to fit them
    computedFacesToMake.bottom = false
  end

  local faces = CreateBoxFaces(options, sideDoveTail, bottomDoveTail, lidDoveTail, computedFacesToMake)

  -- Arrange the contours across as many sheets as required.
  -- All existing geometry and machining rules below remain unchanged;
  -- they are simply applied to one sheet's faces at a time.
  local converted_tool_diameter = 0.25
  if _tool_ok(options.tool) then
    converted_tool_diameter = ConvertUnitsFrom(options.tool.ToolDia, options.tool, mtl_block)
  end

  local required_sheets
  faces, required_sheets = LayoutFacesOnSheets(job, options, faces, converted_tool_diameter)
  if not required_sheets then
    return false
  end

  CreateBoxToolpaths(job, options, faces, required_sheets, computedFacesToMake, converted_tool_diameter)

  SetSheet(job, "Sheet 1")

  SaveDefaultsToRegistry(options, false)
  job:Refresh2DView()
  return true

end -- main

--[[  -------------- CreateBoxFaces --------------------------------------------------
|
|  Build the box faces (bottom, sides, ends, lid) selected by the dialog options.
|  Returns the list of faces, still positioned at their own local origins -
|  layout onto sheets happens separately in LayoutFacesOnSheets.
|
]]
function CreateBoxFaces(options, sideDoveTail, bottomDoveTail, lidDoveTail, computedFacesToMake)
  -- Make the bottom face
  local cad_list = CadObjectList(true)
-- local dovetail_markers = {}
  local faces = {}

  if computedFacesToMake.bottom then
    -- Gremlin added bottomDoveTail seperation from side which is just sideDoveTail
    -- the bottom face is only the bottom so we didn't need to add
    -- a separate value to it, just pass it the bottom value
    local bottom_face = MakeBottomFaceContour(options.width,
      options.depth,
      options.thickness,
      options.start_point,
      bottomDoveTail,
      options.dovetailJoint,  -- if true then create dovetails
      options.bottomType,
      computedFacesToMake,
      options.create_tabs_for_missing_faces,
      "BottomFace" )
    faces[#faces + 1] = bottom_face
  end

  -- -- -- Make sides
  if computedFacesToMake.side1 then
    -- Gremlin added bottomDoveTail seperation from side which is just sideDoveTail
    local sideface1 = MakeSideFace(options.width,
      options.height,
      options.thickness,
      options.start_point,
      sideDoveTail,
      bottomDoveTail,
      lidDoveTail,
      options.dovetailJoint,
      options.lidType,
      options.bottomType,
      computedFacesToMake,
      options.create_tabs_for_missing_faces,
      true,  -- is_side1
      "SideFace1")
    faces[#faces + 1] = sideface1
  end

  if computedFacesToMake.side2 then
    -- Gremlin added bottomDoveTail seperation from side which is just sideDoveTail
    local sideface2 = MakeSideFace(options.width,
      options.height,
      options.thickness,
      options.start_point,
      sideDoveTail,
      bottomDoveTail,
      lidDoveTail,
      options.dovetailJoint,
      options.lidType,
      options.bottomType,
      computedFacesToMake,
      options.create_tabs_for_missing_faces,
      false,  -- is_side1 (so this is side2)
      "SideFace2")
    faces[#faces + 1] = sideface2
  end

  -- -- -- Make ends
  if computedFacesToMake.end1 then
    -- Gremlin added bottomDoveTail seperation from side which is just sideDoveTail
    local endface1 = MakeEndFace(options.depth,
      options.height,
      options.thickness,
      options.start_point,
      sideDoveTail,
      bottomDoveTail,
      lidDoveTail,
      options.dovetailJoint,
      options.lidType,
      options.bottomType,
      computedFacesToMake,
      options.create_tabs_for_missing_faces,
      true,  -- is_end1
      "EndFace1")
    faces[#faces + 1] = endface1
  end

  if computedFacesToMake.end2 then
    -- Gremlin added bottomDoveTail seperation from side which is just sideDoveTail
    local endface2 = MakeEndFace(options.depth,
      options.height,
      options.thickness,
      options.start_point,
      sideDoveTail,
      bottomDoveTail,
      lidDoveTail,
      options.dovetailJoint,
      options.lidType,
      options.bottomType,
      computedFacesToMake,
      options.create_tabs_for_missing_faces,
      false,  -- is_end1 (so this is end2)
      "EndFace2")
    faces[#faces + 1] = endface2
  end

  -- Make lid
  if (computedFacesToMake.lid and options.lidType ~= FaceJointType.None) then
    local lid = MakeLid(options.width,
      options.depth,
      options.thickness,
      lidDoveTail,
      options.start_point,
      options.lidType,
      computedFacesToMake,
      options.create_tabs_for_missing_faces,
      options.dovetailJoint,
      "Lid"
    )
    faces[#faces + 1] = lid
  end

  return faces
end -- CreateBoxFaces

--[[  -------------- LayoutFacesOnSheets --------------------------------------------------
|
|  Arrange the given faces across as many material sheets as required (or onto a
|  single sheet if options.useSingleSheet is set), then make sure each sheet the
|  layout used actually exists in the job's Sheet Manager.
|
|  Returns the (now positioned) faces and the number of sheets used, or nil, nil
|  if a required sheet could not be created.
|
]]
function LayoutFacesOnSheets(job, options, faces, converted_tool_diameter)
  local part_gap = math.max(2 * converted_tool_diameter, options.partSpacing)
  local clampingMargin = math.max(options.clampingMargin or 0.0, 0.75)
  local required_sheets = 1
  if options.useSingleSheet then
    -- Best effort: pack everything onto Sheet 1. Pieces that don't fit are
    -- still laid out (overhanging the material) rather than opening a new sheet.
    faces = ArrangeContours(faces, part_gap, job.XLength, job.YLength, clampingMargin)
    for i = 1, #faces do
      faces[i].sheet_number = 1
    end
  else
    faces, required_sheets = ArrangeContoursToSheets(faces, part_gap, job.XLength, job.YLength, clampingMargin)
  end

  for sheet_num = 1, required_sheets do
    if not SheetEnsureExists(job, sheet_num) then
      return nil
    end
  end

  return faces, required_sheets
end

--[[  -------------- CreateBoxToolpaths --------------------------------------------------
|
|  Walk each sheet in turn, adding the profile/cutout geometry, part labels, and
|  finger-side/fluting vectors for that sheet's faces, then (unless the user asked
|  to skip toolpaths) create the pocket, fluting and cutout toolpaths for it.
|
]]
function CreateBoxToolpaths(job, options, faces, required_sheets, computedFacesToMake, converted_tool_diameter)
  local offset_radius = 0.5 * converted_tool_diameter - options.allowance

  for sheet_num = 1, required_sheets do
    local sheet_name = "Sheet " .. tostring(sheet_num)
    if not SetSheet(job, sheet_name) then
      return false
    end

    -- I really wanted this to be a bit field but this version
    -- of lua doesn't support bitwise operations so I'm using a table of booleans instead
    -- this is so we can decide which tool paths to create
    local jointsOnSheet = {false, false, false, false}

    local sheet_faces = {}
    for i = 1, #faces do
      if (faces[i].sheet_number or 1) == sheet_num then
        sheet_faces[#sheet_faces + 1] = faces[i]
        jointsOnSheet[faces[i].jointtype] = true
      end
    end

    if #sheet_faces > 0 then
      -- Original 12.3 Beta3 geometry logic, now scoped to this sheet's faces.
      local vdcontours = GetAllProfileContours(sheet_faces)
      local cdcontours = GetAllProfileCadContours(sheet_faces)
      local fingerSideContours = GetAllFingerSides(sheet_faces)

      local cutout_cadcontours
      if options.create_dogbones or options.dovetailJoint then
        local dogboned_contours = CreateDogboneProfile(vdcontours, offset_radius)
        cutout_cadcontours = CreateTabbedCadContours(dogboned_contours, cdcontours)
      else
        local offset_contours = vdcontours:Offset(offset_radius, offset_radius, 1, true)
        cutout_cadcontours = CreateTabbedCadContours(offset_contours, cdcontours)
      end

      AddCadListToJob(job, cdcontours, g_box_layer_name)
      local cutout_objects = AddCadListToJob(job, cutout_cadcontours, g_cutout_layer_name)

      if not options.create_dogbones and not options.dovetailJoint then
        local finger_side_objects = {}
        for i = 1, #fingerSideContours do
          finger_side_objects[#finger_side_objects + 1] =
            AddGroupToJob(job, fingerSideContours[i], g_finger_side_layer_name)
        end

        if not options.no_toolpath and jointsOnSheet[FaceJointType.Fingers] then
          CreateFingerSideToolpath(
            g_finger_side_layer_name,
            options.roundover_tool,
            job,
            options.roundover_cut_depth,
            finger_side_objects)
        end
      end

      if options.label_faces then
        AddPartsLabelsToJob(job, sheet_faces, g_labels_layer_name, options.thickness)
      end

      local fluting_objects = nil
      if options.dovetailJoint then
        fluting_objects = AddFlutingVectorsForFaces(
          job, sheet_faces, FLUTE_LAYER_NAME, options.tool)
      end

      if (not options.no_toolpath) then
        if jointsOnSheet[FaceJointType.Inset] then
          assert(((computedFacesToMake.lid and options.lidType == FaceJointType.Inset) or
          (computedFacesToMake.bottom and options.bottomType == FaceJointType.Inset)),
           "Expected that if there are inset joints on this sheet, then at least one of the lid or bottom faces should be present and have an inset joint type.")
          CreateInsetPocketToolpath(job, options, sheet_faces, options.tool, "Pockets")
        end

        if options.dovetailJoint then
          if SelectExactObjects(job, fluting_objects) then
            CreateFlutingToolpath(
              "Fluting Dovetails", 0.0, options.thickness, options.tool)
          end
        end

        CreateCutoutToolpath(
          options.tool,
          job,
          options.thickness,
          options.sideOrAllTabWidth,
          g_cutout_layer_name,
          cutout_objects)
      end -- not options.no_toolpath

    end -- if #sheet_faces > 0 then
  end -- for sheet_num = 1, required_sheets do

  return true
end

-- function OnToolPicker_ToolChooseButton(dialog) 
--   local tool = dialog:GetTool("ToolChooseButton")
--   if tool == nil then
-- 		MessageBox("No tool selected!")
-- 		return true
--   end
  
--   MessageBox("User picked tool ...\n" .. tool_name .. " Diameter = " .. tool.ToolDia)
  
--   return true
-- end


--- By putting this function in the script we don't need to create
--- individual functions unless we need specific handling
function OnLuaButton_XXXX()
  return true
end
