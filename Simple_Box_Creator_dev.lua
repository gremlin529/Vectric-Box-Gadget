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
require("strict")

G_version = "dev"                                                 
G_subVersion = "development"                                      
G_title = "Simple Box"
G_width = 890
G_height = 962                                               
G_htmlFile = "Simple_Box_Creator_" .. G_version .. ".html"       
G_fingerSideLayerName = "Finger Roundover"
G_boxLayerName = "Box"
G_labelsLayerName = "Labels"
G_cutoutLayerName = "CutOut"
G_bottomLayerName = "Bottom Panel"              -- Grooved bottom thinner than the material: its own layers + cutout toolpath -- by Claude 10/9/2026
G_bottomCutoutLayerName = "CutOut Bottom"
G_flipOutlineLayerName = "End 1 Flip Outline"   -- Dovetail + Grooved: End 1 turned over, groove cut on its own sheet -- by Claude 10/9/2026
G_flipSheetName = "End 1 Groove (flipped)"
G_doveTailAngleDegrees = 60

local libraryModule

-- MotazA 16/9/2020 check if job Exists 
---
--- Main Function for Gadget 
---
---@param script_path any
---@diagnostic disable-next-line: lowercase-global
function main(script_path)
  local libraryModule = assert(loadfile(script_path .. "\\Helpers.xlua"))(libraryModule)
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

  -- Remember which sheet was active when the gadget started, so all of the
  -- gadget's sheets get named after it (this exact name for the first sheet,
  -- then "<name>-2", "-3", ... for any additional ones) instead of always
  -- assuming a sheet literally named "Sheet 1" exists.
  local base_sheet_id = job.SheetManager.ActiveSheetId
  local base_sheet_name = job.SheetManager:GetSheetName(base_sheet_id)

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
  options.dovetailAngleDegrees = G_doveTailAngleDegrees --- angle of the dovetail joint in degrees, only used/shown when dovetailJoint is true
  options.lidType = FaceJointType.Inset -- default lid type is inset
  options.bottomType = FaceJointType.Fingers -- default bottom type is tabbed
  options.bottomGrooveWidth = options.thickness --- Grooved bottom only: width of the groove slot (defaults to material thickness, set independently for e.g. a thinner slide-in panel) -- by Claude 9/18/2026
  options.bottomGrooveOffset = 0.25 + options.bottomGrooveWidth --- Grooved bottom only: distance from the wall's outer bottom edge up to the TOP of the groove (must be >= groove width)      -- by Claude 9/18/2026, updated 9/21/2026
  options.bottomGrooveDepth = 0.125         --- Grooved bottom only: how deep the groove is plowed into Side1/Side2/End1              -- by Claude 9/18/2026
  options.bottomFrontGrooveFlip = false    --- Grooved bottom + Dovetail joints only: cut End 1's groove from the other side, on its own sheet (End 1 turned over, lower left corner against the sheet's X0/Y0 stops) -- by Claude 10/9/2026
  options.bottomThickness = 0               --- Grooved bottom only: thickness of the bottom panel. 0 (nothing saved yet) or anything thicker than the material means "use the material thickness" (resolved below, before the dialog opens). A rabbet (Falz) is milled along Side 1/Side 2/End 1's edges only where the panel is thicker than the groove width -- by Claude 10/9/2026 (replaces bottomSameMaterial)
  options.bottomGrooveClearance = 0.01      --- Grooved bottom only: clearance ("Luft") subtracted from how far the panel reaches into each of the 3 grooves, for an easier slide fit -- by Claude 9/21/2026
  options.bottomRabbetDepthCorrection = 0   --- Grooved bottom only: fine-tune correction added to the computed rabbet depth (thickness minus groove width) -- by Claude 9/21/2026
  options.end1Height = options.height       --- "Side Overhang": End 1's own height. Equal to options.height by default (no overhang). Set it lower than
  options.end2Height = options.height       --- the box height and Side 1/Side 2 (always cut "height" tall) will overhang End 1/End 2 by their own difference,
                                             --- independently - so Front and Back can each have their own overhang. Only used when Lid Type = Open Chamfer. -- by Claude 9/20/2026
  options.end1ChamferAngle = 45             --- "Side Overhang": angle (degrees, measured from vertical) of End 1 (Front)'s own chamfer; 45 = classic symmetric chamfer (its horizontal run is derived from this angle and the actual overhang, not typed in directly) -- by Claude 9/20/2026
  options.end2ChamferAngle = 45             --- "Side Overhang": angle (degrees, measured from vertical) of End 2 (Back)'s own chamfer, independently of End 1's -- by Claude 9/20/2026
  options.label_faces   = true        --- default to labelling face vectors
  options.no_toolpath = false
  options.create_dogbones = true
  options.useSingleSheet = false --- if true, pack everything onto one sheet and let non-fitting pieces overhang instead of creating new sheets
  options.partLayout = "Auto"    --- "Auto" picks whichever orientation fits each part best, "Normal" never rotates parts, "Rotated" always rotates every part 90 degrees
  options.roundover_cut_depth = 0.125      --- cut depth for the finger roundover tool (box joints, no dogbones only)

  options.ZoomLevel = "Auto"
  options.dark_mode     = true        --- default to dark mode on


  options.window_width = G_width
  options.window_height = G_height

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
  sideDoveTail.angle = math.rad(G_doveTailAngleDegrees)
  sideDoveTail.min_width = 1.5 -- not sure why this is called min_width it's actually the width of the dovetail.
  sideDoveTail.depth = options.thickness

  -- added by Gremlin to allow for separate widths on bottom vs side tabs
  local bottomDoveTail = {}   
  bottomDoveTail.angle = math.rad(G_doveTailAngleDegrees)
  bottomDoveTail.min_width = 1.5
  bottomDoveTail.depth = options.thickness

  local lidDoveTail = {}   
  lidDoveTail.angle = math.rad(G_doveTailAngleDegrees)
  lidDoveTail.min_width = 1.5
  lidDoveTail.depth = options.thickness

  LoadDefaultsFromRegistry(options, sideDoveTail, bottomDoveTail, lidDoveTail)

  -- Registry may have loaded a saved dovetail angle, so refresh the angle
  -- used by each dovetail table (min_width/max_width are refreshed later,
  -- once the dialog has actually run, in ReadOptionsFromDialog).
  sideDoveTail.angle = math.rad(options.dovetailAngleDegrees)
  bottomDoveTail.angle = math.rad(options.dovetailAngleDegrees)
  lidDoveTail.angle = math.rad(options.dovetailAngleDegrees)

  -- Check to see if the previous set of dimensions were in Inches and now we're in mm or viceversa
  -- and do the appropriate conversions if needed so we display reasonable values
  if (options.InMM ~= job.InMM) then
    local multiplier = job.InMM and 25.4 or (1/25.4)
    options.width = Truncate(options.width * multiplier, 2)
    options.height = Truncate(options.height * multiplier, 2)
    options.depth = Truncate(options.depth * multiplier, 2)
    options.sideOrAllTabWidth = Truncate(options.sideOrAllTabWidth * multiplier, 2)
    options.bottomTabWidth = Truncate(options.bottomTabWidth * multiplier, 2)
    options.lidTabWidth = Truncate(options.lidTabWidth * multiplier, 2)
    options.allowance = Truncate(options.allowance * multiplier, 2)
    options.clampingMargin = Truncate(options.clampingMargin * multiplier, 2)
    options.partSpacing = Truncate(options.partSpacing * multiplier, 2)
    options.roundover_cut_depth = Truncate(options.roundover_cut_depth * multiplier, 2)
    options.bottomGrooveOffset = Truncate(options.bottomGrooveOffset * multiplier, 2)
    options.bottomGrooveDepth = Truncate(options.bottomGrooveDepth * multiplier, 2)
    options.bottomGrooveWidth = Truncate(options.bottomGrooveWidth * multiplier, 2)
    options.bottomGrooveClearance = Truncate(options.bottomGrooveClearance * multiplier, 2)
    options.bottomRabbetDepthCorrection = Truncate(options.bottomRabbetDepthCorrection * multiplier, 2)
    options.bottomThickness = Truncate(options.bottomThickness * multiplier, 2)
    options.end1Height = Truncate(options.end1Height * multiplier, 2)
    options.end2Height = Truncate(options.end2Height * multiplier, 2)
    -- end1ChamferAngle/end2ChamferAngle are in degrees, not a length, so they
    -- don't get rescaled when switching between inches and mm.  -- by Claude 9/20/2026
    options.InMM = job.InMM
  end

  -- Bottom Thickness defaults to the material thickness: when nothing has been saved yet (0)
  -- or the saved value is thicker than the current material, use the material thickness.
  --                                                                       -- by Claude 10/9/2026
  if (options.bottomThickness == nil or options.bottomThickness <= 0 or options.bottomThickness > options.thickness + 0.0001) then
    options.bottomThickness = options.thickness
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

  if IsOpenLidType(options.lidType) then
    -- if we aren't making a lid then we shouldn't make tabs for the lid since there won't be a lid to fit them
    computedFacesToMake.lid = false
  end

  if options.bottomType == FaceJointType.None then
    -- if we aren't making a bottom then we shouldn't make tabs for the bottom since there won't be a bottom to fit them
    computedFacesToMake.bottom = false
  end

  if options.lidType ~= FaceJointType.OpenChamfer then
    -- "Side Overhang" only makes sense with the Open Chamfer lid type (see DisplayDialog
    -- validation) - for any other lid, ignore any stale/leftover end1Height/end2Height
    -- value (e.g. from the registry) rather than silently shrinking End 1/End 2. -- by Claude 9/20/2026
    options.end1Height = options.height
    options.end2Height = options.height
  end

  local faces = CreateBoxFaces(options, sideDoveTail, bottomDoveTail, lidDoveTail, computedFacesToMake)

  -- Arrange the contours across as many sheets as required.
  -- All existing geometry and machining rules below remain unchanged;
  -- they are simply applied to one sheet's faces at a time.
  local converted_tool_diameter = 0.25
  if Tool_ok(options.tool) then
    converted_tool_diameter = ConvertUnitsFrom(options.tool.ToolDia, options.tool, mtl_block)
  end

  local required_sheets, sheet_names
  faces, required_sheets, sheet_names = LayoutFacesOnSheets(job, options, faces, converted_tool_diameter, base_sheet_id, base_sheet_name)
  if not required_sheets then
    return false
  end

  CreateBoxToolpaths(job, options, faces, required_sheets, computedFacesToMake, converted_tool_diameter, base_sheet_name, sheet_names)

  SetSheet(job, base_sheet_name)

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
    local bottom_face = MakeBottomFaceContour(options,
      bottomDoveTail,
      computedFacesToMake,
      "BottomFace")
    faces[#faces + 1] = bottom_face
  end

  -- -- -- Make sides
  if computedFacesToMake.side1 then
    -- Gremlin added bottomDoveTail seperation from side which is just sideDoveTail
    local sideface1 = MakeSideFace(options,
      sideDoveTail,
      bottomDoveTail,
      lidDoveTail,
      computedFacesToMake,
      true,  -- is_side1
      "SideFace1")
    faces[#faces + 1] = sideface1
  end

  if computedFacesToMake.side2 then
    -- Gremlin added bottomDoveTail seperation from side which is just sideDoveTail
    local sideface2 = MakeSideFace(options,
      sideDoveTail,
      bottomDoveTail,
      lidDoveTail,
      computedFacesToMake,
      false,  -- is_side1 (so this is side2)
      "SideFace2")
    faces[#faces + 1] = sideface2
  end

  -- -- -- Make ends
  if computedFacesToMake.end1 then
    -- Gremlin added bottomDoveTail seperation from side which is just sideDoveTail
    local endface1 = MakeEndFace(options,
      sideDoveTail,
      bottomDoveTail,
      lidDoveTail,
      computedFacesToMake,
      true,  -- is_end1 ("Side Overhang": End 1 uses its own (possibly shorter) height, independent of End 2 -- by Claude 9/20/2026)
      "EndFace1")
    faces[#faces + 1] = endface1
  end

  if computedFacesToMake.end2 then
    -- Gremlin added bottomDoveTail seperation from side which is just sideDoveTail
    local endface2 = MakeEndFace(options,
      sideDoveTail,
      bottomDoveTail,
      lidDoveTail,
      computedFacesToMake,
      false,  -- is_end1 (so this is end2; "Side Overhang": End 2 uses its own (possibly shorter) height, independent of End 1 -- by Claude 9/20/2026)
      "EndFace2")
    faces[#faces + 1] = endface2
  end

  -- Make lid
  if (computedFacesToMake.lid and not IsOpenLidType(options.lidType)) then
    local lid = MakeLid(options,
      lidDoveTail,
      computedFacesToMake,
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
function LayoutFacesOnSheets(job, options, faces, converted_tool_diameter, base_sheet_id, base_sheet_name)
  local part_gap = math.max(2 * converted_tool_diameter, options.partSpacing)
  local clampingMargin = math.max(options.clampingMargin or 0.0, 0.75)
  local required_sheets = 1

  -- A Grooved bottom thinner than the material is cut from separate stock, so it is
  -- laid out on a sheet of its own ("Bottom Panel <thickness>") after the normal sheets.  -- by Claude 10/9/2026
  -- Dovetail End 1 groove to be cut from the other side: build the helper part now,
  -- while End 1 is still in its original (unarranged) position.  -- by Claude 10/9/2026
  local flip_face = nil
  for i = 1, #faces do
    if faces[i].flip_groove_contours ~= nil then
      flip_face = MakeFrontGrooveFlipFace(faces[i])
      break
    end
  end

  local bottom_faces = {}
  if IsSeparateBottom(options) then
    local main_faces = {}
    for i = 1, #faces do
      if faces[i].facetype == FaceType.Bottom then
        bottom_faces[#bottom_faces + 1] = faces[i]
      else
        main_faces[#main_faces + 1] = faces[i]
      end
    end
    faces = main_faces
  end
  if options.useSingleSheet then
    -- Best effort: pack everything onto the starting sheet. Pieces that don't
    -- fit are still laid out (overhanging the material) rather than opening
    -- a new sheet.
    faces = ArrangeContours(faces, part_gap, job.XLength, job.YLength, clampingMargin, options.partLayout)
    for i = 1, #faces do
      faces[i].sheet_number = 1
    end
  else
    faces, required_sheets = ArrangeContoursToSheets(faces, part_gap, job.XLength, job.YLength, clampingMargin, options.partLayout)
  end

  local sheet_names = {}
  for sheet_num = 1, required_sheets do
    if not SheetEnsureExists(job, base_sheet_id, base_sheet_name, sheet_num) then
      return nil
    end
    sheet_names[sheet_num] = SheetNameForIndex(base_sheet_name, sheet_num)
  end

  if #bottom_faces > 0 then
    if #faces == 0 then
      required_sheets = 0  -- only the bottom is being made: it gets the only sheet
    end
    bottom_faces = ArrangeContours(bottom_faces, part_gap, job.XLength, job.YLength, clampingMargin, options.partLayout)
    local bottom_sheet_num = required_sheets + 1
    local bottom_sheet_name = string.format("Bottom Panel %g", options.bottomThickness)
    if not SheetEnsureExists(job, base_sheet_id, bottom_sheet_name, 1) then
      return nil
    end
    sheet_names[bottom_sheet_num] = bottom_sheet_name
    for i = 1, #bottom_faces do
      bottom_faces[i].sheet_number = bottom_sheet_num
      faces[#faces + 1] = bottom_faces[i]
    end
    required_sheets = bottom_sheet_num
  end

  if flip_face ~= nil then
    local flip_sheet_num = required_sheets + 1
    if not SheetEnsureExists(job, base_sheet_id, G_flipSheetName, 1) then
      return nil
    end
    sheet_names[flip_sheet_num] = G_flipSheetName
    flip_face.sheet_number = flip_sheet_num
    faces[#faces + 1] = flip_face
    required_sheets = flip_sheet_num
  end

  return faces, required_sheets, sheet_names
end

--[[  -------------- MakeFrontGrooveFlipFace --------------------------------------------------
|
|  Dovetail + Grooved bottom: End 1's groove belongs on the face that lies down on
|  the spoilboard when End 1 is cut, so it is cut in a second setup instead: End 1
|  is turned over (about its vertical axis) and pushed into the sheet's lower left
|  corner (X0/Y0 stops). This helper part is End 1's bounding rectangle at (0,0),
|  with the groove mirrored left/right to match the turned-over part. Its outline
|  is reference only (no cutout); only the groove is machined.  -- by Claude 10/9/2026
|  The part stands upright on that sheet (turned 270 degrees): End 1's bottom
|  edge lies against the left (X0) stop.                          -- by Claude 10/9/2026
|
]]
function MakeFrontGrooveFlipFace(front)
  local fb = front.contour.BoundingBox2D
  local fx1 = fb.MaxX
  local fy0 = fb.MinY
  local part_w = fb.MaxX - fb.MinX
  local part_h = fb.MaxY - fb.MinY

  -- turn 270 degrees (counter-clockwise) and keep the lower left corner at (0,0):
  -- (x, y) -> (y, part_w - x), so the part is part_h wide and part_w tall
  local function Upright(x, y)
    return y, part_w - x
  end

  local outline = Contour(0.0)
  outline:AppendPoint(Point2D(0, 0))
  outline:LineTo(Point2D(part_h, 0))
  outline:LineTo(Point2D(part_h, part_w))
  outline:LineTo(Point2D(0, part_w))
  outline:LineTo(Point2D(0, 0))

  local grooves = ContourGroup(true)
  local pos = front.flip_groove_contours:GetHeadPosition()
  while pos ~= nil do
    local c
    c, pos = front.flip_groove_contours:GetNext(pos)
    local b = c.BoundingBox2D
    -- mirror x about the part's own centre line, then move its lower left to (0,0)
    local ax, ay = Upright(fx1 - b.MaxX, b.MinY - fy0)
    local bx, by = Upright(fx1 - b.MinX, b.MaxY - fy0)
    local gx0 = math.min(ax, bx)
    local gx1 = math.max(ax, bx)
    local gy0 = math.min(ay, by)
    local gy1 = math.max(ay, by)
    local g = Contour(0.0)
    g:AppendPoint(Point2D(gx0, gy0))
    g:LineTo(Point2D(gx1, gy0))
    g:LineTo(Point2D(gx1, gy1))
    g:LineTo(Point2D(gx0, gy1))
    g:LineTo(Point2D(gx0, gy0))
    grooves:AddTail(g)
  end

  local f = Face(outline, nil, {}, {}, "End1GrooveFlip", FaceType.End, FaceJointType.Grooved, {}, nil, grooves)
  f.is_flip_helper = true
  return f
end

-- Grooved bottom thinner than the material: cut from separate stock, so it gets its own
-- sheet, its own layers and its own (shallower) cutout toolpath.  -- by Claude 10/9/2026
function IsSeparateBottom(options)
  return (options.bottomType == FaceJointType.Grooved)
    and (options.bottomThickness ~= nil)
    and (options.bottomThickness < options.thickness - 0.0001)
end

--[[  -------------- CreateBoxToolpaths --------------------------------------------------
|
|  Walk each sheet in turn, adding the profile/cutout geometry, part labels, and
|  finger-side/fluting vectors for that sheet's faces, then (unless the user asked
|  to skip toolpaths) create the pocket, fluting and cutout toolpaths for it.
|
]]
function CreateBoxToolpaths(job, options, faces, required_sheets, computedFacesToMake, converted_tool_diameter, base_sheet_name, sheet_names)
  local offset_radius = 0.5 * converted_tool_diameter - options.allowance

  -- Grooved bottom thinner than the material: it has to be cut from separate stock,
  -- so its vectors go on their own layers with their own (shallower) cutout toolpath
  -- (and LayoutFacesOnSheets already put it on its own sheet).
  -- Same thickness as the material -> everything stays on the normal layers as before.  -- by Claude 10/9/2026
  local separateBottom = IsSeparateBottom(options)

  for sheet_num = 1, required_sheets do
    local sheet_name = (sheet_names and sheet_names[sheet_num]) or SheetNameForIndex(base_sheet_name, sheet_num)
    if not SetSheet(job, sheet_name) then
      return false
    end

    -- I really wanted this to be a bit field but this version
    -- of lua doesn't support bitwise operations so I'm using a table of booleans instead
    -- this is so we can decide which tool paths to create
    local jointsOnSheet = {false, false, false, false}

    local sheet_faces = {}
    local main_faces = {}    -- everything cut from the full material thickness
    local bottom_faces = {}  -- a Grooved bottom thinner than the material (own layers + own cutout depth)
    local real_faces = {}    -- everything except the End 1 flip helper (labels, fluting)
    local flip_faces = {}    -- End 1 flip helper: outline for reference + groove only
    for i = 1, #faces do
      if (faces[i].sheet_number or 1) == sheet_num then
        sheet_faces[#sheet_faces + 1] = faces[i]
        jointsOnSheet[faces[i].jointtype] = true
        if not faces[i].is_flip_helper then
          real_faces[#real_faces + 1] = faces[i]
        end
        if faces[i].is_flip_helper then
          flip_faces[#flip_faces + 1] = faces[i]
        elseif separateBottom and faces[i].facetype == FaceType.Bottom then
          bottom_faces[#bottom_faces + 1] = faces[i]
        else
          main_faces[#main_faces + 1] = faces[i]
        end
      end
    end

    if #sheet_faces > 0 then
      -- Original 12.3 Beta3 geometry logic, now scoped to this sheet's faces.
      local fingerSideContours = GetAllFingerSides(sheet_faces)

      -- Profile vectors + tabbed cutout vectors for a group of faces on the given layers.
      -- Returns the cutout objects (for the cutout toolpath), or nil if the group is empty.
      local function AddProfileAndCutoutVectors(group_faces, profile_layer, cutout_layer)
        if #group_faces == 0 then
          return nil
        end
        local vdcontours = GetAllProfileContours(group_faces)
        local cdcontours = GetAllProfileCadContours(group_faces)
        local cutout_cadcontours
        if options.create_dogbones or options.dovetailJoint then
          local dogboned_contours = CreateDogboneProfile(vdcontours, offset_radius)
          cutout_cadcontours = CreateTabbedCadContours(dogboned_contours, cdcontours)
        else
          local offset_contours = vdcontours:Offset(offset_radius, 0, 1, true)
          cutout_cadcontours = CreateTabbedCadContours(offset_contours, cdcontours)
        end
        AddCadListToJob(job, cdcontours, profile_layer)
        return AddCadListToJob(job, cutout_cadcontours, cutout_layer)
      end

      local cutout_objects = AddProfileAndCutoutVectors(main_faces, G_boxLayerName, G_cutoutLayerName)
      local bottom_cutout_objects = AddProfileAndCutoutVectors(bottom_faces, G_bottomLayerName, G_bottomCutoutLayerName)

      -- End 1 flip helper: outline only as a placement reference, no cutout
      if #flip_faces > 0 then
        AddCadListToJob(job, GetAllProfileCadContours(flip_faces), G_flipOutlineLayerName)
      end

      if not options.create_dogbones and not options.dovetailJoint then
        local finger_side_objects = {}
        for i = 1, #fingerSideContours do
          finger_side_objects[#finger_side_objects + 1] =
            AddGroupToJob(job, fingerSideContours[i], G_fingerSideLayerName)
        end

        if not options.no_toolpath and jointsOnSheet[FaceJointType.Fingers] then
          CreateFingerSideToolpath(
            G_fingerSideLayerName,
            options.roundover_tool,
            job,
            options.roundover_cut_depth,
            finger_side_objects)
        end
      end

      if options.label_faces then
        if #real_faces > 0 then
          AddPartsLabelsToJob(job, real_faces, G_labelsLayerName, options.thickness)
        end
      end

      local fluting_objects = nil
      if options.dovetailJoint and #real_faces > 0 then
        fluting_objects = AddFlutingVectorsForFaces(
          job, real_faces, FLUTE_LAYER_NAME, options.tool)
      end

      if (not options.no_toolpath) then
        if jointsOnSheet[FaceJointType.Inset] then
          assert(((computedFacesToMake.lid and options.lidType == FaceJointType.Inset) or
          (computedFacesToMake.bottom and options.bottomType == FaceJointType.Inset)),
           "Expected that if there are inset joints on this sheet, then at least one of the lid or bottom faces should be present and have an inset joint type.")
          CreateInsetPocketToolpath(job, options, sheet_faces, options.tool, "Pockets")
        end

        -- Grooved (slide-in) bottom: the groove geometry lives on Side1/Side2/End1,
        -- not on the Bottom face itself, so check this sheet's own faces directly
        -- rather than jointsOnSheet (which only tracks the Bottom/Lid face's joint
        -- type and could miss a sheet split across multiple material sheets).  -- by Claude 9/18/2026
        local has_bottom_grooves = false
        for i = 1, #sheet_faces do
          if sheet_faces[i].groove_contours ~= nil then
            has_bottom_grooves = true
            break
          end
        end
        if has_bottom_grooves then
          CreateGroovePocketToolpath(job, options, sheet_faces, options.tool, "Bottom Groove")
        end

        -- "Bottom aus gleichem Material": rabbet (Falz) milled along the bottom
        -- panel's own Side 1/Side 2/End 1 edges, separate pass from the wall
        -- grooves above since it's cut to a different depth.  -- by Claude 9/21/2026
        local has_bottom_rabbet = false
        for i = 1, #sheet_faces do
          if sheet_faces[i].rabbet_contours ~= nil then
            has_bottom_rabbet = true
            break
          end
        end
        if has_bottom_rabbet then
          CreateBottomRabbetToolpath(job, options, sheet_faces, options.tool, "Bottom Rabbet")
        end

        if options.dovetailJoint and fluting_objects ~= nil then
          if SelectExactObjects(job, fluting_objects) then
            CreateFlutingToolpath(
              "Fluting Dovetails", 0.0, options.thickness, options.tool)
          end
        end

        if cutout_objects ~= nil then
          CreateCutoutToolpath(
            options.tool,
            job,
            options.thickness,
            options.sideOrAllTabWidth,
            G_cutoutLayerName,
            cutout_objects)
        end

        -- Thinner bottom panel: separate cutout, only as deep as the bottom is thick
        if bottom_cutout_objects ~= nil then
          CreateCutoutToolpath(
            options.tool,
            job,
            options.bottomThickness,
            options.sideOrAllTabWidth,
            G_bottomCutoutLayerName,
            bottom_cutout_objects,
            string.format("Cut Out Bottom (%g)", options.bottomThickness))
        end
      end -- not options.no_toolpath

    end -- if #sheet_faces > 0 then
  end -- for sheet_num = 1, required_sheets do

  return true
end
