-- Scripting for Archie checkerboard engine.

rowWidthPixels=1024
screenWidth=320
checkSizePixels=400
dzDelta=0.05
maxDepths=512

leftEdge=(rowWidthPixels/2)-(screenWidth/2)
topEdge=checkSizePixels/2

worldLayers={}
cameraLayers={}

function initLayers()
    worldLayers[1]={x=0.0,y=0.0,z=0.0,c={r=0xf,g=0x8,b=0x8}}
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
        c.z=w.z - camPos.z % maxDepths
        if (c.z < 0) then c.z=c.z+maxDepths end

        -- layer x position specified in screen pixel offset, so need to divide by layer distance if in our 'world space'.
        dz = 1 + c.z*dzDelta
        c.x=leftEdge + (w.x - camPos.x) / dz
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

function TIC()

 t=time()
 f=frames()

 -- do something!
 camPos.x=checkSizePixels * math.sin(4 * math.pi * f / maxDepths)
 camPos.y=checkSizePixels * math.sin(4 * math.pi * f / maxDepths)
 camPos.z=2*f % maxDepths
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
