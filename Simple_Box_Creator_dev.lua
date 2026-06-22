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
-- Renamed the Gadget and stopping the upkeep of these comments as we're in GitHub now and the history is preserved there.    2/27/2026     
-- June 21st, just to give proper credit Gremlin ported Sharkcutup's amazing fluting dovetail code to the project, per github history
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
g_height = 850                                                    
g_html_file = "Simple_Box_Creator_" .. g_version .. ".html"       

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
  options.clampingMargin = 0.75                 --- edge margin default
  
  options.cut_layer_name  = "CutOut"        --- layer name default
  options.cut_dovetails = false
  options.lidType = FaceJointType.Inset -- default lid type is inset
  options.bottomType = FaceJointType.Tabbed -- default bottom type is tabbed
  options.label_faces   = true        --- default to labelling face vectors
  options.no_toolpath = false

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
  sideDoveTail.angle = math.rad(60)
  sideDoveTail.min_width = 1.5
  sideDoveTail.depth = options.thickness

  -- added by Gremlin to allow for separate widths on bottom vs side tabs
  local bottomDoveTail = {}   
  bottomDoveTail.angle = math.rad(60)
  bottomDoveTail.min_width = 1.5
  bottomDoveTail.depth = options.thickness

  local lidDoveTail = {}   
  lidDoveTail.angle = math.rad(60)
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
    options.InMM = job.InMM
  end

  local tool = Tool("0.25 Inch End Mill", Tool.END_MILL)
  tool.ToolDia = 0.25
  tool.InMM = false

  options.tool = tool

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

  local noLidTabs = (options.lidType == FaceJointType.Flat) or (options.lidType == FaceJointType.None) or (options.lidType == FaceJointType.Inset)

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
      options.cut_dovetails,  -- if true then create dovetails
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
      options.cut_dovetails, 
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
      options.cut_dovetails, 
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
      options.cut_dovetails, 
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
      options.cut_dovetails, 
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
      options.cut_dovetails,
      "Lid"
    )
    faces[#faces + 1] = lid
  end

  -- Arrange the contours
  -- this line shouldn't be needed we got it above
  -- local mtl_block = MaterialBlock()
  local converted_tool_diameter = 0.25
  if _tool_ok(options.tool) then
    converted_tool_diameter = ConvertUnitsFrom(options.tool.ToolDia, options.tool, mtl_block)
  end
  local part_gap    = 2 * converted_tool_diameter
  local clampingMargin = math.max(options.clampingMargin or 0.0, 0.75)
  faces = ArrangeContours(faces, part_gap, job.XLength, job.YLength, clampingMargin)

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

  if options.cut_dovetails then
    AddFlutingVectorsForFaces(job, faces, FLUTE_LAYER_NAME, options.tool.ToolDia)
  end

  if (not options.no_toolpath) and 
     ((computedFacesToMake.lid and options.lidType == FaceJointType.Inset) or
      (computedFacesToMake.bottom and options.bottomType == FaceJointType.Inset)) then
    CreateInsetPocketToolpath(job, options, faces, options.tool, "Pockets")
  end

  if not options.no_toolpath then
    -- if we are doing dovetails make toolpath for them
    if options.cut_dovetails then
      local flute_layer = job.LayerManager:FindLayerWithName(FLUTE_LAYER_NAME)
      if flute_layer then
        local selection = job.Selection
        selection:Clear()
        SelectVectorsOnLayer(flute_layer, selection, false, true, false)
        CreateFlutingToolpath("Fluting Dovetails", 0.0, options.thickness, options.tool)
      end
    end

    CreateCutoutToolpath(dogboned_cadcontours, options.tool, job, options.thickness, options.sideOrAllTabWidth, options.cut_layer_name)
  end

  SaveDefaultsToRegistry(options, false)
  job:Refresh2DView()
  return true

end

-- Gremlin added bottomDoveTail seperation from side which is just sideDoveTail 
function DisplayDialog(script_path, options, sideDoveTail, bottomDoveTail, lidDoveTail)
  local html_path = "file:" .. script_path .. "\\" .. g_html_file
  local dialog = HTML_Dialog(false, html_path, options.window_width, options.window_height, string.format("%s - Version %s %s", g_title, g_version, g_subVersion))

  dialog:AddLabelField("GadgetTitle", g_title)
  dialog:AddLabelField("GadgetVersion", g_version)

  -- Add Geometry fields
  dialog:AddDoubleField("WidthField", options.width)
  dialog:AddDoubleField("DepthField", options.depth)
  dialog:AddDoubleField("HeightField", options.height)
  dialog:AddDoubleField("SideTabWidthField", options.sideOrAllTabWidth)
  dialog:AddDoubleField("BottomTabWidthField", options.bottomTabWidth)
  dialog:AddDoubleField("TopTabWidthField", options.lidTabWidth)
  dialog:AddCheckBox("AllJointWidths", options.useAllJointWidths)
  dialog:AddDoubleField("AllowanceField", options.allowance)
  dialog:AddDoubleField("ClampingMargin", options.clampingMargin)

  dialog:AddCheckBox("DarkMode", options.dark_mode)
  dialog:AddCheckBox("LabelFaces", options.label_faces)

  -- dialog:AddDoubleField("DovetailAngleField", sideDoveTail.angle)

  dialog:AddDropDownList("ZoomLevel", options.ZoomLevel)

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

  dialog:AddRadioGroup("LidTypeRadio", options.lidType)
  dialog:AddRadioGroup("BottomTypeRadio", options.bottomType)

  local units_string = "Inches"
  if options.tool.InMM then
    units_string = "MM"
  end

  dialog:AddTextField("UnitsLabel", units_string)

  local validator = function(dialog)
    -- Gremlin added bottomDoveTail seperation from side which is just sideDoveTail
    ReadOptionsFromDialog(dialog, options, sideDoveTail, bottomDoveTail, lidDoveTail)
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
    if not _is_nonneg(options.clampingMargin) then
      DisplayMessageBox("Edge margin must be ≥ 0.")
      return false
    end

    local inner_width = options.width - double_thickness
    local inner_depth = options.depth - double_thickness
    local inner_height = options.height - double_thickness

    -- Gremlin added join size seperations overall
    local num_flaps_w_bottom = math.floor((0.5*inner_width) / bottomDoveTail.min_width)
    local total_tab_space_w_bottom = (inner_width - num_flaps_w_bottom*bottomDoveTail.min_width)
    local num_flaps_d_bottom = math.floor((0.5*inner_depth) / bottomDoveTail.min_width)
    local total_tab_space_d_bottom = (inner_depth - num_flaps_d_bottom*bottomDoveTail.min_width)

    if (options.bottomType == FaceJointType.Tabbed) then
      if (num_flaps_w_bottom < 1) or (total_tab_space_w_bottom < 0) then
        if (not options.useAllJointWidths) then
          DisplayMessageBox(string.format("The joint width %.3f is too big given boxes bottom given the inner width is %.3f.", bottomDoveTail.min_width, inner_width))
        else
          DisplayMessageBox(string.format("The bottom joint width %.3f is too big given box inner width is %.3f.", bottomDoveTail.min_width, inner_width))
        end
        return false
      end

      if (num_flaps_d_bottom < 1) or (total_tab_space_d_bottom < 0) then
        if (not options.useAllJointWidths) then
          DisplayMessageBox(string.format("The joint width %.3f is too big given boxes bottom given the inner depth is %.3f.", bottomDoveTail.min_width, inner_depth))
        else
          DisplayMessageBox(string.format("The bottom joint width %.3f is too big given box inner depth is %.3f.", bottomDoveTail.min_width, inner_depth))
        end
        return false
      end
    end

    local num_flaps_w_top = math.floor((0.5*inner_width) / lidDoveTail.min_width)
    local total_tab_space_w_top = (inner_width - num_flaps_w_top*lidDoveTail.min_width)
    local num_flaps_d_top = math.floor((0.5*inner_depth) / lidDoveTail.min_width)
    local total_tab_space_d_top = (inner_depth - num_flaps_d_top*lidDoveTail.min_width)

    -- check the joint widths only when making a tabbed lid
    if (options.lidType == FaceJointType.Tabbed) then
      if (num_flaps_w_top < 1) or (total_tab_space_w_top < 0) then
        DisplayMessageBox(string.format("The lid joint width %.3f is too big given box inner width is %.3f.", lidDoveTail.min_width, inner_width))
        return false
      end
      if (num_flaps_d_top < 1) or (total_tab_space_d_top < 0) then
        DisplayMessageBox(string.format("The lid joint width %.3f is too big given box inner depth is %.3f.", lidDoveTail.min_width, inner_depth)) 
        return false
      end
    end

    local num_flaps_h = math.floor((0.5*inner_height) / sideDoveTail.min_width)
    local total_tab_space_h = (inner_height - num_flaps_h*sideDoveTail.min_width)

    if (num_flaps_h < 1) or (total_tab_space_h < 0) then
      DisplayMessageBox(string.format("The side joint width %.3f is too big given box inner height is %.3f.", sideDoveTail.min_width, inner_height))
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
      local min_space = sideDoveTail.max_width - sideDoveTail.min_width
      -- Gremlin added bottomDoveTail seperation from side which
      local bottom_min_space = bottomDoveTail.max_width - bottomDoveTail.min_width
      local top_min_space = lidDoveTail.max_width - lidDoveTail.min_width

      -- make sure dovetails don't overlap
      if (tab_space_w_bottom <= bottom_min_space) or (tab_space_d_bottom <= bottom_min_space) then
        DisplayMessageBox("The joint width is too small for the bottom.")
        return false
      end      

      if (tab_space_h <= min_space) then        
        DisplayMessageBox("The joint width is too small for the side.")
        return false
      end

      if (options.lidType == FaceJointType.Tabbed) then
        if (tab_space_w_top <= top_min_space) or (tab_space_d_top <= top_min_space) then
          DisplayMessageBox("The joint width is too small for the lid.")
          return false
        end
      end

      min_space = min_space + dia
      if (tab_space_w_bottom <= bottom_min_space) or 
      (tab_space_d_bottom <= bottom_min_space) or 
      (tab_space_h <= min_space) or 
      ((options.lidType == FaceJointType.Tabbed) and 
        ((tab_space_w_top <= top_min_space) or (tab_space_d_top <= top_min_space))) then        
        DisplayMessageBox("The selected tool will not fit between the joints.")
        return false
      end  
    else
      -- Gremlin added bottomDoveTail seperation from side
      tab_space_w_bottom = math.min(tab_space_w_bottom, bottomDoveTail.min_width)
      tab_space_d_bottom = math.min(tab_space_d_bottom, bottomDoveTail.min_width)
      tab_space_w_top = math.min(tab_space_w_top, lidDoveTail.min_width)
      tab_space_d_top = math.min(tab_space_d_top, lidDoveTail.min_width)
      tab_space_h = math.min(tab_space_h, sideDoveTail.min_width)
      if (tab_space_w_bottom <= dia) or (tab_space_d_bottom <= dia) then        
        DisplayMessageBox("The selected tool will not fit between the bottom joints.")
        return false
      end
      if (tab_space_h <= dia) then        
        DisplayMessageBox("The selected tool will not fit between the side joints.")
        return false
      end 
      if (options.useAllJointWidths and options.lidType == FaceJointType.Tabbed and (options.facesToMake.lid or options.create_tabs_for_missing_faces)) then
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
      ReadOptionsFromDialog(dialog, options, sideDoveTail, bottomDoveTail, lidDoveTail)
      SaveDefaultsToRegistry(options, true) -- the user hit cancel but save the window settings anyways
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
  ReadOptionsFromDialog(dialog, options, sideDoveTail, bottomDoveTail, lidDoveTail)

  return true
end

-- Gremlin added joint width seperation for sides top and bottom
-- This function will read the options out of the dialog
function ReadOptionsFromDialog(dialog, options, sideDoveTail, bottomDoveTail, lidDoveTail)
  -- Read back data from the form
  options.width     = dialog:GetDoubleField("WidthField")
  options.depth     = dialog:GetDoubleField("DepthField")
  options.height    = dialog:GetDoubleField("HeightField")
  options.sideOrAllTabWidth  = dialog:GetDoubleField("SideTabWidthField")
  sideDoveTail.min_width = options.sideOrAllTabWidth
  -- Gremlin added joint width seperation for sides top and bottom
  options.useAllJointWidths = dialog:GetCheckBox("AllJointWidths")
  options.bottomTabWidth = dialog:GetDoubleField("BottomTabWidthField")
  options.lidTabWidth = dialog:GetDoubleField("TopTabWidthField")
  options.dark_mode     = dialog:GetCheckBox("DarkMode")
  options.label_faces   = dialog:GetCheckBox("LabelFaces")
  options.ZoomLevel = dialog:GetDropDownListValue("ZoomLevel")

  options.no_toolpath  = dialog:GetCheckBox("NoToolpath")
  options.facesToMake.lid      = dialog:GetCheckBox("MakeLid")
  options.facesToMake.bottom   = dialog:GetCheckBox("MakeBottom")
  options.facesToMake.side1    = dialog:GetCheckBox("MakeSide1")
  options.facesToMake.side2    = dialog:GetCheckBox("MakeSide2")
  options.facesToMake.end1     = dialog:GetCheckBox("MakeEnd1")
  options.facesToMake.end2     = dialog:GetCheckBox("MakeEnd2")
  options.create_tabs_for_missing_faces = dialog:GetCheckBox("CreateTabsForMissingFaces")

  
  -- Set up the dovetail widths based on if we're using separate widths for each piece
  -- or not, use sidedovetail size for everything if not.
  if not options.useAllJointWidths then
    bottomDoveTail.min_width = sideDoveTail.min_width
    lidDoveTail.min_width = sideDoveTail.min_width
  else
    bottomDoveTail.min_width = options.bottomTabWidth
    lidDoveTail.min_width = options.lidTabWidth
  end 

  sideDoveTail.max_width = sideDoveTail.min_width + (2 * options.thickness / math.tan(sideDoveTail.angle))
  bottomDoveTail.max_width = bottomDoveTail.min_width + (2* options.thickness/ math.tan(bottomDoveTail.angle))
  lidDoveTail.max_width = lidDoveTail.min_width + (2 * options.thickness / math.tan(lidDoveTail.angle))

  options.allowance   = dialog:GetDoubleField("AllowanceField")
  options.clampingMargin = dialog:GetDoubleField("ClampingMargin")
  if not options.clampingMargin or options.clampingMargin <= 0 then
    options.clampingMargin = 0.75
  end


  local tab_index = dialog:GetRadioIndex("TabTypeRadio")
  if tab_index == 1 then
    options.cut_dovetails = false   -- Finger joints
  else
    options.cut_dovetails = true    -- Dovetail joints
  end

  local lid_index = dialog:GetRadioIndex("LidTypeRadio")
  options.lidType = lid_index
  
  local bottom_index = dialog:GetRadioIndex("BottomTypeRadio")
  options.bottomType = bottom_index


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
      local current_width = options.sideOrAllTabWidth or sideDoveTail.min_width
      local new_width     = math.max(current_width, calculated_min)

      if new_width ~= current_width then
        options.sideOrAllTabWidth   = new_width
        sideDoveTail.min_width = new_width

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

function SaveDefaultsToRegistry(options, justwindowinfo)
  local registry = Registry("BoxCreator_" .. g_version)

  -- UX defaults
  registry:SetDouble("WindowWidth", options.window_width)
  registry:SetDouble("WindowHeight", options.window_height)
  registry:SetBool("DarkMode", options.dark_mode)
  registry:SetBool("LabelFaces", options.label_faces)
  registry:SetString("ZoomLevel", options.ZoomLevel)

  if justwindowinfo then
    return
  end

  -- Box dimension settings
  registry:SetDouble("Width", options.width)
  registry:SetDouble("Height", options.height)
  registry:SetDouble("Depth", options.depth)
  registry:SetBool("InMM", options.InMM)
  registry:SetDouble("JointWidth", options.sideOrAllTabWidth)
  registry:SetDouble("BottomJointWidth", options.bottomTabWidth)     -- Added by Gremlin
  registry:SetDouble("TopJointWidth", options.lidTabWidth)         -- Added by Gremlin
  registry:SetBool("AllJointWidths", options.useAllJointWidths)           -- Added by Gremlin
  registry:SetDouble("Allowance", options.allowance)                 -- Added by Sharkcutup
  registry:SetDouble("EdgeMargin", options.clampingMargin)              -- Added by Sharkcutup
  registry:SetBool("CutDovetails", options.cut_dovetails)
  registry:SetDouble("LidType", options.lidType)
  registry:SetDouble("BottomType", options.bottomType)

  if options.tool ~= nil then
    options.tool.ToolDBId:SaveDefaults("BoxCreator_"..g_version, "")
  end

  registry:SetBool("NoToolpath", options.no_toolpath)

  -- Machining settings
  registry:SetBool("MakeLid", options.facesToMake.lid)
  registry:SetBool("MakeBottom", options.facesToMake.bottom)
  registry:SetBool("MakeSide1", options.facesToMake.side1)
  registry:SetBool("MakeSide2", options.facesToMake.side2)
  registry:SetBool("MakeEnd1", options.facesToMake.end1)
  registry:SetBool("MakeEnd2", options.facesToMake.end2)
  registry:SetBool("CreateTabsForMissingFaces", options.create_tabs_for_missing_faces)

end

-- Gremlin added bottomDoveTail separation from side which is just dovetail
function LoadDefaultsFromRegistry(options, sideDoveTail, bottomDoveTail, lidDoveTail)
  local registry =  Registry("BoxCreator_" .. g_version)

  options.window_width = registry:GetDouble("WindowWidth", options.window_width)
  options.window_height = registry:GetDouble("WindowHeight", options.window_height)

  options.width = registry:GetDouble("Width", options.width)
  options.height = registry:GetDouble("Height", options.height)
  options.depth = registry:GetDouble("Depth", options.depth)
  options.InMM = registry:GetBool("InMM", options.InMM)
  options.sideOrAllTabWidth = registry:GetDouble("JointWidth", options.sideOrAllTabWidth)
  options.bottomTabWidth = registry:GetDouble("BottomJointWidth", options.sideOrAllTabWidth)  --Added by Gremlin
  options.lidTabWidth = registry:GetDouble("TopJointWidth", options.sideOrAllTabWidth)      --Added by Gremlin
  options.useAllJointWidths = registry:GetBool("AllJointWidths", options.useAllJointWidths)  -- Added by Gremlin
  options.allowance = registry:GetDouble("Allowance", options.allowance)           -- Added by Sharkcutup
  options.clampingMargin = registry:GetDouble("EdgeMargin", options.clampingMargin)      -- Added by Sherkcutup
  -- sideDoveTail.min_width = options.sideOrAllTabWidth
  -- bottomDoveTail.min_width = options.bottomTabWidth -- Added by Gremlin
  -- lidDoveTail.min_width = options.lidTabWidth -- Added by Gremlin
  options.cut_dovetails = registry:GetBool("CutDovetails", options.cut_dovetails)
  options.lidType = registry:GetDouble("LidType", options.lidType)
  options.bottomType = registry:GetDouble("BottomType", options.bottomType)
  options.default_toolid = ToolDBId("BoxCreator_"..g_version, "")

  options.dark_mode     = registry:GetBool("DarkMode", true)     -- default ON
  options.label_faces   = registry:GetBool("LabelFaces", true)    -- default ON
  options.ZoomLevel = registry:GetString("ZoomLevel", options.ZoomLevel) -- default Auto
  options.no_toolpath = registry:GetBool("NoToolpath", options.no_toolpath)

  options.facesToMake.lid = registry:GetBool("MakeLid", options.facesToMake.lid)
  options.facesToMake.bottom = registry:GetBool("MakeBottom", options.facesToMake.bottom)
  options.facesToMake.side1 = registry:GetBool("MakeSide1", options.facesToMake.side1)
  options.facesToMake.side2 = registry:GetBool("MakeSide2", options.facesToMake.side2)
  options.facesToMake.end1 = registry:GetBool("MakeEnd1", options.facesToMake.end1)
  options.facesToMake.end2 = registry:GetBool("MakeEnd2", options.facesToMake.end2)
  options.create_tabs_for_missing_faces = registry:GetBool("CreateTabsForMissingFaces", options.create_tabs_for_missing_faces)

end

function truncate(num, decimals)
    if type(num) ~= "number" or type(decimals) ~= "number" then
        error("Both arguments must be numbers")
    end
    if decimals < 0 then
        error("Decimal places must be non-negative")
    end
    
    local factor = 10 ^ decimals
    -- math.floor for truncating toward negative infinity
    -- For truncating toward zero, use conditional logic
    if num >= 0 then
        return math.floor(num * factor) / factor
    else
        return math.ceil(num * factor) / factor
    end
end

--- By putting this function in the script we don't need to create
--- individual functions unless we need specific handling
function OnLuaButton_XXXX()
  return true
end


