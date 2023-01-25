# Generate code for plotting checkerboards.

import argparse
import binascii
import sys
import os
import struct
from enum import Enum

X_POS=160
CAMERA_Z=-160
CAMERA_X=0
VIEWPORT_WIDTH=160
CANVAS_WIDTH=640

if __name__ == '__main__':
    parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("z_pos", type=int, help="Depth value to generate.")
    parser.add_argument("-o", "--output", metavar="<output>", help="Write ARM asm file to <output> (default is 'bytecodes.asm')")
    parser.add_argument("-v", "--verbose", action="store_true", help="Print all the debugs")
    args = parser.parse_args()

    global g_verbose
    g_verbose=args.verbose

    dst = args.output
    if dst == None:
        dst = "checks.asm"

    asm_file = open(dst, 'w')

    # Standard header.
    z_pos = args.z_pos
    asm_file.write(f'; Generated code for z_pos={z_pos}.\n')

    # x' = vpw * (x - cx) / (z - cz)
    x_dash = VIEWPORT_WIDTH * (X_POS - CAMERA_X) / (z_pos - CAMERA_Z)
    # This is the half-width of a square at this depth.
    print(f'x_dash={x_dash}\n')

    # Plot pixels across the canvas centred on 0, so -CANVAS_WIDTH/2 => CANVAS_WIDTH/2
    for x in range(-CANVAS_WIDTH/2, CANVAS_WIDTH/2):
        

    # Output Archie ARM asm.

    asm_file.close()
