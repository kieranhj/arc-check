-- Scripting for Archie checkerboard engine.

debugFile=io.open("lua_debug.txt", "a")
io.output(debugFile)

maxLayers=8

rowWidthPixels=1024
screenWidth=320
checkSizePixels=400
dzDelta=0.05
maxDepths=512

leftEdge=(rowWidthPixels/2)-(screenWidth/2)
topEdge=checkSizePixels/2

worldLayers={}
cameraLayers={}

function makeWorldLayers(zStart, zStep)
    for i=1,maxLayers do
        w=worldLayers[i]
        w.x=0.0
        w.y=0.0
        w.z=zStart + (i-1)*zStep
    end
end

function initLayers()
    io.write("initLayers()\n")

    worldLayers[1]={x=0.0,y=0.0,z=0.0,c={r=0x8,g=0x8,b=0x8}}
    worldLayers[2]={x=0.0,y=0.0,z=64.0,c={r=0xf,g=0x8,b=0x8}}
    worldLayers[3]={x=0.0,y=0.0,z=128.0,c={r=0xf,g=0x8,b=0x8}}
    worldLayers[4]={x=0.0,y=0.0,z=192.0,c={r=0xf,g=0x8,b=0x8}}
    worldLayers[5]={x=0.0,y=0.0,z=256.0,c={r=0xf,g=0x8,b=0x8}}
    worldLayers[6]={x=0.0,y=0.0,z=320.0,c={r=0xf,g=0x8,b=0x8}}
    worldLayers[7]={x=0.0,y=0.0,z=384.0,c={r=0xf,g=0x8,b=0x8}}
    worldLayers[8]={x=0.0,y=0.0,z=448.0,c={r=0x8,g=0x8,b=0x8}}

    --- makeWorldLayers(0.0,32.0)

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

        if (c.z < 0) then c.z=c.z+maxDepths end

        -- layer x position specified in screen pixel offset, so need to divide by layer distance if in our 'world space'.
        dz = 1 + c.z*dzDelta
        c.x=leftEdge + (w.x - camPos.x) / dz

        -- this doesn't really help!
        if (c.x < 0) then c.x=c.x+1024.0 end
        if (c.x >= 1024) then c.x=c.x-1024.0 end

        -- layer y position specified in world space.
        c.y=topEdge + w.y - camPos.y

        -- fade colour based on distance.
        f=math.modf(16.0*(maxDepths-c.z)/maxDepths)
        c.c.r=math.tointeger(w.c.r*f//16)
        c.c.g=math.tointeger(w.c.g*f//16)
        c.c.b=math.tointeger(w.c.b*f//16)
    end
    table.sort(cameraLayers, function (a,b) return a.z > b.z end)
end

function path_Spring(t, speed)
    wz=speed * t
    radius = 200
    angle = wz * 2 * math.pi / maxDepths
    return {x=radius * math.sin(angle), y=radius * math.cos(angle), z=wz}
end

function path_linearZ(t, speed)
    return {x=0.0, y=0.0, z=speed * t} -- * t % maxDepths}
end

function moveCamera(cameraPathFn, pathParam)
    camPos = cameraPathFn(frames(), pathParam)
    -- camPos.z=1*f % maxDepths
    -- scale = 0 -- 1.0 - camPos.z / maxDepths
    -- camPos.x=4*checkSizePixels * math.cos(4 * math.pi * f / maxDepths) * scale
    -- camPos.y=4*checkSizePixels * math.sin(4 * math.pi * f / maxDepths) * scale
end

function path_Circle(wz)
    radius = 200
    angle = wz * 2 * math.pi / maxDepths
    return {x=radius * math.sin(angle), y=radius * math.cos(angle)}
end

function dist_Even(z)
    -- io.write(string.format("dist_Even: z=%d z MOD 32=%d\n",z, z%32))
    return z % 48 == 0
end

function path_Line(wz)
    return {x=0.0, y=0.0}
end

function updateWorldLayers(layerPathFn, layerDistFn)
    t=0
    i=1

    while (t < maxDepths and i <= maxLayers) do

        z=camPos.z + t

        if (layerDistFn(z)) then
            w=worldLayers[i]

            --- io.write(string.format("add layer %d at z=%d\n", i, z))

            pos = layerPathFn(z)
            w.x = pos.x
            w.y = pos.y
            w.z = z * 1.0

            i=i+1
        end

        t=t+1
    end

end

radius=10
amp=0

function moveWorldLayers()
    for i=1,#worldLayers do
        w=worldLayers[i]

        z=w.z - camPos.z % maxDepths
        if (z < 0) then z=z+maxDepths end

        angle=i+t*3.01 -- decimal gives some rotation
        x=math.sin(angle)*radius
        y=math.cos(angle)*radius
    
        oa=(i+f*3.01)/50
        ox=x+math.sin(oa)*z*amp
        oy=y+math.cos(oa)*z*amp

        w.x=ox
        w.y=oy
    end
end

function TIC()

 f=frames()

 -- do something!
 moveCamera(path_Spring, 1)
 --- moveWorldLayers()
 updateWorldLayers(path_Circle, dist_Even)
 sortCameraLayers()

end

function get_track_value(track_no)
 layer_no = 1 + track_no // 4
 field_no = track_no % 4
 layer = cameraLayers[layer_no]

 if (field_no == 0) then return layer.x end
 if (field_no == 1) then return layer.y end
 if (field_no == 2) then return layer.z end
 if (field_no == 3) then return 256*layer.c.b+16*layer.c.g+layer.c.r end

 return -1
end
