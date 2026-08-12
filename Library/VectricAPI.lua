---@meta

--[[
  VectricAPI.lua -- LuaCATS/EmmyLua type definitions for the Vectric Gadget API.

  Converted from the community ZeroBrane Studio autocomplete table
  (Vectric.lua), using japi.lua as the formatting template, so a Lua
  language server (e.g. sumneko/lua-language-server) can offer signature
  help and hover docs while editing gadget scripts such as
  Simple_Box_Creator_dev.lua and CreateFaces.xlua.

  Differences from the japi.lua template, deliberately:
   - Vectric's API is exposed as bare globals (DisplayMessageBox(...),
     Point2D(x, y), ...), not a namespaced table like `japi.Func(...)`, so
     each entry here is declared as a plain global function rather than as
     a field of a wrapper class.
   - japi.lua's `---#DES 'name'` tag just re-states the qualified name for
     an external doc tool; it adds nothing on its own here, so real
     descriptions are given as plain doc comments instead, which a Lua
     language server shows directly in hover tooltips.
   - Vectric.lua documents constructor/utility *signatures* only, not the
     fields or methods available on the objects they return. The ---@class
     stubs below are therefore empty placeholders: they let the language
     server track type identity (e.g. `local p = Point2D(1,2)` is known to
     be a Point2D) even though member completion on `p` isn't available
     yet. Fill in ---@field / method declarations on these classes as you
     discover them from the SDK docs or from real usage.
   - A handful of obviously-broken entries in the source dump (e.g.
     MaterialBlock() documented as returning a string) are corrected below
     to match what the constructor actually returns.
   - This file only covers what Vectric.lua documents. Globals used
     elsewhere in this project but not present in that dump (e.g.
     ConvertUnitsFrom, GetAllProfileContours, FaceJointType, ToolType,
     FaceJointType.Fingers, etc.) are not included here.
]]

-------------------------------------------------------------------------------
-- Object type stubs (empty placeholders -- see note above)
-------------------------------------------------------------------------------

---@class Point2D
---@class Point3D
---@class Vector2D
---@class Vector3D
---@class Box2D
---@class Matrix2D
---@class MaterialBlock
---@class Contour
---@class ContourGroup
---@class ContourCarriage
---@class Span
---@class CadObjectList
---@class CadObject
---@class CadContour
---@class CadContourGroup
---@class CadObjectGroup
---@class CadBitmap
---@class CadPolyline
---@class CadToolpathPreview
---@class CadMarker
---@class TxtBlock
---@class Component
---@class ComponentGroup
---@class ToolpathManager
---@class ToolDatabase
---@class Tool
---@field Name string
---@field ToolDia number
---@field InMM boolean
---@field ClearStepover number
---@field tool_type integer
---@class ToolpathPosData
---@class GeometrySelector
---@class ProfileParameterData
---@class PocketParameterData
---@class RampingData
---@class LeadInData
---@class DrillParameterData
---@class VCarveParameterData
---@class FlutingParameterData
---@class PrismCarveParameterData
---@class RoughingParameterData
---@class FinishingParameterData
---@class ExternalToolpath
---@class ExternalToolpathOptions
---@class ToolpathSaver
---@class HTML_Dialog
---@class FileDialog
---@class DirectoryReader
---@class ProgressBar
---@class Registry

--- A GUID-style id returned for a created toolpath.
---@alias UUID string

-- Enum-style parameters that Vectric.lua names but doesn't give values for.
-- Modeled as plain integers so the language server has something concrete
-- to check against; replace with real ---@alias ... (A|B|C) values if/when
-- the actual enum constants are pinned down.
---@alias SideFlipDirection integer
---@alias ToolType integer
---@alias ProgressBarMode integer

-------------------------------------------------------------------------------
-- Global Methods
-------------------------------------------------------------------------------

--- Displays MessageBox to user
---@param message string
function DisplayMessageBox(message) end

--- Displays a message box with passed text to user
---@param message string
function MessageBox(message) end

--- Returns true if the script is running inside Aspire
---@return boolean
function IsAspire() end

