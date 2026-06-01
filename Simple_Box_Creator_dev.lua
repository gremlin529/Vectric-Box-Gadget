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

-- remove this line before shipping it's to use the ZeroBrane studio debugger per https://www.jimandi.com/SDK/index.php/ZeroBrane_Studio_Setup
-- require("mobdebug").start()
-- want to turn this on but there's several bits of code that 
-- need addressing first
-- require("strict")

g_version = "dev"                                                    -- Changed by Gremlin
g_subVersion = "development"                                         -- Added by Gremlin
g_title = "Simple Box"
g_width = 845
g_height = 1023                                                    -- Changed by Sharkcutup
g_html_file = "Simple_Box_Creator_" .. g_version .. ".html"             -- Changed by Gremlin
local librayModule

-- MotazA 16/9/2020 check if job Exists 
function main(script_path)
  libraryModule =assert(loadfile(script_path .. "\\CreateFaces.xlua"))(libraryModule)

  local job = VectricJob()
  local mtl_block = MaterialBlock()

  if not job.Exists then
    DisplayMessageBox("No job loaded.")
    return false
  end

  ----------------------- Geometry Options Default Settings --------------------------------
  ------------- Added this blocked off and the line descriptions by Sharkcutup -------------

  local options = {}
  options.width = 18                        --- width  default               
  options.height = 12                       --- height default              
  options.depth = 14                        --- depth default                      
  options.start_point = Point2D(0,0)
  options.thickness = mtl_block.Thickness;
  options.sidetabwidth = 0.3                    --- joint width default      
  options.tabwidthbottom = 1.0              --- joint width for the bottom (as a separate value)   
  options.tabwidthTop = 1.0                 --- joint width for the top (as a separate value)
  options.allJointWidths = false         --- show all joint width options (if false then only show one joint width option and use it for all joints)
  options.cut_layer_name  = "CutOut"        --- layer name default
  options.allowance = 0.0                   --- allowance default 
  options.edge_margin = 0.75                 --- edge margin default
  options.warn_dovetail = true   -- show dovetail warning after create
  options.dark_mode     = true        --- default to dark mode on
  options.cut_dovetails = false
  options.flat_lid = true
  options.flat_bottom = true          --- default to flat bottom
  options.label_faces   = true        --- default to labelling face vectors
  options.no_toolpath = false
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

  local sidedovetail = {}
  sidedovetail.angle = math.rad(60)
  sidedovetail.min_width = 1.5
  sidedovetail.depth = options.thickness

  -- added by Gremlin to allow for separate widths on bottom vs side tabs
  local bottomdovetail = {}   
  bottomdovetail.angle = math.rad(60)
  bottomdovetail.min_width = 1.5
  bottomdovetail.depth = options.thickness

  local topdovetail = {}   
  topdovetail.angle = math.rad(60)
  topdovetail.min_width = 1.5
  topdovetail.depth = options.thickness

  LoadDefaults(options, sidedovetail, bottomdovetail, topdovetail)

  local tool = Tool("0.25 Inch End Mill", Tool.END_MILL)
  tool.ToolDia = 0.25
  tool.InMM = false

  options.tool = tool

  -- Gremlin added bottomdovetail seperation from side which is just sidedovetail
  local dialog_displayed = DisplayDialog(script_path, options, sidedovetail, bottomdovetail, topdovetail)
  if (not dialog_displayed) then 
    return false
  end

  -- Gremlin added extra dovetail parameters for bottom and top which are the same as the side dovetail except for 
  -- the depth which is just the thickness of the material since we are only cutting one face for those
  sidedovetail.depth = options.thickness
  sidedovetail.start_z = mtl_block:CalcAbsoluteZFromDepth(0)
  sidedovetail.start_depth = 0
  sidedovetail.cut_z = mtl_block:CalcAbsoluteZFromDepth(options.thickness)

  bottomdovetail.depth = options.thickness
  bottomdovetail.start_z = mtl_block:CalcAbsoluteZFromDepth(0)
  bottomdovetail.start_depth = 0
  bottomdovetail.cut_z = mtl_block:CalcAbsoluteZFromDepth(options.thickness)

  topdovetail.depth = options.thickness
  topdovetail.start_z = mtl_block:CalcAbsoluteZFromDepth(0)
  topdovetail.start_depth = 0
  topdovetail.cut_z = mtl_block:CalcAbsoluteZFromDepth(options.thickness) 

