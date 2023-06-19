-- Scripting for Archie checkerboard engine.

exportFile = nil -- io.open("lua_frames.txt", "w")
-- exportFile:setvbuf("no")

exportBin = io.open("lua_frames.bin", "wb")
exportBin:setvbuf("no")

debugFile=io.open("lua_debug.txt", "a")
debugFile:setvbuf("no")
io.output(debugFile)

maxLayers=8

rowWidthPixels=1024
screenWidth=320
checkSizePixels=400
dzDelta=0.05
maxDepths=512

framesPerRow=4*50/60.0
rowsPerPattern=64
framesPerPattern=(framesPerRow*rowsPerPattern)

leftEdge=(rowWidthPixels/2)-(screenWidth/2)
topEdge=checkSizePixels/2

worldLayers={}
cameraLayers={}

BLACK={r=0,g=0,b=0}
WHITE={r=0xf,g=0xf,b=0xf}

PINK={r=0xf,g=0x8,b=0x8}
GREEN={r=0x8,g=0xf,b=0x4}
ORANGE={r=0xf,g=0xa,b=0x0}
PURPLE={r=0xc,g=0x6,b=0xf}
GREY={r=0x8,g=0x8,b=0x8}
BLUE={r=0x0,g=0x6,b=0xf}

primaryColour=PINK
secondaryColour=GREY
highlightColour=WHITE

NOTES_SHORT={0,6,12,18}
NOTES_LONG={0,6,12,18,24}

PATTERNS = {}
function initPatterns()
    -- 1-4 intro.
    PATTERNS[5]=NOTES_SHORT
    PATTERNS[6]=NOTES_LONG
    PATTERNS[7]=NOTES_SHORT
    PATTERNS[8]=NOTES_LONG      -- high
    PATTERNS[9]=NOTES_SHORT
    PATTERNS[10]=NOTES_LONG
    PATTERNS[11]=NOTES_SHORT
    PATTERNS[12]=NOTES_LONG     -- high
    -- 13 -> 16 drums kick in (repeated 4x) 
    PATTERNS[17]=NOTES_SHORT
    PATTERNS[18]=NOTES_LONG
    PATTERNS[19]=NOTES_SHORT
    PATTERNS[20]=NOTES_LONG     -- high
    PATTERNS[21]=NOTES_SHORT
    PATTERNS[22]=NOTES_LONG
    PATTERNS[21]=NOTES_SHORT
    PATTERNS[22]=NOTES_LONG     -- high
    -- 23 -> 27 bass tune (repeated 4x)
end

globalFade=1.0

function initLayers()
    io.write(string.format("initLayers(%d)\n", frames()))

    worldLayers[1]={x=0.0,y=0.0,z=0.0,c={r=0x8,g=0x8,b=0x8}}
    worldLayers[2]={x=0.0,y=0.0,z=64.0,c={r=0xf,g=0x8,b=0x8}}
    worldLayers[3]={x=0.0,y=0.0,z=128.0,c={r=0xf,g=0x8,b=0x8}}
    worldLayers[4]={x=0.0,y=0.0,z=192.0,c={r=0xf,g=0x8,b=0x8}}
    worldLayers[5]={x=0.0,y=0.0,z=256.0,c={r=0xf,g=0x8,b=0x8}}
    worldLayers[6]={x=0.0,y=0.0,z=320.0,c={r=0xf,g=0x8,b=0x8}}
    worldLayers[7]={x=0.0,y=0.0,z=384.0,c={r=0xf,g=0x8,b=0x8}}
    worldLayers[8]={x=0.0,y=0.0,z=448.0,c={r=0x8,g=0x8,b=0x8}}
    
    cameraLayers[1]={x=0.0,y=0.0,z=0.0,c={r=0x0,g=0x0,b=0x0}}
    cameraLayers[2]={x=0.0,y=0.0,z=0.0,c={r=0x0,g=0x0,b=0x0}}
    cameraLayers[3]={x=0.0,y=0.0,z=0.0,c={r=0x0,g=0x0,b=0x0}}
    cameraLayers[4]={x=0.0,y=0.0,z=0.0,c={r=0x0,g=0x0,b=0x0}}
    cameraLayers[5]={x=0.0,y=0.0,z=0.0,c={r=0x0,g=0x0,b=0x0}}
    cameraLayers[6]={x=0.0,y=0.0,z=0.0,c={r=0x0,g=0x0,b=0x0}}
    cameraLayers[7]={x=0.0,y=0.0,z=0.0,c={r=0x0,g=0x0,b=0x0}}
    cameraLayers[8]={x=0.0,y=0.0,z=0.0,c={r=0x0,g=0x0,b=0x0}}