--- Returns true if this is a Beta build rather than a release build
---@return boolean
function IsBetaBuild() end

--- Returns application version number as a double e.g 4.004 for Aspire V4.0
---@return number
function GetAppVersion() end

--- Returns application internal build version
---@return number
function GetBuildVersion() end

-------------------------------------------------------------------------------
-- Job related global methods
-------------------------------------------------------------------------------

--- Close the current job, same as File > Close; will prompt to save if needed
---@return boolean
function CloseCurrentJob() end

--- Creates a new job. Returns true if job created OK else false.
---@param name string
---@param bounds Box2D
---@param thickness number
---@param in_mm boolean
---@param origin_on_surface boolean
---@return boolean
function CreateNewJob(name, bounds, thickness, in_mm, origin_on_surface) end

--- Return current job
function VectricJob() end

--- Creates a new two sided job. Returns true if the job was created, otherwise false.
---@param name string
---@param bounds Box2D
---@param thickness number
---@param in_mm boolean
---@param origin_on_surface boolean
---@param flip_direction SideFlipDirection
---@return boolean
function CreateNew2SidedJob(name, bounds, thickness, in_mm, origin_on_surface, flip_direction) end

--- Creates a new rotary job using the given parameters. Returns true if the job was created, otherwise false.
---@param name string
---@param length number
---@param diameter number
---@param xy_origin any @ MaterialBlock.XYOrigin
---@param in_mm boolean
---@param origin_on_surface boolean
---@param wrapped_along_x_axis boolean
---@return boolean
function CreateNewRotaryJob(name, length, diameter, xy_origin, in_mm, origin_on_surface, wrapped_along_x_axis) end

--- Opens an existing CRV or CRV3D file. Returns true if file opened OK, else false.
---@param pathname string
---@return boolean
function OpenExistingJob(pathname) end

--- Save the current job. If no path has been set for the job this displays the File Save As dialog.
---@return boolean
function SaveCurrentJob() end

-------------------------------------------------------------------------------
-- Vector object related global methods
-------------------------------------------------------------------------------

--- Casts the passed CadObject to a CadBitmap
---@param object CadObject
---@return CadBitmap
function CastCadObjectToCadBitmap(object) end

--- Casts the passed CadObject to a CadContour
---@param object CadObject
---@return CadContour
function CastCadObjectToCadContour(object) end

--- Casts the passed CadObject to a CadObjectGroup
---@param object CadObject
---@return CadObjectGroup
function CastCadObjectToCadObjectGroup(object) end

--- Casts the passed CadObject to a CadPolyline
---@param object CadObject
---@return CadPolyline
function CastCadObjectToCadPolyline(object) end

--- Casts the passed CadObject to a CadToolpathPreview
---@param object CadObject
---@return CadToolpathPreview
function CastCadObjectToCadToolpathPreview(object) end

--- Casts the passed CadObject to a TxtBlock
---@param object CadObject
---@return TxtBlock
function CastCadObjectToTxtBlock(object) end

--- Creates a Contour object for a circle consisting of 4 arcs
---@param x number
---@param y number
---@param radius number
---@param tolerance number
---@param z_value number
function CreateCircle(x, y, radius, tolerance, z_value) end

--- Creates a ContourGroup containing a copy of the currently selected contours in the job
---@param smash_beziers boolean
---@param smash_arcs boolean
---@param smash_tol number
function CreateCopyOfSelectedContours(smash_beziers, smash_arcs, smash_tol) end

-------------------------------------------------------------------------------
-- Component Related Global Methods -- Aspire only
-------------------------------------------------------------------------------

--- Aspire only - Returns true if the specified value is considered transparent
---@param value number
---@return boolean
function IsTransparent(value) end

--- Aspire only - Returns the height in reliefs considered transparent. This is
--- the value used internally to represent a "transparent" point.
---@return number
function GetTransparentHeight() end

--- Aspire only - Casts the passed Component to a ComponentGroup
---@param component Component
---@return ComponentGroup
function CastComponentToComponentGroup(component) end

-------------------------------------------------------------------------------
-- DocumentVariable related global methods
-------------------------------------------------------------------------------

