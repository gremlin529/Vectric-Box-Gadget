## Changelog

Changes made to the Simple Box Creator gadget on the `users/hardiagithub/...` branches, newest first. Commit hashes are given where available.

### 2026-10-29

- **Groove deeper than half the material thickness is a warning, not an error** (`56b317f`)
  `GrooveDepthMessage` in `DisplayDialog.xlua` now only reports real errors: a depth of 0 or less, or a groove as deep as the wall. Deeper than half the thickness, `GrooveDepthWarning` shows an orange warning with the wall that stays behind the groove; OK shows it once and still goes ahead. Applies to the bottom and the lid groove (`WarnBottomGrooveDepth` / `WarnLidGrooveDepth`).

- **Lid finger recess: depth limit is a warning, not an error** (`56b317f`)
  A finger recess (Finger Hole, not cut through) may be any depth short of the lid thickness (as deep as the lid is an error pointing to "Cut through"). Deeper than half the lid thickness, `LidRecessDepthWarning` shows an orange warning (`WarnLidHoleDepth`). Replaces the check from 10/27 (`af44d74`).

### 2026-10-28

- **Warning for a thin wall strip beside a groove** (`6f258fb`)
  When 3 mm or less stays below the bottom groove (to the walls' bottom edge) or above the lid groove (to the top edge), the Groove offset field turns orange. Allowed but fragile, so OK shows the warning once and still goes ahead (`GrooveStripWarnings`).

- **Groove depth at most half the material thickness, live validation** (`79f46ca`)
  First version of the depth limit as a hard error; relaxed to a warning on 10/29.

- **Dialog: Grooved Lid Options above Grooved Bottom Options** (`0e37f99`)

### 2026-10-27

- **Lid grip: Rectangle finger hole, through or set depth, "Indented Handle"** (`fbc9de7`, `6faa9e7`)
  Finger hole is Round or Rectangle (width across, length along the depth, corner radius), cut through or as a recess of `lidHoleDepth` in the lid's top face. Distance from the rearmost edge at least 3 mm; the hole must end before the Front's inside face and stay clear of the rabbet bands. New grip type "Indented Handle" (grip tab plus hole; the distance is then measured from the tip of the tab, and at least 3 mm of tab must stay on each side, checked against the tab shape). All hole fields are validated live. Saved "Rounded Square" becomes a square Rectangle, saved "Handle + Hole" becomes "Indented Handle".

- **Grooved Lid Options in two tabs, "Lid & Groove" and "Grip"** (`7210fa8`, `1b8e617`)
  The Grip tab label shows the selected grip ("Add a Grip" when none, otherwise "Grip: Finger Hole" etc.), so it is visible without switching tabs. A tab label turns red when a field on it is invalid while it is hidden.

- **Finger recess must leave at least 2 mm of lid** (`af44d74`)
  Replaced by a warning on 10/29.

- **Release script (gremlin529)** (`168e208`, `4d290cc`)
  `MakeRelease.ps1` used HTM instead of HTML; now checks and preserves the extension.

### 2026-10-26

- **Grip dropdown: None / Finger Hole / Grab Handle** (`78c90a7`)
  Replaces the grip tab checkbox (gremlin's suggestion). None and Finger Hole: no overhang, the lid ends flush with the Back. Finger Hole is pocketed (own toolpath "Lid Finger Hole"), so no loose slug is left. A saved "grip tab unticked" comes up as None.

- **Front/Back/Left/Right everywhere in the dialog** (`175d592`)
  Labels, tooltips, messages, comments and grip sketches use Front/Back/Left/Right instead of End 1/End 2/Side 1/Side 2, including the Grooved Bottom and Open Chamfer sections. Variable and function names in the code are unchanged. Checkbox renamed to "Grip tab overhangs the Back". Grip width is validated live (`ValidateLidGripWidth`, `InvalidLidGripWidth`): > 0 and at most the inside width minus twice the lid groove depth.
  **Renamed:** the flip sheet "End 1 Groove (flipped)" is now **"Front Groove (flipped)"**, its layer "End 1 Flip Outline" is now **"Front Flip Outline"**. Existing jobs with the old name get an additional sheet on the next run.

- **Grip tab: S-curve rounding, no dogbone offset on the lid** (`e2f70e7`)
  With a corner radius >= the overhang, each corner runs out into the back edge in an S-curve (convex arc blended into the edge by a concave fillet); the tab stays exactly `grip_width` wide at the back edge. The dogbone/dovetail offset only handles straight spans and turned the grip arcs into chords, so the Grooved lid is now offset normally. Only the Grooved lid is affected; all other parts are unchanged.

- **Shared sheet for an equally thin bottom and lid** (`fee91e7`)
  Grooved bottom and Grooved lid both thinner than the material and equally thick share one sheet "Bottom + Lid Panel <thickness>", one pair of layers and one cutout toolpath. The rabbets stay separate toolpaths. Different thicknesses, or only one of the two parts ticked under Faces To Machine, keep separate sheets.

- **Dovetails: Front lid groove on the flip sheet** (`ae3fdd8`)
  With "Reverse Front for lid groove on own sheet" the lid groove is cut on the same mirrored helper part as the bottom groove (own group, own depth), so the Front only has to be turned over once. The lid then also reaches into the Front groove (U-shaped rabbet). Unticked, the Front gets no lid groove and the lid stops at its inside face.

- **Grip tab can be switched off** (`87cc9f3`)
  Superseded the same day by the Grip dropdown.

### 2026-10-25

- **New lid type "Grooved": sliding lid with grip tab** (`1a00a46`)
  The mirror image of the Grooved bottom: grooves near the top of Left, Right and Front; the Back is shortened to the lid's underside so the lid slides in from the back. The lid reaches into the three grooves (with clearance) and ends flush with the Back; only a centred grip tab (Square, Rounded or Arc) sticks out, the rest of the overhang is cut flush. A lid thicker than the groove gets the rabbet on its top face, so the underside runs on the groove floor and the top can sit flush with the walls. Groove offset measured from the top to the groove ("Groove") or to the lid's top face ("Lid", 0 = flush). A lid thinner than the material goes on its own sheet "Lid Panel <thickness>". Own toolpaths "Lid Groove" and "Lid Rabbet". The finger pitch stays the same on every corner. All existing lid/bottom types produce the same geometry as before.

### 2026-10-15

- **Groove offset measured to the groove bottom or to the underside of the bottom panel (#86)** (`07f9037`)
  New "Offset to" choice: "Groove" (to the groove bottom) or "Bottom" (to the underside of the bottom panel, e.g. the clearance under a drawer). Older saves are converted so the groove stays where it was.

### 2026-10-09

- **Dovetails + Grooved bottom: Front groove on its own flip sheet** (`331dab7`)
  Optional mirrored helper part on a sheet of its own (upright at X0/Y0), so the Front can be turned over and the groove cut into its inside face. "Bottom same material" replaced by a free "Bottom Thickness" (default = material thickness); a rabbet only where the panel is thicker than the groove; a thinner bottom goes on its own sheet "Bottom Panel <thickness>". The rabbet is one U-shaped band instead of three overlapping rectangles (VCarve dropped the Front band).

- **Rabbet band reaches one tool diameter past the panel edge** (`894b2fd`)
  Any bit fits however narrow the groove depth; the inner edge stays exactly at the groove depth. The tool-fit check moved from groove depth to groove width (the groove in the wall is a closed slot).

- **Shared rabbet function, groove depth vs. bit check (gremlin529)** (`6acc09b`)

- **Sketch: Bottom Clearance in blue, no German terms in tooltips** (`066fa39`)

- **Open Chamfer options: Back/Front sub-panels** (`3ba6787`)

### 2026-10-07 / 2026-10-08

- **Open Chamfer and Grooved Bottom: input fields placed at the sketches** (`4f997a4`, `110d878`)
  Table layout instead of absolute positions, so the sketch zooms with the dialog.

- **gremlin529:** comment translation via GitHub Action, README updated for the new gadget name, Open Chamfer registry fix (`0ee03e7`).

### 2026-10-06

- **gremlin529: Open Chamfer as its own lid type** (`f75d16c`, `887ae96`, `de636a9`, `5033241`)
  Chamfer options split from Lid Type = None; only validated when actually used.

- **New sketch for the Grooved Bottom options** (`8153999`)
  Section through the drawer with "Detail A" of the groove at the Front.

- **Fix: chamfer check compares against the inner depth, not the inner width** (`9e33938`)
  Since the Width/Depth fix (PR #71) Left/Right run along the box depth; the check still used `inner_width`, wrongly rejecting chamfers on boxes deeper than wide.

### 2026-09-22

- **Fix: Left/Right bottom groove stops half a material thickness short of the Front corner**
  The panel only seats at the Front, it slides in at the Back, which stays open.

### 2026-09-21

- **Grooved bottom from the same material** with a rabbet on 3 sides, plus "Groove clearance" and "Rabbet correction" fields.
- **Fix: bottom panel size** along the Front/Back axis (one material thickness was missing; the panel runs out to the Back's outer face).
- **Groove offset measured to the top edge of the groove** (as in the sketch); default and validation adjusted.
- **Fix: rabbet band was shortened by the groove clearance**, leaving a full-thickness strip at the groove floor.
- **Sketch for the Grooved bottom options** (PNG, as the IE7 dialog does not render SVG).
- **Fix: notch in Left/Right at the Back corner** with a Grooved bottom; the wall now runs out to the true outer edge there.

### 2026-09-20

- **Independent end height for Front and Back** for the side top overhang.
- **Chamfer defined by an angle** instead of a width, separately for Front and Back.
- **Fix: finger offset with a Grooved bottom** (`ComputeFingerTrim` dropped partial shortfalls; trim margin drawn at the wrong end).
- **UI: chamfer angle next to the end height field.**

### 2026-09-19

- **Fix: finger size at the Grooved corner** with the side top overhang (pitch from a common reference height).
- **Fix: language-independent sheet lookup** (by sheet ID instead of the name "Sheet 1", which differs on localized VCarve).
- **Dovetails: no Front groove** (it collided with the dovetails); with Box joints the Front groove stops half a thickness short of each edge.

### 2026-09-18

- **New bottom type "Grooved" (sliding bottom):** dado grooves in Left, Right and Front, Back left open so the panel slides in from the back; own groove pocket toolpath, dialog fields, validation and registry save/load. Unknown Lid/Bottom Type values fall back to a default.