end
initLayers()

camPos={x=0.0,y=0.0,z=0.0}

function debugPrintAllLayers(layers)
    io.write(string.format("Layers at frame %d:\n",frames()))
    for i=1,#layers do
        layer=layers[i]
        io.write(string.format("layer[%d] {x=%f,y=%f,z=%f,colour={%d,%d,%d}}\n",
        i,layer.x,layer.y,layer.z,layer.c.r,layer.c.g,layer.c.b))
    end
end

function sortCameraLayers()
    for i=1,#worldLayers do
        w=worldLayers[i]
        c=cameraLayers[i]

        -- wrap layer depth to maxDepths.
        -- TODO: or don't draw it if behind camera!
        c.z=math.modf(w.z - camPos.z) * 1.0

        if (c.z < 0) then
            io.write(string.format("Layer %d behind the camera!\n", i))
            c.z=c.z + maxDepths
        end

        if (c.z > maxDepths) then
            io.write(string.format("Layer %d beyond far clipping plane!\n", i))
            c.z=c.z % maxDepths
        end

        -- layer x position specified in screen pixel offset, so need to divide by layer distance if in our 'world space'.
        dz = 1 + c.z*dzDelta
        c.x=math.modf(leftEdge + (w.x - camPos.x) / dz) * 1.0

        -- this doesn't really help!
        if (c.x < 0) then
            io.write(string.format("Layer %d overflow left! (%f)\n", i, c.x))
            c.x=c.x+rowWidthPixels
        end
        if (c.x >= rowWidthPixels-screenWidth) then
            io.write(string.format("Layer %d overflow right! (%f)\n", i, c.x))
            c.x=c.x-rowWidthPixels
        end

        -- layer y position specified in world space.
        c.y=math.modf(topEdge + w.y - camPos.y) * 1.0

        -- global fade of the screen.
        c.c = colourLerp(BLACK, w.c, globalFade)
    end
    table.sort(cameraLayers, function (a,b) return a.z > b.z end)

    for i=1,#cameraLayers-1 do
        layer1=cameraLayers[i]
        layer2=cameraLayers[i+1]
        if (layer1.c.b > layer2.c.b ) then
            debugPrintAllLayers(worldLayers)
        end
    end
end