--- Returns true if the passed name is invalid for a DocumentVariable
---@param name string
---@return boolean
function IsInvalidDocumentVariableName(name) end

-------------------------------------------------------------------------------
-- Data file location related global methods
-------------------------------------------------------------------------------

--- Returns the location path for the application
---@return string
function GetDataLocation() end

--- Returns the PostP location path for the program
---@return string
function GetPostProcessorLocation() end

--- Returns the Tool Database location path for the program
---@return string
function GetToolDatabaseLocation() end

--- Returns the Gadgets location path for the program
---@return string
function GetGadgetsLocation() end

--- Returns the ToolpathDefaults path for the program
---@return string
function GetToolpathDefaultsLocation() end

--- Returns the BitmapTextures location path for the program, which stores the
--- bitmaps used for displaying different material types
---@return string
function GetBitmapTexturesLocation() end

--- Returns the VectorTextures location path for the program
---@return string
function GetVectorTexturesLocation() end

--- Returns a CadContour which owns the passed Contour object
---@param ctr Contour
---@return CadContour
function CreateCadContour(ctr) end

--- Returns a CadObjectGroup which owns the passed ContourGroup object
---@param ctr ContourGroup
---@return CadObjectGroup
function CreateCadGroup(ctr) end

--- Returns the default value used for contour tolerances within the program
---@return number
function GetDefaultContourTolerance() end

-------------------------------------------------------------------------------
-- MaterialBlock
-------------------------------------------------------------------------------

--- Constructs a new single material block
---@return MaterialBlock
function MaterialBlock() end

--- Returns an "absolute" Z value from a Z value relative to the surface of the block
---@param z_value number
---@return number
function CalcAbsoluteZ(z_value) end

-------------------------------------------------------------------------------
-- CadMarker
-------------------------------------------------------------------------------

--- Creates a CadMarker at the passed position
---@param text string
---@param pt Point2D
---@param pixel_size integer
---@return CadMarker
function CadMarker(text, pt, pixel_size) end

-------------------------------------------------------------------------------
-- CadObjectList / Contour / ContourGroup / Spans
-------------------------------------------------------------------------------

--- Creates a new CadObjectList
---@param owns_objects boolean
---@return CadObjectList
function CadObjectList(owns_objects) end

--- Constructor - starts a new vector (contour) object at the given start Z
---@param start_z number
---@return Contour
function Contour(start_z) end

--- Creates a new empty ContourGroup object
---@param owns_objects boolean
---@return ContourGroup
function ContourGroup(owns_objects) end

--- Creates a "carriage" for the passed contour, positioned at the nearest
--- point on the contour to the passed point, or for the span with the
--- passed index at the passed parameter position (range 0-1.0) on the span.
---@param ctr_or_span_index Contour|integer
---@param pt_or_parameter Point2D|number
---@return ContourCarriage
function ContourCarriage(ctr_or_span_index, pt_or_parameter) end

--- Creates a new span representing a single point
---@param pt3d Point3D
---@return Span
function Span(pt3d) end

--- Creates a new 2D or 3D span representing a line
---@param start_point Point2D|Point3D
---@param end_point Point2D|Point3D
---@return Span
function LineSpan(start_point, end_point) end

--- Creates a new span representing an arc
---@param start_point Point2D|Point3D
---@param end_point Point2D|Point3D
---@param arc_point_or_bulge Point2D|number
---@return Span
function ArcSpan(start_point, end_point, arc_point_or_bulge) end

--- Creates a new span representing a bezier
---@param start_pt Point2D
---@param end_pt Point2D
---@param ctrl_pt_1 Point2D
---@param ctrl_pt_2 Point2D
---@return Span
function BezierSpan(start_pt, end_pt, ctrl_pt_1, ctrl_pt_2) end

-------------------------------------------------------------------------------
-- Point / Vector / Box2D / Matrix2D
-------------------------------------------------------------------------------

--- A new 2D point with the specified X and Y values
---@param x number
---@param y number
---@return Point2D
function Point2D(x, y) end

--- A new 3D point with the specified X, Y and Z values
---@param x number
---@param y number
---@param z number
---@return Point3D
function Point3D(x, y, z) end

