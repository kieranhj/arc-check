-- Scripting for Archie checkerboard engine.

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

function sortCameraLayers()
    for i=1,#worldLayers do
        w=worldLayers[i]
        c=cameraLayers[i]

        -- wrap layer depth to maxDepths.
        -- TODO: or don't draw it if behind camera!
        c.z=(w.z - camPos.z) % maxDepths

        if (c.z < 0) then
            io.write(string.format("Layer %d behind the camera!z\n", i))
            c.z=c.z+maxDepths
        end

        -- layer x position specified in screen pixel offset, so need to divide by layer distance if in our 'world space'.
        dz = 1 + c.z*dzDelta
        c.x=leftEdge + (w.x - camPos.x) / dz

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
        c.y=topEdge + w.y - camPos.y

        -- fade colour based on distance.
        c.c.r = w.c.r
        c.c.g = w.c.g
        c.c.b = w.c.b
    end
    table.sort(cameraLayers, function (a,b) return a.z > b.z end)
end

function colourLerp(startColour, endColour, delta)
        f=math.modf(16.0*delta)
        return {
        r=math.tointeger(startColour.r + (endColour.r - startColour.r) * f//16),
        g=math.tointeger(startColour.g + (endColour.g - startColour.g) * f//16),
        b=math.tointeger(startColour.b + (endColour.b - startColour.b) * f//16)
    }
end

function get_pattern(frameNo)
    return frameNo // (framesPerRow * rowsPerPattern)
end

function get_row(frameNo)
    return (frameNo % (framesPerRow * rowsPerPattern)) // framesPerRow
end

function camlayerPath_Circle(t, speed, radius)
    local wz=speed * t
    local angle = wz * 2 * math.pi / maxDepths
    return {x=radius * math.sin(angle), y=radius * math.cos(angle), z=wz}
end

function camPath_AlongZ(t, speed)
    return {x=0.0, y=0.0, z=speed * t}
end

function moveCamera(cameraPathFn, ...)
    camPos = cameraPathFn(frames(), ...)
end

function layerPath_Circle(wz)
    local radius = 200
    local angle = wz * 2 * math.pi / maxDepths
    return {x=radius * math.sin(angle), y=radius * math.cos(angle)}
end

function layerDist_Regular(wz)
    return wz % 48 == 0
end

function path_Line(wz)
    return {x=0.0, y=0.0}
end

function updateWorldLayers(layerPathFn, layerDistFn)
    local lz=0
    local i=1

    while (lz < maxDepths and i <= maxLayers) do

        local wz=camPos.z + lz

        if (layerDistFn(wz)) then
            local w=worldLayers[i]

            --- io.write(string.format("add layer %d at z=%d\n", i, z))

            local pos = layerPathFn(wz)
            w.x = pos.x
            w.y = pos.y
            w.z = wz * 1.0

            local delta = lz / 512.0
            if (w.z % 384 == 0) then
                w.c = colourLerp(secondaryColour, BLACK, delta)
            else
                w.c = colourLerp(primaryColour, BLACK, delta)
            end

            if get_pattern(frames()) > 1 and frames() % framesPerBeat == 0 then
                if i == 4 then
                    w.c.r = highlightColour.r
                    w.c.g = highlightColour.g
                    w.c.b = highlightColour.b
                end
            end

            -- io.write(string.format("layer %d lz=%d f=%f\n", i, lz, f))

            --- w.c.r = primaryColour.r
            -- w.c.g = primaryColour.g
            -- w.c.b = primaryColour.b

            i=i+1
        end

        lz=lz+1
    end

end


function part1(t)
 moveCamera(camlayerPath_Circle, 1, 200)
 updateWorldLayers(layerPath_Circle, layerDist_Regular)
 -- do highlights etc.
end

function part2(t)
 moveCamera(camPath_AlongZ, 1)
 updateWorldLayers(path_Line, layerDist_Regular)
end


function TIC()
 sequence = {
    {fs=0,fe=1000,fn=part1},
    {fs=1000,fe=2000,fn=part2}
 }

 f=frames()

 for i=1,#sequence do
    seq=sequence[i]
    if (f >= seq.fs and f < seq.fe) then
        seq.fn(f-seq.fs)
    end
 end

 sortCameraLayers()
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
