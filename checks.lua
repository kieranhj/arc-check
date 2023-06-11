-- Scripting for Archie checkerboard engine.

exportFile=io.open("lua_frames.txt", "w")
exportFile:setvbuf("no")

exportBin=io.open("lua_frames.bin", "wb")
exportBin:setvbuf("no")

debugFile=io.open("lua_debug.txt", "a")
io.output(debugFile)

maxLayers=8

rowWidthPixels=1024
screenWidth=320
checkSizePixels=400
dzDelta=0.05
maxDepths=512

framesPerRow=6
rowsPerPattern=64
framesPerBeat=48
framesPerPattern=(framesPerRow*rowsPerPattern)

leftEdge=(rowWidthPixels/2)-(screenWidth/2)
topEdge=checkSizePixels/2

worldLayers={}
cameraLayers={}

BLACK={r=0,g=0,b=0}
WHITE={r=0xf,g=0xf,b=0xf}

primaryColour={r=0xf,g=0x8,b=0x8}
secondaryColour={r=0x8,g=0x8,b=0x8}
highlightColour={r=0xf,g=0xf,b=0xf}


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

        -- fade colour based on distance.
        c.c.r = w.c.r
        c.c.g = w.c.g
        c.c.b = w.c.b
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
    if (delta < 0.0 or delta >= 1.0) then
        io.write(string.format("colourLerp: delta=%f\n", delta))
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

function camPath_Lissajous(t, curZ, speed, radius, xf, yf)
    local wz=curZ+speed
    local angle = t * 2 * math.pi / maxDepths
    return {x=radius * math.sin(xf*angle), y=radius * math.cos(yf*angle), z=wz}
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

function layerDist_Regular(wz, params)
    return wz % params.spacing == 0
end

function layerPath_Origin(wz, params)
    return {x=0.0, y=0.0}
end

function updateWorldLayers(layerPathFn, pathParams, layerDistFn, distParams)
    local lz=0
    local i=1

    while (lz < maxDepths and i <= maxLayers) do

        local wz = math.ceil(camPos.z + lz)

        if (layerDistFn(wz, distParams)) then
            local w=worldLayers[i]

            --- io.write(string.format("add layer %d at z=%d\n", i, z))

            local pos = layerPathFn(wz, pathParams)
            w.x = pos.x
            w.y = pos.y
            w.z = wz * 1.0

            local delta = lz / 512.0
            if (w.z % 192 == 0) then
                w.c = colourLerp(secondaryColour, BLACK, delta)
            else
                w.c = colourLerp(primaryColour, BLACK, delta)
            end

            --if get_pattern(frames()) > 1 and frames() % framesPerBeat == 0 then
            --    if i == 4 then
            --       w.c.r = highlightColour.r
            --       w.c.g = highlightColour.g
            --       w.c.b = highlightColour.b
            --    end
            --end

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

function part1(t, zStart)
 local sp=2
 if (t < framesPerPattern) then sp=0.5
 elseif (t < 2*framesPerPattern) then
   sp=0.5+1.5*((t-framesPerPattern)/framesPerPattern)
 end

 moveCamera(camPath_AlongZ, t, sp)
 updateWorldLayers(layerPath_Origin, nil, layerDist_FarMesh, {spacing=32, firstLayerZ=512})

 -- do highlights etc.
end

function part2(t, zStart)
 local radius = 400 * math.sin(t/100)
 local sp = 2.0

 moveCamera(camPath_Circle, t, sp, radius)
 updateWorldLayers(layerPath_Circle, {radius=radius}, layerDist_Regular, {spacing=32})
end

function part3(t, zStart)
    local radius = 200 * math.sin(t/100)
    local sp = 1.0
   
    moveCamera(camPath_Circle, t, sp, radius)
    updateWorldLayers(layerPath_Circle, {radius=radius}, layerDist_Regular, {spacing=16})
end

function part4(t, zStart)
    local radius = 400 * math.sin(t/100)
    local sp = -1.0
   
    moveCamera(camPath_Circle, t, sp, radius)
    updateWorldLayers(layerPath_Circle, {radius=radius}, layerDist_Regular, {spacing=64})
end

function part5(t, zStart)
    local radius = 600
    camPos.z=0.0
    moveCamera(camPath_Lissajous, t, 0, radius, 1.5, 1.0)
    updateWorldLayers(layerPath_Origin, nil, layerDist_FarMesh, {spacing=32, firstLayerZ=32})
end

lastFrame=-1
lastPlaying=-1
function TIC()
 sequence = {
    {fs=0,fe=framesPerPattern*2,fn=part1,zs=-1},
    {fs=framesPerPattern*2,fe=framesPerPattern*3,fn=part2,zs=-1},
    {fs=framesPerPattern*3,fe=framesPerPattern*4,fn=part4,zs=-1},
    {fs=framesPerPattern*4,fe=framesPerPattern*5,fn=part3,zs=-1},
    {fs=framesPerPattern*5,fe=9999,fn=part5,zs=-1},
 }

 f=frames()
 -- TODO: Allow jump forward in time by running sequence for N frames if there's gap.

 if (f==0) then
    camPos={x=0.0,y=0.0,z=0.0}
 end

 for i=1,#sequence do
    seq=sequence[i]
    if (f >= seq.fs and f < seq.fe) then
        local t=f-seq.fs
        if (t==0) then seq.zs=camPos.z end
        seq.fn(t, seq.zs)
    end
 end

 sortCameraLayers()

 if (f~=lastFrame) then
    lastFrame=f
    if (exportFile) then exportFrame(exportFile) end
    if (exportBin) then exportFrameBin(exportBin) end
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