--- A new 2D vector with the specified X and Y values
---@param x number
---@param y number
---@return Vector2D
function Vector2D(x, y) end

--- A new 3D vector with the specified X, Y and Z values
---@param x number
---@param y number
---@param z number
---@return Vector3D
function Vector3D(x, y, z) end

--- A new Box2D bounding the two passed points
---@param p1 Point2D
---@param p2 Point2D
---@return Box2D
---@overload fun(box: Box2D): Box2D @ A new Box2D with the same values as the passed box
function Box2D(p1, p2) end

--- Returns a Matrix2D which is an identity matrix
---@return Matrix2D
function IdentityMatrix2D() end

--- Returns a Matrix2D which reflects about the line through the two passed points
---@param p1 Point2D
---@param p2 Point2D
---@return Matrix2D
function ReflectionMatrix2D(p1, p2) end

--- Returns a Matrix2D which performs a rotation about the specified point by the specified angle (radians)
---@param rotation_pt Point2D
---@param angle number
---@return Matrix2D
function RotationMatrix2D(rotation_pt, angle) end

--- Returns a Matrix2D which performs scaling around the origin (0,0) by the specified amount
---@param scale_vec Vector2D
---@return Matrix2D
function ScalingMatrix2D(scale_vec) end

--- Returns a Matrix2D which performs the translation specified by the vector
---@param translation_vec Vector2D
---@return Matrix2D
function TranslationMatrix2D(translation_vec) end

-------------------------------------------------------------------------------
-- Tool Path
-------------------------------------------------------------------------------

--- Returns a new object which refers to the single toolpath manager within the program
---@return ToolpathManager
function ToolpathManager() end

--- Creates a pocketing toolpath for the currently selected vectors
---@param name string
---@param tool Tool
---@param area_clear_tool Tool
---@param pocket_data PocketParameterData
---@param pos_data ToolpathPosData
---@param geometry_selector GeometrySelector
---@param create_2d_preview boolean
---@param interactive boolean
---@return UUID
function CreatePocketingToolpath(name, tool, area_clear_tool, pocket_data, pos_data, geometry_selector, create_2d_preview, interactive) end

--- Creates a drilling toolpath for the currently selected vectors
---@param name string
---@param tool Tool
---@param drilling_data DrillParameterData
---@param pos_data ToolpathPosData
---@param geometry_selector GeometrySelector
---@param create_2d_preview boolean
---@param interactive boolean
---@return UUID
function CreateDrillingToolpath(name, tool, drilling_data, pos_data, geometry_selector, create_2d_preview, interactive) end

--- Creates a vcarving toolpath for the currently selected vectors
---@param name string
---@param tool Tool
---@param area_clear_tool Tool
---@param vcarve_data VCarveParameterData
---@param pocket_data PocketParameterData
---@param pos_data ToolpathPosData
---@param geometry_selector GeometrySelector
---@param create_2d_preview boolean
---@param interactive boolean
---@return UUID
function CreateVCarvingToolpath(name, tool, area_clear_tool, vcarve_data, pocket_data, pos_data, geometry_selector, create_2d_preview, interactive) end

--- Creates a prism carving toolpath for the currently selected vectors
---@param name string
---@param tool Tool
---@param prism_data PrismCarveParameterData
---@param pos_data ToolpathPosData
---@param geometry_selector GeometrySelector
---@param create_2d_preview boolean
---@param interactive boolean
---@return UUID
function CreatePrismCarvingToolpath(name, tool, prism_data, pos_data, geometry_selector, create_2d_preview, interactive) end

--- Creates a fluting toolpath for the currently selected vectors
---@param name string
---@param tool Tool
---@param fluting_data FlutingParameterData
---@param pos_data ToolpathPosData
---@param geometry_selector GeometrySelector
---@param create_2d_preview boolean
---@param interactive boolean
---@return UUID
function CreateFlutingToolpath(name, tool, fluting_data, pos_data, geometry_selector, create_2d_preview, interactive) end