-- Make the bottom face
  local cad_list = CadObjectList(true)
-- local dovetail_markers = {}
  local faces = {}

  if options.facesToMake.bottom then
    -- Gremlin added bottomdovetail seperation from side which is just sidedovetail
    -- the bottom face is only the bottom so we didn't need to add
    -- a separate value to it, just pass it the bottom value
    local bottom_face = MakeBottomFaceContour(options.width, 
      options.depth, 
      options.thickness, 
      options.start_point, 
      bottomdovetail, 
      options.cut_dovetails,  -- if true then create dovetails
      options.facesToMake,
      options.create_tabs_for_missing_faces,
      "BottomFace" )
    faces[#faces + 1] = bottom_face
  end

  -- -- -- Make sides
  if options.facesToMake.side1 then
    -- Gremlin added bottomdovetail seperation from side which is just sidedovetail
    local sideface1 = MakeSideFace(options.width,
      options.height, 
      options.thickness, 
      options.start_point, 
      sidedovetail, 
      bottomdovetail,
      topdovetail,
      options.cut_dovetails, 
      options.flat_lid,
      options.facesToMake,
      options.create_tabs_for_missing_faces,
      true,  -- is_side1
      "SideFace1")
    faces[#faces + 1] = sideface1
  end

  if options.facesToMake.side2 then
    -- Gremlin added bottomdovetail seperation from side which is just sidedovetail
    local sideface2 = MakeSideFace(options.width,
      options.height, 
      options.thickness, 
      options.start_point, 
      sidedovetail, 
      bottomdovetail,
      topdovetail,
      options.cut_dovetails, 
      options.flat_lid,
      options.facesToMake,
      options.create_tabs_for_missing_faces,
      false,  -- is_side1 (so this is side2)
      "SideFace2")
    faces[#faces + 1] = sideface2
  end

  -- -- -- Make ends
  if options.facesToMake.end1 then
    -- Gremlin added bottomdovetail seperation from side which is just sidedovetail
    local endface1 = MakeEndFace(options.depth, 
      options.height, 
      options.thickness,
      options.start_point, 
      sidedovetail,
      bottomdovetail,
      topdovetail,
      options.cut_dovetails, 
      options.flat_lid,
      options.facesToMake,
      options.create_tabs_for_missing_faces,
      true,  -- is_end1
      "EndFace1")
    faces[#faces + 1] = endface1
  end

  if options.facesToMake.end2 then
    -- Gremlin added bottomdovetail seperation from side which is just sidedovetail
    local endface2 = MakeEndFace(options.depth, 
      options.height, 
      options.thickness,
      options.start_point, 
      sidedovetail,
      bottomdovetail,
      topdovetail,
      options.cut_dovetails, 
      options.flat_lid,
      options.facesToMake,
      options.create_tabs_for_missing_faces,
      false,  -- is_end1 (so this is end2)
      "EndFace2")
    faces[#faces + 1] = endface2
  end

  -- Make lid
  if options.facesToMake.lid then
    local lid = MakeLid(options.width,
      options.depth,
      options.thickness,
      topdovetail.min_width,
      options.start_point,
      options.flat_lid,
      options.facesToMake,
      options.create_tabs_for_missing_faces,
      "Lid"
    )
    faces[#faces + 1] = lid
  end

  -- Arrange the contours
  local mtl_block = MaterialBlock()
  local converted_tool_diameter = 0.25
  if _tool_ok(options.tool) then
    converted_tool_diameter = ConvertUnitsFrom(options.tool.ToolDia, options.tool, mtl_block)
  end
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
  if options.label_faces then
    AddPartsLabelsToJob(job, faces, "Box", options.thickness)
  end

  if (not options.no_toolpath) and options.facesToMake.lid and options.flat_lid then
    CreateLidPocketToolpath(job, options, faces, options.tool, "Pockets")
  end

  if not options.no_toolpath then
    -- if we are doing dovetails make toolpath for them
    local dovetail_markers = GetAllMarkers(faces)
    if options.cut_dovetails and (#dovetail_markers > 0) then
      CreateDoveTailToolpath(dovetail_markers, sidedovetail, options.tool, options.allowance, options.warn_dovetail)
    end

    CreateCutoutToolpath(dogboned_cadcontours, options.tool, job, options.thickness, options.sidetabwidth, options.cut_layer_name)
  end

  SaveDefaults(options, false)
  job:Refresh2DView()
  return true

end

-- Gremlin added bottomdovetail seperation from side which is just sidedovetail 
function DisplayDialog(script_path, options, sidedovetail, bottomdovetail, topdovetail)
  local html_path = "file:" .. script_path .. "\\" .. g_html_file
  local dialog = HTML_Dialog(false, html_path, options.window_width, options.window_height, string.format("%s - Version %s %s", g_title, g_version, g_subVersion))


  dialog:AddLabelField("GadgetTitle", g_title)
  dialog:AddLabelField("GadgetVersion", g_version)

  -- Add Geometry fields
  dialog:AddDoubleField("WidthField", options.width)
  dialog:AddDoubleField("DepthField", options.depth)
  dialog:AddDoubleField("HeightField", options.height)
  dialog:AddDoubleField("SideTabWidthField", sidedovetail.min_width)
  -- Gremlin added bottomdovetail seperation from side
  dialog:AddDoubleField("BottomTabWidthField", bottomdovetail.min_width)
  dialog:AddDoubleField("TopTabWidthField", topdovetail.min_width)
  dialog:AddCheckBox("AllJointWidths", options.allJointWidths)
  dialog:AddDoubleField("AllowanceField", options.allowance)
  dialog:AddDoubleField("EdgeField", options.edge_margin)

  dialog:AddCheckBox("WarnDovetail", options.warn_dovetail)
  dialog:AddCheckBox("DarkMode", options.dark_mode)
  dialog:AddCheckBox("LabelFaces", options.label_faces)

  -- dialog:AddDoubleField("DovetailAngleField", sidedovetail.angle)

  dialog:AddCheckBox("MakeLid", options.facesToMake.lid)
  dialog:AddCheckBox("MakeBottom", options.facesToMake.bottom)
  dialog:AddCheckBox("MakeSide1", options.facesToMake.side1)
  dialog:AddCheckBox("MakeSide2", options.facesToMake.side2)
  dialog:AddCheckBox("MakeEnd1", options.facesToMake.end1)
  dialog:AddCheckBox("MakeEnd2", options.facesToMake.end2)
  dialog:AddCheckBox("CreateTabsForMissingFaces", options.create_tabs_for_missing_faces)

  -- Add Tool picker
  -- Add toolpath name field
  dialog:AddLabelField("ToolNameField", "")
  dialog:AddToolPicker("ToolChooseButton", "ToolNameField", options.default_toolid)
  dialog:AddToolPickerValidToolType("ToolChooseButton", Tool.END_MILL)
  dialog:AddCheckBox("NoToolpath", options.no_toolpath)

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

-- Bottom Type: 1 = Flat Bottom, 2 = Tabbed Bottom
  local bottom_default_index
  if options.flat_bottom then
    bottom_default_index = 1
  else
    bottom_default_index = 2
  end
  dialog:AddRadioGroup("BottomTypeRadio", bottom_default_index)
  local units_string = "Inches"
  if options.tool.InMM then
    units_string = "MM"
  end

  dialog:AddTextField("UnitsLabel", units_string)

  local validator = function(dialog)
    -- Gremlin added bottomdovetail seperation from side which is just sidedovetail
    ReadOptions(dialog, options, sidedovetail, bottomdovetail, topdovetail)
    local double_thickness = options.thickness * 2
    if options.width <= double_thickness then
      DisplayMessageBox(string.format("The box width %.3f is too small for material thickness %.3f.", options.width, options.thickness))
      return false
    end
    if options.depth <= double_thickness then
      DisplayMessageBox(string.format("The box depth %.3f is too small for material thickness %.3f.", options.depth, options.thickness))
      return false
    end
    if options.height <= double_thickness then
      DisplayMessageBox(string.format("The box height %.3f is too small for material thickness %.3f.", options.height, options.thickness))
      return false
    end

    -- Tool must be chosen and valid (only when creating toolpaths)
    if not options.no_toolpath then
      if not _tool_ok(options.tool) then
        DisplayMessageBox("No tool selected or tool diameter is invalid.\n\nClick 'Select Tool' and pick a valid End Mill.")
        return false
      end
    end

    -- At least one face must be selected
    local at_least_one =
    options.facesToMake.lid or options.facesToMake.bottom or options.facesToMake.side1 or
    options.facesToMake.side2 or options.facesToMake.end1 or options.facesToMake.end2
    if not at_least_one then
      DisplayMessageBox("Select at least one face to create (Lid / Bottom / Sides / Ends).")
      return false
    end

    -- Edge margin must be non-negative
    if not _is_nonneg(options.edge_margin) then
      DisplayMessageBox("Edge margin must be ≥ 0.")
      return false
    end

    local inner_width = options.width - double_thickness
    local inner_depth = options.depth - double_thickness
    local inner_height = options.height - double_thickness

    -- Gremlin added join size seperations overall
    local num_flaps_w_bottom = math.floor((0.5*inner_width) / bottomdovetail.min_width)
    local total_tab_space_w_bottom = (inner_width - num_flaps_w_bottom*bottomdovetail.min_width)
    local num_flaps_d_bottom = math.floor((0.5*inner_depth) / bottomdovetail.min_width)
    local total_tab_space_d_bottom = (inner_depth - num_flaps_d_bottom*bottomdovetail.min_width)

    if (num_flaps_w_bottom < 1) or (total_tab_space_w_bottom < 0) then
      if (not options.allJointWidths) then
        DisplayMessageBox(string.format("The joint width %.3f is too big given boxes bottom given the inner width is %.3f.", bottomdovetail.min_width, inner_width))
      else
        DisplayMessageBox(string.format("The bottom joint width %.3f is too big given box inner width is %.3f.", bottomdovetail.min_width, inner_width))
      end
      return false
    end

    if (num_flaps_d_bottom < 1) or (total_tab_space_d_bottom < 0) then
      if (not options.allJointWidths) then
        DisplayMessageBox(string.format("The joint width %.3f is too big given boxes bottom given the inner depth is %.3f.", bottomdovetail.min_width, inner_depth))
      else
        DisplayMessageBox(string.format("The bottom joint width %.3f is too big given box inner depth is %.3f.", bottomdovetail.min_width, inner_depth))
      end
      return false
    end

    local num_flaps_w_top = math.floor((0.5*inner_width) / topdovetail.min_width)
    local total_tab_space_w_top = (inner_width - num_flaps_w_top*topdovetail.min_width)
    local num_flaps_d_top = math.floor((0.5*inner_depth) / topdovetail.min_width)
    local total_tab_space_d_top = (inner_depth - num_flaps_d_top*topdovetail.min_width)

    -- don't check top joint widths if we are doing a flat lid since those joints won't exist in that case  
    if not options.flat_lid then    
      if (num_flaps_w_top < 1) or (total_tab_space_w_top < 0) then
        DisplayMessageBox(string.format("The lid joint width %.3f is too big given box inner width is %.3f.", topdovetail.min_width, inner_width))
        return false
      end
      if (num_flaps_d_top < 1) or (total_tab_space_d_top < 0) then
        DisplayMessageBox(string.format("The lid joint width %.3f is too big given box inner depth is %.3f.", topdovetail.min_width, inner_depth)) 
        return false
      end
    end

    local num_flaps_h = math.floor((0.5*inner_height) / sidedovetail.min_width)
    local total_tab_space_h = (inner_height - num_flaps_h*sidedovetail.min_width)

    if (num_flaps_h < 1) or (total_tab_space_h < 0) then
      DisplayMessageBox(string.format("The side joint width %.3f is too big given box inner height is %.3f.", sidedovetail.min_width, inner_height))
      return false
    end

    -- Check if tool will fit
    local mtl_block = MaterialBlock()
    local converted_tool_diameter = 0.25
    if _tool_ok(options.tool) then
      converted_tool_diameter = ConvertUnitsFrom(options.tool.ToolDia, options.tool, mtl_block)
    end

    local dia = converted_tool_diameter
    if options.allowance > 0 then
      dia = dia - 2 * options.allowance
    end

    local tab_space_w_bottom = total_tab_space_w_bottom / (num_flaps_w_bottom + 1)
    local tab_space_d_bottom = total_tab_space_d_bottom / (num_flaps_d_bottom + 1)
    local tab_space_w_top = total_tab_space_w_top / (num_flaps_w_top + 1)
    local tab_space_d_top = total_tab_space_d_top / (num_flaps_d_top + 1)
    local tab_space_h = total_tab_space_h / (num_flaps_h + 1)


    if options.cut_dovetails then
      local min_space = sidedovetail.max_width - sidedovetail.min_width
      -- Gremlin added bottomdovetail seperation from side which
      local bottom_min_space = bottomdovetail.max_width - bottomdovetail.min_width
      local top_min_space = topdovetail.max_width - topdovetail.min_width

      -- make sure dovetails don't overlap
      if (tab_space_w_bottom <= bottom_min_space) or (tab_space_d_bottom <= bottom_min_space) then
        DisplayMessageBox("The joint width is too small for the bottom.")
        return false
      end      

      if (tab_space_h <= min_space) then        
        DisplayMessageBox("The joint width is too small for the side.")
        return false
      end

      if (not options.flat_lid) then
        if (tab_space_w_top <= top_min_space) or (tab_space_d_top <= top_min_space) then
          DisplayMessageBox("The joint width is too small for the lid.")
          return false
        end
      end

      min_space = min_space + dia
      if (tab_space_w_bottom <= bottom_min_space) or 
      (tab_space_d_bottom <= bottom_min_space) or 
      (tab_space_h <= min_space) or 
      ((not options.flat_lid) and 
        ((tab_space_w_top <= top_min_space) or (tab_space_d_top <= top_min_space))) then        
        DisplayMessageBox("The selected tool will not fit between the joints.")
        return false
      end  
    else
      -- Gremlin added bottomdovetail seperation from side
      tab_space_w_bottom = math.min(tab_space_w_bottom, bottomdovetail.min_width)
      tab_space_d_bottom = math.min(tab_space_d_bottom, bottomdovetail.min_width)
      tab_space_w_top = math.min(tab_space_w_top, topdovetail.min_width)
      tab_space_d_top = math.min(tab_space_d_top, topdovetail.min_width)
      tab_space_h = math.min(tab_space_h, sidedovetail.min_width)
      if (tab_space_w_bottom <= dia) or (tab_space_d_bottom <= dia) then        
        DisplayMessageBox("The selected tool will not fit between the bottom joints.")
        return false
      end
      if (tab_space_h <= dia) then        
        DisplayMessageBox("The selected tool will not fit between the side joints.")
        return false
      end 
      if (options.allJointWidths and not options.flat_lid and (options.facesToMake.lid or options.create_tabs_for_missing_faces)) then
        if (tab_space_w_top <= dia) or (tab_space_d_top <= dia) then        
          DisplayMessageBox("The selected tool will not fit between the lid joints.")
          return false
        end
      end
    end

    return true
  end

  if GetBuildVersion() >= 9.513 then
    dialog:OnValidate(validator)  
    local success = dialog:ShowDialog()

    if not success then
      ReadOptions(dialog, options, sidedovetail, bottomdovetail, topdovetail)
      SaveDefaults(options, true) -- the user hit cancel but save the window settings anyways
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

  -- Gremlin added joint width seperation
  -- this is actually getting called twice, once here and once in the
  -- validator logic, is that correct?
  ReadOptions(dialog, options, sidedovetail, bottomdovetail, topdovetail)

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

function OnLuaButton_BottomTypeRadio1()
  return true
end

function OnLuaButton_BottomTypeRadio2()
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

function OnLuaButton_CreateTabsForMissingFaces()
  return true
end

function OnLuaButton_WarnDovetail()
  return true
end

function OnLuaButton_AllJointWidths()  
  return true
end


function OnLuaButton_DarkMode()
  return true
end

function OnLuaButton_LabelFaces()
  return true
end

-- HTML checkbox id="NoToolpath" is marked class="LuaButton".
-- Vectric's HTML dialog system expects a handler named OnLuaButton_<id>.
-- If it's missing, VCarve/Aspire shows: "No Button Handler found in the script".
function OnLuaButton_NoToolpath()
  return true
end

-- Gremlin added joint width seperation for sides top and bottom
function ReadOptions(dialog, options, sidedovetail, bottomdovetail, topdovetail)
  -- Read back data from the form
  options.width     = dialog:GetDoubleField("WidthField")
  options.depth     = dialog:GetDoubleField("DepthField")
  options.height    = dialog:GetDoubleField("HeightField")
  options.sidetabwidth  = dialog:GetDoubleField("SideTabWidthField")
  sidedovetail.min_width = options.sidetabwidth
  -- Gremlin added joint width seperation for sides top and bottom
  options.allJointWidths = dialog:GetCheckBox("AllJointWidths")
  options.bottomtabwidth = dialog:GetDoubleField("BottomTabWidthField")
  options.toptabwidth = dialog:GetDoubleField("TopTabWidthField")
  if not options.allJointWidths then
    bottomdovetail.min_width = sidedovetail.min_width
    topdovetail.min_width = sidedovetail.min_width
  else
    bottomdovetail.min_width = options.bottomtabwidth
    topdovetail.min_width = options.toptabwidth
  end 

  options.allowance   = dialog:GetDoubleField("AllowanceField")
  options.edge_margin = dialog:GetDoubleField("EdgeField")
  if not options.edge_margin or options.edge_margin <= 0 then
    options.edge_margin = 0.75
  end

  options.warn_dovetail = dialog:GetCheckBox("WarnDovetail")
  options.dark_mode     = dialog:GetCheckBox("DarkMode")
  options.label_faces   = dialog:GetCheckBox("LabelFaces")
  options.no_toolpath  = dialog:GetCheckBox("NoToolpath")
  options.facesToMake.lid      = dialog:GetCheckBox("MakeLid")
  options.facesToMake.bottom   = dialog:GetCheckBox("MakeBottom")
  options.facesToMake.side1    = dialog:GetCheckBox("MakeSide1")
  options.facesToMake.side2    = dialog:GetCheckBox("MakeSide2")
  options.facesToMake.end1     = dialog:GetCheckBox("MakeEnd1")
  options.facesToMake.end2     = dialog:GetCheckBox("MakeEnd2")
  options.create_tabs_for_missing_faces = dialog:GetCheckBox("CreateTabsForMissingFaces")


  -- sidedovetail.angle = dialog:GetDoubleField("DovetailAngleField")
  sidedovetail.max_width = sidedovetail.min_width + (2 * options.thickness / math.tan(sidedovetail.angle))
  -- Gremlin added bottomdovetail seperation from side which is just sidedovetail
  bottomdovetail.max_width = bottomdovetail.min_width + (2* options.thickness/ math.tan(bottomdovetail.angle))
  topdovetail.max_width = topdovetail.min_width + (2 * options.thickness / math.tan(topdovetail.angle))

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

  local bottom_index = dialog:GetRadioIndex("BottomTypeRadio")
  if bottom_index == 1 then
    options.flat_bottom = true
  else
    options.flat_bottom = false
  end

  -- Get from tool picker
  options.tool = dialog:GetTool("ToolChooseButton")

  ------------------------------------------------------------------
  -- NEW: clamp Joint Width (SideTabWidthField) to
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
      local current_width = options.sidetabwidth or sidedovetail.min_width
      local new_width     = math.max(current_width, calculated_min)

      if new_width ~= current_width then
        options.sidetabwidth   = new_width
        sidedovetail.min_width = new_width

        -- Push it back into the dialog so user sees the update
        if dialog.SetDoubleField ~= nil then
          dialog:SetDoubleField("SideTabWidthField", new_width)
        end
      end
    end
  end
  ------------------------------------------------------------------

  options.window_width  = dialog.WindowWidth
  options.window_height = dialog.WindowHeight
end

function SaveDefaults(options, justwindowinfo)
  local registry = Registry("BoxCreator_" .. g_version)

  registry:SetDouble("WindowWidth", options.window_width)
  registry:SetDouble("WindowHeight", options.window_height)
  registry:SetBool("WarnDovetail", options.warn_dovetail)
  registry:SetBool("DarkMode", options.dark_mode)
  registry:SetBool("LabelFaces", options.label_faces)

  if justwindowinfo then
    return
  end

  registry:SetDouble("Width", options.width)
  registry:SetDouble("Height", options.height)
  registry:SetDouble("Depth", options.depth)
  registry:SetDouble("JointWidth", options.sidetabwidth)
  registry:SetDouble("BottomJointWidth", options.bottomtabwidth)     -- Added by Gremlin
  registry:SetDouble("TopJointWidth", options.toptabwidth)         -- Added by Gremlin
  registry:SetBool("AllJointWidths", options.allJointWidths)           -- Added by Gremlin
  registry:SetDouble("Allowance", options.allowance)                 -- Added by Sharkcutup
  registry:SetDouble("EdgeMargin", options.edge_margin)              -- Added by Sharkcutup
  registry:SetBool("CutDovetails", options.cut_dovetails)
  registry:SetBool("FlatLid", options.flat_lid)
  registry:SetBool("FlatBottom", options.flat_bottom)
  if options.tool ~= nil then
    options.tool.ToolDBId:SaveDefaults("BoxCreator_"..g_version, "")
  end

  registry:SetBool("NoToolpath", options.no_toolpath)

  registry:SetBool("MakeLid", options.facesToMake.lid)
  registry:SetBool("MakeBottom", options.facesToMake.bottom)
  registry:SetBool("MakeSide1", options.facesToMake.side1)
  registry:SetBool("MakeSide2", options.facesToMake.side2)
  registry:SetBool("MakeEnd1", options.facesToMake.end1)
  registry:SetBool("MakeEnd2", options.facesToMake.end2)
  registry:SetBool("CreateTabsForMissingFaces", options.create_tabs_for_missing_faces)

end

-- Gremlin added bottomdovetail separation from side which is just dovetail
function LoadDefaults(options, sidedovetail, bottomdovetail, topdovetail)
  local registry =  Registry("BoxCreator_" .. g_version)

  options.window_width = registry:GetDouble("WindowWidth", options.window_width)
  options.window_height = registry:GetDouble("WindowHeight", options.window_height)

  options.width = registry:GetDouble("Width", options.width)
  options.height = registry:GetDouble("Height", options.height)
  options.depth = registry:GetDouble("Depth", options.depth)
  options.sidetabwidth = registry:GetDouble("JointWidth", options.sidetabwidth)
  options.bottomtabwidth = registry:GetDouble("BottomJointWidth", options.sidetabwidth)  --Added by Gremlin
  options.toptabwidth = registry:GetDouble("TopJointWidth", options.sidetabwidth)      --Added by Gremlin
  options.allJointWidths = registry:GetBool("AllJointWidths", options.allJointWidths)  -- Added by Gremlin
  options.allowance = registry:GetDouble("Allowance", options.allowance)           -- Added by Sharkcutup
  options.edge_margin = registry:GetDouble("EdgeMargin", options.edge_margin)      -- Added by Sherkcutup
  sidedovetail.min_width = options.sidetabwidth
  bottomdovetail.min_width = options.bottomtabwidth -- Added by Gremlin
  topdovetail.min_width = options.toptabwidth -- Added by Gremlin
  options.cut_dovetails = registry:GetBool("CutDovetails", options.cut_dovetails)
  options.flat_lid = registry:GetBool("FlatLid", options.flat_lid)
  options.flat_bottom = registry:GetBool("FlatBottom", options.flat_bottom)
  options.default_toolid = ToolDBId("BoxCreator_"..g_version, "")

  options.warn_dovetail = registry:GetBool("WarnDovetail", true) -- default ON
  options.dark_mode     = registry:GetBool("DarkMode", true)     -- default ON
  options.label_faces   = registry:GetBool("LabelFaces", true)    -- default ON
  options.no_toolpath = registry:GetBool("NoToolpath", options.no_toolpath)

  options.facesToMake.lid = registry:GetBool("MakeLid", options.facesToMake.lid)
  options.facesToMake.bottom = registry:GetBool("MakeBottom", options.facesToMake.bottom)
  options.facesToMake.side1 = registry:GetBool("MakeSide1", options.facesToMake.side1)
  options.facesToMake.side2 = registry:GetBool("MakeSide2", options.facesToMake.side2)
  options.facesToMake.end1 = registry:GetBool("MakeEnd1", options.facesToMake.end1)
  options.facesToMake.end2 = registry:GetBool("MakeEnd2", options.facesToMake.end2)
  options.create_tabs_for_missing_faces = registry:GetBool("CreateTabsForMissingFaces", options.create_tabs_for_missing_faces)

end