function colourLerp(startColour, endColour, delta)
    if (delta < 0.0 or delta > 1.0) then
        io.write(string.format("colourLerp: delta=%f is this expected?\n", delta))
    end

    local lerp=math.modf(16*delta)
    return {
        r=math.tointeger(startColour.r + (endColour.r - startColour.r) * lerp//16),
        g=math.tointeger(startColour.g + (endColour.g - startColour.g) * lerp//16),
        b=math.tointeger(startColour.b + (endColour.b - startColour.b) * lerp//16)
    }
end

function get_pattern(frameNo)
    return frameNo // (framesPerRow * rowsPerPattern)
end

function get_row(frameNo)
    return (frameNo % (framesPerRow * rowsPerPattern)) // framesPerRow
end

function camPath_Circle(t, curZ, speed, radius)
    local wz=curZ+speed
    local angle = wz * 2 * math.pi / maxDepths
    return {x=radius * math.sin(angle), y=radius * math.cos(angle), z=wz}
end

function camPath_LissajousOverTime(t, curZ, speed, radius, xf, yf, xo, yo)
    local wz=curZ+speed
    local angle = t * 2 * math.pi / maxDepths
    return {x=xo + radius * math.sin(xf*angle), y=yo + radius * math.cos(yf*angle), z=wz}
end

function camPath_LissajousOverDist(t, curZ, speed, radius, xf, yf, xo, yo)
    local wz=curZ+speed
    local angle = wz * 2 * math.pi / maxDepths
    return {x=xo + radius * math.sin(xf*angle), y=yo + radius * math.cos(yf*angle), z=wz}
end

function camPath_AlongZ(t, curZ, speed)
    return {x=0.0, y=0.0, z=curZ+speed}
end

function moveCamera(cameraPathFn, t, ...)
    camPos = cameraPathFn(t, camPos.z, ...)
end

function layerPath_Circle(wz, params)
    local radius = params.radius
    local angle = wz * 2 * math.pi / maxDepths
    return {x=radius * math.sin(angle), y=radius * math.cos(angle)}
end

function layerPath_LissajousOverDist(wz, params)
    local radius = params.radius
    local angle = wz * 2 * math.pi / maxDepths
    return {x=params.xo + radius * math.sin(params.xf*angle), y=params.yo + radius * math.cos(params.yf*angle)}
end

function layerPath_LissajousOverTime(wz, params)
    local radius = params.radius
    local angle = (wz + params.t) * 2 * math.pi / maxDepths
    return {x=params.xo + radius * math.sin(params.xf*angle), y=params.yo + radius * math.cos(params.yf*angle)}
end

function layerDist_Regular(wz, params)
    return wz % params.spacing == 0
end

function layerPath_Origin(wz, params)
    return {x=0.0, y=0.0}
end

function colourBipLayer(t, wz, layer_no, params)
    local col = primaryColour

    if (wz % params.secondary_spacing == 0) then
        col = secondaryColour
    end

    if (params.bipFrames) then
        for i=1,#params.bipFrames do
            bip=params.bipFrames[i]
            if (t >= bip.t1 and t < (bip.t1+bip.t2) and bip.wz == wz) then
                local d = (t - bip.t1) / bip.t2
                col = colourLerp(highlightColour, col, d)
            end
        end
    end

    return col
end

function updateWorldLayers(t, layerPathFn, pathParams, layerDistFn, distParams, colourFn, colourParams)
    local lz=0
    local i=1

    while (lz < maxDepths and i <= maxLayers) do

        local wz = math.ceil(camPos.z + lz)

        if (layerDistFn(wz, distParams)) then
            local w=worldLayers[i]

            -- io.write(string.format("add layer %d at z=%d\n", i, z))

            local pos = layerPathFn(wz, pathParams)
            w.x = pos.x
            w.y = pos.y
            w.z = wz * 1.0

            local delta = lz / 512.0
            local c = primaryColour

            if (colourParams) then
                if (colourParams.fadeDepth) then
                    delta = lz / colourParams.fadeDepth
                end
            end

            if (colourFn) then
                c = colourFn(t, wz, i, colourParams)
            else
                -- TODO: A better way of specifying the layer colour.
                if (w.z % 192 == 0) then
                    c = secondaryColour -- colourLerp(secondaryColour, BLACK, delta)
                end
            end

            -- distance fade.
            w.c = colourLerp(c, BLACK, delta)
            i=i+1
        end

        lz=lz+1
    end

    while (i <= maxLayers) do
        -- We have unused layers.
        local w=worldLayers[i]
        w.x = 0.0
        w.y = 0.0
        w.z = camPos.z + maxDepths - 1.0
        w.c.r = 0
        w.c.g = 0
        w.c.b = 0
        i=i+1
    end

end

function layerDist_FarMesh(wz, params)
    if (wz < params.firstLayerZ) then return false end
    return (wz - params.firstLayerZ) % params.spacing == 0
end

function layerDist_NearMesh(wz, params)
    if (wz > params.lastLayerZ) then return false end
    return (wz) % params.spacing == 0
end

function part1(t, zStart, totalFrames) -- zoom towards mesh
 local sp=2
 if (t < framesPerPattern) then sp=0.5
 elseif (t < 2*framesPerPattern) then
   sp=0.5+1.5*((t-framesPerPattern)/framesPerPattern)
 end

 primaryColour=PINK
 moveCamera(camPath_AlongZ, t, sp)
 updateWorldLayers(t,
    layerPath_Origin, nil,
    layerDist_FarMesh,
    {spacing=32, firstLayerZ=512},
    colourBipLayer,
    {secondary_spacing=192})
 -- TODO: Sure we can do better than this for highlights!
-- bipFrames={
--    {t1=256,t2=16,wz=512+32},
--    {t1=256+64,t2=16,wz=512+96},
--    {t1=256+128,t2=16,wz=512+160},
--    {t1=256+160,t2=16,wz=512+224},
--    {t1=256+256,t2=16,wz=512+288},
--    {t1=256+320,t2=16,wz=512+352},
globalFade=1.0
end

function part2(t, zStart, totalFrames) -- circle tunnel
 local radius = 400 * math.sin(t/100)
 local sp = 2.0
 
 local colsp = framesPerPattern
 local colsel={GREEN,PURPLE,PINK,ORANGE}
 local col1 = colsel[((t//colsp)%4)+1]
 local col2 = colsel[(((t//colsp)+1)%4)+1]
 local framesToNextCol = (t%colsp)
 local colft = 100

 if (t < colsp*2) then
    primaryColour = PINK
 else
    if (framesToNextCol < colft) then
        primaryColour = colourLerp(col1, col2, framesToNextCol/colft)
    else
        primaryColour = col2
    end
 end
 moveCamera(camPath_Circle, t, sp, radius)
 updateWorldLayers(t, layerPath_Circle, {radius=radius}, layerDist_Regular, {spacing=32})

 if (totalFrames-t < 100) then globalFade = (totalFrames-t)/100 else globalFade=1.0 end
end

function part3(t, zStart, totalFrames) -- tight circlular tunnel
    local radius = 200 * math.sin(t/100)
    local sp = 1.0

    local colsp = 50
    local colsel={GREEN,PURPLE,PINK,ORANGE,BLUE}
    local col1 = colsel[((t//colsp)%5)+1]
    local col2 = colsel[(((t//colsp)+1)%5)+1]

    local d = (t%colsp)/colsp
    primaryColour = colourLerp(col1, col2, d)

    moveCamera(camPath_Circle, t, sp, radius)
    updateWorldLayers(t, layerPath_Circle, {radius=radius}, layerDist_NearMesh, {spacing=16, lastLayerZ=zStart+712+(totalFrames)*sp}, nil, {fadeDepth=160.0})
    globalFade = 1.0
    -- if (totalFrames-t < 100) then globalFade = (totalFrames-t)/100 else globalFade=1.0 end
end

function part4(t, zStart, totalFrames) -- backwards circular tunnel
    local radius = 400 * math.sin(t/100)
    local sp = -2.0
   
    globalFade = 1.0
    primaryColour = PURPLE
    local colsel={PINK,ORANGE,GREEN,PURPLE}
    primaryColour = colsel[((frames()//(framesPerPattern/2))%4)+1]
    
    moveCamera(camPath_Circle, t, sp, radius)
    updateWorldLayers(t, layerPath_Circle, {radius=radius}, layerDist_Regular, {spacing=48})
    -- if (totalFrames-t < 100) then globalFade = (totalFrames-t)/100 else globalFade=1.0 end
end

function part5(t, zStart, totalFrames) -- hover over mesh
    local radius = 800
    camPos.z=0.0

    primaryColour = BLUE
    moveCamera(camPath_LissajousOverTime, t, 0.1, radius, 1.5, 1.0, 0.0, 0.0)
    updateWorldLayers(t, layerPath_Origin, nil, layerDist_FarMesh, {spacing=32, firstLayerZ=32}, nil, {fadeDepth=320.0})
    if (totalFrames-t < 100) then globalFade = (totalFrames-t)/100 else globalFade=1.0 end
end

function part6(t, zStart, totalFrames) -- lissajous forward motion
    local radius = 400
    local sp = 0.5

    local colsp = framesPerPattern
    local colsel={PINK,ORANGE,GREEN,PURPLE}
    local col1 = colsel[((t//colsp)%4)+1]
    local col2 = colsel[(((t//colsp)+1)%4)+1]
    local framesToNextCol = (t%colsp)
    local colft = 100

    if (t < colsp) then
        primaryColour = ORANGE
     else
        if (framesToNextCol < colft) then
            primaryColour = colourLerp(col1, col2, framesToNextCol/colft)
        else
            primaryColour = col2
        end
    end

    moveCamera(camPath_LissajousOverDist, t, sp, radius, 1.1, 1.6, 0, 0)
    updateWorldLayers(t, layerPath_LissajousOverDist, {radius=radius,xf=1.1,yf=1.6,xo=0.0,yo=0.0}, layerDist_Regular, {spacing=96})
    if (totalFrames-t < 100) then globalFade = (totalFrames-t)/100 else globalFade=1.0 end
end

function part7(t, zStart, totalFrames) -- hover over moving mesh
    local radius = 600
    camPos.z=0.0

    local colsp = framesPerPattern
    local colsel={ORANGE,GREEN,PURPLE,PINK}
    local col1 = colsel[((t//colsp)%4)+1]
    local col2 = colsel[(((t//colsp)+1)%4)+1]
    local framesToNextCol = (t%colsp)
    local colft = 50

    if (t < colsp) then
        primaryColour = GREEN
     else
        if (framesToNextCol < colft) then
            primaryColour = colourLerp(col1, col2, framesToNextCol/colft)
        else
            primaryColour = col2
        end
    end
    
    moveCamera(camPath_AlongZ, t, -0.1)
    updateWorldLayers(t, layerPath_LissajousOverTime, {radius=radius,xf=1.1,yf=1.6,xo=0.0,yo=0.0,t=t}, layerDist_FarMesh, {spacing=48, firstLayerZ=48})
    if (totalFrames-t < 100) then globalFade = (totalFrames-t)/100 else globalFade=1.0 end
end

f=-1
lastFrame=-1
lastPlaying=-1
function TIC()
 sequence = {
    {fs=0,fn=part1,zs=-1},                      -- fly to start [build up]
    {fs=framesPerPattern*2,fn=part2,zs=-1},     -- circular tunnell [highlights 1]
    {fs=framesPerPattern*8,fn=part5,zs=-1},     -- hover over [highlights 2]
    {fs=framesPerPattern*12,fn=part4,zs=-1},    -- drum repeats
    {fs=framesPerPattern*12.5,fn=part4,zs=-1},    -- drum repeats
    {fs=framesPerPattern*13,fn=part4,zs=-1},    -- drum repeats
    {fs=framesPerPattern*13.5,fn=part4,zs=-1},    -- drum repeats
    {fs=framesPerPattern*14,fn=part4,zs=-1},    -- drum repeats
    {fs=framesPerPattern*14.5,fn=part4,zs=-1},    -- drum repeats
    {fs=framesPerPattern*15,fn=part4,zs=-1},    -- drum repeats
    {fs=framesPerPattern*15.5,fn=part4,zs=-1},    -- drum repeats
    {fs=framesPerPattern*16,fn=part6,zs=-1},    -- backwards circular [highlights]
    {fs=framesPerPattern*20,fn=part7,zs=-1},    -- hover over moving [credits]
    {fs=framesPerPattern*24,fn=part3,zs=-1},    -- tight tunnel [bass]
 }

 if (frames() < f) then
  camPos={x=0.0,y=0.0,z=0.0}
 end

 f=frames()
 
 for i=1,#sequence do
    seq=sequence[i]
    next=sequence[i+1]
    if (next) then fe=next.fs else fe=framesPerPattern*28 end
    if (f >= seq.fs and f < fe) then
        local t=f-seq.fs
        if (t==0) then seq.zs=camPos.z end
        if (seq.fn) then seq.fn(t, seq.zs, fe-seq.fs) end
    end
 end

 sortCameraLayers()

 if (f~=lastFrame) then
    if (f>lastFrame) then
        if (exportFile) then exportFrame(exportFile) end
        if (exportBin) then exportFrameBin(exportBin) end
    end
    lastFrame=f
 end

 if (is_running()~=lastPlaying) then
    lastPlaying=is_running()
    if (exportFile) then exportFile:flush() end
    if (exportBin) then exportBin:flush() end
 end
end

function to_rgb(col)
    return 256*col.b+16*col.g+col.r
end

function get_track_value(track_no)
 local layer_no = 1 + track_no // 4
 local field_no = track_no % 4
 local layer = cameraLayers[layer_no]

 if (field_no == 0) then return layer.x end
 if (field_no == 1) then return layer.y end
 if (field_no == 2) then return layer.z end
 if (field_no == 3) then return 256*layer.c.b+16*layer.c.g+layer.c.r end

 return -1
end

function exportFrame(handle)
    handle:write(string.format("frame=%d\n", f))
    for i=1,#cameraLayers do
        layer=cameraLayers[i]
        handle:write(string.format("track[%d]={x=%f,y=%f,z=%f,c=0x0%x%x%x}\n", i, layer.x, layer.y, layer.z, layer.c.b, layer.c.g, layer.c.r))
    end
end

function writeShort(handle, short)
    low_byte = short & 0xff
    high_byte = (short >> 8) & 0xff
    handle:write(string.format("%c%c",low_byte,high_byte))
end

function exportFrameBin(handle)
    -- writeShort(handle, f)
    for i=1,#cameraLayers do
        layer=cameraLayers[i]
        writeShort(handle, math.tointeger(math.modf(layer.x)))
        writeShort(handle, math.tointeger(math.modf(layer.y)))
        writeShort(handle, math.tointeger(math.modf(layer.z)))
        writeShort(handle, to_rgb(layer.c))
    end
end