--- Creates a roughing toolpath
---@param name string
---@param tool Tool
---@param roughing_data RoughingParameterData
---@param pos_data ToolpathPosData
---@param geometry_selector GeometrySelector
---@param interactive boolean
---@return UUID
function CreateRoughingToolpath(name, tool, roughing_data, pos_data, geometry_selector, interactive) end

--- Creates a finishing toolpath for the currently selected vectors
---@param name string
---@param tool Tool
---@param pocket_data PocketParameterData
---@param pos_data ToolpathPosData
---@param geometry_selector GeometrySelector
---@param create_2d_preview boolean
---@param interactive boolean
---@return UUID
function CreateFinishingToolpath(name, tool, pocket_data, pos_data, geometry_selector, create_2d_preview, interactive) end

-------------------------------------------------------------------------------
-- Tool Database
-------------------------------------------------------------------------------

--- Returns a new object which gives access to the single Tool database for the program
---@return ToolDatabase
function ToolDatabase() end

--- Creates a new tool
---@param name string
---@param tool_type ToolType
---@return Tool
function Tool(name, tool_type) end

--- Creates a new ToolpathPosData object with default values
---@return ToolpathPosData
function ToolpathPosData() end

--- Creates a new GeometrySelector object with default values
---@return GeometrySelector
function GeometrySelector() end

--- Creates a new ProfileParameterData object ready to have its parameters set
---@return ProfileParameterData
function ProfileParameterData() end

--- Creates a new RampingData object ready to have its parameters set
---@return RampingData
function RampingData() end

--- Creates a new LeadInData object ready to have its parameters set
---@return LeadInData
function LeadInData() end

--- Creates a new DrillParameterData object ready to have its parameters set
---@return DrillParameterData
function DrillParameterData() end

--- Creates a new VCarveParameterData object ready to have its parameters set
---@return VCarveParameterData
function VCarveParameterData() end

--- Creates a new FlutingParameterData object ready to have its parameters set
---@return FlutingParameterData
function FlutingParameterData() end

--- Creates a new PrismCarveParameterData object ready to have its parameters set
---@return PrismCarveParameterData
function PrismCarveParameterData() end

--- Aspire Only - Creates a new RoughingParameterData object ready to have its parameters set
---@return RoughingParameterData
function RoughingParameterData() end

--- Aspire Only - Creates a new FinishingParameterData object ready to have its parameters set
---@return FinishingParameterData
function FininshingParameterData() end

--- Creates a new external toolpath object
---@param name string
---@param tool Tool
---@param pos_data ToolpathPosData
---@param options ExternalToolpathOptions
---@param contours ContourGroup
---@return ExternalToolpath
function ExternalToolpath(name, tool, pos_data, options, contours) end

--- Creates a new ExternalToolpathOptions object ready to have its parameters set
---@return ExternalToolpathOptions
function ExternalToolpathOptions() end

--- Creates a new object which can be used to save toolpaths
---@return ToolpathSaver
function ToolpathSaver() end

-------------------------------------------------------------------------------
-- User Interface
-------------------------------------------------------------------------------

--- Creates a new dialog object
---@param local_html boolean
---@param html string
---@param width integer
---@param height integer
---@param dialog_name string
---@return HTML_Dialog
function HTML_Dialog(local_html, html, width, height, dialog_name) end

--- Creates a new object used for displaying a File Open / Save dialog
---@return FileDialog
function FileDialog() end

--- Creates a new object used for building lists of files
---@return DirectoryReader
function DirectoryReader() end

--- Creates a new progress bar and displays it in the host program
---@param text string
---@param progress_bar_mode ProgressBarMode
---@return ProgressBar
function ProgressBar(text, progress_bar_mode) end

-------------------------------------------------------------------------------
-- Registry
-------------------------------------------------------------------------------

--- Creates a new object used for reading and writing values in the named registry section
---@param section_name string
---@return Registry
function Registry(section_name) end

-------------------------------------------------------------------------------
-- Easy library
-------------------------------------------------------------------------------

--- Calculates a 2D point from a point based on an angle and distance
---@param point Point2D
---@param ang number
---@param dist number
---@return Point2D
function Polar2D(point, ang, dist) end
