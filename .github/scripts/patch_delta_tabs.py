from pathlib import Path
p = Path('DeltaCustomizationModule.luau')
s = p.read_text(encoding='utf-8')
marker = '\tlocal function savedTabNames()\n'
helper = '''\tlocal normalizingTabs = false
\tlocal function normalizeSavedTabFiles()
\t\tlocal directory = tabDirectory
\t\tif
\t\t\ttype(isfolder) ~= "function"
\t\t\tor type(listfiles) ~= "function"
\t\t\tor type(readfile) ~= "function"
\t\t\tor type(writefile) ~= "function"
\t\t\tor not isfolder(directory)
\t\tthen
\t\t\treturn
\t\tend
\t\tlocal ok, files = pcall(listfiles, directory)
\t\tif not ok or type(files) ~= "table" then
\t\t\treturn
\t\tend
\t\tlocal saved = {}
\t\tfor _, path in files do
\t\t\tlocal name = tostring(path):match("([^/\\\\]+)$")
\t\t\tlocal index = name and tonumber(name:match("^script(%d+)%.lua$"))
\t\t\tif index then
\t\t\t\tlocal readOk, text = pcall(readfile, path)
\t\t\t\tif readOk and type(text) == "string" then
\t\t\t\t\ttable.insert(saved, { index = index, name = name, text = text })
\t\t\t\tend
\t\t\tend
\t\tend
\t\ttable.sort(saved, function(a, b)
\t\t\treturn a.index < b.index
\t\tend)
\t\tlocal keep = {}
\t\tfor index, item in saved do
\t\t\tlocal name = "script" .. tostring(index) .. ".lua"
\t\t\tkeep[name] = true
\t\t\tpcall(writefile, directory .. "/" .. name, item.text)
\t\tend
\t\tif type(delfile) == "function" and type(isfile) == "function" then
\t\t\tfor _, item in saved do
\t\t\t\tif not keep[item.name] then
\t\t\t\t\tlocal path = directory .. "/" .. item.name
\t\t\t\t\tif isfile(path) then
\t\t\t\t\t\tpcall(delfile, path)
\t\t\t\t\tend
\t\t\t\tend
\t\t\tend
\t\tend
\tend

\tlocal function normalizeTabSequence()
\t\tif normalizingTabs or not runtime.alive then
\t\t\treturn
\t\tend
\t\tnormalizingTabs = true
\t\tlocal boxes = getCodeBoxes()
\t\tlocal entries = {}
\t\tlocal keep = {}
\t\tfor index, box in boxes do
\t\t\tlocal oldName = box.Name
\t\t\tlocal newName = "script" .. tostring(index) .. ".lua"
\t\t\tkeep[newName] = true
\t\t\ttable.insert(entries, {
\t\t\t\tbox = box,
\t\t\t\ttab = tabsFrame:FindFirstChild(oldName),
\t\t\t\toldName = oldName,
\t\t\t\tnewName = newName,
\t\t\t\ttext = box.Text or "",
\t\t\t})
\t\tend
\t\tfor index, entry in entries do
\t\t\tif entry.box.Parent then
\t\t\t\tentry.box.Name = entry.newName
\t\t\tend
\t\t\tlocal tab = entry.tab
\t\t\tif tab and tab.Parent then
\t\t\t\ttab.Name = entry.newName
\t\t\t\ttab.LayoutOrder = index
\t\t\t\tlocal title = tab:FindFirstChild("Title", true)
\t\t\t\tif title and title:IsA("TextLabel") then
\t\t\t\t\ttitle.Text = entry.newName
\t\t\t\tend
\t\t\tend
\t\tend
\t\tif type(writefile) == "function" then
\t\t\tfor _, entry in entries do
\t\t\t\tpcall(writefile, tabDirectory .. "/" .. entry.newName, entry.text)
\t\t\tend
\t\tend
\t\tif type(delfile) == "function" and type(isfile) == "function" then
\t\t\tfor _, entry in entries do
\t\t\t\tif entry.oldName ~= entry.newName and not keep[entry.oldName] then
\t\t\t\t\tlocal path = tabDirectory .. "/" .. entry.oldName
\t\t\t\t\tif isfile(path) then
\t\t\t\t\t\tpcall(delfile, path)
\t\t\t\t\tend
\t\t\t\tend
\t\t\tend
\t\tend
\t\tqueueStatusUpdate()
\t\tnormalizingTabs = false
\tend

'''
if 'local function normalizeTabSequence()' not in s:
    if marker not in s:
        raise SystemExit('savedTabNames marker not found')
    s = s.replace(marker, helper + marker, 1)
s = s.replace('\tlocal function savedTabNames()\n\t\tlocal names = {}\n', '\tlocal function savedTabNames()\n\t\tnormalizeSavedTabFiles()\n\t\tlocal names = {}\n', 1)
s = s.replace('\t\trestoringTabs = true\n\t\tlocal saved = savedTabNames()\n', '\t\trestoringTabs = true\n\t\tnormalizeTabSequence()\n\t\tlocal saved = savedTabNames()\n', 1)
old = '''\tconnect(codeFrame.DescendantAdded, function(object)\n\t\tif object:IsA("TextBox") then\n\t\t\ttask.defer(function()\n\t\t\t\thookCodeBox(object)\n\t\t\t\tapplyEditorStyle(object)\n\t\t\t\tqueueStatusUpdate()\n\t\t\tend)\n\t\tend\n\tend)'''
new = '''\tconnect(codeFrame.DescendantAdded, function(object)\n\t\tif object:IsA("TextBox") then\n\t\t\ttask.defer(function()\n\t\t\t\thookCodeBox(object)\n\t\t\t\tapplyEditorStyle(object)\n\t\t\t\tqueueStatusUpdate()\n\t\t\tend)\n\t\t\ttask.delay(0.12, normalizeTabSequence)\n\t\tend\n\tend)'''
if old not in s:
    raise SystemExit('DescendantAdded block not found')
s = s.replace(old, new, 1)
old = '\tconnect(codeFrame.DescendantRemoving, function(object)\n\t\tqueueStatusUpdate()\n'
new = '\tconnect(codeFrame.DescendantRemoving, function(object)\n\t\tqueueStatusUpdate()\n\t\ttask.delay(0.12, normalizeTabSequence)\n'
if old not in s:
    raise SystemExit('DescendantRemoving block not found')
s = s.replace(old, new, 1)
old = '\tbuildToolbar()\n\tapplyToolbarLayout()\n'
new = '\tnormalizeTabSequence()\n\tbuildToolbar()\n\tapplyToolbarLayout()\n'
if old not in s:
    raise SystemExit('startup block not found')
s = s.replace(old, new, 1)
p.write_text(s, encoding='utf-8', newline='\n')
